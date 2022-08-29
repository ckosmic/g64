AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_brush"

ENT.PrintName = "Teleport Trigger"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"

function ENT:Initialize()
    self:PhysicsFromMesh(self.PhysMesh)

    if SERVER then
        self:SetTrigger(true)
    end

    self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid( SOLID_VPHYSICS )
    self:SetSolidFlags(bit.bor(FSOLID_TRIGGER, FSOLID_CUSTOMRAYTEST, FSOLID_CUSTOMBOXTEST, FSOLID_NOT_SOLID))
end

function ENT:Think()
    if SERVER and (self.TargetPos == nil or self.TargetAng == nil) then
        local keyValues = self.OrigTrigger:GetKeyValues()
		local tpTarget = ents.FindByName(keyValues.target)[1]
        if IsValid(tpTarget) then
			self.TargetPos = tpTarget:GetPos()
			self.TargetAng = tpTarget:GetAngles()
		end
    end
end

function ENT:StartTouch(ent)
    if IsValid(ent) and ent:IsPlayer() and ent.IsMario and IsValid(ent.MarioEnt) then
        if self.TargetPos ~= nil and self.TargetAng ~= nil then
            net.Start("G64_TELEPORTMARIO")
                net.WriteEntity(ent.MarioEnt)
                net.WriteVector(self.TargetPos)
                net.WriteAngle(self.TargetAng)
            net.Send(ent)
        end
    end
end
function ENT:Touch(ent)
    
end
function ENT:EndTouch(ent)

end