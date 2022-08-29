AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Vanish Cap"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = false
ENT.Category = "G64"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	
	local ent = ents.Create(ClassName)
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self:SetModel( "models/player/items/humans/top_hat.mdl" )
	self:SetColor( Color( 255, 255, 255 ) )
	self:SetModelScale(2, 0)

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Collected = false

	if SERVER then self:PhysicsInit( SOLID_VPHYSICS ) end
	
	self:PhysWake()
end

function ENT:DrawTranslucent()
	local curBlend = render.GetBlend()
	render.OverrideDepthEnable(true, true)
	render.SetBlend(0)
	render.SetColorMaterial()
	self:DrawModel()
	render.OverrideDepthEnable(false)

	render.SetBlend(0.5)
	self:DrawModel()
	render.SetBlend(curBlend)
end

function ENT:Think()
	if CLIENT then 
		local ply = LocalPlayer()
		local marioEnt = ply.MarioEnt
		if g64utils.WithinBounds(self:GetPos(), ply:GetNetworkOrigin(), 40) and self.Collected == false then
			if IsValid(ply.MarioEnt) and ply.IsMario == true and ply.MarioEnt.hasVanishCap == false then
				ply.MarioEnt.EnableVanishCap = true
			end

			g64utils.RemoveFromClient(self)
            self.Collected = true
		end
	end
end

list.Set("g64_entities", "g64_vanishcap", {
    Category = "Caps",
    Name = "Vanish Cap",
    Material = "materials/vgui/entities/g64_vanishcap.png"
})