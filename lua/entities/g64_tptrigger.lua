AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Teleport Trigger"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:Initialize()
    self:PhysicsFromMesh(self.PhysMesh)

    if SERVER then
        self:SetTrigger(true)
    end

    self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid( SOLID_VPHYSICS )
    self:SetSolidFlags(bit.bor(FSOLID_TRIGGER, FSOLID_CUSTOMRAYTEST, FSOLID_CUSTOMBOXTEST, FSOLID_NOT_SOLID))

    self:SetNoDraw(true)
end

function ENT:Think()
    if SERVER then
        if self.TargetPos == nil or self.TargetAng == nil then
            local keyValues = self.OrigTrigger:GetKeyValues()
            local tpTarget = ents.FindByName(keyValues.target)[1]
            if IsValid(tpTarget) then
                self.TargetPos = tpTarget:GetPos()
                self.TargetAng = tpTarget:GetAngles()
            end
        end
    end
end

function ENT:StartTouch(ent)
end

function ENT:Touch(ent)
    if ent:GetClass() == "g64_mario" and IsValid(ent.Owner) and self.Enabled == true then
        if self.TargetPos ~= nil and self.TargetAng ~= nil then
            net.Start("G64_TELEPORTMARIO")
                net.WriteEntity(ent)
                net.WriteVector(self.TargetPos)
                net.WriteAngle(self.TargetAng)
            net.Send(ent.Owner)
        end
    end
end

function ENT:EndTouch(ent)
end

function ENT:PassesTriggerFilters( entity )
	return true
end

function ENT:KeyValue( key, value )
end

function ENT:OnRemove()
end