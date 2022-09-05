AddCSLuaFile()

include("includes/g64_config.lua")

-- Make level transitions work
local spawnMarioOnceInited = false
local inited = false
hook.Add("InitPostEntity", "G64_CL_INIT_POST_ENTITY", function()
	
	hook.Add("Think", "G64_STEAMID_WAIT_NOTNIL", function()
		local marios = ents.FindByClass("g64_mario")
		for k,v in ipairs(marios) do
			if v.Owner.SteamID ~= nil and LocalPlayer().SteamID ~= nil then
				hook.Remove("Think", "G64_STEAMID_WAIT_NOTNIL")
				if v.Owner:SteamID() == LocalPlayer():SteamID() then
					net.Start("G64_RESETINVALIDPLAYER")
					net.WriteEntity(v)
					net.SendToServer()
					v.Owner.IsMario = false
					v.Owner.SM64LoadedMap = false
					if inited == false then
						spawnMarioOnceInited = true
					else
						inited = true
						net.Start("G64_SPAWNMARIOATPLAYER")
						net.SendToServer()
					end
				end
			end
		end
	end)

	LocalPlayer().CoinCount = 0
	LocalPlayer().RedCoinCount = 0
	LocalPlayer().LivesCount = 4
end)

hook.Add("G64Initialized", "G64_SPAWN_CHANGELEVEL_MARIO", function()
	inited = true
	if spawnMarioOnceInited == false then return end
	timer.Create("blah", 1, 1, function()
		net.Start("G64_SPAWNMARIOATPLAYER")
		net.SendToServer()
	end)
end)

-- Timer for the the libsm64 game loop
G64_TICKRATE = 1/33
systimetimers.Create("G64_GAME_TICK", G64_TICKRATE, 0, function()
	hook.Call("G64GameTick")
end)

hook.Add("G64AdjustedTimeScale", "G64_ADJUST_TIMESCALE", function(timeScale)
	if timeScale == nil then timeScale = 1 end
	G64_TICKRATE = 1/33 / timeScale
	systimetimers.Adjust("G64_GAME_TICK", G64_TICKRATE)
end)

-- Entity collision system from GWater-V3
local propQueue = propQueue or {}
local surfaceIds = surfaceIds or {}
local objects = objects or {}
local objectIds = objectIds or {}

local allEnts = allEnts or {}

function SeqArgs(priority, seqId)
	return bit.bor(bit.lshift(priority, 8), seqId)
end

function StopAllTracks()
	for i = 0, 0x22 do
		libsm64.StopMusic(i)
	end
end

function PlayTrack(seqId)
	if libsm64 ~= nil and libsm64.ModuleLoaded == true and libsm64.IsGlobalInit() then
		StopAllTracks()
		libsm64.PlayMusic(0, SeqArgs(4, seqId), 0)
	end
end

function GetSoundArg(soundTable)
	if type(soundTable) == "table" then
		return libsm64.GetSoundArg(soundTable[1], soundTable[2], soundTable[3], soundTable[4], soundTable[5])
	elseif type(soundTable) == "number" then
		return soundTable
	end
	return nil
end

local meta = FindMetaTable("Player")

function meta:HasGodMode()
	return self:GetNWBool("HasGodMode")
end

local function AddPropMesh(prop)
	if not prop or prop:IsValid() == false then return end
	
	local surf = prop.G64SurfaceType
	local terr = prop.G64TerrainType
	
	if surf == nil then surf = 0 end
	if terr == nil then terr = 0 end
	
	local phys = prop:GetPhysicsObject()

	if prop:IsScripted() and phys:IsValid() and phys:IsCollisionEnabled() then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(phys:GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, phys:GetPos(), phys:GetAngles(), surf, terr))
			finalMesh = nil
		end
		table.insert(libsm64.EntMeshes, prop)
		return
	end
	
	if libsm64.AllowedBrushEnts[prop:GetClass()] and prop:GetBrushSurfaces() ~= nil and #prop:GetBrushSurfaces() > 0 then
		local finalMesh = {}
		local surfaces = prop:GetBrushSurfaces()
		if surfaces == nil or #surfaces == 0 then return end
		for k,surfInfo in pairs(surfaces) do
			local vertices = surfInfo:GetVertices()
			for i = 1, #vertices - 2 do
				local len = #finalMesh
				finalMesh[len + 1] = vertices[1]
				finalMesh[len + 2] = vertices[i + 1]
				finalMesh[len + 3] = vertices[i + 2]
			end
		end
		
		if #finalMesh == 0 then return end
		surfaceIds[#libsm64.EntMeshes+1] = {}
		table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles(), surf, terr))
		table.insert(libsm64.EntMeshes, prop)
		finalMesh = nil
		return
	end
	
	prop:PhysicsInit(6)
	phys = prop:GetPhysicsObject()
	if phys:IsValid() == false then
		prop:PhysicsDestroy()
		return
	end
	
	if phys:IsValid() and phys:IsCollisionEnabled() then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(phys:GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, phys:GetPos(), phys:GetAngles(), surf, terr))
			finalMesh = nil
		end
		table.insert(libsm64.EntMeshes, prop)
	else
		local model = prop:GetModel()
		if not model or not util.GetModelMeshes(model) then return end
		local finalMesh = {}
		for k,mesh in pairs(util.GetModelMeshes(model)) do
			for k,vertex in pairs(mesh.triangles) do
				table.insert(finalMesh, vertex.pos)
			end
		end
		surfaceIds[#libsm64.EntMeshes+1] = {}
		table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles(), surf, terr))
		table.insert(libsm64.EntMeshes, prop)
		finalMesh = nil
	end
	
	prop:PhysicsDestroy()
end

local function RotMatToAng(mat)
	local sy = math.sqrt(mat:GetField(1, 1) * mat:GetField(1, 1) + mat:GetField(2, 1) * mat:GetField(2, 1))
	local x, y, z
	if not (sy < 0.000001) then
		x = math.atan2(mat:GetField(3, 2), mat:GetField(3, 3))
		y = math.atan2(-mat:GetField(3, 1), sy)
		z = math.atan2(mat:GetField(2, 1), mat:GetField(1, 1))
	else
		x = math.atan2(-mat:GetField(2, 3), mat:GetField(2, 2))
		y = math.atan2(-mat:GetField(3, 1), sy)
		z = 0
	end
	x = math.fmod(math.deg(x) + 180, 360)
	y = math.fmod(math.deg(y) + 180, 360)
	z = math.fmod(math.deg(z) + 180, 360)
	return Angle(x, z, y)
end

hook.Add("G64Initialized", "G64_ENTITY_GEO", function()
	
	function libsm64.AddColliderToQueue(ent)
		if ent:IsValid() and not ent.SM64_UPLOADED and (libsm64.AllowedEnts[ent:GetClass()] or libsm64.AllowedBrushEnts[ent:GetClass()]) then
			propQueue[#propQueue+1] = ent
			ent.SM64_UPLOADED = true
		end
	end

	function libsm64.RemoveCollider(ent)
		ent.SM64_UPLOADED = false
		local entIndex = table.KeyFromValue(libsm64.EntMeshes, ent)
		local allEntIndex = table.KeyFromValue(allEnts, ent)
		table.remove(allEnts, allEntIndex)
		if surfaceIds[entIndex] ~= nil then
			for j,surfaceId in pairs(surfaceIds[entIndex]) do
				libsm64.SurfaceObjectDelete(surfaceId)
			end
			table.remove(surfaceIds, entIndex)
			table.remove(libsm64.EntMeshes, entIndex)
		end
	end

	local function ProcessNewEntity(ent)
		if table.HasValue(allEnts, ent) then return end
		libsm64.AddColliderToQueue(ent)
		allEnts[#allEnts + 1] = ent
		if (ent:IsNPC() or ent:IsPlayer()) and ent ~= LocalPlayer() and ent:GetClass() ~= "g64_mario" then
			local min, max = ent:WorldSpaceAABB()
			local hbHeight = max.z - min.z
			local hbRad = max.x - min.x
			ent.G64ObjectId = libsm64.ObjectCreate(ent:GetPos(), hbHeight, hbRad)
			objectIds[#objectIds + 1] = ent.G64ObjectId
			objects[#objects + 1] = ent
		end
	end
	
	local props = ents.GetAll()
	for k,v in ipairs(props) do
		ProcessNewEntity(v)
	end
	
	hook.Add("OnEntityCreated", "G64_ENTITY_CREATED", function(ent)
		ProcessNewEntity(ent)
	end)

	--hook.Add("HUDPaint", "ugh", function(ent)
	--	local e = libsm64.EntMeshes[1]
	--	if IsValid(e) then
	--		surface.SetFont( "DermaLarge" )
	--		surface.SetTextPos( 400, 128 )
	--		surface.SetTextColor( 0, 0, 0 )
	--		local a = e:GetAngles()
	--		debugoverlay.Line(e:GetPos(), e:GetPos() + a:Up() * 400, 0.1, Color(0,0,255))
	--		debugoverlay.Line(e:GetPos(), e:GetPos() + a:Forward() * 400, 0.1, Color(0,255,0))
	--		debugoverlay.Line(e:GetPos(), e:GetPos() + a:Right() * 400, 0.1, Color(255,0,0))
	--		surface.DrawText( "" .. math.Round(a.z) .. ", " .. math.Round(-a.y) .. ", " .. math.Round(-a.x) )
	--	end
	--end)
	
	local prevTimeScale = -1.0
	local prevScaleFactor = -1.0
	local noCollidePos = Vector(0, 0, -32768)
	local function UpdatePropCollisions()
		for k,v in ipairs(libsm64.EntMeshes) do
			local trashCan = {}
			if IsValid(v) == false or not (libsm64.AllowedEnts[v:GetClass()] or libsm64.AllowedBrushEnts[v:GetClass()]) then
				table.insert(trashCan, k)
				for j,surfaceId in pairs(surfaceIds[k]) do
					libsm64.SurfaceObjectDelete(surfaceId)
				end
			else
				local vPhys = v:GetPhysicsObject()
				if vPhys:IsValid() then
					if v.CollisionState ~= nil then
						local vColState = v:GetPhysicsObject():IsCollisionEnabled()
						if v.CollisionState ~= vColState then
							v.CollisionState = vColState
							libsm64.RemoveCollider(v)
						end
					else
						v.CollisionState = v:GetPhysicsObject():IsCollisionEnabled()
					end
				end
				
				local mario = LocalPlayer().MarioEnt
				for j,surfaceId in pairs(surfaceIds[k]) do
					--if v:GetSolidFlags() ~= 256 then print(v, v:GetSolidFlags()) end
					if v:GetCollisionGroup() == COLLISION_GROUP_WORLD or 
					   v.DontCollideWithMario == true or 
					   v == LocalPlayer():GetVehicle() or 
					   (IsValid(mario) and mario.hasVanishCap == true) or
					   v:IsSolid() == false or
					   (IsValid(mario) and mario.heldObj == v) then

						libsm64.SurfaceObjectMove(surfaceId, noCollidePos, v:GetAngles())
					else
						libsm64.SurfaceObjectMove(surfaceId, v:GetPos(), v:GetAngles())
						--local mat = v:GetWorldTransformMatrix()
						--local w = math.sqrt(1.0 + mat:GetField(1,1) + mat:GetField(2,2) + mat:GetField(3,3)) / 2.0
						--local w4 = 4.0 * w
						--local x = (mat:GetField(3,2) - mat:GetField(2,3)) / w4
						--local y = (mat:GetField(1,3) - mat:GetField(3,1)) / w4
						--local z = (mat:GetField(2,1) - mat:GetField(1,2)) / w4
						--print(x,y,z,w)

						--local a = RotMatToAng(v:GetWorldTransformMatrix())
						
						--libsm64.SurfaceObjectMoveQ(surfaceId, v:GetPos(), x,y,z,w)
					end
				end
			end
			for i=1,#trashCan do
				table.remove(surfaceIds, trashCan[i])
				table.remove(libsm64.EntMeshes, trashCan[i])
			end
		end
	end

	hook.Add("G64GameTick", "G64_UPDATE_COLLISION", function()
		UpdatePropCollisions()

		for i = 1, 8 do
			if propQueue[1] == nil then break end
			AddPropMesh(propQueue[1])
			table.remove(propQueue, 1)
		end

		-- Update NPC/Player collision
		for i=#objects,1,-1 do
			v = objects[i]
			if not IsValid(v) or v == LocalPlayer() or (v:IsNPC() and v:GetNoDraw()) then
				if objectIds[i] ~= nil and objectIds[i] >= 0 then
					libsm64.ObjectDelete(objectIds[i])
					table.remove(objectIds, i)
					table.remove(objects, i)
				end
			elseif (v:IsPlayer() and v:Health() <= 0) then
				libsm64.ObjectMove(v.G64ObjectId, noCollidePos)
			else
				libsm64.ObjectMove(v.G64ObjectId, v:GetPos())
			end
		end

		if prevTimeScale ~= GetConVar("host_timescale"):GetFloat() then
			libsm64.TimeScale = GetConVar("host_timescale"):GetFloat()
			prevTimeScale = libsm64.TimeScale
			hook.Call("G64AdjustedTimeScale", nil, libsm64.TimeScale)
		end

		if prevScaleFactor ~= GetConVar("g64_scale_factor"):GetFloat() then
			libsm64.ScaleFactor = GetConVar("g64_scale_factor"):GetFloat()
			prevScaleFactor = libsm64.ScaleFactor
			libsm64.SetScaleFactor(libsm64.ScaleFactor)
			local newBounds = 160 / libsm64.ScaleFactor
			local marioEnt = LocalPlayer().MarioEnt
			if IsValid(marioEnt) then
				marioEnt.Maxs.x = newBounds
				marioEnt.Maxs.y = newBounds
				marioEnt.Maxs.z = newBounds
				marioEnt.Mins.x = -newBounds
				marioEnt.Mins.y = -newBounds
				marioEnt.Mins.z = -newBounds

				net.Start("G64_REMOVEINVALIDMARIO")
				net.WriteEntity(marioEnt)
				net.SendToServer()
			end

			-- Recreate prop collisions since their vertices depend on scale factor
			for i=#libsm64.EntMeshes,1,-1 do
				v = libsm64.EntMeshes[i]
				libsm64.RemoveCollider(v)
			end
			table.Empty(libsm64.EntMeshes)
			table.Empty(surfaceIds)

			local props = ents.GetAll()
			for k,v in ipairs(props) do
				ProcessNewEntity(v)
			end
		end

		libsm64.SetAutoUpdateState(GetConVar("g64_auto_update"):GetBool())
	end)

	hook.Add("Think", "G64_CL_THINK", function()
		libsm64.GeneralUpdate()

		-- Update entity attack timers
		local frameTime = FrameTime()
		for i=#allEnts,1,-1 do
			v = allEnts[i]
			if IsValid(v) then
				if v.HitStunTimer == nil then
					v.HitStunTimer = 0
				end
				v.HitStunTimer = v.HitStunTimer - frameTime
			else
				table.remove(allEnts, i)
			end
		end
	end)

	hook.Add("G64UpdatePropCollisions", "G64_INSTANT_PROP_UPDATE", function()
		UpdatePropCollisions()
	end)
	
	hook.Add("PreCleanupMap", "G64_CLEANUP_ENTITIES", function()
		for k,v in ipairs(libsm64.EntMeshes) do
			for j,surfaceId in pairs(surfaceIds[k]) do
				libsm64.SurfaceObjectDelete(surfaceId)
			end
		end
		table.Empty(libsm64.EntMeshes)
	end)

	local request = {
		url = "https://api.github.com/repos/ckosmic/g64/releases",
		method = "GET",
		success = function(code, body, headers)
			local response = util.JSONToTable(body)
			local tag = response[1].tag_name
			local version = string.sub(tag, 2, #tag)
			local lVersion = libsm64.GetPackageVersion()
			local result = libsm64.CompareVersions(lVersion, version)
			if result == 0 then
				if GetConVar("g64_auto_update"):GetBool() == true then
					chat.AddText(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please reconnect to auto-download the newest version.\n")
				else
					chat.AddText(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please download the latest version from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest", Color(255, 100, 100), " or turn auto-updates on in the G64 settings menu.\n")
				end
				libsm64.PackageOutdated = true
			elseif result == 1 then
				print("[G64] You have a higher version of libsm64-g64 than what's on GitHub. How?\n")
			elseif result == 2 then
				print("[G64] libsm64-g64 package is up to date.\n")
			end
		end,
		failed = function(reason)
			print("Failed to get update information: ", reason)
		end
	}
	if libsm64.GetPackageVersion ~= nil then HTTP(request) end
end)

hook.Add("ShutDown", "G64_SHUTTING_DOWN", function()
	if libsm64.ModuleLoaded == true then
		libsm64.GlobalTerminate()
	end
end)

net.Receive("G64_CHANGESURFACEINFO", function(len)
	local ent = net.ReadEntity()
	ent.G64SurfaceType = net.ReadInt(16)
	ent.G64TerrainType = net.ReadUInt(16)
	libsm64.RemoveCollider( ent )
	libsm64.AddColliderToQueue( ent )
end)

net.Receive("G64_TELEPORTMARIO", function(len)
	local mario = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()

	if IsValid(mario) then
		libsm64.SetMarioPosition(mario.MarioId, pos)
		libsm64.SetMarioAngle(mario.MarioId, math.rad(ang[2]-90)/(math.pi*math.pi))
	end
end)

concommand.Add("g64_load_module", function(ply, cmd, args)
	LoadSM64Module()
end)
concommand.Add("g64_init", function(ply, cmd, args)
	libsm64.GlobalInit()
end)
concommand.Add("g64_terminate", function(ply, cmd, args)
	print(libsm64.GlobalTerminate())
end)
concommand.Add("g64_isinit", function(ply, cmd, args)
	print(libsm64.IsGlobalInit())
end)
concommand.Add("g64_purge_map_cache", function(ply, cmd, args)
	file.Delete("g64/cache/" .. game.GetMap() .. "_cache.dat")
end)
concommand.Add("g64_config_set", function(ply, cmd, args)
	if g64config.Config[args[1]] == nil then MsgC(Color(255,100,100), "[G64] Config contains no key: ", args[1], "\n") return end
	
	local parsed = tonumber(args[2])
	if parsed ~= nil then
		g64config.Config[args[1]] = parsed
	else
		g64config.Config[args[1]] = args[2]
	end
	
	g64config.Save()
end)
concommand.Add("g64_set_lives", function(ply, cmd, args)
	local marioEnt = ply.MarioEnt
	if IsValid(marioEnt) then
		libsm64.MarioSetLives(marioEnt.MarioId, tonumber(args[1]))
	end
end)

hook.Remove("HUDPaint", "G64_CL_THINK_DEBUG")
hook.Add("OnContextMenuOpen", "G64_CTX_OPEN", function()
	hook.Add("HUDPaint", "G64_CL_THINK_DEBUG", function()
		local trTab = util.GetPlayerTrace(LocalPlayer())
		local tr = util.TraceLine(trTab)
		local tx, ty = input.GetCursorPos()
		surface.SetFont( "Default" )
		surface.SetTextColor( 255, 255, 255 )
		surface.SetTextPos( tx + 30, ty + 30 ) 
		surface.DrawText( tr.Entity:GetClass() )
		surface.SetTextPos( tx + 30, ty + 40 ) 
		surface.DrawText( tr.Entity:GetCollisionGroup() )
		surface.SetTextPos( tx + 30, ty + 50 ) 
		surface.DrawText( tostring(bit.band(FSOLID_NOT_SOLID, v:GetSolidFlags()) == FSOLID_NOT_SOLID) )
	end)
end)

hook.Add("OnContextMenuClose", "G64_CTX_CLOSE", function()
	hook.Remove("HUDPaint", "G64_CL_THINK_DEBUG")
end)

--local prevThing = 0
--hook.Remove("Think", "G64_CL_THINK_DEBUG")
--hook.Add("Think", "G64_CL_THINK_DEBUG", function()
--	local automatic = GetConVar("dsp_automatic"):GetInt()
--	if automatic != prevThing then
--		print("dsp_automatic", GetConVar("dsp_automatic"):GetInt())
--		print("dsp_db_mixdrop", GetConVar("dsp_db_mixdrop"):GetFloat())
--		print("dsp_mix_max", GetConVar("dsp_mix_max"):GetFloat())
--		print("dsp_mix_min", GetConVar("dsp_mix_min"):GetFloat())
--		print("-------------------")
--		prevThing = automatic
--	end
--end)