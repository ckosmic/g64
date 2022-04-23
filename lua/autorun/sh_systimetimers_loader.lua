if SERVER then
  require("systimetimers")
  AddCSLuaFile("includes/modules/systimetimers.lua")
elseif CLIENT then
  require("systimetimers")
end
