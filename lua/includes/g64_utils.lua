AddCSLuaFile()

g64utils = {}

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
end