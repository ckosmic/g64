AddCSLuaFile()

util.AddNetworkString("G64_LOADMAPGEO")
util.AddNetworkString("G64_PLAYERREADY")
util.AddNetworkString("G64_HURTNPC")
util.AddNetworkString("G64_USEENTITY")
util.AddNetworkString("G64_MARIOTRACE")
util.AddNetworkString("G64_TRANSMITMOVE")
util.AddNetworkString("G64_TRANSMITCAP")
util.AddNetworkString("G64_DAMAGEMARIO")
util.AddNetworkString("G64_INITLOCALCLIENT")
util.AddNetworkString("G64_TICKREMOTEMARIO")
util.AddNetworkString("G64_MARIOGROUNDPOUND")
util.AddNetworkString("G64_TRANSMITCOLORS")
util.AddNetworkString("G64_UPDATEREMOTECOLORS")
util.AddNetworkString("G64_UPDATEREMOTECAP")
util.AddNetworkString("G64_REQUESTCOLORS")
util.AddNetworkString("G64_UPLOADCOLORS")
util.AddNetworkString("G64_REMOVEINVALIDMARIO")
util.AddNetworkString("G64_CHANGESURFACEINFO")

g64sv = {}
g64sv.PlayerColors = {}
g64sv.PlayerTick = {}

local directionAngCos = math.cos(math.pi / 2)
local function DegreesFromEyes(ply, pos)
	if(!pos) then return 360 end
	local dPos = (pos + ply:EyeAngles():Forward()*300) - ply:GetShootPos()
	dPos:Normalize()
	local flDot = ply:EyeAngles():Forward():Dot(dPos)
	local flDegreesFromCrosshair = math.deg(math.acos(flDot))
	return math.abs(flDegreesFromCrosshair)
end

local animInfo = {}
local networkedPos = Vector()
local upOffset = Vector(0,0,5)
animInfo.rotation = {}
net.Receive("G64_TRANSMITMOVE", function(len, ply)
	if(IsValid(ply.MarioEnt)) then
	
		networkedPos.x = net.ReadInt(16)
		networkedPos.y = net.ReadInt(16)
		networkedPos.z = net.ReadInt(16)
		networkedPos = networkedPos + upOffset
		ply:SetPos(networkedPos)
		ply.MarioEnt:SetPos(networkedPos)
		
		animInfo.animID = net.ReadInt(16)
		animInfo.animAccel = net.ReadInt(32)
		animInfo.rotation[1] = net.ReadInt(16)
		animInfo.rotation[2] = net.ReadInt(16)
		animInfo.rotation[3] = net.ReadInt(16)
		
		local health = net.ReadUInt(4)
		ply:SetHealth(health)
		
		local flags = net.ReadUInt(32)
		
		local filter = RecipientFilter()
		filter:AddAllPlayers()
		filter:RemovePlayer(ply)
		local plys = filter:GetPlayers()
		for i = 1, #plys do
			if(DegreesFromEyes(plys[i], networkedPos) > plys[i]:GetFOV()) then
				filter:RemovePlayer(plys[i])
			end
		end
		
		net.Start("G64_TICKREMOTEMARIO", false)
			net.WriteEntity(ply.MarioEnt)
			net.WriteInt(animInfo.animID, 16)
			net.WriteInt(animInfo.animAccel, 32)
			net.WriteInt(animInfo.rotation[1], 16)
			net.WriteInt(animInfo.rotation[2], 16)
			net.WriteInt(animInfo.rotation[3], 16)
			net.WriteUInt(flags, 32)
		net.Send(filter)
	end
end)

net.Receive("G64_TRANSMITCOLORS", function(len, ply)
	if(IsValid(ply.MarioEnt)) then
		if(g64sv.PlayerColors[ply] == nil) then g64sv.PlayerColors[ply] = {} end
		local colTab = g64sv.PlayerColors[ply]
		for i=1, 6 do
			colTab[i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
		end
		
		net.Start("G64_UPDATEREMOTECOLORS", false)
			net.WriteEntity(ply.MarioEnt)
			for i=1, 6 do
				net.WriteUInt(colTab[i][1], 8)
				net.WriteUInt(colTab[i][2], 8)
				net.WriteUInt(colTab[i][3], 8)
			end
		net.SendOmit(ply)
	end
end)

net.Receive("G64_REQUESTCOLORS", function(len, ply)
	local owner = net.ReadEntity()
	if(IsValid(owner.MarioEnt)) then
		if(g64sv.PlayerColors[owner] != nil) then
			local colTab = g64sv.PlayerColors[owner]
			
			net.Start("G64_UPDATEREMOTECOLORS", false)
				net.WriteEntity(owner.MarioEnt)
				for i=1, 6 do
					net.WriteUInt(colTab[i][1], 8)
					net.WriteUInt(colTab[i][2], 8)
					net.WriteUInt(colTab[i][3], 8)
				end
			net.Send(ply)
		end
	end
end)

hook.Add("EntityTakeDamage", "G64_PLAYER_DAMAGED", function(target, dmg)
	if(target:IsPlayer() && target.IsMario == true && target:HasGodMode() == false) then
		local damage = math.ceil(dmg:GetDamage()/10)
		local src = dmg:GetDamagePosition()
	
		net.Start("G64_DAMAGEMARIO", true)
			net.WriteUInt(damage, 8)
			net.WriteInt(src.x, 16)
			net.WriteInt(src.y, 16)
			net.WriteInt(src.z, 16)
		net.Send(target)
		
		return true
	end
end)

hook.Add("PlayerDeath", "G64_PLAYER_DEATH", function(victim, inflictor, attacker)
	if(IsValid(victim.MarioEnt)) then
		victim.MarioEnt:Remove()
	end
end)

-- Exit mario if the use key is pressed
hook.Add("KeyPress", "G64_EXIT_MARIO", function(ply, key)
	if(IsValid(ply.MarioEnt)) and ( key == IN_USE ) then
		ply.MarioEnt:Remove()
	end
end)

hook.Add("EntityRemoved", "G64_ENTITY_REMOVED", function(ent)
	local ply = ent.Owner
	if(ply != nil && ply:IsValid() && ply:IsPlayer() && ply.IsMario == true) then
		g64sv.PlayerColors[ply] = nil
		g64sv.PlayerTick[ply] = nil
	end
end)

net.Receive("G64_UPLOADCOLORS", function(len, ply)
	if(g64sv.PlayerColors[ply] == nil) then g64sv.PlayerColors[ply] = {} end
	for i=1, 6 do
		g64sv.PlayerColors[ply][i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
	end
end)

net.Receive("G64_MARIOTRACE", function(len, ply)
	local mario = net.ReadEntity()
	local startPos = net.ReadVector()
	local scaleFactor = net.ReadFloat()
	local forward = net.ReadVector()
	
	local tr = util.TraceHull({
		start = startPos,
		endpos = (startPos + forward * (90 / scaleFactor)),
		filter = { mario, ply },
		mins = Vector(-16, -16, -(40 / scaleFactor)),
		maxs = Vector(16, 16, 71),
		mask = MASK_SHOT_HULL
	})
	if(tr.Hit && IsValid(tr.Entity)) then
		if(tr.Entity:IsNPC() || tr.Entity:IsPlayer() || tr.Entity:Health() > 0) then
			local d = DamageInfo()
			d:SetDamage(math.random(8, 12))
			d:SetAttacker(mario)
			d:SetInflictor(mario)
			d:SetDamageType(DMG_GENERIC)
			d:SetDamageForce(forward * 15000)
			tr.Entity:TakeDamageInfo(d)
			mario:EmitSound("Flesh.ImpactHard", 75, 100, 1, CHAN_BODY)
		elseif(tr.Entity:GetPhysicsObject():IsValid()) then
			local phys = tr.Entity:GetPhysicsObject()
			local forcevec = forward * 7800
			local forcepos = tr.HitPos
			
			phys:ApplyForceOffset(forcevec, forcepos)
		end
	end
	
	if(ply:GetUseEntity() != NULL) then
		ply:GetUseEntity():Use(mario, mario, USE_ON)
	end
end)

net.Receive("G64_MARIOGROUNDPOUND", function(len, ply)
	local mario = net.ReadEntity()
	local target = net.ReadEntity()
	
	if(IsValid(target) && (target:IsPlayer() || target:IsNPC() || target:Health() > 0)) then
		local d = DamageInfo()
		d:SetDamage(math.random(12, 16))
		d:SetAttacker(mario)
		d:SetInflictor(mario)
		d:SetDamageType(DMG_GENERIC)
		d:SetDamageForce((target:GetPos() - mario:GetPos()) * 15000)
		target:TakeDamageInfo(d)
		mario:EmitSound("Flesh.ImpactHard", 75, 100, 1, CHAN_BODY)
	elseif(target:GetPhysicsObject():IsValid()) then
		local phys = target:GetPhysicsObject()
		local forcedir = target:GetPos() - mario:GetPos()
		local forcevec = forcedir:GetNormalized() * (300000 / forcedir:Length()) + Vector(0,0,4500)
		
		phys:ApplyForceCenter(forcevec)
	end
end)

net.Receive("G64_REMOVEINVALIDMARIO", function(len, ply)
	local ent = net.ReadEntity()
	if(ent != nil) then ent:Remove() end
end)

local meta = FindMetaTable("Player")

meta.DefaultGodEnable = meta.DefaultGodEnable or meta.GodEnable
meta.DefaultGodDisable = meta.DefaultGodDisable or meta.GodDisable

function meta:GodEnable()
	print("god enabled")
	self:SetNWBool("HasGodMode", true)
	self:DefaultGodEnable()
end

function meta:GodDisable()
	print("god disabled")
	self:SetNWBool("HasGodMode", false)
	self:DefaultGodDisable()
end