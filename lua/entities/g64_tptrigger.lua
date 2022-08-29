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

function ENT:StartTouch(ent)
    if IsValid(ent) and ent:IsPlayer() and ent.IsMario and IsValid(ent.MarioEnt) then
        net.Start("G64_TELEPORTMARIO")
            net.WriteEntity(ent.MarioEnt)
            net.WriteVector(self.TargetPos)
            net.WriteAngle(self.TargetAng)
        net.Send(ent)
    end
end
function ENT:Touch(ent)
    
end
function ENT:EndTouch(ent)

end