AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Metal Cap"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"

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
	self:SetColor( Color( 200, 200, 200 ) )
	self:SetModelScale(2, 0)

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	if SERVER then self:PhysicsInit( SOLID_VPHYSICS ) end
	
	self:PhysWake()
end

local metalMat = Material("debug/env_cubemap_model")
function ENT:Draw()
	render.MaterialOverride(metalMat)
	self:DrawModel()
	render.MaterialOverride(nil)
end

function ENT:Think()
	if self:GetPos():DistToSqr(self.Owner:GetPos()) < 4000 then
		if CLIENT then 
			if self.Owner.MarioEnt ~= nil and self.Owner.IsMario == true and self.Owner.MarioEnt.hasMetalCap == false then
				self.Owner.MarioEnt.EnableMetalCap = true
			end
			return
		end
		self:Remove()
	end
end