AddCSLuaFile()

include("includes/g64_config.lua")

-- Make level transitions work
local spawnMarioOnceInited = false
hook.Add("InitPostEntity", "G64_INIT_POST_ENTITY", function()
	local marios = ents.FindByClass("g64_mario")
	for k,v in ipairs(marios) do
		if(v.Owner:SteamID() == LocalPlayer():SteamID()) then
			net.Start("G64_RESETINVALIDPLAYER")
			net.WriteEntity(v)
			net.SendToServer()
			v.Owner.IsMario = false
			v.Owner.SM64LoadedMap = false
			spawnMarioOnceInited = true
			InitializeWorld(0)
		end
	end
end)

hook.Add("G64Initialized", "G64_SPAWN_CHANGELEVEL_MARIO", function()
	if(spawnMarioOnceInited == false) then return end
	net.Start("G64_SPAWNMARIOATPLAYER")
	net.SendToServer()
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
	if(libsm64 != nil && libsm64.ModuleLoaded == true && libsm64.IsGlobalInit()) then
		StopAllTracks()
		libsm64.PlayMusic(0, SeqArgs(4, seqId), 0)
	end
end

function GetSoundArg(soundTable)
	if(type(soundTable) == "table") then
		return libsm64.GetSoundArg(soundTable[1], soundTable[2], soundTable[3], soundTable[4], soundTable[5])
	elseif(type(soundTable) == "number") then
		return soundTable
	end
	return nil
end

local meta = FindMetaTable("Player")

function meta:HasGodMode()
	return self:GetNWBool("HasGodMode")
end

local function AddPropMesh(prop)
	if(!prop || !prop:IsValid()) then return end
	
	local surf = prop.G64SurfaceType
	local terr = prop.G64TerrainType
	
	if(surf == nil) then surf = 0 end
	if(terr == nil) then terr = 0 end
	
	if(prop:IsScripted() && prop:GetPhysicsObject():IsValid() && prop:GetPhysicsObject():IsCollisionEnabled()) then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(prop:GetPhysicsObject():GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles(), surf, terr))
			finalMesh = nil
		end
		table.insert(libsm64.EntMeshes, prop)
		return
	end
	
	if(libsm64.AllowedBrushEnts[prop:GetClass()]) then
		local finalMesh = {}
		local surfaces = prop:GetBrushSurfaces()
		if(surfaces == nil || #surfaces == 0) then return end
		for k,surfInfo in pairs(surfaces) do
			local vertices = surfInfo:GetVertices()
			for i = 1, #vertices - 2 do
				local len = #finalMesh
				finalMesh[len + 1] = vertices[1]
				finalMesh[len + 2] = vertices[i + 1]
				finalMesh[len + 3] = vertices[i + 2]
			end
		end
		
		if(#finalMesh == 0) then return end
		surfaceIds[#libsm64.EntMeshes+1] = {}
		table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles(), surf, terr))
		table.insert(libsm64.EntMeshes, prop)
		finalMesh = nil
		return
	end
	
	local model = prop:GetModel()
	if(!model && !util.GetModelMeshes(model)) then return end
	
	prop:PhysicsInit(6)
	if(!prop:GetPhysicsObject():IsValid()) then
		prop:PhysicsDestroy()
		return
	end
	
	if(prop:GetPhysicsObject():IsValid() && prop:GetPhysicsObject():IsCollisionEnabled()) then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(prop:GetPhysicsObject():GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles(), surf, terr))
			finalMesh = nil
		end
		table.insert(libsm64.EntMeshes, prop)
	else
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

hook.Add("G64Initialized", "G64_ENTITY_GEO", function()
	
	function libsm64.AddColliderToQueue(ent)
		if(ent:IsValid() && !ent.SM64_UPLOADED && (libsm64.AllowedEnts[ent:GetClass()] || libsm64.AllowedBrushEnts[ent:GetClass()])) then
			propQueue[#propQueue+1] = ent
			ent.SM64_UPLOADED = true
		end
	end

	function libsm64.RemoveCollider(ent)
		ent.SM64_UPLOADED = false
		local entIndex = table.KeyFromValue(libsm64.EntMeshes, ent)
		if(surfaceIds[entIndex] != nil) then
			for j,surfaceId in pairs(surfaceIds[entIndex]) do
				libsm64.SurfaceObjectDelete(surfaceId)
			end
			table.remove(surfaceIds, entIndex)
			table.remove(libsm64.EntMeshes, entIndex)
		end
	end

	local function ProcessNewEntity(ent)
		libsm64.AddColliderToQueue(ent)
		allEnts[#allEnts + 1] = ent
		if((ent:IsNPC() || ent:IsPlayer()) && ent != LocalPlayer() && ent:GetClass() != "g64_mario") then
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
	
	local prevTimeScale = -1.0
	local prevScaleFactor = -1.0
	hook.Add("Think", "G64_UPDATE_COLLISION", function()
		for k,v in ipairs(libsm64.EntMeshes) do
			local trashCan = {}
			if(!IsValid(v) || !(libsm64.AllowedEnts[v:GetClass()] || libsm64.AllowedBrushEnts[v:GetClass()])) then
				table.insert(trashCan, k)
				for j,surfaceId in pairs(surfaceIds[k]) do
					libsm64.SurfaceObjectDelete(surfaceId)
				end
			else
				local vPhys = v:GetPhysicsObject()
				if(vPhys:IsValid()) then
					if(v.CollisionState != nil) then
						local vColState = v:GetPhysicsObject():IsCollisionEnabled()
						if(v.CollisionState != vColState) then
							v.CollisionState = vColState
							libsm64.RemoveCollider(v)
						end
					else
						v.CollisionState = v:GetPhysicsObject():IsCollisionEnabled()
					end
				end
				
				for j,surfaceId in pairs(surfaceIds[k]) do
					libsm64.SurfaceObjectMove(surfaceId, v:GetPos(), v:GetAngles())
				end
			end
			for i=1,#trashCan do
				table.remove(surfaceIds, trashCan[i])
				table.remove(libsm64.EntMeshes, trashCan[i])
			end
		end

		for i = 1, 8 do
			if(!propQueue[1]) then break end
			AddPropMesh(propQueue[1])
			table.remove(propQueue, 1)
		end

		-- Update NPC/Player collision
		for i=#objects,1,-1 do
			v = objects[i]
			if(!IsValid(v)) then
				if(objectIds[i] != nil && objectIds[i] > 0) then
					libsm64.ObjectDelete(objectIds[i])
					table.remove(objectIds, i)
					table.remove(objects, i)
				end
			else
				libsm64.ObjectMove(v.G64ObjectId, v:GetPos())
			end
		end

		-- Update entity attack timers
		local frameTime = FrameTime()
		for i=#allEnts,1,-1 do
			v = allEnts[i]
			if(IsValid(v)) then
				if(v.HitStunTimer == nil) then
					v.HitStunTimer = 0
				end
				v.HitStunTimer = v.HitStunTimer - frameTime
			else
				table.remove(allEnts, i)
			end
		end

		if prevTimeScale != GetConVar("host_timescale"):GetFloat() then
			libsm64.TimeScale = GetConVar("host_timescale"):GetFloat()
			prevTimeScale = libsm64.TimeScale
			hook.Call("G64AdjustedTimeScale", nil, libsm64.TimeScale)
		end

		if prevScaleFactor != GetConVar("g64_scale_factor"):GetFloat() then
			libsm64.ScaleFactor = GetConVar("g64_scale_factor"):GetFloat()
			prevScaleFactor = libsm64.ScaleFactor
			libsm64.SetScaleFactor(libsm64.ScaleFactor)
		end

		libsm64.SetAutoUpdateState(GetConVar("g64_auto_update"):GetBool())
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
			if(result == 0) then
				if(GetConVar("g64_auto_update"):GetBool() == true) then
					MsgC(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please reconnect to auto-download the newest version.\n")
				else
					MsgC(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please download the latest version from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest", Color(255, 100, 100), " or turn auto-updates on in the G64 settings menu.\n")
				end
				libsm64.PackageOutdated = true
			elseif(result == 1) then
				print("[G64] You have a higher version of libsm64-g64 than what's on GitHub. How?\n")
			elseif(result == 2) then
				print("[G64] libsm64-g64 package is up to date.\n")
			end
		end,
		failed = function(reason)
			print("Failed to get update information: ", reason)
		end
	}
	if(libsm64.GetPackageVersion != nil) then HTTP(request) end
end)

hook.Add("ShutDown", "G64_SHUTTING_DOWN", function()
	if(libsm64.ModuleLoaded == true) then
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
concommand.Add("g64_config_set", function(ply, cmd, args)
	if(g64config.Config[args[1]] == nil) then MsgC(Color(255,100,100), "[G64] Config contains no key: ", args[1], "\n") return end
	
	local parsed = tonumber(args[2])
	if(parsed != nil) then
		g64config.Config[args[1]] = parsed
	else
		g64config.Config[args[1]] = args[2]
	end
	
	g64config.Save()
end)