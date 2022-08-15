AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Wing Cap"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "G64"

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

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	if CLIENT then 
		local ply = LocalPlayer()
		local marioEnt = ply.MarioEnt
		if g64utils.WithinBounds(self:GetPos(), ply:GetNetworkOrigin(), 40) and self.Collected == false then
			if IsValid(ply.MarioEnt) and ply.IsMario == true and ply.MarioEnt.hasWingCap == false then
				ply.MarioEnt.EnableWingCap = true
			end

			g64utils.RemoveFromClient(self)
            self.Collected = true
		end
	end
end

list.Set("g64_entities", "g64_wingcap", {
    Category = "Caps",
    Name = "Wing Cap",
    Material = "materials/vgui/entities/g64_wingcap.png"
})