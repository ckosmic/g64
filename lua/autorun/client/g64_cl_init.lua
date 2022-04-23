AddCSLuaFile()

include("g64/g64_config.lua")

-- Entity collision system from GWater-V3
local propQueue = propQueue or {}
local surfaceIds = surfaceIds or {}

local function AddPropMesh(prop)
	if(!prop || !prop:IsValid()) then return end
	
	if(prop:IsScripted() && prop:GetPhysicsObject():IsValid()) then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(prop:GetPhysicsObject():GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles()))
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
		table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles()))
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
	
	if(prop:GetPhysicsObject():IsValid()) then
		surfaceIds[#libsm64.EntMeshes+1] = {}
		for k,convex in pairs(prop:GetPhysicsObject():GetMeshConvexes()) do
			local finalMesh = {}
			for k,vertex in pairs(convex) do
				finalMesh[#finalMesh + 1] = vertex.pos
			end
			table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles()))
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
		table.insert(surfaceIds[#libsm64.EntMeshes+1], libsm64.SurfaceObjectCreate(finalMesh, prop:GetPos(), prop:GetAngles()))
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
	
	local props = ents.GetAll()
	for k,v in ipairs(props) do
		libsm64.AddColliderToQueue(v)
	end
	
	hook.Add("OnEntityCreated", "G64_ENTITY_CREATED", function(ent)
		libsm64.AddColliderToQueue(ent)
	end)
	
	hook.Add("Think", "G64_UPDATE_COLLISION", function()
		for k,v in ipairs(libsm64.EntMeshes) do
			local trashCan = {}
			if(!IsValid(v) || !(libsm64.AllowedEnts[v:GetClass()] || libsm64.AllowedBrushEnts[v:GetClass()])) then
				table.insert(trashCan, k)
				for j,surfaceId in pairs(surfaceIds[k]) do
					libsm64.SurfaceObjectDelete(surfaceId)
				end
			else
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
	end)
	
	hook.Add("PreCleanupMap", "G64_CLEANUP_ENTITIES", function()
		for k,v in ipairs(libsm64.EntMeshes) do
			for j,surfaceId in pairs(surfaceIds[k]) do
				libsm64.SurfaceObjectDelete(surfaceId)
			end
		end
		table.Empty(libsm64.EntMeshes)
	end)
end)

hook.Add("ShutDown", "G64_SHUTTING_DOWN", function()
	libsm64.GlobalTerminate()
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
	if(sm64config.Config[args[1]] == nil) then MsgC(Color(255,100,100), "[G64] Config contains no key: ", args[1], "\n") return end
	
	local parsed = tonumber(args[2])
	if(parsed != nil) then
		sm64config.Config[args[1]] = parsed
	else
		sm64config.Config[args[1]] = args[2]
	end
	
	sm64config.Save()
end)