AddCSLuaFile()

MAP_GEO_CACHE_VERSION = 1

g64utils = {}

g64utils.MarioHasFlag = function(mask, flag)
    return (bit.band(mask, flag) != 0)
end

if CLIENT then
    g64utils.MarioRT = GetRenderTargetEx("Mario_Texture", 1024, 64, RT_SIZE_OFFSCREEN, MATERIAL_RT_DEPTH_NONE, 0, 0, IMAGE_FORMAT_RGBA8888)
    g64utils.MarioLightingMat = CreateMaterial("g64/libsm64_mario_lighting", "VertexLitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = "vgui/white",
        ["$receiveflashlight"] = "1",
        Proxies = {
            ["Clamp"] = { min="0.0", max="1.0", srcVar1="$color2", resultVar="$color2" },
        }
    })
    g64utils.MarioVertsMat = CreateMaterial("g64/libsm64_mario_verts", "UnlitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = "vgui/white",
        ["$vertexcolor"] = "1",
        ["$receiveflashlight"] = "1",
    })
    g64utils.MarioTexMat = CreateMaterial("g64/libsm64_mario_tex", "VertexLitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = g64utils.MarioRT:GetName(),
        ["$decal"] = "1",
        ["$translucent"] = "1",
        ["$receiveflashlight"] = "1",
    })
    g64utils.MarioWingsMat = CreateMaterial("g64/libsm64_mario_wings", "VertexLitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = g64utils.MarioRT:GetName(),
        ["$alphatest"] = "1",
        ["$nocull"] = "1",
        ["$receiveflashlight"] = "1",
    })
    g64utils.DebugMat = CreateMaterial("g64/libsm64_debug", "UnlitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = "vgui/white",
        ["$decal"] = "1",
        ["$vertexcolor"] = "1"
    })
    g64utils.WhiteMat = CreateMaterial("g64/libsm64_white", "UnlitGeneric", {
        ["$model"] = "1",
        ["$basetexture"] = "vgui/white",
        ["$translucent"] = "1",
    })
    g64utils.MetalMat = Material("debug/env_cubemap_model")

    -- A mask of just Marios
    g64utils.MarioTargetRT = GetRenderTarget("G64_MARIO_TARGET", ScrW(), ScrH())
    g64utils.MarioTargetMat = CreateMaterial("g64/libsm64_mario_target", "UnlitGeneric", {
        ["$basetexture"] = g64utils.MarioTargetRT:GetName(),
        ["$vertexalpha"] = "1",
        ["$alpha"] = "0.5"
    })

    -- What's shown after opaque objects have been rendered
    g64utils.FramebufferRT = GetRenderTarget("G64_FB", ScrW(), ScrH())
    g64utils.FramebufferMat = CreateMaterial("g64/libsm64_framebuffer", "UnlitGeneric", {
        ["$basetexture"] = g64utils.FramebufferRT:GetName(),
        ["$vertexalpha"] = "1",
        ["$alpha"] = "1"
    })

    hook.Add("PostDrawOpaqueRenderables", "G64_COPY_FRAMEBUFFER", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
        render.SetWriteDepthToDestAlpha(false)
        render.CopyRenderTargetToTexture(g64utils.FramebufferRT) -- Used for vanish cap translucency

        render.PushRenderTarget(g64utils.MarioTargetRT)
        render.OverrideAlphaWriteEnable(true, true)
        render.ClearDepth()
        render.Clear(0,0,0,0)
        render.OverrideAlphaWriteEnable(false)
        render.PopRenderTarget()
    end)
    hook.Add("PostDrawTranslucentRenderables", "G64_OVERLAY_FRAMEBUFFER", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
        -- Overlay a translucent image of opaque entites that have been rendered under Mario
        render.SetWriteDepthToDestAlpha(false)
        render.PushRenderTarget(g64utils.MarioTargetRT)
        cam.Start2D()
            render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN)
            render.DrawTextureToScreen(g64utils.FramebufferRT)
            render.OverrideBlend(false)
        cam.End2D()
        render.PopRenderTarget()
        render.SetWriteDepthToDestAlpha(true)

        render.SetMaterial(g64utils.MarioTargetMat)
        render.DrawScreenQuad()
    end)

    g64utils.Inputs = {}
    g64utils.Inputs[1] = Vector()
	g64utils.Inputs[2] = false
	g64utils.Inputs[3] = false
	g64utils.Inputs[4] = false
    g64utils.GetInputTable = function()
        local inputs = g64utils.Inputs
        if input.IsButtonDown(GetConVar("g64_forward"):GetInt()) then
            inputs[1].z = -1
        elseif input.IsButtonDown(GetConVar("g64_back"):GetInt()) then
            inputs[1].z = 1
        else
            inputs[1].z = 0
        end
        if input.IsButtonDown(GetConVar("g64_moveleft"):GetInt()) then
            inputs[1].x = -1
        elseif input.IsButtonDown(GetConVar("g64_moveright"):GetInt()) then
            inputs[1].x = 1
        else
            inputs[1].x = 0
        end
        -- Normalize joystick inputs
        local mag = math.sqrt((inputs[1].x * inputs[1].x) + (inputs[1].z * inputs[1].z))
        if mag > 0 then
            inputs[1].x = inputs[1].x / mag
            inputs[1].z = inputs[1].z / mag
        end

        if input.IsButtonDown(GetConVar("g64_jump"):GetInt()) then
            inputs[2] = true
        else
            inputs[2] = false
        end

        if input.IsButtonDown(GetConVar("g64_attack"):GetInt()) then
            inputs[3] = true
        else
            inputs[3] = false
        end

        if input.IsButtonDown(GetConVar("g64_duck"):GetInt()) then
            inputs[4] = true
        else
            inputs[4] = false
        end

        return g64utils.Inputs
    end
    g64utils.GetZeroInputTable = function()
        local inputs = g64utils.Inputs
        inputs[1].z = 0
        inputs[1].x = 0
        inputs[2] = false
        inputs[3] = false
        inputs[4] = false

        return g64utils.Inputs
    end

    g64utils.WriteMapCache = function(filename, map, disp)
		if not file.Exists("g64/cache", "DATA") then
			file.CreateDir("g64/cache")
		end
		local filename = "g64/cache/" .. game:GetMap() .. "_cache.dat"
		local f = file.Open(filename, "wb", "DATA")

		-- File header
		f:WriteULong(MAP_GEO_CACHE_VERSION)
		f:WriteShort(libsm64.XDelta)
		f:WriteShort(libsm64.YDelta)
		f:WriteShort(libsm64.WorldMin.x)
        f:WriteShort(libsm64.WorldMin.y)
        f:WriteShort(libsm64.WorldMin.z)
		f:WriteShort(libsm64.WorldMax.x)
        f:WriteShort(libsm64.WorldMax.y)
        f:WriteShort(libsm64.WorldMax.z)
		f:WriteUShort(libsm64.XChunks)
		f:WriteUShort(libsm64.YChunks)
		f:WriteUShort(libsm64.XDispChunks)
		f:WriteUShort(libsm64.YDispChunks)

		-- Map geometry data
		for x=1, libsm64.XChunks, 1 do
			for y=1, libsm64.YChunks, 1 do
				local chunk = map[x][y]
				f:WriteULong(#chunk)
				for i=1, #chunk, 1 do
					local vert = chunk[i]
					f:WriteFloat(vert.x)
					f:WriteFloat(vert.y)
					f:WriteFloat(vert.z)
				end
			end
		end
		for x=1, libsm64.XDispChunks, 1 do
			for y=1, libsm64.YDispChunks, 1 do
				local chunk = disp[x][y]
				f:WriteULong(#chunk)
				for i=1, #chunk, 1 do
					local vert = chunk[i]
					f:WriteFloat(vert.x)
					f:WriteFloat(vert.y)
					f:WriteFloat(vert.z)
				end
			end
		end
		f:Close()
	end
    g64utils.LoadMapCache = function(filename)
        if not file.Exists(filename, "DATA") then return false end

		if libsm64.LoadMapCache(filename, MAP_GEO_CACHE_VERSION) == false then return false end
        libsm64.MapLoaded = true

        return true
	end
end