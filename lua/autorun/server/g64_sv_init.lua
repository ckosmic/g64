AddCSLuaFile()

util.AddNetworkString("G64_LOADMAPGEO")
util.AddNetworkString("G64_PLAYERREADY")
util.AddNetworkString("G64_HURTNPC")
util.AddNetworkString("G64_USEENTITY")
util.AddNetworkString("G64_MARIOTRACE")
util.AddNetworkString("G64_TRANSMITMOVE")
util.AddNetworkString("G64_DAMAGEMARIO")
util.AddNetworkString("G64_INITLOCALCLIENT")
util.AddNetworkString("G64_TICKREMOTEMARIO")
util.AddNetworkString("G64_MARIOGROUNDPOUND")
util.AddNetworkString("G64_TRANSMITCOLORS")
util.AddNetworkString("G64_UPDATEREMOTECOLORS")

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