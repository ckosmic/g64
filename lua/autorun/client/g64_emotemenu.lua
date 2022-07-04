AddCSLuaFile()

g64emote = g64emote or {}

local wH = ScrW()/2
local hH = ScrH()/2

local radialMaterial = Material("vgui/radial")
local mousePos = Vector()

g64emote.Segments = 8
g64emote.SegAng = math.pi/g64emote.Segments*2

g64emote.SelRad = 2048
g64emote.OrigPoints = {
    { x = wH, y = hH+g64emote.SelRad },
    { x = wH - (hH+g64emote.SelRad - hH) * math.sin(g64emote.SegAng), y = hH + (hH+g64emote.SelRad - hH) * math.cos(g64emote.SegAng) }
}
g64emote.Triangle = {
    { x = wH, y = hH },
    { x = 0, y = 0 },
    { x = 0, y = 0 }
}
g64emote.Emotes = {
    {
        action = "ACT_START_SLEEPING",
        name = "Sleep"
    },
    {
        action = "ACT_COUGHING",
        name = "Cough"
    },
    {
        action = "ACT_SHOCKWAVE_BOUNCE",
        name = "Bounce"
    },
    {
        action = "ACT_GROUND_BONK",
        name = "Bonk"
    },
    {
        action = "ACT_DEATH_EXIT_LAND",
        name = "Hard Bonk"
    },
    {
        action = "ACT_BACKFLIP_LAND",
        name = "Haha"
    },
    {
        action = "ACT_THROWING",
        name = "Throw"
    },
    {
        action = "ACT_HEAVY_THROW",
        name = "Heavy Throw"
    },
    {
        action = "ACT_SHOCKED",
        name = "Shock"
    },
    {
        action = "ACT_PUTTING_ON_CAP",
        name = "Adjust Cap"
    },
    {
        action = "ACT_UNKNOWN_0002020E",
        name = "Wave"
    },
    {
        action = "ACT_BUTT_STUCK_IN_GROUND",
        name = "Butt Stuck"
    },
}

g64emote.CalculateSegments = function(segs)
    g64emote.Segments = segs
    g64emote.SegAng = math.pi/segs*2
    g64emote.SelRad = 2048
    g64emote.OrigPoints[2].x = wH - (hH+g64emote.SelRad - hH) * math.sin(g64emote.SegAng)
    g64emote.OrigPoints[2].y = hH + (hH+g64emote.SelRad - hH) * math.cos(g64emote.SegAng)
end

g64emote.ActiveEmotes = {}

g64emote.LoadActiveEmotes = function()
    g64emote.ActiveEmotes = string.Split(GetConVar("g64_active_emotes"):GetString(), ",")
    for i=1, #g64emote.ActiveEmotes do
        g64emote.ActiveEmotes[i] = tonumber(g64emote.ActiveEmotes[i])
        if g64emote.ActiveEmotes[i] == nil then
            table.remove(g64emote.ActiveEmotes, i)
        end
    end
    g64emote.CalculateSegments(#g64emote.ActiveEmotes)
end

g64emote.Selected = 0

local function AddHooks()
    hook.Add("HUDPaint", "G64_EMOTE_THINK", function()
        local marioEnt = LocalPlayer().MarioEnt
        if input.IsKeyDown(GetConVar("g64_emotemenu"):GetInt()) and IsValid(marioEnt) and #g64emote.ActiveEmotes > 0 then
            if g64emote.MenuOpen == false then
                g64emote.PanelContainer:Show()
                g64emote.PanelContainer:MakePopup()
            end
            g64emote.MenuOpen = true
        else
            if g64emote.MenuOpen == true then
                g64emote.PanelContainer:Hide()
                g64emote.PanelContainer:MouseCapture(false)
                g64emote.PanelContainer:SetMouseInputEnabled(false)
            end
            g64emote.MenuOpen = false
        end

        
        if g64emote.MenuOpen == true then
            render.SetStencilWriteMask( 0xFF )
            render.SetStencilTestMask( 0xFF )
            render.SetStencilReferenceValue( 0 )
            render.SetStencilCompareFunction( STENCIL_ALWAYS )
            render.SetStencilPassOperation( STENCIL_KEEP )
            render.SetStencilFailOperation( STENCIL_KEEP )
            render.SetStencilZFailOperation( STENCIL_KEEP )
            render.ClearStencil()

            render.SetStencilEnable( true )
            render.SetStencilReferenceValue( 1 )
            render.SetStencilCompareFunction( STENCIL_ALWAYS )
            render.SetStencilPassOperation( STENCIL_REPLACE )
            render.SetStencilTestMask(255)
            render.SetStencilWriteMask(255)

            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(radialMaterial)
            surface.DrawTexturedRect(ScrW()/2-256, ScrH()/2-256, 512, 512)

            render.SetStencilReferenceValue( 1 )
            render.SetStencilCompareFunction( STENCIL_EQUAL )
            render.SetStencilPassOperation( STENCIL_NEVER )
            render.SetStencilTestMask(255)
            render.SetStencilWriteMask(255)

            surface.SetFont("Default")
            surface.SetTextColor(255,255,255)
            for i=1, #g64emote.ActiveEmotes do
                local angle = math.pi/2 + g64emote.SegAng * (i-1)
                local x2 = wH + (256*math.cos(angle))
                local y2 = hH + (256*math.sin(angle))
                surface.SetDrawColor(0,0,0,230)
                surface.DrawLine(wH, hH, x2, y2)
                local x3 = wH + (180*math.cos(angle+g64emote.SegAng/2))
                local y3 = hH + (180*math.sin(angle+g64emote.SegAng/2))
                local segText = g64emote.Emotes[g64emote.ActiveEmotes[i]].name
                local w, h = surface.GetTextSize(segText)
                surface.SetTextPos(x3 - w/2, y3 - h/2)
                surface.DrawText(segText)
            end

            mousePos.x, mousePos.y = input.GetCursorPos()
            local mouseDist = math.sqrt(((wH - mousePos.x) * (wH - mousePos.x)) + ((hH - mousePos.y) * (hH - mousePos.y)))
            mousePos.x = mousePos.x - wH
            mousePos.y = mousePos.y - hH
            mousePos:Normalize()

            if mouseDist > 110 then
                local angle = math.atan2(mousePos.y, mousePos.x) + math.pi + math.pi/2

                g64emote.Selected = math.floor(angle/(math.pi*2)*g64emote.Segments) + 1
                g64emote.Selected = math.fmod(g64emote.Selected, g64emote.Segments)
                if g64emote.Selected == 0 then g64emote.Selected = g64emote.Segments end

                angle = math.floor(angle/g64emote.SegAng)*g64emote.SegAng
                local cosAng = math.cos(angle)
                local sinAng = math.sin(angle)

                g64emote.Triangle[2].x = wH + (g64emote.OrigPoints[1].x - wH) * cosAng - (g64emote.OrigPoints[1].y - hH) * sinAng
                g64emote.Triangle[2].y = hH + (g64emote.OrigPoints[1].y - hH) * cosAng + (g64emote.OrigPoints[1].x - wH) * sinAng
                g64emote.Triangle[3].x = wH + (g64emote.OrigPoints[2].x - wH) * cosAng - (g64emote.OrigPoints[2].y - hH) * sinAng
                g64emote.Triangle[3].y = hH + (g64emote.OrigPoints[2].y - hH) * cosAng + (g64emote.OrigPoints[2].x - wH) * sinAng

                surface.SetDrawColor(163,163,163,100)
                if g64emote.Segments > 2 then
                    draw.NoTexture()
                    surface.DrawPoly(g64emote.Triangle)
                elseif g64emote.Segments == 2 then
                    mousePos.x, mousePos.y = input.GetCursorPos()
                    if mousePos.x > wH then
                        surface.DrawRect(wH, hH-256, 256, 512)
                        g64emote.Selected = 2
                    else
                        surface.DrawRect(wH-256, hH-256, 256, 512)
                        g64emote.Selected = 1
                    end
                elseif g64emote.Segments == 1 then
                    surface.DrawRect(wH-256, hH-256, 512, 512)
                    g64emote.Selected = 1
                end
            else
                g64emote.Selected = 0
            end

            render.SetStencilEnable( false )
        else
            if g64emote.Selected > 0 then
                local action = g64types.SM64MarioAction[g64emote.Emotes[g64emote.ActiveEmotes[g64emote.Selected]].action]
                marioEnt:SetMarioAction(action)
                g64emote.Selected = 0
            end
        end
    end)
end

local function CreatePanels()
    if g64emote.PanelContainer then g64emote.PanelContainer:Remove() end

    g64emote.PanelContainer = vgui.Create("DPanel")
    g64emote.PanelContainer:SetPos(ScrW()/2-256, ScrH()/2-256)
    g64emote.PanelContainer:SetSize(512, 512)
    g64emote.PanelContainer:SetDrawBackground(false)
    g64emote.PanelContainer:Hide()

    hook.Remove("HUDPaint", "G64_EMOTE_THINK")
    AddHooks()
end

g64emote.LoadActiveEmotes()
timer.Remove("WaitToCreatePanels")
timer.Create("WaitToCreatePanels", 0.1, 1, CreatePanels)