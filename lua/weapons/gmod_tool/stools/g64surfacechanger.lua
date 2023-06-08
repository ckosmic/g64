AddCSLuaFile()

include("includes/g64_types.lua")

TOOL.Category = "G64"
TOOL.Name = "#tool.g64surfacechanger.name"

TOOL.Information = { { name = "left" } }

TOOL.ClientConVar[ "g64surfacetype" ] = g64types.SM64SurfaceType.SURFACE_DEFAULT
TOOL.ClientConVar[ "g64terraintype" ] = g64types.SM64TerrainType.TERRAIN_STONE

local function SetSurfaceInfo( ply, ent, data )
	if data.SurfaceType then ent.G64SurfaceType = data.SurfaceType end
	if data.TerrainType then ent.G64TerrainType = data.TerrainType end
	
	if SERVER then 
		duplicator.StoreEntityModifier( ent, "g64_surfaceinfo", data )
		
		local filter = RecipientFilter()
		filter:AddAllPlayers()
		net.Start("G64_CHANGESURFACEINFO")
			net.WriteEntity(ent)
			net.WriteInt(data.SurfaceType, 16)
			net.WriteUInt(data.TerrainType, 16)
		net.Send(filter)
	end
end
duplicator.RegisterEntityModifier( "g64_surfaceinfo", SetSurfaceInfo )

function TOOL:LeftClick( trace )
	local ent = trace.Entity
	if IsValid( ent ) and (ent:IsPlayer() or ent == Entity(0)) then return end
	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return end
	if CLIENT then return true end
	
	local surf = self:GetClientNumber( "g64surfacetype", g64types.SM64SurfaceType.SURFACE_DEFAULT )
	local terr = self:GetClientNumber( "g64terraintype", g64types.SM64TerrainType.TERRAIN_STONE )
	
	SetSurfaceInfo( self:GetOwner(), ent, { SurfaceType = surf, TerrainType = terr } )
	return true
end

function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Description = "#tool.g64surfacechanger.desc" } )

	CPanel:AddControl( "ListBox", { Label = "#tool.g64surfacechanger.surf", Options = list.Get( "SurfaceTypes" ) } )
	CPanel:AddControl( "ListBox", { Label = "#tool.g64surfacechanger.terr", Options = list.Get( "TerrainTypes" ) } )

end

list.Set( "TerrainTypes", "#tool.g64surfacechanger.stone", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_STONE } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.grass", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_GRASS } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.snow", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_SNOW } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.sand", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_SAND } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.spooky", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_SPOOKY } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.water", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_WATER } ) 
list.Set( "TerrainTypes", "#tool.g64surfacechanger.slide", { g64surfacechanger_g64terraintype = g64types.SM64TerrainType.TERRAIN_SLIDE } ) 

list.Set( "SurfaceTypes", "#tool.g64surfacechanger.default", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_DEFAULT } )         	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.burning", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_BURNING } )         	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hangable", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HANGABLE } )        	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.slow", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_SLOW } )            	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.very_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_VERY_SLIPPERY } )    	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_SLIPPERY } )        	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.not_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_NOT_SLIPPERY } )     	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.shallow_quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_SHALLOW_QUICKSAND } ) 	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_QUICKSAND } )   
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.deep_quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_DEEP_QUICKSAND } )  	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.instant_quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_INSTANT_QUICKSAND } )	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.ice", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_ICE } )             	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD } )            	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_SLIPPERY } )    	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_very_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_VERY_SLIPPERY } )	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_not_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_NOT_SLIPPERY } ) 	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.vertical_wind", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_VERTICAL_WIND } )  
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.horizontal_wind", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HORIZONTAL_WIND } )  
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.noise_default", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_NOISE_DEFAULT } )
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.vanish_cap_walls", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_VANISH_CAP_WALLS } )  