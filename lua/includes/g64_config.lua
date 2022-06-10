AddCSLuaFile()

if SERVER then return end

g64config = {}
g64config.ConVars = {}

g64config.Config = {
	MarioColors = {
		{0  , 0  , 255},
		{255, 0  , 0  },
		{254, 193, 121},
		{114, 28 , 14 },
		{255, 255, 255},
		{115, 6  , 0  },
	}
}

g64config.Save = function()
	local json = util.TableToJSON(g64config.Config, true)
	file.CreateDir("g64")
	file.Write("g64/config.json", json)
end

g64config.Load = function()
	if file.Exists("g64/config.json", "DATA") then
		local json = file.Read("g64/config.json", "DATA")
		local loaded = util.JSONToTable(json)
		local loadedKeys = table.GetKeys(loaded)
		local defaultKeys = table.GetKeys(g64config.Config)
		local dirty = false
		for i = 1, #defaultKeys do
			if not table.HasValue(loadedKeys, defaultKeys[i]) then
				table.insert(loaded, g64config.Config[defaultKeys[i]])
				dirty = true
			end
		end
		for i = 1, #loadedKeys do
			if not table.HasValue(defaultKeys, loadedKeys[i]) then
				loaded[loadedKeys[i]] = nil
				dirty = true
			end
		end
		if dirty then
			g64config.Save()
		end
		g64config.Config = loaded
	else
		g64config.Save()
	end
	return g64config.Config
end