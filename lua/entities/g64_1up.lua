AddCSLuaFile()
include("includes/g64_sprites.lua")

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "1-Up"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	
	local ent = ents.Create(ClassName)
	ent:SetOwner(ply)
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self.Owner = self:GetOwner()

	self:SetModel( "models/props_phx/misc/soccerball.mdl" )
	self:SetColor( Color( 255, 255, 255 ) )

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
    else
        g64utils.GlobalInit()
    end

    self:PhysWake()

    self.Collected = false
end

function ENT:DrawTranslucent()
    local angle = EyeAngles()
    angle = Angle(angle.x, angle.y, 0)
    angle:RotateAroundAxis(angle:Up(), -90)
    angle:RotateAroundAxis(angle:Forward(), 90)

    local w = 20
    local h = 20

    render.OverrideDepthEnable(true, true)
    cam.Start3D2D(self:GetPos(), angle, 1)
        surface.SetDrawColor(color_white)
        surface.SetMaterial(g64utils.HealthMat)
        local he = g64sprites.Health
        local u0, v0 = he.one_up.u,        0
        local u1, v1 = he.one_up.u + he.one_up.w / he.tex_width,   1
        u0 = u0 + he.one_up.w / he.tex_width / he.tex_width -- Source engine is just so funny right haha
        u1 = u1 + he.one_up.w / he.tex_width / he.tex_width -- Source engine is just so silly right haha
        surface.DrawTexturedRectUV(-w/2, -h/2, w, h, u0, v0, u1, v1)
    cam.End3D2D()
    render.OverrideDepthEnable(false)
end

local plyOffset = Vector(0, 0, 30)
function ENT:Think()
    if self:GetOwner() ~= nil and self:GetOwner():EntIndex() > 0 then
        self.Owner = ents.GetByIndex(self:GetOwner():EntIndex())
        self:SetOwner(nil)
    end
    if CLIENT then
        local ply = LocalPlayer()
        local marioEnt = ply.MarioEnt
        if g64utils.WithinBounds(self:GetPos(), ply:GetNetworkOrigin(), 40) and self.Collected == false and self:GetNWEntity("IgnoreEnt") ~= ply then
            if IsValid(marioEnt) then
                libsm64.MarioSetLives(marioEnt.MarioId, marioEnt.marioNumLives + 1)
            end

            local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_GENERAL_COLLECT_1UP)
            libsm64.PlaySoundGlobal(soundArg)

            ParticleEffect("coin_pickup", self:GetPos(), Angle())

            g64utils.RemoveFromClient(self)
            net.Start("G64_COLLECTED1UP")
            net.SendToServer()
            self.Collected = true
        end

        self:SetNextClientThink(CurTime())
        return true
    end
end

function ENT:PhysicsCollide(data, physobj)
    local LastSpeed = math.max( data.OurOldVelocity:Length(), data.Speed )
	local NewVelocity = physobj:GetVelocity()
	NewVelocity:Normalize()

	LastSpeed = math.max( NewVelocity:Length(), LastSpeed )

	local TargetVelocity = NewVelocity * LastSpeed * 0.2

	physobj:SetVelocity( TargetVelocity )
end