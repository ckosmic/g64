-- luabsp by h3xcat: https://github.com/h3xcat/gmod-luabsp
-- ckosmic: reads displacement info/vertices
-- with help from https://github.com/maesse/CubeHags

local lib_id =  debug.getinfo( 1, "S" ).short_src
luabsp = {}

-- -----------------------------------------------------------------------------
-- -- Global Constants                                                        --
-- -----------------------------------------------------------------------------
HEADER_LUMPS = 64

LUMP_ENTITIES                       =  0 -- Map entities
LUMP_PLANES                         =  1 -- Plane array
LUMP_TEXDATA                        =  2 -- Index to texture names
LUMP_VERTEXES                       =  3 -- Vertex array
LUMP_VISIBILITY                     =  4 -- Compressed visibility bit arrays
LUMP_NODES                          =  5 -- BSP tree nodes
LUMP_TEXINFO                        =  6 -- Face texture array
LUMP_FACES                          =  7 -- Face array
LUMP_LIGHTING                       =  8 -- Lightmap samples
LUMP_OCCLUSION                      =  9 -- Occlusion polygons and vertices
LUMP_LEAFS                          = 10 -- BSP tree leaf nodes
LUMP_FACEIDS                        = 11 -- Correlates between dfaces and Hammer face IDs. Also used as random seed for detail prop placement.
LUMP_EDGES                          = 12 -- Edge array
LUMP_SURFEDGES                      = 13 -- Index of edges
LUMP_MODELS                         = 14 -- Brush models (geometry of brush entities)
LUMP_WORLDLIGHTS                    = 15 -- Internal world lights converted from the entity lump
LUMP_LEAFFACES                      = 16 -- Index to faces in each leaf
LUMP_LEAFBRUSHES                    = 17 -- Index to brushes in each leaf
LUMP_BRUSHES                        = 18 -- Brush array
LUMP_BRUSHSIDES                     = 19 -- Brushside array
LUMP_AREAS                          = 20 -- Area array
LUMP_AREAPORTALS                    = 21 -- Portals between areas
LUMP_UNUSED0                        = 22 -- Unused
LUMP_UNUSED1                        = 23 -- Unused
LUMP_UNUSED2                        = 24 -- Unused
LUMP_UNUSED3                        = 25 -- Unused
LUMP_DISPINFO                       = 26 -- Displacement surface array
LUMP_ORIGINALFACES                  = 27 -- Brush faces array before splitting
LUMP_PHYSDISP                       = 28 -- Displacement physics collision data
LUMP_PHYSCOLLIDE                    = 29 -- Physics collision data
LUMP_VERTNORMALS                    = 30 -- Face plane normals
LUMP_VERTNORMALINDICES              = 31 -- Face plane normal index array
LUMP_DISP_LIGHTMAP_ALPHAS           = 32 -- Displacement lightmap alphas (unused/empty since Source 2006)
LUMP_DISP_VERTS                     = 33 -- Vertices of displacement surface meshes
LUMP_DISP_LIGHTMAP_SAMPLE_POSITIONS = 34 -- Displacement lightmap sample positions
LUMP_GAME_LUMP                      = 35 -- Game-specific data lump
LUMP_LEAFWATERDATA                  = 36 -- Data for leaf nodes that are inside water
LUMP_PRIMITIVES                     = 37 -- Water polygon data
LUMP_PRIMVERTS                      = 38 -- Water polygon vertices
LUMP_PRIMINDICES                    = 39 -- Water polygon vertex index array
LUMP_PAKFILE                        = 40 -- Embedded uncompressed Zip-format file
LUMP_CLIPPORTALVERTS                = 41 -- Clipped portal polygon vertices
LUMP_CUBEMAPS                       = 42 -- env_cubemap location array
LUMP_TEXDATA_STRING_DATA            = 43 -- Texture name data
LUMP_TEXDATA_STRING_TABLE           = 44 -- Index array into texdata string data
LUMP_OVERLAYS                       = 45 -- info_overlay data array
LUMP_LEAFMINDISTTOWATER             = 46 -- Distance from leaves to water
LUMP_FACE_MACRO_TEXTURE_INFO        = 47 -- Macro texture info for faces
LUMP_DISP_TRIS                      = 48 -- Displacement surface triangles
LUMP_PHYSCOLLIDESURFACE             = 49 -- Compressed win32-specific Havok terrain surface collision data. Deprecated and no longer used.
LUMP_WATEROVERLAYS                  = 50 -- info_overlay's on water faces?
LUMP_LEAF_AMBIENT_INDEX_HDR         = 51 -- Index of LUMP_LEAF_AMBIENT_LIGHTING_HDR
LUMP_LEAF_AMBIENT_INDEX             = 52 -- Index of LUMP_LEAF_AMBIENT_LIGHTING
LUMP_LIGHTING_HDR                   = 53 -- HDR lightmap samples
LUMP_WORLDLIGHTS_HDR                = 54 -- Internal HDR world lights converted from the entity lump
LUMP_LEAF_AMBIENT_LIGHTING_HDR      = 55 -- HDR related leaf lighting data?
LUMP_LEAF_AMBIENT_LIGHTING          = 56 -- HDR related leaf lighting data?
LUMP_XZIPPAKFILE                    = 57 -- XZip version of pak file for Xbox. Deprecated.
LUMP_FACES_HDR                      = 58 -- HDR maps may have different face data
LUMP_MAP_FLAGS                      = 59 -- Extended level-wide flags. Not present in all levels.
LUMP_OVERLAY_FADES                  = 60 -- Fade distances for overlays
LUMP_OVERLAY_SYSTEM_LEVELS          = 61 -- System level settings (min/max CPU & GPU to render this overlay)
LUMP_PHYSLEVEL                      = 62 --
LUMP_DISP_MULTIBLEND                = 63 -- Displacement multiblend info


-- -----------------------------------------------------------------------------
-- -- Helper functions                                                        --
-- -----------------------------------------------------------------------------
--[[
local function signed( val, length )
    local val = val
    local lastbit = 2^(length*8 - 1)
    if val >= lastbit then
        val = val - lastbit*2
    end
    return val
end
]]

local function unsigned( val, length )
    local val = val
    if val < 0 then
        val = val + 2^(length*8)
    end
    return val
end

local function plane_intersect( p1, p2, p3 )
    local A1, B1, C1, D1 = p1.A, p1.B, p1.C, p1.D
    local A2, B2, C2, D2 = p2.A, p2.B, p2.C, p2.D
    local A3, B3, C3, D3 = p3.A, p3.B, p3.C, p3.D


    local det = (A1)*( B2*C3 - C2*B3 )
              - (B1)*( A2*C3 - C2*A3 )
              + (C1)*( A2*B3 - B2*A3 )

    if math.abs(det) < 0.001 then return nil end -- No intersection, planes must be parallel

    local x = (D1)*( B2*C3 - C2*B3 )
            - (B1)*( D2*C3 - C2*D3 )
            + (C1)*( D2*B3 - B2*D3 )

    local y = (A1)*( D2*C3 - C2*D3 )
            - (D1)*( A2*C3 - C2*A3 )
            + (C1)*( A2*D3 - D2*A3 )

    local z = (A1)*( B2*D3 - D2*B3 )
            - (B1)*( A2*D3 - D2*A3 )
            + (D1)*( A2*B3 - B2*A3 )

    return Vector(x,y,z)/det
end

local function is_point_inside_planes( planes, point )
    for i=1, #planes do
        local plane = planes[i]
        local t = point.x*plane.A + point.y*plane.B + point.z*plane.C
        if t - plane.D > 0.01 then return false end
    end
    return true
end

local function vertices_from_planes( planes )
    local verts = {}

    for i=1, #planes do
        local N1 = planes[i];

        for j=i+1, #planes do
            local N2 = planes[j]

            for k=j+1, #planes do
                local N3 = planes[k]

                local pVert = plane_intersect(N1, N2, N3)
                if pVert and is_point_inside_planes(planes,pVert) then
                    verts[#verts + 1] = pVert
                end
            end
        end
    end

    -- Filter out duplicate points
    local verts2 = {}
    for _, v1 in pairs(verts) do
        local exist = false
        for __, v2 in pairs(verts2) do
            if (v1-v2):LengthSqr() < 0.001 then
                exist = true
                break
            end
        end

        if not exist then
            verts2[#verts2 + 1] = v1
        end
    end

    return verts2
end

local function str2numbers( str )
    local ret = {}
    for k, v in pairs( string.Explode( " ", str ) ) do
        ret[k] = tonumber(v)
    end
    return unpack( ret )
end

local function find_uv( point, textureVecs, texSizeX, texSizeY )
    local x,y,z = point.x, point.y, point.z
    local u = textureVecs[1].x * x + textureVecs[1].y * y + textureVecs[1].z * z + textureVecs[1].offset
    local v = textureVecs[2].x * x + textureVecs[2].y * y + textureVecs[2].z * z + textureVecs[2].offset
    return u/texSizeX, v/texSizeY
end

-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
local LuaBSP
do
    local entity_datatypes = {
        ["origin"] = "Vector",
        ["sunnormal"] = "Vector",
        ["fogdir"] = "Vector",
        ["world_mins"] = "Vector",
        ["world_maxs"] = "Vector",
        ["angles"] = "Angle",
        ["fogcolor"] = "Color",
        ["fogcolor2"] = "Color",
        ["suncolor"] = "Color",
        ["bottomcolor"] = "Color",
        ["duskcolor"] = "Color",
        ["bottomcolor"] = "Color",
        ["_light"] = "Color",
        ["_lighthdr"] = "Color",
        ["rendercolor"] = "Color",
    }
	local dispIndexToFaceIndex = {}
    local cycles = 512

    local lump_parsers
    lump_parsers = {
        [LUMP_ENTITIES] = -- Map entities
            function(fl, lump_data)
                lump_data.data = {}
                local keyvals =  fl:Read( lump_data.filelen-1 ) -- Ignore last character (NUL)
                for v in keyvals:gmatch("({.-})") do
                    local data = util.KeyValuesToTable( "_"..v )
                    --[[
                    for k, v in pairs( data ) do
                        if entity_datatypes[k] == "Vector" then
                            data[k] = Vector(str2numbers(v))
                        elseif entity_datatypes[k] == "Angle" then
                            data[k] = Angle(str2numbers(v))
                        elseif entity_datatypes[k] == "Color" then
                            data[k] = Color(str2numbers(v))
                        end
                    end]]
                    lump_data.data[#lump_data.data + 1] = data
                end
            end,
        [LUMP_PLANES] = -- Plane array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 20

                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        A = fl:ReadFloat(),                -- float | normal vector x component
                        B = fl:ReadFloat(),                -- float | normal vector y component
                        C = fl:ReadFloat(),                -- float | normal vector z component
                        D = fl:ReadFloat(),                -- float | distance from origin
                        type = fl:ReadLong(), -- int | plane axis identifier
                    }
                end
            end,
        [LUMP_TEXDATA] = -- Index to texture names
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 32
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        reflectivity = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() ),
                        nameStringTableID = fl:ReadLong(),
                        width = fl:ReadLong(),
                        height = fl:ReadLong(),
                        view_width = fl:ReadLong(),
                        view_height = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_VERTEXES] = -- Vertex array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 12
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = Vector(
                        fl:ReadFloat(), -- float | x
                        fl:ReadFloat(), -- float | y
                        fl:ReadFloat()  -- float | z
                    )
                end
            end,
        [LUMP_VISIBILITY] = -- Compressed visibility bit arrays
            function(fl, lump_data) end,
        [LUMP_NODES] = -- BSP tree nodes
            function(fl, lump_data) end,
        [LUMP_TEXINFO] = -- Face texture array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 72
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        textureVecs = {
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                        },
                        lightmapVecs = {
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                            { x = fl:ReadFloat(), y = fl:ReadFloat(), z = fl:ReadFloat(), offset = fl:ReadFloat()},
                        },
                        flags = fl:ReadLong(),
                        textdata = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_FACES] = -- Face array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 56
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        planenum = unsigned( fl:ReadShort(), 2 ),                         -- unsigned short | the plane number
                        side = fl:ReadByte(),                              -- byte | faces opposite to the node's plane direction
                        onNode = fl:ReadByte(),                            -- byte | 1 of on node, 0 if in leaf
                        firstedge = fl:ReadLong(),            -- int | index into surfedges
                        numedges = fl:ReadShort(),            -- short | number of surfedges
                        texinfo = fl:ReadShort(),             -- short | texture info
                        dispinfo = fl:ReadShort(),            -- short | displacement info
                        surfaceFogVolumeID = fl:ReadShort(),  -- short | ?
                        styles = {                                         -- byte[4] | switchable lighting info
                            fl:ReadByte(),
                            fl:ReadByte(),
                            fl:ReadByte(),
                            fl:ReadByte(),
                        },
                        lightofs = fl:ReadLong(),             -- int | offset into lightmap lump
                        area = fl:ReadFloat(),                             -- float | face area in units^2
                        LightmapTextureMinsInLuxels = {                    -- int[2] | texture lighting info
                            fl:ReadLong(),
                            fl:ReadLong(),
                        },
                        LightmapTextureSizeInLuxels = {                    -- int[2] | texture lighting info
                            fl:ReadLong(),
                            fl:ReadLong(),
                        },
                        origFace = fl:ReadLong(),             -- int | original face this was split from
                        numPrims = fl:ReadUShort(),                         -- unsigned short | primitives
                        firstPrimID = fl:ReadUShort(),                      -- unsigned short
                        smoothingGroups = fl:ReadULong(),                   -- unsigned int | lightmap smoothing group
                    }
					if(lump_data.data[i].dispinfo != -1) then
						dispIndexToFaceIndex[lump_data.data[i].dispinfo] = i
					end
                end
            end,
        [LUMP_LIGHTING] = -- Lightmap samples
            function(fl, lump_data) end,
        [LUMP_OCCLUSION] = -- Occlusion polygons and vertices
            function(fl, lump_data) end,
        [LUMP_LEAFS] = -- BSP tree leaf nodes
            function(fl, lump_data) end,
        [LUMP_FACEIDS] = -- Correlates between dfaces and Hammer face IDs. Also used as random seed for detail prop placement.
            function(fl, lump_data) end,
        [LUMP_EDGES] = -- Edge array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        unsigned( fl:ReadShort(), 2 ), -- unsigned short | vertex indice 1
                        unsigned( fl:ReadShort(), 2 ), -- unsigned short | vertex indice 2
                    }
                end
            end,
        [LUMP_SURFEDGES] = -- Index of edges
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = fl:ReadLong()
                end
            end,
        [LUMP_MODELS] = -- Brush models (geometry of brush entities)
            function(fl, lump_data) end,
        [LUMP_WORLDLIGHTS] = -- Internal world lights converted from the entity lump
            function(fl, lump_data) end,
        [LUMP_LEAFFACES] = -- Index to faces in each leaf
            function(fl, lump_data) end,
        [LUMP_LEAFBRUSHES] = -- Index to brushes in each leaf
            function(fl, lump_data) end,
        [LUMP_BRUSHES] = -- Brush array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 12
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        firstside = fl:ReadLong(),  -- int | first brushside
                        numsides = fl:ReadLong(),   -- int | number of brushsides
                        contents = fl:ReadLong(),   -- int | content flags
                    }
                end
            end,
        [LUMP_BRUSHSIDES] = -- Brushside array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 8
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        planenum = fl:ReadUShort(),             -- unsigned short | facing out of the leaf
                        texinfo =  fl:ReadShort(),  -- short | texture info
                        dispinfo = fl:ReadShort(), -- short | displacement info
                        bevel = fl:ReadShort(),    -- short | is the side a bevel plane?
                    }
                end
            end,
        [LUMP_AREAS] = -- Area array
            function(fl, lump_data) end,
        [LUMP_AREAPORTALS] = -- Portals between areas
            function(fl, lump_data) end,
        [LUMP_UNUSED0] = -- Unused
            function(fl, lump_data) end,
        [LUMP_UNUSED1] = -- Unused
            function(fl, lump_data) end,
        [LUMP_UNUSED2] = -- Unused
            function(fl, lump_data) end,
        [LUMP_UNUSED3] = -- Unused
            function(fl, lump_data) end,
        [LUMP_DISPINFO] = -- Displacement surface array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 176
				local function ReadCDispSubNeighbor()
					return {
						span = fl:ReadByte(),
						neighborSpan = fl:ReadByte(),
						neighbor = fl:ReadUShort(),
						unknown = fl:ReadByte(),
						neighborOrientation = fl:ReadByte()
					}
				end
				local function ReadCDispCornerNeighbors()
					return {
						neighbors = { fl:ReadUShort(), fl:ReadUShort(), fl:ReadUShort(), fl:ReadUShort() },
						nNeighbors = fl:ReadByte()
					}
				end
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        startPosition = Vector(fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat()),
                        dispVertStart = fl:ReadLong(),
						dispTriStart = fl:ReadLong(),
						power = fl:ReadLong(),
						flags = fl:ReadByte(),
						minTess = fl:Read(3),
						smoothingAngle = fl:ReadFloat(),
						contents = fl:ReadULong(),
						mapFace = fl:ReadUShort(),
						lightmapAlphaStart = fl:ReadLong(),
						lightmapSamplePositionStart = fl:ReadLong(),
						edgeNeighbors = {
							{ ReadCDispSubNeighbor(), ReadCDispSubNeighbor() },
							{ ReadCDispSubNeighbor(), ReadCDispSubNeighbor() },
							{ ReadCDispSubNeighbor(), ReadCDispSubNeighbor() },
							{ ReadCDispSubNeighbor(), ReadCDispSubNeighbor() }
						},
						cornerNeighbors = {
							ReadCDispCornerNeighbors(),
							ReadCDispCornerNeighbors(),
							ReadCDispCornerNeighbors(),
							ReadCDispCornerNeighbors()
						},
						unknown = fl:Read(6),
						allowedVerts = {
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong(),
							fl:ReadULong()
						}
                    }
                end
            end,
        [LUMP_ORIGINALFACES] = -- Brush faces array before splitting
            function(fl, lump_data)
                lump_parsers[LUMP_FACES]( fl, lump_data )
            end,
        [LUMP_PHYSDISP] = -- Displacement physics collision data
            function(fl, lump_data) end,
        [LUMP_PHYSCOLLIDE] = -- Physics collision data
            function(fl, lump_data) end,
        [LUMP_VERTNORMALS] = -- Face plane normals
            function(fl, lump_data) end,
        [LUMP_VERTNORMALINDICES] = -- Face plane normal index array
            function(fl, lump_data) end,
        [LUMP_DISP_LIGHTMAP_ALPHAS] = -- Displacement lightmap alphas (unused/empty since Source 2006)
            function(fl, lump_data) end,
        [LUMP_DISP_VERTS] = -- Vertices of displacement surface meshes
            function(fl, lump_data) 
				lump_data.data = {}
				lump_data.size = lump_data.filelen / 20
				for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
					lump_data.data[i] = {
						vec = Vector(fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat()),
						dist = fl:ReadFloat(),
						alpha = fl:ReadFloat()
					}
				end
			end,
        [LUMP_DISP_LIGHTMAP_SAMPLE_POSITIONS] = -- Displacement lightmap sample positions
            function(fl, lump_data) end,
        [LUMP_GAME_LUMP] = -- Game-specific data lump
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = fl:ReadLong()
                for i=1,lump_data.size do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = {
                        id      = fl:Read( 4 ),
                        flags   = fl:ReadShort(),
                        version = fl:ReadShort(),
                        fileofs = fl:ReadLong(),
                        filelen = fl:ReadLong(),
                    }
                end
            end,
        [LUMP_LEAFWATERDATA] = -- Data for leaf nodes that are inside water
            function(fl, lump_data) end,
        [LUMP_PRIMITIVES] = -- Water polygon data
            function(fl, lump_data) end,
        [LUMP_PRIMVERTS] = -- Water polygon vertices
            function(fl, lump_data) end,
        [LUMP_PRIMINDICES] = -- Water polygon vertex index array
            function(fl, lump_data) end,
        [LUMP_PAKFILE] = -- Embedded uncompressed Zip-format file
            function(fl, lump_data) end,
        [LUMP_CLIPPORTALVERTS] = -- Clipped portal polygon vertices
            function(fl, lump_data) end,
        [LUMP_CUBEMAPS] = -- env_cubemap location array
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 16

                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    local origin = Vector(fl:ReadLong(), fl:ReadLong(), fl:ReadLong())
                    local size = fl:ReadLong()
    
                    if size < 1 then size = 6 end -- default size should be 32x32

                    lump_data.data[i] = {
                        origin = origin,
                        size = 2^(size-1)
                    }
                end
            end,
        [LUMP_TEXDATA_STRING_DATA] = -- Texture name data
            function(fl, lump_data)
                lump_data.data = {}
                local data = string.Explode( "\0", fl:Read(lump_data.filelen) )
                local offset = 0
                for k, v in pairs(data) do
                    lump_data.data[offset] = v
                    offset = offset + 1 +  #v
                end
            end,
        [LUMP_TEXDATA_STRING_TABLE] = -- Index array into texdata string data
            function(fl, lump_data)
                lump_data.data = {}
                lump_data.size = lump_data.filelen / 4
                for i=0, lump_data.size - 1 do
                    if i % cycles == 0 then coroutine.yield() end
                    lump_data.data[i] = fl:ReadLong()
                end
            end,
        [LUMP_OVERLAYS] = -- info_overlay data array
            function(fl, lump_data) end,
        [LUMP_LEAFMINDISTTOWATER] = -- Distance from leaves to water
            function(fl, lump_data) end,
        [LUMP_FACE_MACRO_TEXTURE_INFO] = -- Macro texture info for faces
            function(fl, lump_data) end,
        [LUMP_DISP_TRIS] = -- Displacement surface triangles
            function(fl, lump_data) end,
        [LUMP_PHYSCOLLIDESURFACE] = -- Compressed win32-specific Havok terrain surface collision data. Deprecated and no longer used.
            function(fl, lump_data) end,
        [LUMP_WATEROVERLAYS] = -- info_overlay's on water faces?
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_INDEX_HDR] = -- Index of LUMP_LEAF_AMBIENT_LIGHTING_HDR
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_INDEX] = -- Index of LUMP_LEAF_AMBIENT_LIGHTING
            function(fl, lump_data) end,
        [LUMP_LIGHTING_HDR] = -- HDR lightmap samples
            function(fl, lump_data) end,
        [LUMP_WORLDLIGHTS_HDR] = -- Internal HDR world lights converted from the entity lump
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_LIGHTING_HDR] = -- HDR related leaf lighting data?
            function(fl, lump_data) end,
        [LUMP_LEAF_AMBIENT_LIGHTING] = -- HDR related leaf lighting data?
            function(fl, lump_data) end,
        [LUMP_XZIPPAKFILE] = -- XZip version of pak file for Xbox. Deprecated.
            function(fl, lump_data) end,
        [LUMP_FACES_HDR] = -- HDR maps may have different face data
            function(fl, lump_data) end,
        [LUMP_MAP_FLAGS] = -- Extended level-wide flags. Not present in all levels.
            function(fl, lump_data) end,
        [LUMP_OVERLAY_FADES] = -- Fade distances for overlays
            function(fl, lump_data) end,
        [LUMP_OVERLAY_SYSTEM_LEVELS] = -- System level settings (min/max CPU & GPU to render this overlay)
            function(fl, lump_data) end,
        [LUMP_PHYSLEVEL] = --
            function(fl, lump_data) end,
        [LUMP_DISP_MULTIBLEND] = -- Displacement multiblend info
            function(fl, lump_data) end,
    }

    LuaBSP = {}
    LuaBSP.__index = LuaBSP

    function LuaBSP:GetMapFileHandle( mapname )
        self.mapname = mapname or self.mapname
        local filename = "maps/"..self.mapname..".bsp"
        local fl = file.Open( filename, "rb", "GAME")
        if not fl then error( "[LuaBSP] Unable to open: "..filename ) end

        return fl
    end

    function LuaBSP.new( mapname )
        assert( mapname, "[LuaBSP] Invalid map name" )

        local self = setmetatable({}, LuaBSP)
        local filename = "maps/"..mapname..".bsp"
        local fl = self:GetMapFileHandle( mapname )

        local ident = fl:Read( 4 ) -- BSP file identifier
        if ident ~= "VBSP" then error( "[LuaBSP] Invalid file header: "..ident ) return end

        self.version = fl:ReadLong() -- BSP file version
        self.lumps = {} -- lump directory array

        for i=0, HEADER_LUMPS-1 do
            self.lumps[i] = {
                fileofs = fl:ReadLong(), -- offset into file (bytes)
                filelen = fl:ReadLong(), -- length of lump (bytes)
                version = fl:ReadLong(), -- lump format version
                fourCC  = fl:Read( 4 ),  -- lump ident code
            }
        end
        self.map_revision = fl:ReadLong() -- the map's revision (iteration, version) number

        --[[
        for i=0, HEADER_LUMPS-1 do
            local lump_data = self.lumps[i]
            fl:Seek( lump_data.fileofs )
            lump_parsers[i]( fl, lump_data )
        end
        ]]

        fl:Close()

        return self
    end

    function LuaBSP:LoadLumps( callback, ... )
        local fl = self:GetMapFileHandle()
        local lumpArgs = {...}

        local function LoadLump(index)
            local lump = lumpArgs[index]
            local lump_data = self.lumps[lump]
            fl:Seek( lump_data.fileofs )
            local co
            hook.Add("Think", "LoadLumpsThink", function()
                if not co then
                    co = coroutine.create(lump_parsers[lump])
                end
                if coroutine.resume(co, fl, lump_data) == false then
                    hook.Remove("Think", "LoadLumpsThink")
                    if(index + 1 > #lumpArgs) then
                        co = nil
                        fl:Close()
                        return callback()
                    else
                        return LoadLump(index + 1)
                    end
                end
            end)
        end

        LoadLump(1)
    end
	
	function LuaBSP:LoadDisplacementInfos(callback)
		self:LoadLumps( function()
            local fl = self:GetMapFileHandle()
            local faces = self.lumps[LUMP_FACES]
            
            local displacement_infos = {}
            for _,face_lump in ipairs( faces.data ) do
                local dispinfoIndex = face_lump.dispinfo
                if(dispinfoIndex != -1) then
                    local dispInfo = self.lumps[LUMP_DISPINFO]["data"][dispinfoIndex]
                    table.insert(displacement_infos, dispInfo)
                end
            end
            --for _,origface_lump in ipairs( origFaces.data ) do
            --	local dispinfoIndex = origface_lump.dispinfo
            --	if(dispinfoIndex != -1) then
            --		local dispInfo = self.lumps[LUMP_DISPINFO]["data"][dispinfoIndex]
            --		table.insert(displacement_infos, dispInfo)
            --	end
            --end
            --for _,brushside_lump in ipairs( brushSides.data ) do
            --	local dispinfoIndex = brushside_lump.dispinfo
            --	if(dispinfoIndex != -1) then
            --		local dispInfo = self.lumps[LUMP_DISPINFO]["data"][dispinfoIndex]
            --		table.insert(displacement_infos, dispInfo)
            --	end
            --end
            self.displacement_infos = displacement_infos
            
            fl:Close()
            return callback()
        end, LUMP_DISPINFO, LUMP_FACES )
	end
	
	function LuaBSP:LoadDisplacementVertices(callback)
		self:LoadLumps( function()
            self:LoadDisplacementInfos(function()

                local fl = self:GetMapFileHandle()
                local worldFaces = self.lumps[LUMP_FACES]["data"]
                local worldEdges = self.lumps[LUMP_EDGES]["data"]
                local surfEdges = self.lumps[LUMP_SURFEDGES]["data"]
                local worldVerts = self.lumps[LUMP_VERTEXES]["data"]
                local dispVerts = self.lumps[LUMP_DISP_VERTS]["data"]
                
                self.displacement_vertices = {}
                local displacement_vertices = {}
                local curVert = 0
                for _,dispinfo in ipairs( self.displacement_infos ) do
                    local power = dispinfo.power
                    local PostSpacing = bit.lshift(1, power) + 1
                    
                    local nVerts = PostSpacing * PostSpacing
                    local nTris = bit.lshift(1, power) * bit.lshift(1, power) * 2
                    local thisDispVerts = {}
                    for i = 0, nVerts do
                        thisDispVerts[i] = dispVerts[i + curVert]
                    end
                    curVert = curVert + nVerts
                        
                    local pointStartIndex = -1
                    local face = worldFaces[dispinfo.mapFace]
                    if not face then break end
                    if(face.numedges <= 4) then
                        local pointStart = dispinfo.startPosition
                    
                        local surfPoints = {}
                        
                        for i = 0, face.numedges - 1 do
                            local eIndex = surfEdges[face.firstedge + i]
                            if(eIndex < 0) then
                                surfPoints[i] = worldVerts[worldEdges[-eIndex][2]]
                            else
                                surfPoints[i] = worldVerts[worldEdges[eIndex][1]]
                            end
                        end
                        
                        if(pointStartIndex == -1) then
                            local minIndex = -1
                            local minDist = 10000000.0
                            for i = 0, 3 do
                                local segment = pointStart - surfPoints[i]
                                local distSq = segment:LengthSqr()
                                if(distSq < minDist) then
                                    minDist = distSq
                                    minIndex = i
                                end
                            end
                            
                            pointStartIndex = minIndex
                        end
                        
                        local tmpPoints = {}
                        for i = 0, 3 do
                            tmpPoints[i] = surfPoints[i]
                        end
                        for i = 0, 3 do
                            surfPoints[i] = tmpPoints[(i + pointStartIndex) % 4]
                        end
                        
                        local ooInt = 1.0 / (PostSpacing - 1.0)
                        local edgeInt = { (surfPoints[1] - surfPoints[0]) * ooInt, (surfPoints[2] - surfPoints[3]) * ooInt }
                        
                        local vertexGrid = {}
                        for i = 0, PostSpacing-1 do
                            local endPts = { (edgeInt[1] * i) + surfPoints[0], (edgeInt[2] * i) + surfPoints[3] }
                            local seg = (endPts[2] - endPts[1])
                            local segInt = seg * ooInt
                            vertexGrid[i] = {}
                            
                            for j = 0, PostSpacing-1 do
                                local ndx = i * PostSpacing + j
                                local vertexInfo = thisDispVerts[ndx]
                                local vertex = endPts[1] + (segInt * j)
                                vertex = vertex + vertexInfo.vec * vertexInfo.dist
                                vertexGrid[i][j] = vertex
                            end
                        end
                        
                        for x = 0, #vertexGrid-1 do
                            for y = 0, #vertexGrid[x]-1 do
                                local ndx = x * (#vertexGrid-1) + y
                                if(ndx % 2 == 0) then
                                    table.insert(displacement_vertices, vertexGrid[x][y])
                                    table.insert(displacement_vertices, vertexGrid[x+1][y])
                                    table.insert(displacement_vertices, vertexGrid[x+1][y+1])
                                    
                                    table.insert(displacement_vertices, vertexGrid[x][y])
                                    table.insert(displacement_vertices, vertexGrid[x+1][y+1])
                                    table.insert(displacement_vertices, vertexGrid[x][y+1])
                                else
                                    table.insert(displacement_vertices, vertexGrid[x+1][y])
                                    table.insert(displacement_vertices, vertexGrid[x][y+1])
                                    table.insert(displacement_vertices, vertexGrid[x][y])
                                    
                                    table.insert(displacement_vertices, vertexGrid[x+1][y])
                                    table.insert(displacement_vertices, vertexGrid[x+1][y+1])
                                    table.insert(displacement_vertices, vertexGrid[x][y+1])
                                end
                            end
                        end
                    end
                end
                
                self.displacement_vertices = displacement_vertices
                fl:Close()
                return callback()

            end)
        end, LUMP_DISP_VERTS, LUMP_EDGES, LUMP_SURFEDGES, LUMP_VERTEXES )
	end

    function LuaBSP:LoadStaticProps(callback)
        self:LoadLumps( function() 

            local fl   = self:GetMapFileHandle()
            local lump = self.lumps[LUMP_GAME_LUMP]

            local static_props = {}
            for _,game_lump in ipairs( lump.data ) do
                local version = game_lump.version
                local static_props_entry = {
                    names        = {},
                    leaf         = {},
                    leaf_entries = 0,
                    entries      = {},
                }

                if not (version >= 4 and version < 12) then continue end

                fl:Seek( game_lump.fileofs )

                local dict_entries = fl:ReadLong()
                if dict_entries < 0 or dict_entries >= 9999 then continue end

                for i=1,dict_entries do
                    static_props_entry.names[i-1] = fl:Read( 128 ):match( "^[^%z]+" ) or ""
                end

                local leaf_entries = fl:ReadLong()
                if leaf_entries < 0 then continue end

                static_props_entry.leaf_entries = leaf_entries
                for i=1,leaf_entries do
                    static_props_entry.leaf[i] = fl:ReadUShort()
                end

                local amount = fl:ReadLong()
                if amount < 0 or amount >= ( 8192 * 2 ) then continue end

                for i=1,amount do
                    local static_prop = {}
                    static_props_entry.entries[i] = static_prop

                    static_prop.Origin = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )
                    static_prop.Angles = Angle( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )

                    if version >= 11 then
                        static_prop.Scale = fl:ReadShort()
                    end

                    local _1,_2 = string.byte(fl:Read(2),1,2)
                    local proptype = _1 + _2 * 256

                    static_prop.PropType = static_props_entry.names[proptype]
                    if not static_prop.PropType then continue end

                    static_prop.FirstLeaf = fl:ReadShort()
                    static_prop.LeafCount = fl:ReadShort()
                    static_prop.Solid     = fl:ReadByte()
                    static_prop.Flags     = fl:ReadByte()
                    static_prop.Skin      = fl:ReadLong()
                    if not static_prop.Skin then continue end

                    static_prop.FadeMinDist    = fl:ReadFloat()
                    static_prop.FadeMaxDist    = fl:ReadFloat()
                    static_prop.LightingOrigin = Vector( fl:ReadFloat(), fl:ReadFloat(), fl:ReadFloat() )

                    if version >= 5 then
                        static_prop.ForcedFadeScale = fl:ReadFloat()
                    end

                    if version == 6 or version == 7 then
                        static_prop.MinDXLevel = fl:ReadShort()
                        static_prop.MaxDXLevel = fl:ReadShort()
                    end

                    if version >= 8 then
                        static_prop.MinCPULevel = fl:ReadByte()
                        static_prop.MaxCPULevel = fl:ReadByte()
                        static_prop.MinGPULevel = fl:ReadByte()
                        static_prop.MaxGPULevel = fl:ReadByte()
                    end

                    if version >= 7 then
                        static_prop.DiffuseModulation = Color( string.byte( fl:Read( 4 ), 1, 4 ) )
                    end

                    if version >= 10 then
                        static_prop.unknown = fl:ReadFloat()
                    end

                    if version == 9 then
                        static_prop.DisableX360 = fl:ReadByte() == 1
                    end

                end

                table.insert( static_props, static_props_entry )
            end

            self.static_props = static_props

            fl:Close()
            return callback()

        end, LUMP_GAME_LUMP )
    end

    function LuaBSP:GetClipBrushes( single_mesh )
        self:LoadLumps( LUMP_BRUSHES, LUMP_BRUSHSIDES, LUMP_PLANES, LUMP_TEXINFO )

        local brushes = {}
        local brush_verts = {}

        for brush_id = 0, #self.lumps[LUMP_BRUSHES]["data"]-1 do
            local brush = self.lumps[LUMP_BRUSHES]["data"][brush_id]
            local brush_firstside = brush.firstside
            local brush_numsides = brush.numsides
            local brush_contents = brush.contents

            if bit.band( brush_contents, CONTENTS_PLAYERCLIP ) == 0 then continue end

            local base_color = Vector(1,0,1)
            if not single_mesh then
                brush_verts = {}
            end

            brush.p_bsides = {}
            local planes = {}
            for i = 0, brush_numsides - 1 do
                local brushside_id = (brush_firstside + i)
                local brushside = self.lumps[LUMP_BRUSHSIDES]["data"][brushside_id]

                if brushside.bevel ~= 0 then continue end -- bevel != 0 means its used for physics collision, not interested
                local plane = self.lumps[LUMP_PLANES]["data"][brushside.planenum]
                brush.p_bsides[#brush.p_bsides + 1] = {
                    brushside = brushside,
                    plane = plane
                }
                planes[#planes + 1] = plane
            end

            brush.p_points = vertices_from_planes(planes)
            brush.p_render_data = {}
            for _, bside in pairs(brush.p_bsides) do
                local plane = bside.plane
                if not plane then continue end
                local render_data = {
                    texinfo = bside.brushside.texinfo,
                    plane = plane,
                    points = {},
                }
                for __, point in pairs(brush.p_points) do
                    local t = point.x*plane.A + point.y*plane.B + point.z*plane.C
                    if math.abs(t-plane.D) > 0.01  then continue end -- Not on a plane

                    render_data.points[#render_data.points + 1] = point
                end

                -- sort them in clockwise order
                local norm = Vector(plane.A, plane.B, plane.C)
                local c = render_data.points[1]
                table.sort(render_data.points, function(a, b)
                    return norm:Dot((c-a):Cross(b-c)) > 0.001
                end)

                render_data.norm = norm

                local points = render_data.points
                local norm = render_data.norm
                local dot = math.abs( norm:Dot(Vector(-1,100,100):GetNormalized()) )
                local color = Color(100+55*dot,100+55*dot,100+55*dot) -- Color( 40357164 / 255 )
                color.r = color.r * base_color.x
                color.g = color.g * base_color.y
                color.b = color.b * base_color.z
                color.a = 255

                local texinfo = self.lumps[LUMP_TEXINFO]["data"][render_data.texinfo]


                local ref = Vector(0,0,-1)
                if math.abs( norm:Dot( Vector(0,0,1) ) ) == 1 then
                    ref = Vector(0,1,0)
                end

                local tv1 = norm:Cross( ref ):Cross( norm ):GetNormalized()
                local tv2 = norm:Cross( tv1 )

                local textureVecs = {{x=tv2.x,y=tv2.y,z=tv2.z,offset=0},
                                    {x=tv1.x,y=tv1.y,z=tv1.z,offset=0}}-- texinfo.textureVecs
                local u, v
                for j = 1, #points - 2 do
                    u1, v1 = find_uv(points[1], textureVecs, 32, 32)
                    u2, v2 = find_uv(points[j+1], textureVecs, 32, 32)
                    u3, v3 = find_uv(points[j+2], textureVecs, 32, 32)
                    brush_verts[#brush_verts + 1] = { pos = points[1]+norm*0  , u = u1, v = v1, color = color }
                    brush_verts[#brush_verts + 1] = { pos = points[j+1]+norm*0, u = u2, v = v2, color = color }
                    brush_verts[#brush_verts + 1] = { pos = points[j+2]+norm*0, u = u3, v = v3, color = color }
                end
            end

            if not single_mesh then
                local obj = Mesh()
                obj:BuildFromTriangles( brush_verts )

                brush.p_mesh = obj
                brushes[#brushes+1] = obj
            end
        end

        if single_mesh then
            local obj = Mesh()
            obj:BuildFromTriangles( brush_verts )

            return obj
        end

        return brushes
    end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function luabsp.LoadMap( map_name )
    return LuaBSP.new( map_name )
end

function luabsp.GetLibraryID()
    return lib_id
end

return luabsp