AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.Category = "G64"
ENT.PrintName = "Red Coin"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.AdminOnly = false

ENT.CoinColor = Color(255, 0, 0)
ENT.CoinValue = 2

RegisterG64Entity(ENT, "g64_redcoin")

include("entities/g64_coin.lua")
include("includes/g64_utils.lua")

list.Set("g64_entities", "g64_redcoin", {
    Category = "Items",
    Name = "Red Coin",
    Material = "",
    IconGenerator = {
        material = g64utils.CoinMat,
        u = { 1*0.25, 1*0.25+0.25 },
        v = { 0, 1 },
        tint = Color(255, 0, 0)
    }
})
