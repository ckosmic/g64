AddCSLuaFile()

ENT.CoinFrame = 0
ENT.IgnoreEnt = nil

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

	self:SetModel( "models/props_phx/misc/soccerball.mdl" )
	self:SetColor( Color( 255, 255, 255 ) )

	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
        self:PhysicsInit( SOLID_VPHYSICS )
    else
        g64utils.GlobalInit()
    end

    self:PhysWake()

    self.Collected = false

    timer.Create("G64_COIN_FRAME_TIMER" .. self:EntIndex(), 0.1, 0, function()
        self.CoinFrame = self.CoinFrame + 1
        self.CoinFrame = math.fmod(self.CoinFrame, 4)
    end)

    self:StartThinkTimer()
end

function ENT:OnRemove()
    timer.Remove("G64_COIN_FRAME_TIMER" .. self:EntIndex())
end

function ENT:Draw()
    local angle = EyeAngles()
    angle = Angle(angle.x, angle.y, 0)
    angle:RotateAroundAxis(angle:Up(), -90)
    angle:RotateAroundAxis(angle:Forward(), 90)

    local w = 20
    local h = 20

    render.OverrideDepthEnable(true, true)
    cam.Start3D2D(self:GetPos(), angle, 1)
        surface.SetDrawColor(self.CoinColor:Unpack())
        surface.SetMaterial(g64utils.CoinMat)
        local u0, v0 = self.CoinFrame*0.25,        0
        local u1, v1 = self.CoinFrame*0.25+0.25,   1
        u0 = u0 + 0.25 / 32 -- Source engine is just so funny right haha
        u1 = u1 + 0.25 / 32 -- Source engine is just so silly right haha
        surface.DrawTexturedRectUV(-w/2, -h/2, w, h, u0, v0, u1, v1)
    cam.End3D2D()
    render.OverrideDepthEnable(false)
end

local plyOffset = Vector(0, 0, 30)
function ENT:StartThinkTimer()
    timer.Create("G64_COIN_THINK_DELAY" .. self:EntIndex(), 0.5, 1, function() 
        function self:Think()
            if self:GetOwner() ~= nil and self:GetOwner():EntIndex() > 0 then
                self.Owner = ents.GetByIndex(self:GetOwner():EntIndex())
                self:SetOwner(nil)
            end
            if CLIENT then
                local ply = LocalPlayer()
                if g64utils.WithinBounds(self:GetPos(), ply:GetNetworkOrigin(), 40) and self.Collected == false and self:GetNWEntity("IgnoreEnt") ~= ply then
                    ply.CoinCount = ply.CoinCount + self.CoinValue
                    
                    if self.CoinValue == 1 then
                        local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_GENERAL_COIN)
                        libsm64.PlaySoundGlobal(soundArg)
                    elseif self.CoinValue == 2 then
                        local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_MENU_COLLECT_RED_COIN) + bit.lshift(ply.RedCoinCount, 16)
                        libsm64.PlaySoundGlobal(soundArg)
                        ply.RedCoinCount = ply.RedCoinCount + 1
                        ply.RedCoinCount = math.fmod(ply.RedCoinCount, 8)
                    elseif self.CoinValue == 5 then
                        local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_GENERAL_COIN)
                        timer.Create("G64_BLUE_COIN_SOUND", 0.07, 5, function()
                            libsm64.PlaySoundGlobal(soundArg)
                        end)
                    end

                    if IsValid(ply.MarioEnt) then
                        libsm64.MarioHeal(ply.MarioEnt.MarioId, self.CoinValue)
                    end

                    ParticleEffect("coin_pickup", self:GetPos(), Angle())

                    g64utils.RemoveFromClient(self)
                    net.Start("G64_COLLECTEDCOIN")
                    net.SendToServer()
                    self.Collected = true
                end

                self:SetNextClientThink(CurTime())
                return true
            end
        end
    end)
end

function ENT:PhysicsCollide(data, physobj)
    local LastSpeed = math.max( data.OurOldVelocity:Length(), data.Speed )
	local NewVelocity = physobj:GetVelocity()
	NewVelocity:Normalize()

	LastSpeed = math.max( NewVelocity:Length(), LastSpeed )

	local TargetVelocity = NewVelocity * LastSpeed * 0.7

	physobj:SetVelocity( TargetVelocity )
end