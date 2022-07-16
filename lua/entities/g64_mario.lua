AddCSLuaFile()

DEFINE_BASECLASS("base_anim")

include("includes/g64_types.lua")
include("includes/g64_config.lua")
include("includes/g64_utils.lua")

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Mario"
ENT.Author = "ckosmic"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "G64"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.MarioId = -10
ENT.Mins = Vector(-64, -64, -64)
ENT.Maxs = Vector( 64,  64,  64)
ENT.Invalid = false

-- Would be nice if I didn't have to do this
function ENT:RemoveFromClient()
	if self.Owner == LocalPlayer() then
		net.Start("G64_REMOVEINVALIDMARIO")
		net.WriteEntity(self)
		net.SendToServer()
		return true
	end
	return false
end

-- Ensure singleton mario
function ENT:RemoveInvalid()
	self.Invalid = true
	if CLIENT then
		self:RemoveFromClient()
		chat.AddText(Color(255,100,100), "[G64] There can only be one Mario spawned at a time.")
	else
		self:Remove()
	end
end

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
	self:DrawShadow(true)
	self:SetRenderMode(RENDERMODE_NORMAL)
	self:AddEFlags(EFL_DIRTY_ABSTRANSFORM)
	
	self.Owner = self:GetOwner()

	if not IsValid(self.Owner) then
		local plys = player.GetAll()
		local dist = 99999
		for k,v in ipairs(plys) do
			if self:GetPos():Distance(v:GetPos()) < dist then
				self.Owner = v
			end
		end
	end

	self.OwnerHealth = self.Owner:Health()
	self.OwnerMaxHealth = self.Owner:GetMaxHealth()
	-- Remove Mario if already spawned or if the player is dead or driving
	if IsValid(self.Owner.MarioEnt) or not self.Owner:Alive() or self.Owner:InVehicle() then self:RemoveInvalid() return end
	self.Owner.IsMario = true
	self.Owner:SetModelScale(0.8, 0)
	
	if CLIENT then
		self:SetNoDraw(true)

		hook.Add("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex(), function()
			if libsm64 == nil then return end

			-- Check if the binary module or libsm64 are outdated, chat to player once if so
			if libsm64.OutdatedNotified == nil and libsm64.GetModuleVersion ~= nil then
				libsm64.ModuleVersion = libsm64.GetModuleVersion()
				libsm64.LibSM64Version = libsm64.GetLibVersion()
				local libreq = libsm64.CheckLibRequirement()

				if libsm64.ModuleOutdated == true and libsm64.LibSM64Outdated == true then
					chat.AddText(Color(255, 100, 100), "[G64] Your G64 binary module and libsm64 versions are outdated! Please download the latest versions of both from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest\n")
					libsm64.OutdatedNotified = true
					if not game.SinglePlayer() then
						hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
						self:RemoveFromClient()
						return
					end
				elseif libsm64.ModuleOutdated == true then
					chat.AddText(Color(255, 100, 100), "[G64] Your version of the G64 binary module is outdated! Please download the latest version of the G64 binary module from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest\n")
					libsm64.OutdatedNotified = true
					if not game.SinglePlayer() then
						hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
						self:RemoveFromClient()
						return
					end
				elseif libsm64.LibSM64Outdated == true then
					chat.AddText(Color(255, 100, 100), "[G64] Your version of libsm64 is outdated! Please download the latest version of libsm64 from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest\n")
					libsm64.OutdatedNotified = true
					if not game.SinglePlayer() then
						hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
						self:RemoveFromClient()
						return
					end
				end
			end

			-- Prevent Mario from spawning in multiplayer if anything is outdated
			if not game.SinglePlayer() and (libsm64.ModuleOutdated == true or libsm64.LibSM64Outdated == true or libsm64.GetModuleVersion == nil or libsm64.PackageOutdated == true) then
				if libsm64.GetModuleVersion == nil then
					if libsm64.PackageOutdated == true then
						hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
						self:RemoveFromClient()
						if GetConVar("g64_auto_update"):GetBool() then
							chat.AddText(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please reconnect to auto-download the newest version.\n")
						else
							chat.AddText(Color(255, 100, 100), "[G64] Your libsm64-g64 package is outdated! Please download the latest version from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest", Color(255, 100, 100), " or turn auto-updates on in the G64 settings menu.\n")
						end
						return
					end
				else
					hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
					self:RemoveFromClient()
					chat.AddText(Color(255, 100, 100), "[G64] Your version of libsm64 or the G64 binary module is outdated! Please download the latest version from ", Color(86, 173, 255), "https://github.com/ckosmic/g64/releases/latest\n")
					return
				end
			end

			if not libsm64.ModuleExists then
				chat.AddText(Color(255, 100, 100), "[G64] Couldn't locate the libsm64-gmod binary module!\nPlease place it in ", Color(100, 255, 100), "garrysmod/lua/bin", Color(255, 100, 100), " and reconnect.")
				hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
				self:RemoveFromClient()
			end
			if libsm64.ModuleLoaded == true and libsm64.MapLoaded == true then
				hook.Remove("Think", "G64_WAIT_FOR_MODULE" .. self:EntIndex())
				
				g64config.Load()
				
				if g64utils.GlobalInit() == false then
					self:RemoveFromClient()
				end
				
				self.Mins = Vector(-160/libsm64.ScaleFactor, -160/libsm64.ScaleFactor, -160/libsm64.ScaleFactor)
				self.Maxs = Vector( 160/libsm64.ScaleFactor,  160/libsm64.ScaleFactor,  160/libsm64.ScaleFactor)

				if self.Owner == LocalPlayer() then
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
		self.Owner.PreviousWeapon = self.Owner:GetActiveWeapon()
		self.Owner:SetActiveWeapon(NULL)
		if self.Owner:FlashlightIsOn() then self.Owner:Flashlight(false) end
	end
	
	self:SetAngles(Angle())

	hook.Add("ShutDown", "G64_SERVER_SHUTDOWN", function()
		if SERVER and IsValid(self) then
			self:Remove()
		end
	end)
	
	net.Receive("G64_PLAYERREADY", function(len, ply)
		ply.MarioEnt = self
		-- Only gets run on the player who spawned Mario
		if ply == self.Owner then
			drive.PlayerStartDriving(ply, self, "G64_DRIVE")
			ply:SetObserverMode(OBS_MODE_CHASE)
		end
	end)
end

function ENT:OnRemove()
	if self.Invalid == false then
		if CLIENT then
			if libsm64 ~= nil and libsm64.ModuleLoaded then
				libsm64.MarioDelete(self.MarioId)
				
				hook.Remove("G64GameTick", "G64_MARIO_TICK" .. self.MarioId)
				hook.Remove("PostDrawOpaqueRenderables", "G64_RENDER_OPAQUES" .. self.MarioId)
				hook.Remove("CreateMove", "G64_CREATEMOVE" .. self.MarioId)
				hook.Remove("CalcView", "G64_CALCVIEW" .. self.MarioId)
				hook.Remove("CalcVehicleView", "G64_CALCVEHICLEVIEW" .. self.MarioId)
				hook.Remove("HUDItemPickedUp", "G64_ITEM_PICKED_UP" .. self.MarioId)
				hook.Remove("HUDShouldDraw", "G64_HUD_SHOULD_DRAW" .. self.MarioId)
				
				self.MarioId = -10
				if self.Owner ~= nil && IsValid(self.Owner) then -- Is null if local player disconnects
					self.Owner:SetNoDraw(false)
					if self.Owner == LocalPlayer() and (g64utils.MarioHasFlag(self.marioFlags, 0x00000008) or g64utils.MarioHasFlag(self.marioFlags, 0x00000004) or g64utils.MarioHasFlag(self.marioFlags, 0x00000002)) then
						StopAllTracks()
					end
				end
			end
		else
			if not IsValid(self.Owner) then return end
			self.Owner:SetObserverMode(OBS_MODE_NONE)
			self.Owner:SetMaxHealth(self.OwnerMaxHealth)
			self.Owner:SetHealth(self.OwnerHealth)
			self.Owner:SetNotSolid(false)
			drive.PlayerStopDriving(self.Owner)
			if self.Owner:InVehicle() then self.Owner:ExitVehicle() end
			if IsValid(self.Owner.PreviousWeapon) then
				-- Workaround for weapon becoming invisible and unusable
				self.Owner:SelectWeapon("weapon_crowbar")
				self.Owner:SelectWeapon(self.Owner.PreviousWeapon:GetClass())
			end
		end
		if IsValid(self.Owner) then
			self.Owner:SetModelScale(1, 0)
			self.Owner.IsMario = false
		end
	end
end

function ENT:OnReloaded()
	self:Remove()
end



local upOffset = Vector(0,0,5)

if CLIENT then

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

	function ENT:SetMarioAction(action)
		libsm64.SetMarioAction(self.MarioId, action)
	end

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

	function ENT:MarioIsAttacking()
		if g64utils.MarioHasFlag(self.marioFlags, 0x00100000) or 
		   g64utils.MarioHasFlag(self.marioFlags, 0x00200000) or
		   g64utils.MarioHasFlag(self.marioFlags, 0x00400000) or 
		   self.marioAction == g64types.SM64MarioAction.ACT_DIVE or
		   self.marioAction == g64types.SM64MarioAction.ACT_DIVE_SLIDE or
		   self.marioAction == g64types.SM64MarioAction.ACT_SLIDE_KICK or
		   self.marioAction == g64types.SM64MarioAction.ACT_SLIDE_KICK_SLIDE then
			return true
		else
			return false
		end
	end

	local function MatTypeToTerrainType(matType)
		if matType == MAT_CONCRETE or matType == MAT_TILE or matType == MAT_PLASTIC or matType == MAT_GLASS or matType == MAT_METAL then
			return 0, g64types.SM64TerrainType.TERRAIN_STONE
		elseif matType == MAT_DIRT or matType == MAT_FOLIAGE then
			return 0, g64types.SM64TerrainType.TERRAIN_GRASS
		elseif matType == MAT_GRASS then
			return 1, g64types.SM64TerrainType.TERRAIN_GRASS
		elseif matType == MAT_SNOW then
			return 0, g64types.SM64TerrainType.TERRAIN_SNOW
		elseif matType == MAT_SAND then
			return 0, g64types.SM64TerrainType.TERRAIN_SAND
		elseif matType == MAT_SLOSH then
			return 0, g64types.SM64TerrainType.TERRAIN_WATER
		elseif matType == MAT_WOOD then
			return 0, g64types.SM64TerrainType.TERRAIN_SPOOKY
		else
			return 0, g64types.SM64TerrainType.TERRAIN_STONE
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
		xOffset = worldMin.x + 16384
		yOffset = worldMin.y + 16384
		self.marioPos = Vector()
		self.marioCenter = Vector()
		self.marioForward = Vector()
		self.marioAction = 0
		self.marioFlags = 0
		self.marioParticleFlags = 0
		self.marioInvincTimer = 0
		self.marioHurtCounter = 0
		self.marioHealth = 2176
		self.marioWaterLevel = -100000
		self.marioNumLives = 4
		self.bufferIndex = 0
		self.lerpedPos = Vector()
		self.animInfo = {}
		self.tickTime = -1
		self.wingsIndices = {}
		self.hasWingCap = false
		self.hasMetalCap = false
		self.hasVanishCap = false
		self.marioDead = false
		self.view = {
			origin = Vector(),
			angles = Angle(),
			fov = nil,
			inited = false
		}
	end

	local fLerpVector = LerpVector
	function ENT:GenerateMesh()
		local interpolation = (GetConVar("g64_interpolation"):GetBool())
		
		local vertex = vertexBuffers[self.MarioId][self.bufferIndex + 1]
		local lastVertex = vertexBuffers[self.MarioId][1 - self.bufferIndex + 1]
		
		if vertex == nil or lastVertex == nil or vertex[1] == nil or lastVertex[1] == nil then return end
		if vertex[1][#vertex[1]] == nil or lastVertex[1][#lastVertex[1]] == nil then return end
		
		local vertCount = #vertex[1]
		local triCount = vertCount/3
		if vertCount == 0 then return end
		
		if self.Mesh and self.Mesh:IsValid() then
			self.Mesh:Destroy()
			self.Mesh = nil
		end
		self.Mesh = Mesh()
		if self.WingsMesh and self.WingsMesh:IsValid() then
			self.WingsMesh:Destroy()
			self.WingsMesh = nil
		end
		self.WingsMesh = Mesh()
		
		local t = (SysTime() - fixedTime) / G64_TICKRATE
		local col
		local myColorTable = self.colorTable
		
		local posTab = vertex[1]
		local lastPosTab = lastVertex[1]
		local normTab = vertex[2]
		local lastNormTab = lastVertex[2]
		local uTab = vertex[3]
		local vTab = vertex[4]
		local colTab = vertex[5]
		local wingIndex = 1
		local uvOffset = 2/704
		local hasWingCap = self.hasWingCap

		-- Create main mesh
		mesh.Begin(self.Mesh, MATERIAL_TRIANGLES, triCount)
		for i = 1, vertCount do
			if posTab[i] == nil or lastPosTab[i] == nil then
				mesh.End()
				return
			end
			if hasWingCap == true and vertCount > 2256 and i > vertCount-24 then
				self.wingsIndices[wingIndex] = i
				wingIndex = wingIndex + 1
			else
				col = myColorTable[colTab[i]]
				
				if interpolation then
					mesh.Position(fLerpVector(t, posTab[i], lastPosTab[i]))
					mesh.Normal(fLerpVector(t, normTab[i], lastNormTab[i]))
				else
					mesh.Position(posTab[i])
					mesh.Normal(normTab[i])
				end
				mesh.TexCoord(0, uTab[i]+uvOffset, vTab[i]+uvOffset)
				mesh.Color(col[1], col[2], col[3], 255)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()
		
		-- Create wings mesh
		if hasWingCap == true then
			local j = 1
			local wingsIndices = self.wingsIndices
			uvOffset = 0.5/704
			
			mesh.Begin(self.WingsMesh, MATERIAL_TRIANGLES, #wingsIndices/3)
			for i = 1, #wingsIndices do
				j = wingsIndices[i]
				if posTab[j] == nil or lastPosTab[j] == nil then
					mesh.End()
					return
				end
				col = myColorTable[colTab[j]]
				
				if interpolation then
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

	function ENT:DrawEither()
		if self.marioInvincTimer ~= nil and self.marioInvincTimer >= 3 and self.bufferIndex == 1 and self.marioHealth ~= 255 then return end -- Hitstun blinking effect
		
		if self.hasVanishCap == true then
			if self.Owner == LocalPlayer() then
				-- Vanish cap silhouette when inside or behind objects
				render.SetStencilWriteMask( 0xFF )
				render.SetStencilTestMask( 0xFF )
				render.SetStencilReferenceValue( 0 )
				render.SetStencilCompareFunction( STENCIL_ALWAYS )
				render.SetStencilPassOperation( STENCIL_KEEP )
				render.SetStencilFailOperation( STENCIL_KEEP )
				render.SetStencilZFailOperation( STENCIL_KEEP )
				render.ClearStencil()

				render.SetStencilEnable( true )
				render.SetStencilReferenceValue( 57 )
				render.SetStencilCompareFunction( STENCIL_ALWAYS )
				render.SetStencilZFailOperation( STENCIL_REPLACE )

				render.SetWriteDepthToDestAlpha(false)
				render.MaterialOverride(g64utils.WhiteMat)
				self:DrawModel()

				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.ClearBuffersObeyStencil(70, 70, 70, 100, false)
				render.SetStencilEnable(false)
			end

			-- Draw Mario to translucency mask
			render.PushRenderTarget(g64utils.MarioTargetRT)
			render.MaterialOverride(g64utils.WhiteMat)
			self:DrawModel()
			render.PopRenderTarget()
		end

		if self.hasMetalCap then
			-- Lighting
			render.MaterialOverride(g64utils.MarioLightingMat)
			self:DrawModel()

			-- Metal material
			render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_ZERO, BLENDFUNC_ADD)
			render.MaterialOverride(g64utils.MetalMat)
			self:DrawModel()
			render.OverrideBlend(false)

			if self.WingsMesh then
				cam.PushModelMatrix( self:GetWorldTransformMatrix() )
				self.WingsMesh:Draw()
				cam.PopModelMatrix()
			end
		else
			-- Lighting
			render.MaterialOverride(g64utils.MarioLightingMat)
			self:DrawModel()

			-- Vertex colors
			render.MaterialOverride(g64utils.MarioVertsMat)
			render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_ZERO, BLENDFUNC_ADD)
			self:DrawModel()
			render.OverrideBlend(false)
			
			-- Textures
			render.MaterialOverride(g64utils.MarioTexMat)
			self:DrawModel()
			if self.WingsMesh then
				render.SetMaterial(g64utils.MarioWingsMat)
				cam.PushModelMatrix( self:GetWorldTransformMatrix() )
				self.WingsMesh:Draw()
				cam.PopModelMatrix()
			end
		end

		render.MaterialOverride(nil)
		render.OverrideBlend(false)
	end

	function ENT:Draw()
		if self.hasVanishCap == true then return end
		self:DrawEither()
	end

	function ENT:DrawTranslucent()
		if self.hasVanishCap == false then return end
		self:DrawEither()
	end
	
	function ENT:GetRenderMesh()
		return { Mesh = self.Mesh, Material = g64utils.MarioLightingMat }
	end

	function ENT:StartRemoteMario()
		local lPlayer = LocalPlayer()
	
		if self.MarioId < 0 or self.MarioId == nil then
			self:InitSomeVariables()
			local entPos = self:GetPos()
			self.tickedPos = -entPos*libsm64.ScaleFactor
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
			
			if tickCount > 0 then
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5+8)
			end
			
			libsm64.MarioAnimTick(self.animInfo, self.MarioId, self.bufferIndex, self.marioFlags, self.tickedPos)
			
			self.hasWingCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000008)
			self.hasMetalCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000004)
			self.hasVanishCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000002)
			
			tickCount = tickCount + 1
			
			if (1 / RealFrameTime()) > 33 then
				self.bufferIndex = 1 - self.bufferIndex
			else
				-- Player ping is too high or FPS is too low, don't even bother interpolating
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5)
			end

			self.Owner:SetNoDraw(true)
		end
		
		function self:Think()
			tickDeltaTime = SysTime() - self.tickTime
			
			if (not gui.IsGameUIVisible() or not game.SinglePlayer()) and tickDeltaTime < 1.5 then
				self:GenerateMesh()
			end
			
			self:NextThink(CurTime())
			return true
		end
		
		hook.Add("G64GameTick", "G64_MARIO_TICK" .. self.MarioId, function()
			if self.tickTime < 0 then return end
			tickDeltaTime = SysTime() - self.tickTime
			-- If hasn't received any update in > 1.5s, don't tick and don't draw
			if tickDeltaTime > 1.5 then
				self:SetNoDraw(true)
				return
			else
				self:SetNoDraw(false)
			end
			MarioTick()
		end)
	end
	
	net.Receive("G64_UPDATEREMOTECOLORS", function(len, ply)
		local sent = net.ReadEntity()
		if sent.MarioId == nil or sent.MarioId < 0 or sent.IsRemote == false then return end
		if sent.colorTable == nil then sent.colorTable = {} end
		for i=1, 6 do
			sent.colorTable[i] = { net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) }
		end
	end)
	
	net.Receive("G64_TICKREMOTEMARIO", function(len, ply)
		local sent = net.ReadEntity()
		if sent.MarioId == nil or sent.MarioId < 0 or sent.IsRemote == false then return end
		if sent.animInfo == nil then sent.animInfo = {} end
		sent.animInfo.animID = net.ReadInt(16)
		sent.animInfo.animAccel = net.ReadInt(32)
		sent.animInfo.rotation = Angle(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
		sent.marioFlags = net.ReadUInt(32)
		
		libsm64.SetMarioPosition(sent.MarioId, sent:GetPos())
		sent.tickedPos = -sent:GetPos()*libsm64.ScaleFactor
		
		sent.tickTime = SysTime()
	end)

	function ENT:StartLocalMario()
		local lPlayer = LocalPlayer()
		local tickCount = 0
		
		local function TransmitColors()
			net.Start("G64_TRANSMITCOLORS")
				for i=1, 6 do
					net.WriteUInt(g64config.Config.MarioColors[i][1], 8)
					net.WriteUInt(g64config.Config.MarioColors[i][2], 8)
					net.WriteUInt(g64config.Config.MarioColors[i][3], 8)
				end
			net.SendToServer()
		end

		if self.MarioId == nil or self.MarioId < 0 then
			self:InitSomeVariables()
			local entPos = lPlayer:GetPos()
			marioChunk = PointInChunk(entPos)
			marioDispChunk = PointInDispChunk(entPos)
			libsm64.StaticSurfacesLoad(libsm64.MapVertices[marioChunk.x][marioChunk.y], libsm64.DispVertices[marioDispChunk.x][marioDispChunk.y])
			self.MarioId = libsm64.MarioCreate(entPos, false)
			self.IsRemote = false
			self:SetRenderBounds(self.Mins, self.Maxs)
			tickCount = 0

			libsm64.SetMarioAngle(self.MarioId, math.rad(lPlayer:GetAngles()[2]-90)/(math.pi*math.pi))
			libsm64.MarioSetLives(self.MarioId, lPlayer.LivesCount)

			vertexBuffers[self.MarioId] = { {}, {} }
			stateBuffers[self.MarioId] = { {}, {} }
			
			stateBuffers[self.MarioId][1] = libsm64.GetMarioTableReference(self.MarioId, 6)
			vertexBuffers[self.MarioId][1] = libsm64.GetMarioTableReference(self.MarioId, 5)
			stateBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 6)
			vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5)
			
			TransmitColors()
			
			self:SetNoDraw(false)
		end

		local function LoadStaticSurfaces()
			marioChunk = PointInChunk(self.marioPos)
			marioDispChunk = PointInDispChunk(self.marioPos)
			if marioChunk.x ~= prevMarioChunk.x or marioChunk.y ~= prevMarioChunk.y or marioDispChunk.x ~= prevMarioDispChunk.x or marioDispChunk.y ~= prevMarioDispChunk.y then
				prevMarioChunk.x = marioChunk.x
				prevMarioChunk.y = marioChunk.y
				prevMarioDispChunk.x = marioDispChunk.x
				prevMarioDispChunk.y = marioDispChunk.y
				if GetConVar("g64_debug_collision"):GetBool() then
					print("[G64] Mario World Chunk: ", marioChunk.x .. ", " .. marioChunk.y)
					print("[G64] Mario Disp Chunk: ", marioDispChunk.x .. ", " .. marioDispChunk.y)
				end
				libsm64.StaticSurfacesLoad(libsm64.MapVertices[marioChunk.x][marioChunk.y], libsm64.DispVertices[marioDispChunk.x][marioDispChunk.y])
			end
		end

		local function SpawnParticles()
			if self.marioParticleFlags ~= 0 then
				if g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_MIST_CIRCLE) then
					ParticleEffect("ground_pound", self.marioPos, Angle())
				end
				if g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_DUST) then
					ParticleEffect("mario_dust", self.marioPos, Angle())
				end
				if g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_HORIZONTAL_STAR) then
					ParticleEffect("mario_horiz_star", self.marioPos, Angle())
				end
				if g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_VERTICAL_STAR) or g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_TRIANGLE) then
					local tr = util.TraceLine({
						start = self.marioCenter,
						endpos = self.marioCenter + self.marioForward * (140 / libsm64.ScaleFactor),
						filter = { self, lPlayer },
					})
					local ang = tr.HitNormal:Angle()
					ParticleEffect("mario_vert_star", tr.HitPos, ang)
				end
				if g64utils.MarioHasFlag(self.marioParticleFlags, g64types.SM64ParticleType.PARTICLE_FIRE) then
					ParticleEffect("mario_fire", self.marioPos, Angle())
				end
			end
		end

		local dontAttack = {
			g64_yellowcoin = true,
			g64_redcoin = true,
			g64_bluecoin = true,
			g64_1up = true
		}
		local function PerformGroundAttacks()
			if self:MarioIsAttacking() then
				local tr = util.TraceHull({
					start = self.marioCenter,
					endpos = self.marioCenter + self.marioForward * (90 / libsm64.ScaleFactor),
					filter = { self, lPlayer },
					mins = Vector(-16, -16, -(40 / libsm64.ScaleFactor)),
					maxs = Vector(16, 16, 71),
					mask = MASK_SHOT_HULL
				})
				hitPos = tr.HitPos
				if IsValid(tr.Entity) and tr.Hit and tr.Entity.HitStunTimer ~= nil and tr.Entity.HitStunTimer < 0 and not dontAttack[tr.Entity:GetClass()] then
					local min, max = tr.Entity:WorldSpaceAABB()
					if tr.Entity:IsNPC() == true or tr.Entity:IsPlayer() == true then
						if libsm64.MarioAttack(self.MarioId, tr.HitPos, max.z - min.z) == true then
							local dmg = 15
							if self.marioAction == g64types.SM64MarioAction.ACT_JUMP_KICK then
								dmg = 22
							end
							tr.Entity.HitStunTimer = 0.25
							local ang = tr.HitNormal:Angle()
							ParticleEffect("mario_vert_star", tr.HitPos, ang)
							net.Start("G64_DAMAGEENTITY")
								net.WriteEntity(self)
								net.WriteEntity(tr.Entity)
								net.WriteVector(self.marioForward)
								net.WriteVector(tr.HitPos)
								net.WriteUInt(dmg, 8)
							net.SendToServer()
						end
					else
						tr.Entity.HitStunTimer = 0.25
						local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_ACTION_HIT)
						libsm64.PlaySoundGlobal(soundArg)
						net.Start("G64_DAMAGEENTITY")
							net.WriteEntity(self)
							net.WriteEntity(tr.Entity)
							net.WriteVector(self.marioForward)
							net.WriteVector(tr.HitPos)
							net.WriteUInt(15, 8)
						net.SendToServer()
					end
				end
			end
		end

		local trDownVec = Vector(0, 0, -150/libsm64.ScaleFactor)
		local function PerformAerialAttacks()
			local tr = util.TraceHull({
				start = self.marioCenter,
				endpos = self.marioCenter + trDownVec,
				filter = function(ent) return (ent ~= self.Owner and ent:Health() > 0) end,
				mins = trMins,
				maxs = trMaxs,
				mask = MASK_SHOT_HULL
			})
			if IsValid(tr.Entity) and tr.Hit and tr.Entity.HitStunTimer ~= nil and tr.Entity.HitStunTimer < 0 and not dontAttack[tr.Entity:GetClass()] then
				local min, max = tr.Entity:WorldSpaceAABB()
				if tr.Entity:IsNPC() == true or tr.Entity:IsPlayer() == true then
					if libsm64.MarioAttack(self.MarioId, tr.Entity:GetPos(), max.z - min.z) == true then
						tr.Entity.HitStunTimer = 0.25
						local dmg = 24
						if self.marioAction == g64types.SM64MarioAction.ACT_GROUND_POUND then
							libsm64.SetMarioAction(self.MarioId, g64types.SM64MarioAction.ACT_TRIPLE_JUMP)
							local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_ACTION_HIT)
							libsm64.PlaySoundGlobal(soundArg)
							dmg = 32
						end
						ParticleEffect("mario_horiz_star", self.marioPos, Angle())
						net.Start("G64_DAMAGEENTITY")
							net.WriteEntity(self)
							net.WriteEntity(tr.Entity)
							net.WriteVector(-self:GetUp())
							net.WriteVector(tr.HitPos)
							net.WriteUInt(24, 8)
						net.SendToServer()
					end
				elseif self.marioAction == g64types.SM64MarioAction.ACT_GROUND_POUND then
					tr.Entity.HitStunTimer = 0.25
					local soundArg = GetSoundArg(g64types.SM64SoundTable.SOUND_GENERAL_POUND_ROCK)
					libsm64.PlaySoundGlobal(soundArg)
					net.Start("G64_DAMAGEENTITY")
						net.WriteEntity(self)
						net.WriteEntity(tr.Entity)
						net.WriteVector(self.marioForward)
						net.WriteVector(tr.HitPos)
						net.WriteUInt(32, 8)
					net.SendToServer()
				end
			end
			-- If we're not over a living ent, get floor mat instead
			if not IsValid(tr.Entity) then
				tr = util.TraceLine({
					start = self.marioCenter,
					endpos = self.marioCenter + trDownVec,
					filter = { self, lPlayer },
					mask = MASK_SOLID
				})

				if self.hasVanishCap == true then 
					-- Prevent Mario from getting stuck in props
					if tr.Entity.SM64_UPLOADED == true then
						libsm64.MarioExtendCapTime(self.MarioId, 1)
					end
					tr = util.TraceLine({
						start = self.marioCenter,
						endpos = self.marioCenter + trDownVec,
						filter = { self, lPlayer },
						mask = MASK_PLAYERSOLID_BRUSHONLY
					})
				end

				if tr.Entity.G64SurfaceType == nil and tr.Entity.G64TerrainType == nil then
					local alt, terrType = MatTypeToTerrainType(tr.MatType)
					local surfType = g64types.SM64SurfaceType.SURFACE_DEFAULT
					
					if alt == 1 then
						surfType = g64types.SM64SurfaceType.SURFACE_NOISE_DEFAULT
					end

					libsm64.SetMarioFloorOverrides(self.MarioId, terrType, surfType, 0)
				else
					-- Turn off overrides
					libsm64.SetMarioFloorOverrides(self.MarioId, 0x7, 0x100, 0)
				end
			end
		end

		local function CheckForSpecialCaps()
			if self.EnableWingCap == true then
				libsm64.MarioEnableCap(self.MarioId, 0x00000008, GetConVar("g64_wingcap_timer"):GetInt(), GetConVar("g64_cap_music"):GetBool())
				self.EnableWingCap = false
				self.hasWingCap = true
			end
			if self.EnableMetalCap == true then
				libsm64.MarioEnableCap(self.MarioId, 0x00000004, GetConVar("g64_metalcap_timer"):GetInt(), GetConVar("g64_cap_music"):GetBool())
				self.EnableMetalCap = false
				self.hasMetalCap = true
			end
			if self.EnableVanishCap == true then
				libsm64.MarioEnableCap(self.MarioId, 0x00000002, GetConVar("g64_vanishcap_timer"):GetInt(), GetConVar("g64_cap_music"):GetBool())
				self.EnableVanishCap = false
				self.hasVanishCap = true
				-- Update prop collisions instantly or else Mario will teleport
				-- to the center of the map
				hook.Call("G64UpdatePropCollisions")
			end
		end

		local entFilter = {}
		local function MarioCalcView(ply, origin, angles, fov, znear, zfar)
			if FrameTime() == 0 then return self.view end
			if gui.IsGameUIVisible() and game.SinglePlayer() then return self.view end
			local t = (SysTime() - fixedTime) / G64_TICKRATE
			if stateBuffers[self.MarioId][self.bufferIndex + 1][1] ~= nil then
				if not ply:InVehicle() then
					self.lerpedPos = LerpVector(t, stateBuffers[self.MarioId][self.bufferIndex + 1][1], stateBuffers[self.MarioId][1-self.bufferIndex + 1][1]) + upOffset
					self:SetNetworkOrigin(self.lerpedPos)
					self:SetPos(self.lerpedPos)
				end
			end
			
			self.view.origin = self.lerpedPos
			self.view.origin.z = self.view.origin.z + 50 / libsm64.ScaleFactor
			self.view.angles = angles

			entFilter[1] = self
			entFilter[2] = ply

			CalcView_ThirdPerson(self.view, 500, 4, ply, entFilter)
			return self.view
		end

		local function BuildEntityFilter()
			local i = 3
			if self.Owner:InVehicle() then
				for k,v in ipairs(ents.FindInSphere(self.lerpedPos, 100)) do
					v.DontCollideWithMario = true
					entFilter[i] = v
					i = i + 1
				end
			else
				for k,v in ipairs(entFilter) do
					v.DontCollideWithMario = false
				end
				table.Empty(entFilter)
				entFilter[1] = self
				entFilter[2] = self.Owner
			end
		end

		local function CheckIfDead()
			if self.marioNumLives == 0 and self.marioHealth == 0 and self.marioDead == false then
				self.marioDead = true
				timer.Create("G64_RESPAWN_TIMER", 5, 1, function()
					if self.marioNumLives == 0 and self.marioHealth == 0 then
						net.Start("G64_RESPAWNMARIO")
						net.WriteEntity(self)
						net.SendToServer()
						lPlayer.LivesCount = 4
					else
						self.marioDead = false
					end
				end)
			end
		end
		
		local hitPos = Vector()
		local animInfo
		local trMins = Vector(-16, -16, -4)
		local trMaxs = Vector(16, 16, 4)
		local vDown = false
		local function MarioTick()
			if self.MarioId == nil then return end
			fixedTime = SysTime()

			if g64utils.IsSpawnMenuOpen() == false and g64utils.IsChatOpen == false then
				inputs = g64utils.GetInputTable()
				if input.IsButtonDown(GetConVar("g64_freemove"):GetInt()) == true then
					if vDown == false and GetConVar("sv_cheats"):GetBool() then
						if self.marioAction == g64types.SM64MarioAction.ACT_DEBUG_FREE_MOVE then
							libsm64.SetMarioAction(self.MarioId, g64types.SM64MarioAction.ACT_IDLE)
						else
							libsm64.SetMarioAction(self.MarioId, g64types.SM64MarioAction.ACT_DEBUG_FREE_MOVE)
						end
						vDown = true
					end
				else
					vDown = false
				end
			else
				inputs = g64utils.GetZeroInputTable()
			end
		
			local facing = lPlayer:GetAimVector()
			if tickCount > 0 then
				stateBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 6+8)
				vertexBuffers[self.MarioId][2] = libsm64.GetMarioTableReference(self.MarioId, 5+8)
			end
			libsm64.MarioTick(self.MarioId, self.bufferIndex, facing, inputs[1], inputs[2], inputs[3], inputs[4])
			
			tickCount = tickCount + 1
			
			animInfo = libsm64.GetMarioAnimInfo(self.MarioId)
			
			local marioState = stateBuffers[self.MarioId][self.bufferIndex + 1]
			
			if not lPlayer:InVehicle() then self.marioPos = marioState[1] end
			self.marioForward = Vector(math.sin(marioState[3]), math.cos(math.pi*2 - marioState[3]), 0)
			self.marioFlags = marioState[6]
			self.marioParticleFlags = marioState[7]
			self.marioHealth = bit.rshift(marioState[4], 8)
			self.marioInvincTimer = marioState[8]
			self.marioHurtCounter = marioState[9]
			self.colorTable = g64config.Config.MarioColors
			self.hasWingCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000008)
			self.hasMetalCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000004)
			self.hasVanishCap = g64utils.MarioHasFlag(self.marioFlags, 0x00000002)
			self.marioCenter = Vector(self.marioPos)
			self.marioCenter.z = self.marioCenter.z + 50 / libsm64.ScaleFactor
			self.marioAction = marioState[5]
			self.marioNumLives = marioState[10]

			lPlayer.LivesCount = self.marioNumLives

			--if(lPlayer:GetPos():DistToSqr(self.lerpedPos) > 100000) then
			--	-- Probably used a teleporter, so teleport Mario to the player
			--	libsm64.SetMarioPosition(self.MarioId, lPlayer:GetPos())
			--end
			
			LoadStaticSurfaces()
			SpawnParticles()
			PerformGroundAttacks()
			PerformAerialAttacks()
			CheckForSpecialCaps()
			CheckIfDead()
			
			self.bufferIndex = 1 - self.bufferIndex
			
			if animInfo == nil then return end
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

		local upVec = Vector(0,0,10000)
		local downVec = Vector(0,0,-10000)
		local function FindWaterLevel()
			local tr = util.TraceLine({
				start = self.lerpedPos,
				endpos = self.lerpedPos + upVec,
				mask = MASK_WATER
			})
			
			if tr.Hit == true then
				self.marioWaterLevel = self.lerpedPos.z + upVec.z * tr.FractionLeftSolid
				libsm64.SetMarioWaterLevel(self.MarioId, self.marioWaterLevel * libsm64.ScaleFactor)
			else
				local tr = util.TraceLine({
					start = self.lerpedPos,
					endpos = self.lerpedPos + downVec,
					mask = MASK_WATER
				})
				
				if tr.Hit == true and tr.Fraction < 1 then
					self.marioWaterLevel = tr.HitPos.z
					libsm64.SetMarioWaterLevel(self.MarioId, self.marioWaterLevel * libsm64.ScaleFactor)
				else
					self.marioWaterLevel = -1000000
					libsm64.SetMarioWaterLevel(self.MarioId, -1000000)
				end
			end
		end

		local function VehicleTick()
			if lPlayer:InVehicle() then
				self.marioPos = lPlayer:GetPos()
				self.lerpedPos = lPlayer:GetPos()
				if not self.InVehicle then
					-- Runs once as soon as Mario enters a vehicle
					self.InVehicle = true
					BuildEntityFilter()

					hook.Remove("CalcView", "G64_CALCVIEW" .. self.MarioId)

					libsm64.SetMarioAngle(self.MarioId, 0)
				end

				libsm64.SetMarioPosition(self.MarioId, lPlayer:GetPos())
				libsm64.SetMarioAction(self.MarioId, g64types.SM64MarioAction.ACT_HOLD_BUTT_SLIDE_NO_CANCEL)
			else
				if self.InVehicle == true then
					-- Runs once as soon as Mario exits a vehicle
					self.InVehicle = false
					BuildEntityFilter()

					hook.Add("CalcView", "G64_CALCVIEW" .. self.MarioId, MarioCalcView)

					libsm64.SetMarioPosition(self.MarioId, lPlayer:GetPos())
					libsm64.SetMarioAction(self.MarioId, g64types.SM64MarioAction.ACT_IDLE)
				end

				FindWaterLevel()
			end
		end
		
		-- Tick Mario at 30Hz
		hook.Add("G64GameTick", "G64_MARIO_TICK" .. self.MarioId, function()
			if FrameTime() == 0 then return end
			MarioTick()
		end)

		function self:Think()
			if FrameTime() == 0 then return end

			if input.IsButtonDown(GetConVar("g64_remove"):GetInt()) then
				self:RemoveFromClient()
			end

			if not gui.IsGameUIVisible() or not game.SinglePlayer() then
				self:GenerateMesh()
			end

			VehicleTick()

			self:NextThink(CurTime())
			return true
		end

		net.Receive("G64_DAMAGEMARIO", function(len,ply)
			if self.marioInvincTimer < 3 then
				if self.Owner:InVehicle() and not self.hasMetalCap and not self.hasVanishCap then
					libsm64.SetMarioInvincibility(self.MarioId, 30)
				end
				local damage = net.ReadUInt(8)
				local src = Vector(net.ReadInt(16), net.ReadInt(16), net.ReadInt(16))
				libsm64.MarioTakeDamage(self.MarioId, damage, 0, src)
			end
		end)

		hook.Add("PostDrawOpaqueRenderables", "G64_RENDER_OPAQUES" .. self.MarioId, function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
			if self.MarioId == nil or self.MarioId < 0 or libsm64 == nil or libsm64.ModuleLoaded == false or libsm64.IsGlobalInit() == false or isDraw3DSkybox or bDrawingDepth then return end
			
			-- Debug map collision
			if GetConVar("g64_debug_collision"):GetBool() and marioChunk.x ~= nil and marioChunk.y ~= nil then
				local mapverts = libsm64.MapVertices[marioChunk.x][marioChunk.y]
				local mapvertcount = #mapverts
				if mapvertcount == 0 then return end
				math.randomseed(0)
				render.SetMaterial(g64utils.DebugMat) -- Apply the material
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
				render.SetMaterial(g64utils.DebugMat) -- Apply the material
				render.ResetModelLighting(1,1,1)
				mesh.Begin(MATERIAL_TRIANGLES, math.Min(dispvertcount/3, 8192))
				for i = 1, math.Min(dispvertcount, 32768) do
					mesh.Position(dispverts[i])
					mesh.Color(math.random(0, 255),math.random(0, 255),math.random(0, 255),255)
					mesh.AdvanceVertex()
				end
				mesh.End()
			end

			if GetConVar("g64_debug_rays"):GetBool() and self.marioCenter ~= nil and libsm64.ScaleFactor ~= nil then
				if self:MarioIsAttacking() then
					local tr = util.TraceHull({
						start = self.marioCenter,
						endpos = self.marioCenter + self.marioForward * (90 / libsm64.ScaleFactor),
						filter = { self, lPlayer },
						mins = Vector(-16, -16, -(40 / libsm64.ScaleFactor)),
						maxs = Vector(16, 16, 71),
						mask = MASK_SHOT_HULL
					})
					
					render.DrawLine(self.marioCenter, self.marioCenter + self.marioForward * (120 / libsm64.ScaleFactor), Color(0, 0, 255))
					render.DrawWireframeBox(tr.HitPos, Angle(0,0,0), Vector(-25, -25, -(40 / libsm64.ScaleFactor)), Vector(25, 25, 71), Color(255,255,255),true)
				end
				if self.marioWaterLevel ~= nil then
					render.DrawLine(Vector(self.lerpedPos[1],self.lerpedPos[2],self.marioWaterLevel), Vector(self.lerpedPos[1],self.lerpedPos[2],self.marioWaterLevel+100), Color(255,0,0))
				end
			end
			
		end)
		
		hook.Add("HUDItemPickedUp", "G64_ITEM_PICKED_UP" .. self.MarioId, function(itemName)
			if itemName == "item_healthkit" then
				libsm64.MarioHeal(self.MarioId, 4)
			elseif itemName == "item_healthvial" then
				libsm64.MarioHeal(self.MarioId, 2)
			end
		end)

		local hideHud = {
			CHudHealth = true,
			CHudBattery = true,
			CHudSuitPower = true,
			CHudPoisonDamageIndicator = true
		}
		hook.Add("HUDShouldDraw", "G64_HUD_SHOULD_DRAW" .. self.MarioId, function(name)
			if hideHud[name] == true then return false end
		end)
		
		-- From drive_base.lua
		CalcView_ThirdPerson = function( view, dist, hullsize, ply, entityfilter )
			local newdist = dist / libsm64.ScaleFactor
			local neworigin = view.origin - ply:EyeAngles():Forward() * newdist
			local newmask = MASK_SOLID
			if self.hasVanishCap == true then newmask = MASK_PLAYERSOLID_BRUSHONLY end
			if self.marioAction == g64types.SM64MarioAction.ACT_DEBUG_FREE_MOVE then newmask = MASK_CURRENT end

			if hullsize && hullsize > 0 then
				local tr = util.TraceHull({
					start	= view.origin,
					endpos	= neworigin,
					mins	= Vector( hullsize, hullsize, hullsize ) * -1,
					maxs	= Vector( hullsize, hullsize, hullsize ),
					filter	= entityfilter,
					mask    = newmask
				})
				
				if tr.Hit then
					neworigin = tr.HitPos
				end

			end

			view.origin		= neworigin
			view.angles		= ply:EyeAngles()
		end

		hook.Add("CalcView", "G64_CALCVIEW" .. self.MarioId, MarioCalcView)

		hook.Add("OnSpawnMenuClose", "G64_SMENU_CLOSED", function()
			if GetConVar("g64_upd_col_flag"):GetBool() then
				TransmitColors()
			end
		end)

	end

else

	

end