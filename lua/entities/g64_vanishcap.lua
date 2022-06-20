AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Vanish Cap"
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

	self:SetModel( "models/player/items/humans/top_hat.mdl" )
	self:SetColor( Color( 255, 255, 255 ) )
	self:SetModelScale(2, 0)

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

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
	if self:GetOwner() ~= nil and self:GetOwner():EntIndex() > 0 then
		self.Owner = ents.GetByIndex(self:GetOwner():EntIndex())
		self:SetOwner(nil)
	end
	if self.Owner ~= nil and self:GetPos():DistToSqr(self.Owner:GetPos()) < 4000 then
		if CLIENT then 
			if self.Owner.MarioEnt ~= nil and self.Owner.IsMario == true and self.Owner.MarioEnt.hasVanishCap == false then
				self.Owner.MarioEnt.EnableVanishCap = true
			end
			return
		end
		self:Remove()
	end
end