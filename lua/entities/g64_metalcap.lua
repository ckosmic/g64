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
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self:SetModel( "models/player/items/humans/top_hat.mdl" )
	self:SetColor( Color( 200, 200, 200 ) )
	self:SetModelScale(2, 0)

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Collected = false

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
	if CLIENT then 
		local ply = LocalPlayer()
		local marioEnt = ply.MarioEnt
		if g64utils.WithinBounds(self:GetPos(), ply:GetNetworkOrigin(), 40) and self.Collected == false then
			if IsValid(ply.MarioEnt) and ply.IsMario == true and ply.MarioEnt.hasMetalCap == false then
				ply.MarioEnt.EnableMetalCap = true
			end

			g64utils.RemoveFromClient(self)
            self.Collected = true
		end
	end
end

list.Set("g64_entities", "g64_metalcap", {
    Category = "Caps",
    Name = "Metal Cap",
    Material = "materials/vgui/entities/g64_metalcap.png"
})