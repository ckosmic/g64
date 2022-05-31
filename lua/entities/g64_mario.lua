AddCSLuaFile()

DEFINE_BASECLASS("base_anim")

include("includes/g64_types.lua")
include("includes/g64_config.lua")

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Mario"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"

ENT.MarioId = -10
ENT.Mins = Vector(-64, -64, -64)
ENT.Maxs = Vector( 64,  64,  64)
ENT.Invalid = false

-- Would be nice if I didn't have to do this
function ENT:RemoveFromClient()
	if(self.Owner == LocalPlayer()) then
		net.Start("G64_REMOVEINVALIDMARIO")
		net.WriteEntity(self)
		net.SendToServer()
	end
end

-- Ensure singleton mario
function ENT:RemoveInvalid()
	self.Invalid = true
	if(CLIENT) then
		self:RemoveFromClient()
		chat.AddText(Color(255,100,100), "[G64] There can only be one Mario spawned at a time.")
	else
		self:Remove()
	end
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if(!tr.Hit) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	
	local ent = ents.Create(ClassName)
	ent:SetOwner(ply)
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self:DrawShadow(true)
	self:SetRenderMode(RENDERMODE_NORMAL)
	self:AddEFlags(EFL_DIRTY_ABSTRANSFORM)
	
	self.Owner = self:GetOwner()
	self.OwnerHealth = self.Owner:Health()
	self.OwnerMaxHealth = self.Owner:GetMaxHealth()
	print(self.Owner:Alive())
	if(self.Owner.IsMario == true || self.Owner:Alive() == false) then self:RemoveInvalid() return end
	self.Owner.IsMario = true
	self.Owner:SetModelScale(0.8, 0)
	if (CLIENT) then
		self:SetNoDraw(true)
		hook.Add("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex(), function()
			if(libsm64 != nil && libsm64.ModuleExists == false) then
				chat.AddText(Color(255, 100, 100), "[G64] Couldn't locate the libsm64-gmod binary module!\nPlease place it in ", Color(100, 255, 100), "garrysmod/lua/bin", Color(255, 100, 100), " and reconnect.")
				hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
				self:RemoveFromClient()
			end
			if(libsm64 != nil && libsm64.ModuleLoaded == true && libsm64.MapLoaded == true) then
				hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
				
				g64config.Load()
				
				local romPath = GetConVar("g64_rompath"):GetString()
				if(romPath == nil || romPath == "") then
					chat.AddText(Color(255,100,100), "[G64] ROM path is empty. Please specify a valid ROM path in the G64 settings.")
					self:RemoveFromClient()
					return
				end
				
				if(libsm64.IsGlobalInit() == false) then
					local textureData = libsm64.GlobalInit(romPath)
					if(textureData == false) then
						chat.AddText(Color(255, 100, 100), "[G64] Error loading ROM at `", romPath, "`. Please check if the file exists.")
						self:RemoveFromClient()
						return
					else
						self:CreateMarioTexture(textureData)
					end
				end
				
				if(self.Owner == LocalPlayer()) then
				-- Only runs on the player who spawned Mario
					net.Start("G64_PLAYERREADY")
					net.SendToServer()
				
					self.Owner.MarioEnt = self
					self:StartLocalMario()
				else
				-- Runs on everyone else
					self:StartRemoteMario()
				end
				
				self.Owner:SetNoDraw(true)
				--collectgarbage("setstepmul", 200)
				--collectgarbage("setpause", 1000)
			end
		end)
	else
		self:SetModel("models/hunter/misc/sphere075x075.mdl") -- Easiest circle shadow ever
		self.Owner:SetMaxHealth(8)
		if(self.Owner:FlashlightIsOn()) then self.Owner:Flashlight(false) end
	end
	
	self:SetAngles(Angle())
	
	net.Receive("G64_PLAYERREADY", function(len, ply)
		ply.MarioEnt = self
		-- Only gets run on the player who spawned Mario
		if(ply == self.Owner) then
			drive.PlayerStartDriving(ply, self, "G64_DRIVE")
			ply:SetObserverMode(OBS_MODE_CHASE)
		end
	end)
end

function ENT:OnRemove()
	if(self.Invalid == false) then
		if (CLIENT) then
			if(libsm64 != nil && libsm64.ModuleLoaded) then
				libsm64.MarioDelete(self.MarioId)
				
				if(systimetimers.Exists("G64_MARIO_TICK" .. self.MarioId)) then
					systimetimers.Remove("G64_MARIO_TICK" .. self.MarioId)
				end
				hook.Remove("PostDrawOpaqueRenderables", "G64_RENDER_OPAQUES" .. self.MarioId)
				hook.Remove("CreateMove", "G64_CREATEMOVE" .. self.MarioId)
				hook.Remove("CalcView", "G64_CALCVIEW" .. self.MarioId)
				hook.Remove("HUDItemPickedUp", "SM64_ITEM_PICKED_UP" .. self.MarioId)
				
				self.MarioId = -10
				if(self.Owner != nil && IsValid(self.Owner)) then -- Is null if local player disconnects
					self.Owner:SetNoDraw(false)
					if(self.Owner == LocalPlayer()) then
						StopAllTracks()
					end
				end
			end
		else
			self.Owner:SetObserverMode(OBS_MODE_NONE)
			self.Owner:SetMaxHealth(self.OwnerMaxHealth)
			self.Owner:SetHealth(self.OwnerHealth)
			drive.PlayerStopDriving(self.Owner)
			
		end
		if(self.Owner) then
			self.Owner:SetModelScale(1, 0)
			self.Owner.IsMario = false
		end
	end
end

function ENT:OnReloaded()
	self:Remove()
end



local tickRate = 1/33
local upOffset = Vector(0,0,5)

if (CLIENT) then

	local marioRT = GetRenderTargetEx("Mario_Texture", 1024, 64, RT_SIZE_OFFSCREEN, MATERIAL_RT_DEPTH_NONE, 0, 0, IMAGE_FORMAT_RGBA8888)
	local marioMat = CreateMaterial("g64/libsm64_mario_lighting", "VertexLitGeneric", {
		["$model"] = "1",
		["$basetexture"] = "vgui/white"
	})
	local vertMat = CreateMaterial("g64/libsm64_mario_verts", "UnlitGeneric", {
		["$model"] = "1",
		["$basetexture"] = "vgui/white",
		["$vertexcolor"] = "1"
	})
	local texMat = CreateMaterial("g64/libsm64_mario_tex", "VertexLitGeneric", {
		["$model"] = "1",
		["$decal"] = "1",
		["$alphatest"] = "1",
		["$nocull"] = "1",
	})
	local debugMat = CreateMaterial("g64/libsm64_debug", "UnlitGeneric", {
		["$model"] = "1",
		["$basetexture"] = "vgui/white",
		["$decal"] = "1",
		["$vertexcolor"] = "1"
	})
	local metalMat = Material("debug/env_cubemap_model")

	function ENT:CreateMarioTexture(textureData)
		local TEX_WIDTH = 1024
		local TEX_HEIGHT = 64
		local CONTENT_WIDTH = 704
		local oldW = ScrW()
		local oldH = ScrH()
		texMat:SetTexture("$basetexture", marioRT)
		
		local oldRT = render.GetRenderTarget()
		
		render.SetRenderTarget(marioRT)
		render.SetViewPort(0, 0, TEX_WIDTH, TEX_HEIGHT)
		render.Clear(0, 0, 0, 0)
		cam.Start2D()
			for i = 1, #textureData do
				surface.SetDrawColor(textureData[i][1], textureData[i][2], textureData[i][3], textureData[i][4])
				surface.DrawRect(i%CONTENT_WIDTH, math.floor(i/CONTENT_WIDTH), 1, 1)
			end
		cam.End2D()
		render.SetRenderTarget(oldRT)
		render.SetViewPort(0, 0, oldW, oldH)
	end

	local xDelta = 0
	local yDelta = 0
	local worldMin = Vector()
	local worldMax = Vector()
	local xOffset = worldMin.x + 16384
	local yOffset = worldMin.y + 16384
	local xChunks = 0
	local yChunks = 0
	local xDispChunks = 0
	local yDispChunks = 0
	local marioChunk = Vector()
	local marioDispChunk = Vector()
	local prevMarioChunk = Vector()
	local prevMarioDispChunk = Vector()
	local scaleFactor = 1
	local prevWaterLevel = 0

	local attackTimer = 0

	local vertexBuffers = {}
	local stateBuffers = {}

	local inputs = {}
	inputs[1] = Vector()
	inputs[2] = false
	inputs[3] = false
	inputs[4] = false

	local fixedTime = 0

	local function PointInChunk(point)
		local chunk = Vector()
		chunk.x = math.min(math.floor((point.x - xOffset + 16384) / xDelta * xChunks) + 1, xChunks)
		chunk.y = math.min(math.floor((point.y - yOffset + 16384) / yDelta * yChunks) + 1, yChunks)
		return chunk
	end

	local function PointInDispChunk(point)
		local chunk = Vector()
		chunk.x = math.min(math.floor((point.x - xOffset + 16384) / xDelta * xDispChunks) + 1, xDispChunks)
		chunk.y = math.min(math.floor((point.y - yOffset + 16384) / yDelta * yDispChunks) + 1, yDispChunks)
		return chunk
	end

	local function MarioHasFlag(mask, flag)
		return (bit.band(mask, flag) != 0)
	end

	function ENT:MarioIsAttacking()
		if(MarioHasFlag(self.marioAction, g64types.SM64MarioActionFlags.ACT_FLAG_ATTACKING) &&
			  (self.marioAction == g64types.SM64MarioAction.ACT_PUNCHING ||
			   self.marioAction == g64types.SM64MarioAction.ACT_JUMP_KICK ||
			   self.marioAction == g64types.SM64MarioAction.ACT_GROUND_POUND_LAND ||
			   self.marioAction == g64types.SM64MarioAction.ACT_SLIDE_KICK ||
			   self.marioAction == g64types.SM64MarioAction.ACT_SLIDE_KICK_SLIDE ||
			   self.marioAction == g64types.SM64MarioAction.ACT_DIVE ||
			   self.marioAction == g64types.SM64MarioAction.ACT_DIVE_SLIDE ||
			   self.marioAction == g64types.SM64MarioAction.ACT_MOVE_PUNCHING)) then
			return self.marioAction
		else
			return nil
		end
	end

	local function MatTypeToTerrainType(matType)
		if(matType == MAT_CONCRETE || matType == MAT_TILE || matType == MAT_PLASTIC || matType == MAT_GLASS || matType == MAT_METAL) then
			return g64types.SM64TerrainType.TERRAIN_STONE
		elseif(matType == MAT_DIRT || matType == MAT_GRASS || matType == MAT_FOLIAGE) then
			return g64types.SM64TerrainType.TERRAIN_GRASS
		elseif(matType == MAT_SNOW) then
			return g64types.SM64TerrainType.TERRAIN_SNOW
		elseif(matType == MAT_SAND) then
			return g64types.SM64TerrainType.TERRAIN_SAND
		elseif(matType == MAT_SLOSH) then
			return g64types.SM64TerrainType.TERRAIN_WATER
		elseif(matType == MAT_WOOD) then
			return g64types.SM64TerrainType.TERRAIN_SPOOKY
		else
			return g64types.SM64TerrainType.TERRAIN_STONE
		end
	end

	local fLerpVector = LerpVector
	function ENT:GenerateMesh()
		local interpolation = (GetConVar("g64_interpolation"):GetBool())
		
		local vertex = vertexBuffers[self.MarioId][self.bufferIndex + 1]
		local lastVertex = vertexBuffers[self.MarioId][1 - self.bufferIndex + 1]
		
		if(vertex == nil || lastVertex == nil || vertex[1] == nil || lastVertex[1] == nil) then return end
		if(vertex[1][#vertex[1]] == nil || lastVertex[1][#lastVertex[1]] == nil) then return end
		
		local vertCount = #vertex[1]
		local triCount = vertCount/3
		if(vertCount == 0) then return end
		
		if(self.Mesh && self.Mesh:IsValid()) then
			self.Mesh:Destroy()
			self.Mesh = nil
		end
		self.Mesh = Mesh()
		if(self.WingsMesh && self.WingsMesh:IsValid()) then
			self.WingsMesh:Destroy()
			self.WingsMesh = nil
		end
		self.WingsMesh = Mesh()
		
		local t = (SysTime() - fixedTime) / tickRate
		local col
		local myColorTable = self.colorTable
		
		local posTab = vertex[1]
		local lastPosTab = lastVertex[1]
		local normTab = vertex[2]
		local uTab = vertex[3]
		local vTab = vertex[4]
		local colTab = vertex[5]
		local wingIndex = 1
		local uvOffset = 2/704
		local hasWingCap = self.hasWingCap
		
		mesh.Begin(self.Mesh, MATERIAL_TRIANGLES, triCount)
		for i = 1, vertCount do
			if(posTab[i] == nil || lastPosTab[i] == nil) then
				mesh.End()
				return
			end
			if(hasWingCap == true && i > vertCount-24) then
				self.wingsIndices[wingIndex] = i
				wingIndex = wingIndex + 1
			else
				col = myColorTable[colTab[i]]
				
				if(interpolation) then
					mesh.Position(fLerpVector(t, posTab[i], lastPosTab[i]))
				else
					mesh.Position(posTab[i])
				end
				mesh.Normal(normTab[i])
				mesh.TexCoord(0, uTab[i]+uvOffset, vTab[i]+uvOffset)
				mesh.Color(col[1], col[2], col[3], 255)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()
		
		if(hasWingCap == true) then
			local j = 1
			local wingsIndices = self.wingsIndices
			uvOffset = 1/704
			
			mesh.Begin(self.WingsMesh, MATERIAL_TRIANGLES, #wingsIndices/3)
			for i = 1, #wingsIndices do
				j = wingsIndices[i]
				if(posTab[j] == nil || lastPosTab[j] == nil) then
					mesh.End()
					return
				end
				col = myColorTable[colTab[j]]
				
				if(interpolation) then
					mesh.Position(fLerpVector(t, posTab[j], lastPosTab[j]))
				else
					mesh.Position(posTab[j])
				end
				mesh.Normal(normTab[j])
				mesh.TexCoord(0, uTab[j]+uvOffset, vTab[j]+uvOffset)
				mesh.Color(col[1], col[2], col[3], 255)
				mesh.AdvanceVertex()
			end
			mesh.End()
		end
	end
	
	function ENT:InitSomeVariables()
		xDelta = libsm64.XDelta
		yDelta = libsm64.YDelta
		worldMin = libsm64.WorldMin
		worldMax = libsm64.WorldMax
		xChunks = libsm64.XChunks
		yChunks = libsm64.YChunks
		xDispChunks = libsm64.XDispChunks
		yDispChunks = libsm64.YDispChunks
		scaleFactor = libsm64.ScaleFactor
		xOffset = worldMin.x + 16384
		yOffset = worldMin.y + 16384
		self.marioPos = Vector()
		self.marioCenter = Vector()
		self.marioForward = Vector()
		self.marioAction = 0
		self.marioFlags = 0
		self.marioParticleFlags = 0
		self.marioInvincTimer = 0
		self.marioHealth = 2176
		self.marioWaterLevel = -100000
		self.bufferIndex = 0
		self.lerpedPos = Vector()
		self.animInfo = {}
		self.tickTime = -1
		self.wingsIndices = {}
		self.hasWingCap = false
		self.hasMetalCap = false
		self.view = {
			origin = Vector(),
			angles = Angle(),
			fov = nil
		}
	end

	function ENT:Draw()
		if(self.marioInvincTimer != nil && self.marioInvincTimer >= 3 && self.bufferIndex == 1 && self.marioHealth != 255) then return end -- Hitstun blinking effect
		
		if(self.hasMetalCap) then
			render.MaterialOverride(metalMat)
			self:DrawModel()

			if(self.WingsMesh) then
				cam.PushModelMatrix( self:GetWorldTransformMatrix() )
				self.WingsMesh:Draw()
				cam.PopModelMatrix()
			end
			
			-- Lighting
			render.OverrideBlend(true, BLEND_ZERO, BLEND_SRC_COLOR, BLENDFUNC_REVERSE_SUBTRACT)
			render.MaterialOverride(marioMat)
			self:DrawModel()
			render.OverrideBlend(false)
		else
			-- Vertex colors
			self:DrawModel()
			
			-- Lighting
			render.OverrideBlend(true, BLEND_ZERO, BLEND_SRC_COLOR, BLENDFUNC_REVERSE_SUBTRACT)
			render.MaterialOverride(marioMat)
			self:DrawModel()
			render.OverrideBlend(false)
			
			-- Textures
			render.MaterialOverride(texMat)
			self:DrawModel()
			if(self.WingsMesh) then
				cam.PushModelMatrix( self:GetWorldTransformMatrix() )
				self.WingsMesh:Draw()
				cam.PopModelMatrix()
			end
		
		end
		
		render.MaterialOverride(nil)
	end
	
	function ENT:GetRenderMesh()
		return { Mesh = self.Mesh, Material = vertMat }
	end

	function ENT:StartRemoteMario()
		local lPlayer = LocalPlayer()
	
		if(self.MarioId < 0 || self.MarioId == nil) then
			self:InitSomeVariables()
			local entPos = self:GetPos()
			self.tickedPos = -entPos*scaleFactor
			self.MarioId = libsm64.MarioCreate(entPos, true)
			self.IsRemote = true
			self:SetRenderBounds(self.Mins, self.Maxs)
			self.colorTable = table.Copy(g64types.DefaultMarioColors)
			
			vertexBuffers[self.MarioId] = { {}, {} }
			
			vertexBuffers[self.MarioId][1] = libsm64.GetMarioTableReference(self.MarioId, 5)
			vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5)
			
			self:SetNoDraw(false)
			
			net.Start("G64_REQUESTCOLORS", false)
				net.WriteEntity(self.Owner)
			net.SendToServer()
		end
		
		local tickCount = 0
		local tickDeltaTime = 0
		local function MarioTick()
			fixedTime = SysTime()
			
			if(tickCount > 0) then
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5+8)
			end
			
			libsm64.MarioAnimTick(self.animInfo, self.MarioId, self.bufferIndex, self.marioFlags, self.tickedPos)
			
			self.hasWingCap = MarioHasFlag(self.marioFlags, 0x00000008)
			self.hasMetalCap = MarioHasFlag(self.marioFlags, 0x00000004)
			
			tickCount = tickCount + 1
			
			if(GetConVar("g64_interpolation"):GetBool() && (1 / RealFrameTime()) > 33) then
				self.bufferIndex = 1 - self.bufferIndex
			else
				-- Player ping is too high or FPS is too low, don't even bother interpolating
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5)
			end

			self.Owner:SetNoDraw(true)
		end
		
		function self:Think()
			tickDeltaTime = SysTime() - self.tickTime
			
			if((!gui.IsGameUIVisible() || !game.SinglePlayer()) && tickDeltaTime < 1.5) then
				self:GenerateMesh()
			end
			
			-- If hasn't received any update in > 1.5s, don't tick and don't draw
			if(tickDeltaTime > 1.5) then
				self:SetNoDraw(true)
				systimetimers.Pause("G64_MARIO_TICK" .. self.MarioId)
			else
				self:SetNoDraw(false)
				systimetimers.Resume("G64_MARIO_TICK" .. self.MarioId)
			end
			
			self:NextThink(CurTime())
			return true
		end
		
		systimetimers.Create("G64_MARIO_TICK" .. self.MarioId, tickRate, 0, function()
			if(self.tickTime < 0) then return end
			tickDeltaTime = SysTime() - self.tickTime
			MarioTick()
		end)
	end
	
	net.Receive("G64_UPDATEREMOTECOLORS", function(len, ply)
		local sent = net.ReadEntity()
		if(sent.MarioId == nil || sent.MarioId < 0 || sent.IsRemote == false) then return end
		if(sent.colorTable == nil) then sent.colorTable = {} end
		for i=1, 6 do
			sent.colorTable[i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
		end
	end)
	
	net.Receive("G64_TICKREMOTEMARIO", function(len, ply)
		local sent = net.ReadEntity()
		if(sent.MarioId == nil || sent.MarioId < 0 || sent.IsRemote == false) then return end
		if(sent.animInfo == nil) then sent.animInfo = {} end
		sent.animInfo.animID = net.ReadInt(16)
		sent.animInfo.animAccel = net.ReadInt(32)
		sent.animInfo.rotation = Angle(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
		sent.marioFlags = net.ReadUInt(32)
		
		libsm64.SetMarioPosition(sent.MarioId, sent:GetPos())
		sent.tickedPos = -sent:GetPos()*scaleFactor
		
		sent.tickTime = SysTime()
	end)

	function ENT:StartLocalMario()
		local lPlayer = LocalPlayer()
		
		local function TransmitColors()
			net.Start("G64_TRANSMITCOLORS")
				for i=1, 6 do
					net.WriteUInt(g64config.Config.MarioColors[i][1], 8)
					net.WriteUInt(g64config.Config.MarioColors[i][2], 8)
					net.WriteUInt(g64config.Config.MarioColors[i][3], 8)
				end
			net.SendToServer()
		end
		
		if(self.MarioId == nil || self.MarioId < 0) then
			self:InitSomeVariables()
			local entPos = lPlayer:GetPos()
			marioChunk = PointInChunk(entPos)
			marioDispChunk = PointInDispChunk(entPos)
			libsm64.StaticSurfacesLoad(libsm64.MapVertices[marioChunk.x][marioChunk.y], libsm64.DispVertices[marioDispChunk.x][marioDispChunk.y])
			self.MarioId = libsm64.MarioCreate(entPos, false)
			self.IsRemote = false
			self:SetRenderBounds(self.Mins, self.Maxs)
			
			vertexBuffers[self.MarioId] = { {}, {} }
			stateBuffers[self.MarioId] = { {}, {} }
			
			stateBuffers[self.MarioId][1] = libsm64.GetMarioTableReference(self.MarioId, 6)
			vertexBuffers[self.MarioId][1] = libsm64.GetMarioTableReference(self.MarioId, 5)
			stateBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 6)
			vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5)
			
			TransmitColors()
			
			self:SetNoDraw(false)
		end
		
		hook.Add("CreateMove", "G64_CREATEMOVE" .. self.MarioId, function(cmd)
			local buttons = cmd:GetButtons()
			inputs = libsm64.GetInputsFromButtonMask(buttons)
		end)
		
		local hitPos = Vector()
		local animInfo
		local tickCount = 0
		local downVec = Vector(0,0,-400)
		local function MarioTick()
			if(self.MarioId == nil) then return end
			fixedTime = SysTime()
		
			local facing = lPlayer:GetAimVector()
			if(tickCount > 0) then
				stateBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 6+8)
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5+8)
			end
			libsm64.MarioTick(self.MarioId, self.bufferIndex, facing, inputs[1], inputs[2], inputs[3], inputs[4])
			
			tickCount = tickCount + 1
			
			animInfo = libsm64.GetMarioAnimInfo(self.MarioId)
			
			local marioState = stateBuffers[self.MarioId][self.bufferIndex + 1]
			
			self.marioPos = marioState[1]
			self.marioForward = Vector(math.sin(marioState[3]), math.cos(math.pi*2 - marioState[3]), 0)
			self.marioFlags = marioState[6]
			self.marioParticleFlags = marioState[7]
			self.marioHealth = bit.rshift(marioState[4], 8)
			self.marioInvincTimer = marioState[8]
			self.colorTable = g64config.Config.MarioColors
			self.hasWingCap = MarioHasFlag(self.marioFlags, 0x00000008)
			self.hasMetalCap = MarioHasFlag(self.marioFlags, 0x00000004)

			--if(lPlayer:GetPos():DistToSqr(self.lerpedPos) > 100000) then
			--	-- Probably used a teleporter, so teleport Mario to the player
			--	libsm64.SetMarioPosition(self.MarioId, lPlayer:GetPos())
			--end
			
			marioChunk = PointInChunk(self.marioPos)
			marioDispChunk = PointInDispChunk(self.marioPos)
			if(marioChunk.x ~= prevMarioChunk.x || marioChunk.y ~= prevMarioChunk.y || marioDispChunk.x ~= prevMarioDispChunk.x || marioDispChunk.y ~= prevMarioDispChunk.y) then
				prevMarioChunk.x = marioChunk.x
				prevMarioChunk.y = marioChunk.y
				prevMarioDispChunk.x = marioDispChunk.x
				prevMarioDispChunk.y = marioDispChunk.y
				if(GetConVar("g64_debugcollision"):GetBool()) then
					print("[G64] Mario World Chunk: ", marioChunk.x .. ", " .. marioChunk.y)
					print("[G64] Mario Disp Chunk: ", marioDispChunk.x .. ", " .. marioDispChunk.y)
				end
				libsm64.StaticSurfacesLoad(libsm64.MapVertices[marioChunk.x][marioChunk.y], libsm64.DispVertices[marioDispChunk.x][marioDispChunk.y])
			end
			
			self.marioCenter = Vector(self.marioPos)
			self.marioCenter.z = self.marioCenter.z + 50 / scaleFactor
			
			self.marioTop = Vector(self.marioCenter)
			self.marioTop.z = self.marioTop.z + 50 / scaleFactor
			
			if(self.marioPos.z*scaleFactor-30 >= self.marioWaterLevel) then
				local entWaterLevel = self:WaterLevel()
				self.marioWaterLevel = -100000
				if(entWaterLevel > 0) then
					self.marioWaterLevel = self.marioPos.z*scaleFactor-30
				else
					local waterTrace = util.TraceLine({
						start = self.marioTop,
						endPos = self.marioTop + downVec,
						filter = { self, lPlayer },
					})
					if(bit.band(util.PointContents(waterTrace.HitPos), CONTENTS_WATER) == CONTENTS_WATER) then
						self.marioWaterLevel = waterTrace.HitPos.z*scaleFactor-30
					end
				end
			end
			
			libsm64.SetMarioWaterLevel(self.MarioId, self.marioWaterLevel)
			
			if(self.marioParticleFlags != 0) then
				if(MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_MIST_CIRCLE)) then
					ParticleEffect("ground_pound", self.marioPos, Angle())
					ParticleEffect("mario_fire", self.marioPos, Angle())
				end
				if(MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_DUST)) then
					ParticleEffect("mario_dust", self.marioPos, Angle())
				end
				if(MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_HORIZONTAL_STAR)) then
					ParticleEffect("mario_horiz_star", self.marioPos, Angle())
				end
				if(MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_VERTICAL_STAR) || MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_TRIANGLE)) then
					local tr = util.TraceLine({
						start = self.marioCenter,
						endpos = self.marioCenter + self.marioForward * (140 / scaleFactor),
						filter = { self, lPlayer },
					})
					local ang = tr.HitNormal:Angle()
					ParticleEffect("mario_vert_star", tr.HitPos, ang)
				end
				if(MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_FIRE)) then
					ParticleEffect("mario_fire", self.marioPos, Angle())
				end
			end
			
			self.marioAction = marioState[5]
			if(attackTimer < SysTime() && self:MarioIsAttacking() != nil) then
				attackTimer = SysTime() + 0.6
				if(self.marioAction == g64types.SM64MarioAction.ACT_GROUND_POUND_LAND) then
					local surroundingEnts = ents.FindInSphere(self.marioPos, 75)
					for k,v in ipairs(surroundingEnts) do
						if(v != self && v != lPlayer) then
							net.Start("G64_MARIOGROUNDPOUND")
								net.WriteEntity(self)
								net.WriteEntity(v)
							net.SendToServer()
						end
					end
				else
					net.Start("G64_MARIOTRACE")
						net.WriteEntity(self)
						net.WriteVector(self.marioCenter)
						net.WriteFloat(scaleFactor)
						net.WriteVector(self.marioForward)
					net.SendToServer()
					if(GetConVar("g64_debugrays"):GetBool()) then
						local tr = util.TraceHull({
							start = self.marioCenter,
							endpos = self.marioCenter + self.marioForward * (90 / scaleFactor),
							filter = { self, lPlayer },
							mins = Vector(-16, -16, -(40 / scaleFactor)),
							maxs = Vector(16, 16, 71),
							mask = MASK_SHOT_HULL
						})
						hitPos = tr.HitPos
					end
				end
			end
			
			local tr = util.TraceLine({
				start = self.marioCenter,
				endpos = self.marioCenter + Vector(0, 0, -400),
				filter = { self, lPlayer }
			})
			if(tr.Entity.G64SurfaceType == nil && tr.Entity.G64TerrainType == nil) then
				libsm64.SetMarioFloorOverrides(self.MarioId, MatTypeToTerrainType(tr.MatType), g64types.SM64SurfaceType.SURFACE_DEFAULT)
			else
				-- Turn off overrides
				libsm64.SetMarioFloorOverrides(self.MarioId, 0x7, 0x39)
			end
			
			if(self.EnableWingCap == true) then
				libsm64.MarioEnableCap(self.MarioId, 0x00000008, GetConVar("g64_wingcap_timer"):GetInt(), GetConVar("g64_cap_music"):GetBool())
				self.EnableWingCap = false
				self.hasWingCap = true
			end
			if(self.EnableMetalCap == true) then
				libsm64.MarioEnableCap(self.MarioId, 0x00000004, GetConVar("g64_metalcap_timer"):GetInt(), GetConVar("g64_cap_music"):GetBool())
				self.EnableMetalCap = false
				self.hasMetalCap = true
			end
			
			self.bufferIndex = 1 - self.bufferIndex
			
			if(animInfo == nil) then return end
			local myPos = self.marioPos
			local myAng = self.marioForward
			net.Start("G64_TRANSMITMOVE")
				net.WriteInt(myPos.x, 16)
				net.WriteInt(myPos.y, 16)
				net.WriteInt(myPos.z, 16)
				net.WriteInt(animInfo.animID, 16)
				net.WriteInt(animInfo.animAccel, 32)
				net.WriteInt(animInfo.rotation[1], 16)
				net.WriteInt(animInfo.rotation[2], 16)
				net.WriteInt(animInfo.rotation[3], 16)
				net.WriteUInt(self.marioHealth, 4)
				net.WriteUInt(self.marioFlags, 32)
			net.SendToServer()

			self.Owner:SetNoDraw(true)
		end
		
		-- Tick Mario at 30Hz
		systimetimers.Create("G64_MARIO_TICK" .. self.MarioId, tickRate, 0, function()
			MarioTick()
		end)

		function self:Think()
			if(!gui.IsGameUIVisible() || !game.SinglePlayer()) then
				self:GenerateMesh()
			end
			--print(collectgarbage("count"))
			self:NextThink(CurTime())
			return true
		end

		hook.Add("PostDrawOpaqueRenderables", "G64_RENDER_OPAQUES" .. self.MarioId, function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
			if (self.MarioId == nil || self.MarioId < 0 || libsm64 == nil || libsm64.ModuleLoaded == false || libsm64.IsGlobalInit() == false || isDraw3DSkybox || bDrawingDepth) then return end
			
			-- Debug map collision
			if(GetConVar("g64_debugcollision"):GetBool() && marioChunk.x != nil && marioChunk.y != nil) then
				local mapverts = libsm64.MapVertices[marioChunk.x][marioChunk.y]
				local mapvertcount = #mapverts
				if mapvertcount == 0 then return end
				math.randomseed(0)
				render.SetMaterial(debugMat) -- Apply the material
				render.ResetModelLighting(1,1,1)
				mesh.Begin(MATERIAL_TRIANGLES, math.Min(mapvertcount/3, 8192))
				for i = 1, math.Min(mapvertcount, 32768) do
					mesh.Position(mapverts[i])
					mesh.Color(math.random(0, 255),math.random(0, 255),math.random(0, 255),255)
					mesh.AdvanceVertex()
				end
				mesh.End()
				
				local dispverts = libsm64.DispVertices[marioDispChunk.x][marioDispChunk.y]
				local dispvertcount = #dispverts
				if dispvertcount == 0 then return end
				render.SetMaterial(debugMat) -- Apply the material
				render.ResetModelLighting(1,1,1)
				mesh.Begin(MATERIAL_TRIANGLES, math.Min(dispvertcount/3, 8192))
				for i = 1, math.Min(dispvertcount, 32768) do
					mesh.Position(dispverts[i])
					mesh.Color(math.random(0, 255),math.random(0, 255),math.random(0, 255),255)
					mesh.AdvanceVertex()
				end
				mesh.End()
			end
			
			if(self.marioCenter != nil && scaleFactor != nil && GetConVar("g64_debugrays"):GetBool()) then
				render.DrawLine(self.marioCenter + Vector(0,0,60 / scaleFactor), self.marioCenter + Vector(0,0,60 / scaleFactor) + self.marioForward * (90 / scaleFactor), Color(0, 0, 255))
				render.DrawWireframeBox(hitPos, Angle(0,0,0), Vector(-16, -16, -(40 / scaleFactor)), Vector(16, 16, 71), Color(255,255,255),true)
			end
		end)
		
		hook.Add("HUDItemPickedUp", "SM64_ITEM_PICKED_UP" .. self.MarioId, function(itemName)
			if(itemName == "item_healthkit") then
				libsm64.MarioHeal(self.MarioId, 16)
			elseif(itemName == "item_healthvial") then
				libsm64.MarioHeal(self.MarioId, 8)
			end
		end)
		
		-- From drive_base.lua
		CalcView_ThirdPerson = function( view, dist, hullsize, ply, entityfilter )
			local neworigin = view.origin - ply:EyeAngles():Forward() * dist
			
			if ( hullsize && hullsize > 0 ) then
				local tr = util.TraceHull( {
					start	= view.origin,
					endpos	= neworigin,
					mins	= Vector( hullsize, hullsize, hullsize ) * -1,
					maxs	= Vector( hullsize, hullsize, hullsize ),
					filter	= entityfilter
				} )

				if ( tr.Hit ) then
					neworigin = tr.HitPos
				end

			end

			view.origin		= neworigin
			view.angles		= ply:EyeAngles()
		end
		
		
		hook.Add("CalcView", "G64_CALCVIEW" .. self.MarioId, function(ply, origin, angles, fov, znear, zfar)
			if(gui.IsGameUIVisible() && game.SinglePlayer()) then return self.view end
			local t = (SysTime() - fixedTime) / tickRate
			if(stateBuffers[self.MarioId][self.bufferIndex + 1][1] != nil) then
				self.lerpedPos = LerpVector(t, stateBuffers[self.MarioId][self.bufferIndex + 1][1], stateBuffers[self.MarioId][1-self.bufferIndex + 1][1]) + upOffset
				self:SetNetworkOrigin(self.lerpedPos)
				self:SetPos(self.lerpedPos)
			end
			
			self.view.origin = self.lerpedPos
			self.view.origin.z = self.view.origin.z + 50 / scaleFactor
			self.view.angles = angles
			
			CalcView_ThirdPerson(self.view, 200, 2, ply, { self, ply })
			return self.view
		end)
		
		hook.Add("OnSpawnMenuClose", "G64_SMENU_CLOSED", function()
			if(GetConVar("g64_upd_col_flag"):GetBool() == true) then
				TransmitColors()
			end
		end)
		
		net.Receive("G64_DAMAGEMARIO", function(len,ply)
			local damage = net.ReadUInt(8)
			local src = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
			libsm64.MarioTakeDamage(self.MarioId, damage, 0, src)
		end)
	end

else

	

end