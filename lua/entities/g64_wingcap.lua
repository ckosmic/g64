AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Wing Cap"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"

function ENT:SpawnFunction(ply, tr, ClassName)
	if(!tr.Hit) then return end
	
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

	if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
	
	self:PhysWake()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	if(self:GetPos():DistToSqr(self.Owner:GetPos()) < 4000) then
		if(CLIENT) then 
			if(self.Owner.MarioEnt != nil && self.Owner.IsMario == true && self.Owner.MarioEnt.hasWingCap == false) then
				self.Owner.MarioEnt.EnableWingCap = true
			end
			return
		end
		self:Remove()
	end
end