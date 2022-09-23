AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Mario Physbox"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:Initialize()
    self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionBounds(Vector(-16, -16, -5), Vector(16, 16, 55))
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

    if SERVER then
        self:SetModel("models/hunter/misc/sphere075x075.mdl")
        self:PhysicsInit( SOLID_BBOX )
		self:PhysWake()
        self.PhysicsObject = self:GetPhysicsObject() 
    end

    self:SetNoDraw(true)
end

function ENT:Think()
    if SERVER then
        if not IsValid(self.Mario) then
            self:Remove()
        else
            self:SetPos(self.Mario:GetPos())
        end

        if self.PhysicsObject and self.PhysicsObject:IsValid() then
            self.PhysicsObject:SetVelocityInstantaneous(Vector())
            self.PhysicsObject:SetAngleVelocity(Vector())
        else
            self.PhysicsObject = self:GetPhysicsObject()
        end
    else
        if not IsValid(self.Mario) then
            self.Mario = self:GetNWEntity("Mario")
        else
            self:SetNetworkOrigin(self.Mario:GetPos())
        end
        self.Mario.PhysBox = self
    end
end

function ENT:OnRemove()
end