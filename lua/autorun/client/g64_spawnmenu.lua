AddCSLuaFile()

include("g64/g64_types.lua")
include("g64/g64_config.lua")

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
		
		local toggleInterp = vgui.Create("DCheckBoxLabel")
		toggleInterp:SetText("Enable interpolation")
		toggleInterp:SetTextColor(Color(0,0,0))
		toggleInterp:SetTooltip([[Makes Mario's mesh and position smoother but will
		cause artifacts and may lead to slightly worse performance]])
		if(g64config.Config.Interpolation == 1) then toggleInterp:SetValue(true)
		else toggleInterp:SetValue(false) end
		toggleInterp.OnChange = function(panel, val)
			if(val == true) then g64config.Config.Interpolation = 1
			else g64config.Config.Interpolation = 0 end
			g64config.Save()
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
		end
		
		colorListView.OnRowSelected = function(panel, rowIndex, row)
			local colTab = g64config.Config.MarioColors[rowIndex]
			colorMixer:SetColor(Color(colTab[1], colTab[2], colTab[3], 255))
		end
		colorListView:SelectFirstItem()
		
		local resetColorsButton = vgui.Create("DButton")
		resetColorsButton:SetText("Reset colors")
		resetColorsButton.DoClick = function()
			g64config.Config.MarioColors = table.Copy(sm64types.DefaultMarioColors)
			local rowIndex, pan = colorListView:GetSelectedLine()
			local colTab = g64config.Config.MarioColors[rowIndex]
			colorMixer:SetColor(Color(colTab[1], colTab[2], colTab[3], 255))
			g64config.Save()
		end
		
		panel:AddItem(genHeader)
		panel:AddItem(toggleInterp)
		panel:AddItem(colHeader)
		panel:AddItem(colorListView)
		panel:AddItem(colorMixer)
		panel:AddItem(resetColorsButton)
	end)
end)