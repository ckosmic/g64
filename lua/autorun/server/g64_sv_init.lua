AddCSLuaFile()

util.AddNetworkString("G64_LOADMAPGEO")
util.AddNetworkString("G64_PLAYERREADY")
util.AddNetworkString("G64_HURTNPC")
util.AddNetworkString("G64_USEENTITY")
util.AddNetworkString("G64_DAMAGEENTITY")
util.AddNetworkString("G64_TRANSMITMOVE")
util.AddNetworkString("G64_TRANSMITCAP")
util.AddNetworkString("G64_DAMAGEMARIO")
util.AddNetworkString("G64_INITLOCALCLIENT")
util.AddNetworkString("G64_TICKREMOTEMARIO")
util.AddNetworkString("G64_TRANSMITCOLORS")
util.AddNetworkString("G64_UPDATEREMOTECOLORS")
util.AddNetworkString("G64_UPDATEREMOTECAP")
util.AddNetworkString("G64_REQUESTCOLORS")
util.AddNetworkString("G64_UPLOADCOLORS")
util.AddNetworkString("G64_REMOVEINVALIDMARIO")
util.AddNetworkString("G64_CHANGESURFACEINFO")
util.AddNetworkString("G64_RESETINVALIDPLAYER")
util.AddNetworkString("G64_SPAWNMARIOATPLAYER")

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
	if(IsValid(ply.MarioEnt)) and ( key == IN_RELOAD ) then
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

local useBlacklist = {
	prop_vehicle = true,
	prop_vehicle_airboat = true,
	prop_vehicle_apc = true,
	prop_vehicle_cannon = true,
	prop_vehicle_crane = true,
	prop_vehicle_driveable = true,
	prop_vehicle_jeep = true,
	prop_vehicle_prisoner_pod = true,
}
hook.Add("PlayerUse", "G64_PLAYER_USE", function(ply, ent)
	if(IsValid(ply.MarioEnt) && ply.IsMario == true && useBlacklist[ent:GetClass()]) then return false end
end)

hook.Add("PlayerDisconnected", "G64_PLY_DISCONNECT", function(ply)
	if(IsValid(ply.MarioEnt) && ply.IsMario == true) then ply.MarioEnt:Remove() end
end)

net.Receive("G64_UPLOADCOLORS", function(len, ply)
	if(g64sv.PlayerColors[ply] == nil) then g64sv.PlayerColors[ply] = {} end
	for i=1, 6 do
		g64sv.PlayerColors[ply][i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
	end
end)

net.Receive("G64_DAMAGEENTITY", function(len, ply)
	local mario = net.ReadEntity()
	local victim = net.ReadEntity()
	local forceVec = net.ReadVector()
	local hitPos = net.ReadVector()
	local minDmg = net.ReadUInt(8)

	if(!IsValid(victim) || !IsValid(mario)) then return end
	if(victim:IsNPC() || victim:IsPlayer() || victim:Health() > 0) then
		local d = DamageInfo()
		d:SetDamage(math.random(minDmg, minDmg+10))
		d:SetAttacker(mario)
		d:SetInflictor(mario)
		d:SetDamageType(DMG_GENERIC)
		d:SetDamageForce(forceVec * 15000)
		d:SetDamagePosition(hitPos)

		victim:TakeDamageInfo(d)
	elseif(victim:GetPhysicsObject():IsValid()) then
		local phys = victim:GetPhysicsObject()
		
		phys:ApplyForceOffset(forceVec * 7800, hitPos)
	end
	
	if(ply:GetUseEntity() != NULL) then
		ply:GetUseEntity():Use(mario, mario, USE_ON)
	end
end)

net.Receive("G64_REMOVEINVALIDMARIO", function(len, ply)
	local ent = net.ReadEntity()
	if(ent != nil) then ent:Remove() end
end)

net.Receive("G64_RESETINVALIDPLAYER", function(len, ply)
	local mario = net.ReadEntity()
	if(mario != nil) then mario:Remove() end
	ply.SM64LoadedMap = false
end)

net.Receive("G64_SPAWNMARIOATPLAYER", function(len, ply)
	local mario = ents.Create("g64_mario")
	mario:SetPos(ply:GetPos())
	mario:SetOwner(ply)
	mario:Spawn()
	mario:Activate()
	undo.Create("Mario")
		undo.AddEntity(mario)
		undo.SetPlayer(ply)
	undo.Finish()
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