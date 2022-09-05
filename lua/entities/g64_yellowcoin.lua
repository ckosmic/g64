AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"

ENT.Category = "G64"
ENT.PrintName = "Coin"
ENT.Author = "ckosmic"
ENT.Spawnable = false
ENT.AdminSpawnable = true
ENT.AdminOnly = false

ENT.CoinColor = Color(255, 255, 0)
ENT.CoinValue = 1

RegisterG64Entity(ENT, "g64_yellowcoin")

include("entities/g64_coin.lua")
include("includes/g64_utils.lua")

list.Set("g64_entities", "g64_yellowcoin", {
    Category = "Items",
    Name = "Coin",
    Material = "",
    IconGenerator = {
        material = g64utils.CoinMat,
        u = { 1*0.25, 1*0.25+0.25 },
        v = { 0, 1 },
        tint = Color(255, 255, 0)
    }
})