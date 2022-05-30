AddCSLuaFile("includes/g64_luabsp.lua")
AddCSLuaFile("includes/g64_config.lua")
AddCSLuaFile("includes/g64_types.lua")
AddCSLuaFile()

game.AddParticles("particles/sm64.pcf")
PrecacheParticleSystem("ground_pound")
PrecacheParticleSystem("mario_dust")
PrecacheParticleSystem("mario_horiz_star")
PrecacheParticleSystem("mario_vert_star")
PrecacheParticleSystem("mario_fire")

CreateConVar("g64_metalcap_timer", "600", FCVAR_CHEAT, "Timer for the metal cap (default: 600)", 0, 65535)
CreateConVar("g64_wingcap_timer", "1800", FCVAR_CHEAT, "Timer for the wing cap (default: 1800)", 0, 65535)
CreateConVar("g64_processdisplacements", "1", FCVAR_CHEAT)
CreateConVar("g64_processstaticprops", "1", FCVAR_CHEAT)

REQUIRED_LIBSM64 = 1
REQUIRED_MODULE = 1

if CLIENT then

	include("includes/g64_config.lua")

	CreateClientConVar("g64_debugcollision", "0", true, false)
	CreateClientConVar("g64_debugrays", "0", true, false)
	CreateClientConVar("g64_interpolation", "1", true, false)
	CreateClientConVar("g64_rompath", "", true, false)
	CreateClientConVar("g64_upd_col_flag", "0", true, false)
	CreateClientConVar("g64_cap_music", "1", true, false)

	local function LoadFailure()
		libsm64.ModuleExists = false
		libsm64.ModuleLoaded = false
		libsm64.MapLoaded = false
		libsm64.ScaleFactor = 2
	end

	local function LoadSM64Module()
		if(file.Exists("lua/bin/gmcl_g64_win64.dll", "MOD")) then
			require("g64")
			libsm64.ModuleVersion = libsm64.GetModuleVersion()
			libsm64.LibSM64Version = libsm64.GetLibVersion()
			local libreq = libsm64.CheckLibRequirement()

			if(REQUIRED_MODULE != libsm64.ModuleVersion && REQUIRED_LIBSM64 != libsm64.LibSM64Version) then
				chat.AddText(Color(255, 100, 100), "[G64] Your G64 binary module and libsm64 versions are outdated! Please download the latest versions of both from ", Color(86, 173, 255), "https://github.com/ckosmic/g64#installation\n")
				LoadFailure()
				return
			elseif(REQUIRED_MODULE != libsm64.ModuleVersion || mismatch == 1) then
				chat.AddText(Color(255, 100, 100), "[G64] Your version of the G64 binary module is outdated! Please download the latest version of the G64 binary module from ", Color(86, 173, 255), "https://github.com/ckosmic/g64#installation\n")
				LoadFailure()
				return
			elseif(REQUIRED_LIBSM64 != libsm64.LibSM64Version || mismatch == 2) then
				chat.AddText(Color(255, 100, 100), "[G64] Your version of libsm64 is outdated! Please download the latest version of libsm64 from ", Color(86, 173, 255), "https://github.com/ckosmic/g64#installation\n")
				LoadFailure()
				return
			end

			libsm64.ModuleExists = true
			libsm64.ModuleLoaded = true
			libsm64.MapLoaded = false
			libsm64.ScaleFactor = 2.5
			print("[G64] Loaded G64 binary module! (version "..libsm64.ModuleVersion..", libsm64 version "..libsm64.LibSM64Version..")")
			
			libsm64.SetScaleFactor(libsm64.ScaleFactor)
			
			if(!LocalPlayer().SM64LoadedMap) then
				net.Start("G64_UPLOADCOLORS")
					for i=1, 6 do
						net.WriteUInt(g64config.Config.MarioColors[i][1], 8)
						net.WriteUInt(g64config.Config.MarioColors[i][2], 8)
						net.WriteUInt(g64config.Config.MarioColors[i][3], 8)
					end
				net.SendToServer()
				
				timer.Simple(2, function()
					net.Start("G64_LOADMAPGEO")
					print("[G64] Getting map geometry...")
					net.SendToServer()
				end)
				
				local vertices = {}
				local dispVertices = {}
				local startTime = CurTime()
				local worldMin = Vector()
				local worldMax = Vector()
				local xDelta, yDelta
				local xChunks, yChunks
				local xDispChunks, yDispChunks
				local tileSize = 1000
				local dispTileSize = 500
				local xOffset, yOffset
				local chunkMin, chunkMax
				local dispChunkMin, dispChunkMax
				
				local function InitMapDownload()
					worldMin = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
					worldMax = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
					xDelta = worldMax.x - worldMin.x
					yDelta = worldMax.y - worldMin.y
					xOffset = worldMin.x + 16384
					yOffset = worldMin.y + 16384
					xChunks = math.ceil(xDelta / tileSize)
					yChunks = math.ceil(yDelta / tileSize)
					xDispChunks = math.ceil(xDelta / dispTileSize)
					yDispChunks = math.ceil(yDelta / dispTileSize)
					if(GetConVar("g64_debugcollision"):GetBool()) then
						print("[G64] Chunks: ", xChunks, yChunks)
						print("[G64] World bounds: ", worldMin.x, worldMin.y, worldMax.x, worldMax.y)
					end
					for i = 1, xChunks do
						vertices[i] = {}
						for j = 1, yChunks do
							vertices[i][j] = {}
						end
					end
					for i = 1, xDispChunks do
						dispVertices[i] = {}
						for j = 1, yDispChunks do
							dispVertices[i][j] = {}
						end
					end
					libsm64.XDelta = xDelta
					libsm64.YDelta = yDelta
					libsm64.WorldMin = worldMin
					libsm64.WorldMax = worldMax
					libsm64.XChunks = xChunks
					libsm64.YChunks = yChunks
					libsm64.XDispChunks = xDispChunks
					libsm64.YDispChunks = yDispChunks
				end
				
				function PlaceTriangleInChunks(vecs, vertTable, nChunksX, nChunksY, vertOffset)
					local triVerts = {}
					local chunksToPlaceIn = {}
					local triMin = Vector(16384, 16384)
					local triMax = Vector(-16384, -16384)
					
					if(vertOffset == nil) then vertOffset = Vector() end
					
					for i = 1, 3 do
						local x = math.Clamp(vecs[i].x + vertOffset.x, worldMin.x, worldMax.x)
						local y = math.Clamp(vecs[i].y + vertOffset.y, worldMin.y, worldMax.y)
						local z = vecs[i].z + vertOffset.z
						local xChunk, yChunk
						xChunk = math.floor((x + 16384 - xOffset - 100) / xDelta * nChunksX) -- Subtract then add 100 units for vertices that may be on chunk borders
						yChunk = math.floor((y + 16384 - yOffset - 100) / yDelta * nChunksY)
						if(xChunk < triMin.x) then triMin.x = xChunk end
						if(yChunk < triMin.y) then triMin.y = yChunk end
						xChunk = math.floor((x + 16384 - xOffset + 100) / xDelta * nChunksX)
						yChunk = math.floor((y + 16384 - yOffset + 100) / yDelta * nChunksY)
						if(xChunk > triMax.x) then triMax.x = xChunk + 1 end
						if(yChunk > triMax.y) then triMax.y = yChunk + 1 end
						table.insert(triVerts, Vector(x, y, z))
					end
					triMin.x = math.Clamp(triMin.x, 0, nChunksX-1)
					triMin.y = math.Clamp(triMin.y, 0, nChunksY-1)
					triMax.x = math.Clamp(triMax.x, 0, nChunksX-1)
					triMax.y = math.Clamp(triMax.y, 0, nChunksY-1)
					
					for u = triMin.x, triMax.x do
						for v = triMin.y, triMax.y do
							chunksToPlaceIn[tostring(u) .. " " .. tostring(v)] = { u, v }
						end
					end
					
					for k,m in pairs(chunksToPlaceIn) do
						local x = m[1] + 1
						local y = m[2] + 1
						for l,n in ipairs(triVerts) do
							if(vertTable[x] == nil || vertTable[x][y] == nil) then print("Vertex array out of bounds at: ", x, y) end
							table.insert(vertTable[x][y], n)
						end
					end
				end
				
				function ParseBSP()
					include("includes/g64_luabsp.lua")
					local bsp = luabsp.LoadMap(game:GetMap())
					
					-- Displacements aren't included in map phys geometry,
					-- so we have to do the next cursed thing: bsp parsing
					local function ParseDisplacements()
						print("[G64] Processing displacements...")
						bsp:LoadDisplacementVertices()
						for i = 1, #bsp.displacement_vertices, 3 do
							local vecs = {
								bsp.displacement_vertices[i],
								bsp.displacement_vertices[i+1],
								bsp.displacement_vertices[i+2]
							}
							
							PlaceTriangleInChunks(vecs, dispVertices, xDispChunks, yDispChunks)
						end
					end
					
					-- Neither are prop_statics
					local function ParseStaticProps()
						print("[G64] Processing static props...")
						
						local function RotateVertices(verts, ang)
							local cosa = math.cos(ang.y * 0.017453)
							local sina = math.sin(ang.y * 0.017453)
							
							local cosb = math.cos(ang.x * 0.017453)
							local sinb = math.sin(ang.x * 0.017453)
							
							local cosc = math.cos(ang.z * 0.017453)
							local sinc = math.sin(ang.z * 0.017453)
							
							local Axx = cosa*cosb
							local Axy = cosa*sinb*sinc - sina*cosc
							local Axz = cosa*sinb*cosc + sina*sinc
							
							local Ayx = sina*cosb
							local Ayy = sina*sinb*sinc + cosa*cosc
							local Ayz = sina*sinb*cosc - cosa*sinc
							
							local Azx = -sinb
							local Azy = cosb*sinc
							local Azz = cosb*cosc
							
							local returnVerts = {}
							for i = 1, #verts do
								local px = verts[i].x
								local py = verts[i].y
								local pz = verts[i].z
								
								local nx = Axx*px + Axy*py + Axz*pz
								local ny = Ayx*px + Ayy*py + Ayz*pz
								local nz = Azx*px + Azy*py + Azz*pz
								
								returnVerts[i] = Vector(nx, ny, nz)
							end
							
							return returnVerts
						end
						
						bsp:LoadStaticProps()
						for i = 1, #bsp.static_props do
							local props = {}
							for k,v in ipairs(bsp.static_props[i].names) do
								local csEnt = ents.CreateClientProp(v)
								props[v] = {}
								if(csEnt:GetPhysicsObject():IsValid()) then
									for k,convex in pairs(csEnt:GetPhysicsObject():GetMeshConvexes()) do
										for k,vertex in pairs(convex) do
											table.insert(props[v], vertex.pos)
										end
									end
								end
								csEnt:Remove()
							end
							for k,v in ipairs(bsp.static_props[i].entries) do
								local propVerts = props[v.PropType]
								if(propVerts != nil && v.Solid == 6) then
									local rotatedVerts = RotateVertices(propVerts, v.Angles)
									for j = 1, #rotatedVerts, 3 do
										local vecs = {
											rotatedVerts[j],
											rotatedVerts[j+1],
											rotatedVerts[j+2]
										}
										
										PlaceTriangleInChunks(vecs, vertices, xChunks, yChunks, v.Origin)
									end
								end
							end
						end
					end
					
					if(GetConVar("g64_processdisplacements"):GetBool()) then
						ParseDisplacements()
					end
					if(GetConVar("g64_processstaticprops"):GetBool()) then
						ParseStaticProps()
					end
				end
				
				net.Receive("G64_LOADMAPGEO", function(len, ply)
					local msg = net.ReadUInt(8)
					if(msg == 0) then
						-- Setup variables n stuff
						InitMapDownload()
					elseif(msg == 1) then
						-- Process map phys geometry
						local vertCount = net.ReadUInt(32)
						local tileArea = tileSize * tileSize
						for i = 1, vertCount, 3 do
							local v1 = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
							local v2 = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
							local v3 = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
							local vecs = { v1, v2, v3 }
							
							PlaceTriangleInChunks(vecs, vertices, xChunks, yChunks)
						end
					elseif(msg == 2) then
						ParseBSP()
						
						local endTime = CurTime()
						local deltaTime = endTime - startTime
						print("[G64] Received map geometry!")
						
						libsm64.MapVertices = vertices
						libsm64.DispVertices = dispVertices
						libsm64.MapLoaded = true
						libsm64.AllowedEnts = {
							prop_physics = true,
							prop_vehicle = true,
							prop_vehicle_airboat = true,
							prop_vehicle_apc = true,
							prop_vehicle_driveable = true,
							prop_vehicle_jeep = true,
							prop_vehicle_prisoner_pod = true,
							prop_door_rotating = true,
							gmod_sent_vehicle_fphysics_base = true,
							--[[npc_alyx = true,
							npc_antlion = true,
							npc_antlion_template_maker = true,
							npc_antlionguard = true,
							npc_barnacle = true,
							npc_barney = true,
							npc_breen = true,
							npc_citizen = true,
							npc_combine_camera = true,
							npc_combine_s = true,
							npc_combinedropship = true,
							npc_combinegunship = true,
							npc_crabsynth = true,
							npc_cranedriver = true,
							npc_crow = true,
							npc_cscanner = true,
							npc_dog = true,
							npc_eli = true,
							npc_fastzombie = true,
							npc_fisherman = true,
							npc_gman = true,
							npc_headcrab = true,
							npc_headcrab_black = true,
							npc_headcrab_fast = true,
							npc_helicopter = true,
							npc_ichthyosaur = true,
							npc_kleiner = true,
							npc_manhack = true,
							npc_metropolice = true,
							npc_monk = true,
							npc_mortarsynth = true,
							npc_mossman = true,
							npc_pigeon = true,
							npc_poisonzombie = true,
							npc_rollermine = true,
							npc_seagull = true,
							npc_sniper = true,
							npc_stalker = true,
							npc_strider = true,
							npc_turret_ceiling = true,
							npc_turret_floor = true,
							npc_turret_ground = true,
							npc_vortigaunt = true,
							npc_zombie = true,
							npc_zombie_torso = true,]]
						}
						libsm64.AllowedBrushEnts = {
							func_door = true,
							func_door_rotating = true,
							func_movelinear = true,
							func_tracktrain = true,
							func_wall = true,
							func_breakable = true,
							func_brush = true,
							func_detail = true,
							func_lod = true,
							func_rotating = true,
							func_physbox = true,
							func_useableladder = true
						}
						libsm64.EntMeshes = {}
						
						hook.Run("G64Initialized")
					end
				end)
			end
		else
			libsm64 = {}
			LoadFailure()
			MsgC(Color(255, 100, 100), "[G64] Couldn't locate the G64 binary module! Please download it from https://github.com/ckosmic/g64#installation\n")
		end
	end

	hook.Add("Think", "G64_INITIALIZE", function()
		hook.Remove("Think", "G64_INITIALIZE")
		g64config.Load()
		
		LoadSM64Module()
	end)
else
	net.Receive("G64_LOADMAPGEO", function(len, ply)
		if(!ply.SM64LoadedMap) then
			print("[G64] Loading map geometry...")
			LoadMapGeometry(ply)
		end
		ply.SM64LoadedMap = true
	end)
	
	function LoadMapGeometry(ply)
		local convexes = Entity(0):GetPhysicsObject():GetMeshConvexes()
		local triCount = 0
		local worldMin, worldMax = Entity(0):GetModelBounds()
		net.Start("G64_LOADMAPGEO", false)
		net.WriteUInt(0, 8)
		
		net.WriteInt(worldMin.x, 16)
		net.WriteInt(worldMin.y, 16)
		net.WriteInt(worldMin.z, 16)
		net.WriteInt(worldMax.x, 16)
		net.WriteInt(worldMax.y, 16)
		net.WriteInt(worldMax.z, 16)
		
		net.Send(ply)
		hook.Add("Tick", "G64_MAP_LOADER" .. ply:EntIndex(), function()
			local counter = 0
			while(counter < 32 && #convexes ~= 0) do
				local convex = table.remove(convexes)
				net.Start("G64_LOADMAPGEO", false)
				net.WriteUInt(1, 8)
				net.WriteUInt(#convex, 32)
				counter = counter + 1
				for i = 1, #convex do
					local vertex = convex[i].pos
					net.WriteInt(vertex.x, 16)
					net.WriteInt(vertex.y, 16)
					net.WriteInt(vertex.z, 16)
					triCount = triCount + 1
				end
				net.Send(ply)
			end
			if(#convexes == 0) then
				hook.Remove("Tick", "G64_MAP_LOADER" .. ply:EntIndex())
				net.Start("G64_LOADMAPGEO", false)
				net.WriteUInt(2, 8)
				net.Send(ply)
			end
		end)
	end
end

drive.Register("G64_DRIVE",
{
}, "drive_base")