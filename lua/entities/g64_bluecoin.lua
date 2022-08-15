AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.PrintName = "Blue Coin"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "G64"

ENT.CoinColor = Color(120, 120, 255)
ENT.CoinValue = 5

include("entities/g64_coin.lua")
include("includes/g64_utils.lua")

list.Set("g64_entities", "g64_bluecoin", {
    Category = "Items",
    Name = "Blue Coin",
    Material = "",
    IconGenerator = {
        material = g64utils.CoinMat,
        u = { 1*0.25, 1*0.25+0.25 },
        v = { 0, 1 },
        tint = Color(120, 120, 255)
    }
})
