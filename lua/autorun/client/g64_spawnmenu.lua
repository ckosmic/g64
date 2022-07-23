AddCSLuaFile()

include("includes/g64_types.lua")
include("includes/g64_config.lua")

hook.Add("AddToolMenuCategories", "G64_CREATE_SPAWN_MENU", function()
	spawnmenu.AddToolCategory("Utilities", "G64", "#G64")
end)

hook.Add("PopulateToolMenu", "G64_CREATE_MENU_SETTINGS", function()
	g64config.Load()
	
	spawnmenu.AddToolMenuOption("Utilities", "G64", "G64_Settings", "#Settings", "", "", function(panel)
		panel:ClearControls()
		
		local genHeader = vgui.Create("DLabel")
		genHeader:SetText("General")
		genHeader:SetTextColor(Color(0,0,0))
		genHeader:SetFont("DermaDefaultBold")
		
		local filePathEntry = vgui.Create("DTextEntry")
		filePathEntry:SetPlaceholderText("No file specified")
		filePathEntry:SetValue(GetConVar("g64_rompath"):GetString())
		filePathEntry.OnEnter = function(self)
			GetConVar("g64_rompath"):SetString(self:GetValue())
		end
		
		local browseButton = vgui.Create("DButton")
		browseButton:SetText("Browse...")
		browseButton.DoClick = function()
			local filePath = libsm64.OpenFileDialog()
			if not isnumber(filePath) then
				GetConVar("g64_rompath"):SetString(filePath)
				filePathEntry:SetValue(filePath)
			else
				if filePath == 0 then
					chat.AddText(Color(255, 100, 100), "[G64] Failed to open file.")
				elseif filePath == 1 then
					chat.AddText(Color(255, 100, 100), "[G64] File browser unsupported on non-windows computers.")
				end
			end
		end

		local toggleUpdates = vgui.Create("DCheckBoxLabel")
		toggleUpdates:SetText("Auto-update")
		toggleUpdates:SetTextColor(Color(0,0,0))
		toggleUpdates:SetTooltip([[Allows the addon to update libsm64
		and the G64 module upon disconnect.]])
		if GetConVar("g64_auto_update"):GetBool() then toggleUpdates:SetValue(true)
		else toggleUpdates:SetValue(false) end
		toggleUpdates:SetConVar("g64_auto_update")
		
		local toggleInterp = vgui.Create("DCheckBoxLabel")
		toggleInterp:SetText("Enable mesh interpolation")
		toggleInterp:SetTextColor(Color(0,0,0))
		toggleInterp:SetTooltip([[Makes Mario's mesh move smoother but will
		cause artifacts and may cause a slight performance drop.]])
		if GetConVar("g64_interpolation"):GetBool() then toggleInterp:SetValue(true)
		else toggleInterp:SetValue(false) end
		toggleInterp:SetConVar("g64_interpolation")
		
		local toggleCapMusic = vgui.Create("DCheckBoxLabel")
		toggleCapMusic:SetText("Play cap music")
		toggleCapMusic:SetTextColor(Color(0,0,0))
		toggleCapMusic:SetTooltip([[Plays the wing cap or metal cap theme
		when picking up a cap.]])
		if GetConVar("g64_cap_music"):GetBool() then toggleCapMusic:SetValue(true)
		else toggleCapMusic:SetValue(false) end
		toggleCapMusic:SetConVar("g64_cap_music")

		local rspnOnDeath = vgui.Create("DCheckBoxLabel")
		rspnOnDeath:SetText("Respawn Mario on Game Over")
		rspnOnDeath:SetTextColor(Color(0,0,0))
		rspnOnDeath:SetTooltip([[Puts you back in Mario mode after
		you run out of lives and die.]])
		if GetConVar("g64_respawn_mario_on_death"):GetBool() then rspnOnDeath:SetValue(true)
		else rspnOnDeath:SetValue(false) end
		rspnOnDeath:SetConVar("g64_respawn_mario_on_death")

		local volumeSlider = vgui.Create("DNumSlider")
		volumeSlider:SetText("Volume")
		volumeSlider:SetMin(0)
		volumeSlider:SetMax(1)
		volumeSlider:SetDecimals(2)
		volumeSlider:SetConVar("g64_global_volume")
		volumeSlider:SetDark(true)
		volumeSlider.OnValueChanged = function(panel, value)
			if libsm64 ~= nil then libsm64.SetGlobalVolume(value) end
		end

		local hudToggle = vgui.Create("DCheckBoxLabel")
		hudToggle:SetText("Enable HUD")
		hudToggle:SetTextColor(Color(0,0,0))
		hudToggle:SetTooltip([[Enables the HUD.]])
		if GetConVar("g64_hud_enable"):GetBool() then hudToggle:SetValue(true)
		else hudToggle:SetValue(false) end
		hudToggle:SetConVar("g64_hud_enable")

		local hudScaleSlider = vgui.Create("DNumSlider")
		hudScaleSlider:SetText("HUD scale")
		hudScaleSlider:SetMin(0)
		hudScaleSlider:SetMax(6)
		hudScaleSlider:SetDecimals(0)
		hudScaleSlider:SetConVar("g64_hud_scale")
		hudScaleSlider:SetDark(true)
		
		local colHeader = vgui.Create("DLabel")
		colHeader:SetText("Colors")
		colHeader:SetTextColor(Color(0,0,0))
		colHeader:SetFont("DermaDefaultBold")
		
		local colorListView = vgui.Create("DListView")
		colorListView:SetMultiSelect(false)
		colorListView:AddColumn("Body Part")
		colorListView:AddLine("Overalls")
		colorListView:AddLine("Shirt / Hat")
		colorListView:AddLine("Skin")
		colorListView:AddLine("Hair")
		colorListView:AddLine("Gloves")
		colorListView:AddLine("Shoes")
		colorListView:SetHeight(150)
		
		local colorMixer = vgui.Create("DColorMixer")
		colorMixer.ValueChanged = function(panel, color)
			local rowIndex, pan = colorListView:GetSelectedLine()
			g64config.Config.MarioColors[rowIndex] = { color.r, color.g, color.b }
			g64config.Save()
			GetConVar("g64_upd_col_flag"):SetBool(true)
		end
		
		colorListView.OnRowSelected = function(panel, rowIndex, row)
			local colTab = g64config.Config.MarioColors[rowIndex]
			colorMixer:SetColor(Color(colTab[1], colTab[2], colTab[3], 255))
		end
		colorListView:SelectFirstItem()
		
		local resetColorsButton = vgui.Create("DButton")
		resetColorsButton:SetText("Reset colors")
		resetColorsButton.DoClick = function()
			g64config.Config.MarioColors = table.Copy(g64types.DefaultMarioColors)
			local rowIndex, pan = colorListView:GetSelectedLine()
			local colTab = g64config.Config.MarioColors[rowIndex]
			colorMixer:SetColor(Color(colTab[1], colTab[2], colTab[3], 255))
			g64config.Save()
		end
		
		panel:AddItem(genHeader)
		panel:AddItem(filePathEntry)
		panel:AddItem(browseButton)
		panel:AddItem(toggleUpdates)
		panel:AddItem(toggleInterp)
		panel:AddItem(toggleCapMusic)
		panel:AddItem(rspnOnDeath)
		panel:AddItem(volumeSlider)
		panel:AddItem(hudToggle)
		panel:AddItem(hudScaleSlider)
		panel:AddItem(colHeader)
		panel:AddItem(colorListView)
		panel:AddItem(colorMixer)
		panel:AddItem(resetColorsButton)
	end)
	
	spawnmenu.AddToolMenuOption("Utilities", "G64", "G64_MusicPlayer", "#Music Player", "", "", function(panel)
		panel:ClearControls()
		g64utils.GlobalInit()
		
		local musicListView = vgui.Create("DListView")
		musicListView:SetMultiSelect(false)
		musicListView:AddColumn("Song")
		musicListView:AddLine("Star Catch Fanfare")
		musicListView:AddLine("Title Theme")
		musicListView:AddLine("Bob-Omb Battlefield")
		musicListView:AddLine("Inside the Castle Walls")
		musicListView:AddLine("Dire, Dire Docks")
		musicListView:AddLine("Lethal Lava Land")
		musicListView:AddLine("Koopa's Theme")
		musicListView:AddLine("Snow Mountain")
		musicListView:AddLine("Slider")
		musicListView:AddLine("Haunted House")
		musicListView:AddLine("Piranha Plant's Lullaby")
		musicListView:AddLine("Cave Dungeon")
		musicListView:AddLine("Star Select")
		musicListView:AddLine("Powerful Mario")
		musicListView:AddLine("Metallic Mario")
		musicListView:AddLine("Koopa's Message")
		musicListView:AddLine("Koopa's Road")
		musicListView:AddLine("High Score")
		musicListView:AddLine("Merry Go-Round")
		musicListView:AddLine("Race Fanfare")
		musicListView:AddLine("Star Spawn")
		musicListView:AddLine("Stage Boss")
		musicListView:AddLine("Koopa Clear")
		musicListView:AddLine("Looping Steps")
		musicListView:AddLine("Ultimate Koopa")
		musicListView:AddLine("Staff Roll")
		musicListView:AddLine("Correct Solution")
		musicListView:AddLine("Toad's Message")
		musicListView:AddLine("Peach's Message")
		musicListView:AddLine("Game Start")
		musicListView:AddLine("Ultimate Koopa Clear")
		musicListView:AddLine("Ending Demo")
		musicListView:AddLine("File Select")
		musicListView:AddLine("Lakitu")
		musicListView:SetHeight(400)
		function musicListView:DoDoubleClick(lineId, line)
			PlayTrack(lineId)
		end
		
		local playButton = vgui.Create("DButton")
		playButton:SetText("Play")
		playButton.DoClick = function()
			local rowIndex, pan = musicListView:GetSelectedLine()
			PlayTrack(rowIndex)
		end
		
		local stopButton = vgui.Create("DButton")
		stopButton:SetText("Stop")
		stopButton.DoClick = function()
			local rowIndex, pan = musicListView:GetSelectedLine()
			StopAllTracks()
		end
		
		panel:AddItem(musicListView)
		panel:AddItem(playButton)
		panel:AddItem(stopButton)
	end)

	spawnmenu.AddToolMenuOption("Utilities", "G64", "G64_KeyBinds", "#Key Binds", "", "", function(panel)
		panel:ClearControls()
		
		local header_forward = vgui.Create("DLabel")
		header_forward:SetText("Move forward")
		header_forward:SetTextColor(Color(0,0,0))
		local binder_forward = vgui.Create("DBinder")
		binder_forward:SetConVar("g64_forward")
		
		local header_back = vgui.Create("DLabel")
		header_back:SetText("Move back")
		header_back:SetTextColor(Color(0,0,0))
		local binder_back = vgui.Create("DBinder")
		binder_back:SetConVar("g64_back")

		local header_moveleft = vgui.Create("DLabel")
		header_moveleft:SetText("Move left")
		header_moveleft:SetTextColor(Color(0,0,0))
		local binder_moveleft = vgui.Create("DBinder")
		binder_moveleft:SetConVar("g64_moveleft")

		local header_moveright = vgui.Create("DLabel")
		header_moveright:SetText("Move right")
		header_moveright:SetTextColor(Color(0,0,0))
		local binder_moveright = vgui.Create("DBinder")
		binder_moveright:SetConVar("g64_moveright")

		local header_jump = vgui.Create("DLabel")
		header_jump:SetText("Jump")
		header_jump:SetTextColor(Color(0,0,0))
		local binder_jump = vgui.Create("DBinder")
		binder_jump:SetConVar("g64_jump")

		local header_duck = vgui.Create("DLabel")
		header_duck:SetText("Crouch")
		header_duck:SetTextColor(Color(0,0,0))
		local binder_duck = vgui.Create("DBinder")
		binder_duck:SetConVar("g64_duck")

		local header_attack = vgui.Create("DLabel")
		header_attack:SetText("Attack")
		header_attack:SetTextColor(Color(0,0,0))
		local binder_attack = vgui.Create("DBinder")
		binder_attack:SetConVar("g64_attack")

		local header_remove = vgui.Create("DLabel")
		header_remove:SetText("Remove Mario")
		header_remove:SetTextColor(Color(0,0,0))
		local binder_remove = vgui.Create("DBinder")
		binder_remove:SetConVar("g64_remove")

		local header_emotemenu = vgui.Create("DLabel")
		header_emotemenu:SetText("Emote menu")
		header_emotemenu:SetTextColor(Color(0,0,0))
		local binder_emotemenu = vgui.Create("DBinder")
		binder_emotemenu:SetConVar("g64_emotemenu")

		local header_freemove = vgui.Create("DLabel")
		header_freemove:SetText("Free move")
		header_freemove:SetTextColor(Color(0,0,0))
		local binder_freemove = vgui.Create("DBinder")
		binder_freemove:SetConVar("g64_freemove")
		
		
		panel:AddItem(header_forward)
		panel:AddItem(binder_forward)
		panel:AddItem(header_back)
		panel:AddItem(binder_back)
		panel:AddItem(header_moveleft)
		panel:AddItem(binder_moveleft)
		panel:AddItem(header_moveright)
		panel:AddItem(binder_moveright)
		panel:AddItem(header_jump)
		panel:AddItem(binder_jump)
		panel:AddItem(header_duck)
		panel:AddItem(binder_duck)
		panel:AddItem(header_attack)
		panel:AddItem(binder_attack)
		panel:AddItem(header_remove)
		panel:AddItem(binder_remove)
		panel:AddItem(header_emotemenu)
		panel:AddItem(binder_emotemenu)
		panel:AddItem(header_freemove)
		panel:AddItem(binder_freemove)
	end)

	spawnmenu.AddToolMenuOption("Utilities", "G64", "G64_Emotes", "#Emotes", "", "", function(panel)
		panel:ClearControls()
		g64emote.LoadActiveEmotes()

		local emoteStates = {}
		for i=1, #g64emote.Emotes do
			emoteStates[i] = false
		end
		for i=1, #g64emote.ActiveEmotes do
			emoteStates[g64emote.ActiveEmotes[i]] = true
		end

		local emotesHeader = vgui.Create("DLabel")
		emotesHeader:SetText("Emote List")
		emotesHeader:SetTextColor(Color(0,0,0))
		emotesHeader:SetFont("DermaDefaultBold")
		emotesHeader:SetWrap(true)
		emotesHeader:SetAutoStretchVertical(true)

		local activeHeader = vgui.Create("DLabel")
		activeHeader:SetText("Active Emotes")
		activeHeader:SetTextColor(Color(0,0,0))
		activeHeader:SetFont("DermaDefaultBold")
		activeHeader:SetWrap(true)
		activeHeader:SetAutoStretchVertical(true)
		
		local activeListView = vgui.Create("DListView")
		activeListView:SetMultiSelect(false)
		activeListView:AddColumn("Active Emote")
		activeListView:SetHeight(200)
		for i=1, #emoteStates do
			if emoteStates[i] == true then
				activeListView:AddLine(g64emote.Emotes[i].name)
			end
		end
		activeListView.RefreshList = function()
			activeListView:Clear()
			table.Empty(g64emote.ActiveEmotes)
			for i=1, #emoteStates do
				if emoteStates[i] == true then
					table.insert(g64emote.ActiveEmotes, i)
					activeListView:AddLine(g64emote.Emotes[i].name)
				end
			end
			GetConVar("g64_active_emotes"):SetString(table.concat(g64emote.ActiveEmotes, ","))
			g64emote.CalculateSegments(#g64emote.ActiveEmotes)
		end
		activeListView.OnRowSelected = function(panel, rowIndex, row)
			activeListView:ClearSelection()
		end

		local function AddActiveEmote(index)
			emoteStates[index] = not emoteStates[index]
			activeListView.RefreshList()
		end

		local emotesListView = vgui.Create("DListView")
		emotesListView:SetMultiSelect(false)
		emotesListView:AddColumn("Emote")
		for i=1, #g64emote.Emotes do
			emotesListView:AddLine(g64emote.Emotes[i].name)
		end
		emotesListView:SetHeight(400)
		function emotesListView:DoDoubleClick(lineId, line)
			AddActiveEmote(lineId)
		end

		local addButton = vgui.Create("DButton")
		addButton:SetText("Add / Remove")
		addButton.DoClick = function()
			local rowIndex, pan = emotesListView:GetSelectedLine()
			AddActiveEmote(rowIndex)
		end

		panel:AddItem(emotesHeader)
		panel:AddItem(emotesListView)
		panel:AddItem(addButton)
		panel:AddItem(activeHeader)
		panel:AddItem(activeListView)
	end)
end)

G64EntityCategories = {
	"Main",
	"Items",
	"Caps"
}

hook.Add("G64SpawnMenuPopulate", "G64_SPAWN_MENU_POPULATE", function(panel, tree, node)
	local cats = {}
	local ents = list.Get("g64_entities")

	if ents then
		for k,v in pairs(ents) do
			v.Category = v.Category or "Other Stuff"
			cats[v.Category] = cats[v.Category] or {}
			v.ClassName = k
			v.PrintName = v.Name
			table.insert(cats[v.Category], v)
		end
	end

	local entnode = tree:AddNode("Entities", "icon16/bricks.png")
	local ListPanel = vgui.Create("ContentContainer", panel)
	ListPanel:SetVisible(false)
	ListPanel:SetTriggerSpawnlistChange(false)

	entnode.DoPopulate = function(self)
		ListPanel:Clear()
		
		for k1,v1 in next, G64EntityCategories do
			local k,v = v1, cats[v1]
			local Header = vgui.Create("ContentHeader", ListPanel)
			Header:SetText(k)
			ListPanel:Add(Header)
			
			for k,ent in SortedPairsByMemberValue(v, "PrintName") do
				spawnmenu.CreateContentIcon("g64_entity", ListPanel, {
					nicename = ent.PrintName or ent.ClassName,
					spawnname = ent.ClassName,
					material = ent.Material,
					admin = false,
					icongenerator = ent.IconGenerator
				})
			end
		end
	end

	entnode.DoClick = function(self)
		self:DoPopulate()
		panel:SwitchPanel(ListPanel)
	end

	local FirstNode = tree:Root():GetChildNode(0)
	if IsValid(FirstNode) then
		FirstNode:InternalDoClick()
	end
end)

spawnmenu.AddCreationTab("G64", function()
	local contentPanel = vgui.Create("SpawnmenuContentPanel")
	contentPanel:CallPopulateHook("G64SpawnMenuPopulate")
	return contentPanel
end, "icon16/controller.png", 50, "Mario in Garry's Mod!")

local blankIconMat = Material("vgui/entities/g64_blankicon")
spawnmenu.AddContentType("g64_entity", function(container, data)
	if not data.nicename then return end
	if not data.spawnname then return end

	local icon = vgui.Create("ContentIcon", container)
	icon:SetContentType("g64_entity")
	icon:SetSpawnName(data.spawnname)
	icon:SetName(data.nicename)
	if data.material then icon:SetMaterial(data.material) end
	if data.icongenerator then
		icon.Padding = 0
		icon.Image:SetVisible(true)
		icon.Image:SetPos(0, 0)
		icon.Image:NoClipping(false)
		function icon.Image:Paint(w,h)
			g64utils.GlobalInit()
			local w2 = w - icon.Padding * 2
			local h2 = h - icon.Padding * 2
			local u0, v0 = data.icongenerator.u[1], data.icongenerator.v[1]
			local u1, v1 = data.icongenerator.u[2], data.icongenerator.v[2]

			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)

			surface.SetMaterial(blankIconMat)
			surface.DrawTexturedRect(3 + icon.Border, 3 + icon.Border, 128 - 8 - icon.Border * 2, 128 - 8 - icon.Border * 2)
			
			render.PopFilterMin()
			render.PopFilterMag()

			render.PushFilterMag(TEXFILTER.LINEAR)

			if data.icongenerator.tint then surface.SetDrawColor(data.icongenerator.tint:Unpack())
			else surface.SetDrawColor(color_white) end
			surface.SetMaterial(data.icongenerator.material)
			surface.DrawTexturedRectUV(w2*0.175+icon.Padding+3, h2*0.175+icon.Padding+3, w2*0.65, h2*0.65, u0, v0, u1, v1)
			
			render.PopFilterMag()

			icon:Paint(icon:GetSize())
		end
		function icon:PerformLayout()
			if ( self:IsDown() && !self.Dragging ) then
				self.Padding = 6
			else
				self.Padding = 0
			end
		end
	end
	icon:SetAdminOnly(data.admin and true or false)
	icon:SetColor(Color(0, 0, 0, 255))
	
	icon.DoClick = function()
		RunConsoleCommand("gm_spawnsent", data.spawnname)
		surface.PlaySound("ui/buttonclickrelease.wav")
	end
	
	icon.OpenMenu = function(icon)
		local menu = DermaMenu()
			menu:AddOption("Copy to clipboard", function() 
				SetClipboardText(data.spawnname) 
			end):SetIcon("icon16/page_copy.png")
			menu:AddOption("Spawn using toolgun", function() 
				RunConsoleCommand("gmod_tool", "creator") 
				RunConsoleCommand("creator_type", "0") 
				RunConsoleCommand("creator_name", data.spawnname) 
			end):SetIcon("icon16/brick_add.png")
		menu:Open()
	end
	
	if IsValid(container) then
		container:Add(icon)
	end

	return icon
end)