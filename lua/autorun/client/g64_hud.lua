AddCSLuaFile()
include("includes/g64_sprites.lua")
include("includes/g64_types.lua")

UI_SCALE = 6
ICON_SIZE = 16 * UI_SCALE
HUD_TOP_Y = 15
SCREEN_WIDTH = ScrW()
SCREEN_HEIGHT = ScrH()
ASPECT_RATIO = SCREEN_WIDTH / SCREEN_HEIGHT

local aw, ah = 0

local isSwimming = false
local emphasizingFlag = false
local sPowerMeterVisibleTimer = 0
local sPowerMeterStoredHealth = 8
local sPowerMeterHUD = {
    animation = 0,
    x = ScrW()/2-32*UI_SCALE,
    y = 240+35
}

local function GFX_DIMENSIONS_FROM_LEFT_EDGE(v)
    return (SCREEN_WIDTH * 0.5 - SCREEN_HEIGHT * 0.5 * ASPECT_RATIO + v * UI_SCALE)
end
local function GFX_DIMENSIONS_FROM_RIGHT_EDGE(v)
    return (SCREEN_WIDTH * 0.5 + SCREEN_HEIGHT * 0.5 * ASPECT_RATIO - v * UI_SCALE)
end
local function GFX_DIMENSIONS_RECT_FROM_LEFT_EDGE(v)
    return (math.floor(GFX_DIMENSIONS_FROM_LEFT_EDGE(v)))
end
local function GFX_DIMENSIONS_RECT_FROM_RIGHT_EDGE(v)
    return (math.ceil(GFX_DIMENSIONS_FROM_RIGHT_EDGE(v)))
end

local function animate_power_meter_emphasized()
    if emphasizingFlag == false then
        if sPowerMeterVisibleTimer == 45 then
            sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_DEEMPHASIZING
        end
    else
        sPowerMeterVisibleTimer = 0
    end
end

local function animate_power_meter_deemphasizing()
    local speed = 5
    if sPowerMeterHUD.y >= 181 then
        speed = 3
    end
    if sPowerMeterHUD.y >= 191 then
        speed = 2
    end
    if sPowerMeterHUD.y >= 196 then
        speed = 1
    end

    sPowerMeterHUD.y = sPowerMeterHUD.y + speed

    if sPowerMeterHUD.y >= 201 then
        sPowerMeterHUD.y = 200
        sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_VISIBLE
    end
end

local function animate_power_meter_hiding()
    sPowerMeterHUD.y = sPowerMeterHUD.y + 20
    if sPowerMeterHUD.y >= 301 then
        sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_HIDDEN
        sPowerMeterVisibleTimer = 0
    end
end

local function handle_power_meter_actions(numHealthWedges)
    if numHealthWedges < 8 and sPowerMeterStoredHealth == 8 and sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_HIDDEN then
        sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_EMPHASIZED
        sPowerMeterHUD.y = 166
    end

    if numHealthWedges == 8 and sPowerMeterStoredHealth == 7 then
        sPowerMeterVisibleTimer = 0
    end

    if numHealthWedges == 8 and sPowerMeterVisibleTimer > 45 then
        sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_HIDING
    end

    sPowerMeterStoredHealth = numHealthWedges

    if isSwimming == true then
        if sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_HIDDEN or sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_EMPHASIZED then
            sPowerMeterHUD.animation = g64types.SM64PowerMeterAnimation.POWER_METER_DEEMPHASIZING
            sPowerMeterHUD.y = 166
        end
        sPowerMeterVisibleTimer = 0
    end
end

local function SetCurrentAtlasDimensions(w, h)
    aw, ah = w, h
end

local function DrawSprite(sprite, x, y, rw, rh)
    local w, h = sprite.w, sprite.h
    local u0, v0 = sprite.u, sprite.v
    local u1, v1 = u0 + w / aw, v0 + h / ah
    local du = 0.5 / aw -- half pixel anticorrection
    local dv = 0.5 / ah -- half pixel anticorrection
    u0, v0 = (u0 - du) / (1 - 2 * du), (v0 - dv) / (1 - 2 * dv)
    u1, v1 = (u1 - du) / (1 - 2 * du), (v1 - dv) / (1 - 2 * dv)
    if false then u1 = u1-0.5/aw end
    surface.DrawTexturedRectUV(x, y, rw, rh, u0, v0, u1, v1)
end

local function DrawNumber(num, x, y)
    local num_str = tostring(num)
    for i = 1, #num_str do
        local c = num_str:sub(i,i)
        DrawSprite(g64sprites.Characters[c], x + (i-1) * 12*UI_SCALE, y, ICON_SIZE, ICON_SIZE)
    end
end

hook.Remove("HUDPaint", "G64_DRAW_HUD")
hook.Add("HUDPaint", "G64_DRAW_HUD", function()
    if GetConVar("g64_hud_enable"):GetBool() == false then return end
    local lPlayer = LocalPlayer()
    local marioEnt = lPlayer.MarioEnt
    if not IsValid(marioEnt) or not lPlayer.IsMario then return end

    local topUp = HUD_TOP_Y*UI_SCALE
    local showX = 1

    local starCount = 0
    local coinCount = lPlayer.CoinCount
    local marioNumLives = lPlayer.LivesCount
    local marioHealth = marioEnt.marioHealth
    if marioHealth < 0 then marioHealth = 0 end
    if marioHealth > 8 then marioHealth = 8 end

    if marioNumLives == nil then return end
    
    if starCount >= 100 then
        showX = 0
    end

    surface.SetDrawColor(color_white)
    surface.SetMaterial(g64utils.UIMat)
    SetCurrentAtlasDimensions(g64sprites.UI.tex_width, g64sprites.UI.tex_height)
    if marioNumLives >= 0 then
        DrawSprite(g64sprites.UI.mario_head, GFX_DIMENSIONS_RECT_FROM_LEFT_EDGE(22), topUp, ICON_SIZE, ICON_SIZE)
        DrawSprite(g64sprites.UI.times, GFX_DIMENSIONS_RECT_FROM_LEFT_EDGE(38), topUp, ICON_SIZE, ICON_SIZE)
        DrawNumber(marioNumLives, GFX_DIMENSIONS_RECT_FROM_LEFT_EDGE(54), topUp)
    end

    DrawSprite(g64sprites.UI.coin, GFX_DIMENSIONS_FROM_RIGHT_EDGE(320-168), topUp, ICON_SIZE, ICON_SIZE)
    DrawSprite(g64sprites.UI.times, GFX_DIMENSIONS_FROM_RIGHT_EDGE(320-184), topUp, ICON_SIZE, ICON_SIZE)
    DrawNumber(coinCount, GFX_DIMENSIONS_FROM_RIGHT_EDGE(320-198), topUp)

    DrawSprite(g64sprites.UI.star, GFX_DIMENSIONS_FROM_RIGHT_EDGE(78), topUp, ICON_SIZE, ICON_SIZE)
    if showX == 1 then
        DrawSprite(g64sprites.UI.times, GFX_DIMENSIONS_FROM_RIGHT_EDGE(78)+ICON_SIZE, topUp, ICON_SIZE, ICON_SIZE)
    end
    DrawNumber(starCount, (showX * 14 * UI_SCALE) + GFX_DIMENSIONS_FROM_RIGHT_EDGE(78 - 16), topUp)

    local healthX = ScrW()/2-32*UI_SCALE
    local healthY = (240-sPowerMeterHUD.y-35)*UI_SCALE
    local wedgeSprite = g64sprites.Health["wedge_" .. marioEnt.marioHealth]

    surface.SetMaterial(g64utils.HealthMat)
    SetCurrentAtlasDimensions(g64sprites.Health.tex_width, g64sprites.Health.tex_height)
    DrawSprite(g64sprites.Health.bg_0, healthX, healthY, 32*UI_SCALE, 64*UI_SCALE)
    DrawSprite(g64sprites.Health.bg_1, healthX+31*UI_SCALE, healthY, 32*UI_SCALE, 64*UI_SCALE)
    if marioHealth > 0 and wedgeSprite then
        DrawSprite(wedgeSprite, healthX+15*UI_SCALE, healthY+16*UI_SCALE, 32*UI_SCALE, 64*UI_SCALE)
    end
end)

hook.Add("G64GameTick", "G64_HUD_TICK", function() 
    local marioEnt = LocalPlayer().MarioEnt
    if not IsValid(marioEnt) or not LocalPlayer().IsMario then return end

    UI_SCALE = GetConVar("g64_hud_scale"):GetInt()
    ICON_SIZE = 16 * UI_SCALE

    if marioEnt.marioHurtCounter > 0 then
        emphasizingFlag = true
    else
        emphasizingFlag = false
    end

    if sPowerMeterHUD.animation ~= g64types.SM64PowerMeterAnimation.POWER_METER_HIDING then
        handle_power_meter_actions(marioEnt.marioHealth)
    end

    if sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_HIDDEN then
        return
    end

    if sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_EMPHASIZED then
        animate_power_meter_emphasized()
    elseif sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_DEEMPHASIZING then
        animate_power_meter_deemphasizing()
    elseif sPowerMeterHUD.animation == g64types.SM64PowerMeterAnimation.POWER_METER_HIDING then
        animate_power_meter_hiding()
    end

    sPowerMeterVisibleTimer = sPowerMeterVisibleTimer + 1
end)