AddCSLuaFile()
include("includes/g64_utils.lua")

g64sv = {}
g64sv.PlayerColors = {}
g64sv.PlayerTick = {}

local directionAngCos = math.cos(math.pi / 2)
local function DegreesFromEyes(ply, pos)
	if not pos then return 360 end
	local dPos = (pos + ply:EyeAngles():Forward()*300) - ply:GetShootPos()
	dPos:Normalize()
	local flDot = ply:EyeAngles():Forward():Dot(dPos)
	local flDegreesFromCrosshair = math.deg(math.acos(flDot))
	return math.abs(flDegreesFromCrosshair)
end

local function GetSeatPoint(veh, role)
	if IsValid(veh) and veh:IsVehicle() then
		local seatAttachment = veh:LookupAttachment("vehicle_feet_passenger" .. role)
		local vPos, vAng = nil
		if seatAttachment > 0 then
			local seat = veh:GetAttachment(seatAttachment)
			return seat.Pos, seat.Ang
		else
			return veh:GetPassengerSeatPoint(role)
		end
	end
	return nil, nil
end

local animInfo = {}
local networkedPos = Vector()
local upOffset = Vector(0,0,5)
local traceTable = {}
local lastSafePos = Vector()
animInfo.rotation = {}
net.Receive("G64_TRANSMITMOVE", function(len, ply)
	if IsValid(ply.MarioEnt) then
	
		local mario = ply.MarioEnt

		networkedPos.x = net.ReadInt(16)
		networkedPos.y = net.ReadInt(16)
		networkedPos.z = net.ReadInt(16)
		networkedPos = networkedPos + upOffset
		local dist = mario:GetNWFloat("PlyMarioDist")
		ply:SetGroundEntity(nil)

		if not IsValid(ply.UsingCamera) then
			ply:SetNWEntity("UsingCamera", ply)
		else
			ply.UsingCamera:SetNWBool("locked", ply.UsingCamera.locked)
			ply:SetNWEntity("UsingCamera", ply.UsingCamera)
		end
		
		
		animInfo.animID = net.ReadInt(16)
		animInfo.animAccel = net.ReadInt(32)
		animInfo.rotation[1] = net.ReadInt(16)
		animInfo.rotation[2] = net.ReadInt(16)
		animInfo.rotation[3] = net.ReadInt(16)
		
		local health = net.ReadUInt(4)
		ply:SetHealth(health)

		if ply:InVehicle() then
			if health <= 0 then
				ply:ExitVehicle()
			end
		else
			ply:SetPos(networkedPos)
			mario:SetPos(networkedPos)
			mario.NetworkedPos = networkedPos
		end
		
		local flags = net.ReadUInt(32)
		if g64utils.MarioHasFlag(flags, 0x00000002) then
			ply:SetNotSolid(true)
		else
			ply:SetNotSolid(false)
		end
		
		local filter = RecipientFilter()
		filter:AddAllPlayers()
		filter:RemovePlayer(ply)
		local plys = filter:GetPlayers()
		for i = 1, #plys do
			if DegreesFromEyes(plys[i], networkedPos) > plys[i]:GetFOV() then
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
	if IsValid(ply.MarioEnt) then
		if g64sv.PlayerColors[ply] == nil then g64sv.PlayerColors[ply] = {} end

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
	if IsValid(owner.MarioEnt) then
		if g64sv.PlayerColors[owner] ~= nil then
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

hook.Add("InitPostEntity", "G64_SV_INIT_POST_ENTITY", function()
	local triggers = ents.FindByClass("trigger_teleport")
	for k,v in ipairs(triggers) do
		local amins, amaxs = v:GetRotatedAABB(v:OBBMins(), v:OBBMaxs())
		local keyValues = v:GetKeyValues()
		local tpTarget = ents.FindByName(keyValues.target)[1]

		local tg = ents.Create("g64_tptrigger")
		tg.PhysMesh = {}
		local surfaces = v:GetBrushSurfaces()
		for k,surfInfo in pairs(surfaces) do
			local vertices = surfInfo:GetVertices()
			for i = 1, #vertices - 2 do
				local len = #tg.PhysMesh
				tg.PhysMesh[len + 1] = { pos = vertices[1] }
				tg.PhysMesh[len + 2] = { pos = vertices[i + 1] }
				tg.PhysMesh[len + 3] = { pos = vertices[i + 2] }
			end
		end

		tg:Spawn()
		tg:SetPos(v:GetPos())
		tg:SetAngles(v:GetAngles())
		
		v.G64TPTrigger = tg
		tg.OrigTrigger = v
		tg.Enabled = true
		if keyValues.StartDisabled == 1 then tg.Enabled = false end
		if IsValid(tpTarget) then
			tg.TargetPos = tpTarget:GetPos()
			tg.TargetAng = tpTarget:GetAngles()
		else
			tg.TargetPos = nil
			tg.TargetAng = nil
		end
	end
end)

hook.Add("EntityTakeDamage", "G64_PLAYER_DAMAGED", function(target, dmg)
	if target:IsPlayer() and target.IsMario == true and target:HasGodMode() == false then
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

hook.Add("EntityRemoved", "G64_ENTITY_REMOVED", function(ent)
	local ply = ent.Owner
	if ply ~= nil and ply:IsValid() and ply:IsPlayer() and ply.IsMario == true then
		g64sv.PlayerColors[ply] = nil
		g64sv.PlayerTick[ply] = nil
	end
end)

local useBlacklist = {
	g64_physbox = true
}
hook.Add("PlayerUse", "G64_PLAYER_USE", function(ply, ent)
	if IsValid(ply.MarioEnt) and ply.IsMario == true and useBlacklist[ent:GetClass()] and ply:Health() > 0 then return false end
end)

hook.Add("PlayerDisconnected", "G64_PLY_DISCONNECT", function(ply)
	if IsValid(ply.MarioEnt) and ply.IsMario == true then ply.MarioEnt:Remove() end
end)

hook.Add("PlayerDeath", "G64_PLAYER_DEATH", function(victim, inflictor, attacker)
	if IsValid(victim.MarioEnt) then
		victim.MarioEnt:Remove()
	end
end)

hook.Add("PlayerEnteredVehicle", "G64_PLAYER_ENTERED_VEHICLE", function(ply, veh, role)
	if IsValid(ply.MarioEnt) and ply.IsMario == true then
		local vPos, vAng = GetSeatPoint(veh, role)
		local mario = ply.MarioEnt

		local driveable = veh:GetClass() ~= "prop_vehicle_prisoner_pod"
		-- Check for simfphys cars
		for k,v in ipairs(ents.FindInSphere(veh:GetPos(), 10)) do
			if v:GetClass() == "gmod_sent_vehicle_fphysics_base" then
				driveable = true
			end
		end

		if driveable then
			mario:SetParent(ply)
			mario:SetLocalAngles(Angle(0,-90,0))
			local offset = ply:GetPos()
			offset:Add(ply:GetForward()*10)
			offset:Add(ply:GetUp()*6)
			mario:SetPos(offset)
		else
			mario:SetParent(veh)
			mario:SetPos(vPos)
			mario:SetAngles(veh:GetAngles())
		end

		veh:SetThirdPersonMode(true)
		ply:SetActiveWeapon(NULL)
		ply:CrosshairDisable()
		drive.PlayerStopDriving(ply)
	end
end)

hook.Add("PlayerLeaveVehicle", "G64_PLAYER_LEFT_VEHICLE", function(ply, veh)
	if IsValid(ply.MarioEnt) and ply.IsMario == true then
		local mario = ply.MarioEnt
		mario:SetParent(nil)
		mario:SetAngles(Angle())

		local mins, maxs = veh:WorldSpaceAABB()
		local exitPt = veh:CheckExitPoint(120, maxs.z-mins.z+75)
		if exitPt ~= nil then
			ply:SetPos(exitPt)
			mario:SetPos(exitPt)
		end

		ply:CrosshairDisable()
		ply.MarioEnt:SetPos(ply:GetPos())
		drive.PlayerStartDriving(ply, ply.MarioEnt, "G64_DRIVE")
		ply.MarioEnt:SetAngles(Angle())
		ply:SetObserverMode(OBS_MODE_CHASE)
	end
end)

hook.Add("SetupMove", "G64_SETUP_MOVE", function(ply, mv, cmd)
	if not (IsValid(ply.MarioEnt) and ply.IsMario == true) then return end

	if mv:KeyPressed(IN_USE) and ply:InVehicle() then
		ply:ExitVehicle()
	end
end)

hook.Add("AcceptInput", "G64_ACCEPT_INPUT", function(ent, inp, activator, caller, value)
	if ent:GetClass() == "trigger_teleport" and IsValid(ent.G64TPTrigger) then
		if inp == "Enable" then
			ent.G64TPTrigger.Enabled = true
		elseif inp == "Disable" then
			ent.G64TPTrigger.Enabled = false
		end
		--print(ent, inp, activator, caller, value)
	end
end)

local allEnts = ents.GetAll()
hook.Add("OnEntityCreated", "G64_SV_ON_ENT_CREATED", function(ent)
	if IsValid(ent) == false then return end
	table.insert(allEnts, ent)
end)

local markedForDeletion = {}
timer.Remove("G64_SOLIDITY_CHECK")
timer.Create("G64_SOLIDITY_CHECK", 1, 0, function()
	table.Empty(markedForDeletion)
	for k,v in ipairs(allEnts) do
		if IsValid(v) == false then
			table.insert(markedForDeletion, k)
			continue
		end
		local kv = v:GetKeyValues()
		if kv.Solidity ~= nil then
			v:SetNWInt("Solidity", kv.Solidity)
		else
			v:SetNWInt("Solidity", -1)
		end
	end

	for k,v in ipairs(markedForDeletion) do
		table.remove(allEnts, v)
	end
end)

local physgunBlacklist = {
	g64_physbox = true,
	g64_mario = true
}
hook.Add("PhysgunPickup", "G64_PHYSGUN_PICKUP", function(ply, ent)
	if physgunBlacklist[ent:GetClass()] then
		return false
	end
end)

local function SpawnMarioAtPlayer(ply)
	ply.MarioEnt = nil
	local mario = ents.Create("g64_mario")
	mario.Owner = ply
	mario:SetPos(ply:GetPos())
	mario:SetOwner(ply)
	mario:Spawn()
	mario:Activate()
	undo.Create("Mario")
		undo.AddEntity(mario)
		undo.SetPlayer(ply)
	undo.Finish()
end

net.Receive("G64_UPLOADCOLORS", function(len, ply)
	if g64sv.PlayerColors[ply] == nil then g64sv.PlayerColors[ply] = {} end
	for i=1, 6 do
		g64sv.PlayerColors[ply][i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
	end
end)

local function damageEntity(mario, victim, forceVec, hitPos, minDmg, ply)
	--print(mario, victim, forceVec, hitpos, minDmg, ply)
	if not IsValid(victim) or not IsValid(mario) then return end
	local victimHealth = victim:Health()
	if victim:IsNPC() or victim:IsPlayer() or victimHealth > 0 then
		local d = DamageInfo()
		local damage = math.random(minDmg, minDmg+10)
		d:SetDamage(damage)
		d:SetAttacker(mario)
		d:SetInflictor(mario)
		d:SetDamageType(DMG_GENERIC)
		d:SetDamageForce(forceVec * 15000)
		d:SetDamagePosition(hitPos)

		local damageDiff = victimHealth - damage
		if victim.IsMario then damageDiff = victimHealth - math.ceil(damage / 10) end

		if (victim:IsNPC() or victim:IsPlayer()) and damageDiff <= 0 and victimHealth > 0 then
			local coin = nil
			if victim:IsPlayer() then coin = ents.Create("g64_bluecoin")
			else coin = ents.Create("g64_yellowcoin") end
			local entPos = victim:GetPos()
			entPos:Add(Vector(0, 0, 30))
			coin:SetPos(entPos)
			coin:Spawn()
			coin:SetNWEntity("IgnoreEnt", victim)
			local coinPhys = coin:GetPhysicsObject()
			if IsValid(coinPhys) then
				coinPhys:SetVelocity(Vector(math.random(-100, 100), math.random(-100, 100), math.random(200, 400)))
			end
		end

		victim:TakeDamageInfo(d)
	elseif victim:GetPhysicsObject():IsValid() then
		local phys = victim:GetPhysicsObject()
		
		phys:ApplyForceOffset(forceVec * 7800, hitPos)
		
		-- Allow damage taking for things like damage detectors
		if victim.TakeDamageInfo ~= nil then
			local d = DamageInfo()
			local damage = math.random(minDmg, minDmg+10)
			d:SetDamage(damage)
			d:SetAttacker(mario)
			d:SetInflictor(mario)
			d:SetDamageType(DMG_GENERIC)
			d:SetDamageForce(forceVec * 15000)
			d:SetDamagePosition(hitPos)
			
			victim:TakeDamageInfo(d)
		end
	end
	
	if ply:GetUseEntity() ~= NULL then
		ply:GetUseEntity():Use(ply, mario, USE_ON)
	end
end

net.Receive("G64_DAMAGEENTITY", function(len, ply)
	local mario = net.ReadEntity()
	local victim = net.ReadEntity()
	local forceVec = net.ReadVector()
	local hitPos = net.ReadVector()
	local minDmg = net.ReadUInt(8)
	damageEntity(mario, victim, forceVec, hitPos, minDmg, ply)
end)

net.Receive("G64_REMOVEINVALIDMARIO", function(len, ply)
	local ent = net.ReadEntity()
	ply:ExitVehicle()
	if IsValid(ent) then ent:Remove() end
end)

net.Receive("G64_RESETINVALIDPLAYER", function(len, ply)
	local mario = net.ReadEntity()
	if mario ~= nil then mario:Remove() end
	ply.SM64LoadedMap = false
end)

net.Receive("G64_REMOVEFROMCLIENT", function(len, ply)
	local ent = net.ReadEntity()
	if IsValid(ent) then ent:Remove() end
end)

net.Receive("G64_SPAWNMARIOATPLAYER", function(len, ply)
	SpawnMarioAtPlayer(ply)
end)

net.Receive("G64_RESPAWNMARIO", function(len, ply)
	local ent = net.ReadEntity()
	if IsValid(ent) then ent:Remove() end
	if GetConVar("g64_respawn_mario_on_death"):GetBool() == false then return end
	timer.Create("G64_DELAY_PLAYER_RESPAWN", 0.1, 1, function()
		local spawns = ents.FindByClass("info_player_start")
		local random_entry = math.random(#spawns)
		local spawnpoint = spawns[random_entry]
		ply:SetPos(spawnpoint:GetPos())
		timer.Create("G64_DELAY_MARIO_RESPAWN", 0.1, 1, function()
			SpawnMarioAtPlayer(ply)
		end)
	end)
end)

net.Receive("G64_COLLECTED1UP", function(len, ply)
	if ply.IsMario == nil or ply.IsMario == false then
		ply:SetArmor(ply:Armor() + 25)
	end
end)

net.Receive("G64_COLLECTEDCOIN", function(len, ply)
	if ply.IsMario == nil or ply.IsMario == false then
		ply:SetHealth(ply:Health() + 25)
	end
end)

net.Receive("G64_UPDATEHELDOBJECT", function(len, ply)
	local ent = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()
	local arg = net.ReadUInt(8)
	if IsValid(ent) then
		if arg < 2 then
			ent:SetNotSolid(false)
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(true)
				phys:Wake()
				if arg == 1 then
					phys:SetVelocity(ang:Forward()*200 + Vector(0,0,200))
				end
			end
		else
			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:SetNotSolid(true)
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end
		end
	end
end)

local function GrabRequestReply(_, ply)
	local mario = ply.MarioEnt
	local entity = net.ReadEntity()
	local forceVec = net.ReadVector()
	local hitPos = net.ReadVector()
	local volume = 1000000
	local phys = entity:GetPhysicsObject()
	
	if phys:IsValid() and phys:IsMotionEnabled() and phys:IsMoveable() then -- if not frozen
		volume = phys:GetVolume()
	end

	if volume < 65000 then
		net.Start("G64_GRABREQUEST")
			net.WriteBool(true)
			net.WriteEntity(entity)
		net.Send(ply)
	else
		damageEntity(mario, entity, forceVec, hitPos, 15, ply)
		net.Start("G64_GRABREQUEST", true)
			net.WriteBool(false)
			net.WriteEntity(entity)
		net.Send(ply)
	end
end
net.Receive("G64_GRABREQUEST", GrabRequestReply)

local meta = FindMetaTable("Player")

meta.DefaultGodEnable = meta.DefaultGodEnable or meta.GodEnable
meta.DefaultGodDisable = meta.DefaultGodDisable or meta.GodDisable

function meta:GodEnable()
	self:SetNWBool("HasGodMode", true)
	self:DefaultGodEnable()
end

function meta:GodDisable()
	self:SetNWBool("HasGodMode", false)
	self:DefaultGodDisable()
end