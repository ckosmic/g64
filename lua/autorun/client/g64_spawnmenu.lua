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
		if GetConVar("g64_interpolation"):GetBool() then toggleCapMusic:SetValue(true)
		else toggleCapMusic:SetValue(false) end
		toggleCapMusic:SetConVar("g64_cap_music")

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
		panel:AddItem(volumeSlider)
		panel:AddItem(colHeader)
		panel:AddItem(colorListView)
		panel:AddItem(colorMixer)
		panel:AddItem(resetColorsButton)
	end)
	
	spawnmenu.AddToolMenuOption("Utilities", "G64", "G64_MusicPlayer", "#Music Player", "", "", function(panel)
		panel:ClearControls()
		
		local musicHeader = vgui.Create("DLabel")
		musicHeader:SetText("Uh what")
		musicHeader:SetTextColor(Color(0,0,0))
		musicHeader:SetFont("DermaDefaultBold")
		musicHeader:SetWrap(true)
		musicHeader:SetAutoStretchVertical(true)
		
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
			--print(libsm64.GetCurrentMusic())
			local rowIndex, pan = musicListView:GetSelectedLine()
			PlayTrack(rowIndex)
		end
		
		local stopButton = vgui.Create("DButton")
		stopButton:SetText("Stop")
		stopButton.DoClick = function()
			local rowIndex, pan = musicListView:GetSelectedLine()
			StopAllTracks()
		end
		
		function musicHeader:Paint(w,h)
			if libsm64 ~= nil and libsm64.ModuleLoaded == true and libsm64.IsGlobalInit() then
				self:SetText("Initialized.")
				self:SetColor(Color(30, 200, 30))
				stopButton:SetEnabled(true)
				playButton:SetEnabled(true)
			else
				self:SetText("Not initialized. Please spawn Mario at least once to use the music player.")
				self:SetColor(Color(255, 30, 30))
				stopButton:SetEnabled(false)
				playButton:SetEnabled(false)
			end
		end
		
		panel:AddItem(musicHeader)
		panel:AddItem(musicListView)
		panel:AddItem(playButton)
		panel:AddItem(stopButton)
	end)
end)