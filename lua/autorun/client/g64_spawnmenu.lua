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
			if(!isnumber(filePath)) then
				GetConVar("g64_rompath"):SetString(filePath)
				filePathEntry:SetValue(filePath)
			else
				if(filePath == 0) then
					chat.AddText(Color(255, 100, 100), "[G64] Failed to open file.")
				elseif(filePath == 1) then
					chat.AddText(Color(255, 100, 100), "[G64] File browser unsupported on non-windows computers.")
				end
			end
		end
		
		local toggleInterp = vgui.Create("DCheckBoxLabel")
		toggleInterp:SetText("Enable mesh interpolation")
		toggleInterp:SetTextColor(Color(0,0,0))
		toggleInterp:SetTooltip([[Makes Mario's mesh move smoother but will
		cause artifacts and may lead to a slight performance drop.]])
		if(GetConVar("g64_interpolation"):GetBool()) then toggleInterp:SetValue(true)
		else toggleInterp:SetValue(false) end
		toggleInterp:SetConVar("g64_interpolation")
		
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
		panel:AddItem(toggleInterp)
		panel:AddItem(colHeader)
		panel:AddItem(colorListView)
		panel:AddItem(colorMixer)
		panel:AddItem(resetColorsButton)
	end)
end)