include("includes/g64_types.lua")

TOOL.Category = "G64"
TOOL.Name = "#tool.g64surfacechanger.name"

TOOL.Information = { { name = "left" } }

TOOL.ClientConVar[ "g64surfacetype" ] = g64types.SM64SurfaceType.SURFACE_DEFAULT
TOOL.ClientConVar[ "g64terraintype" ] = g64types.SM64TerrainType.TERRAIN_STONE

if ( CLIENT ) then
	language.Add( "tool.g64surfacechanger.name", "Surface Changer" )
	language.Add( "tool.g64surfacechanger.desc", "Change the G64 surface of an object" )
	language.Add( "tool.g64surfacechanger.surf", "Surface type" )
	language.Add( "tool.g64surfacechanger.terr", "Terrain type" )
	language.Add( "tool.g64surfacechanger.left", "Apply selected Surface / Terrain Type to an object" )
	
	language.Add( "tool.g64surfacechanger.stone", "Stone" )
	language.Add( "tool.g64surfacechanger.grass", "Grass" )
	language.Add( "tool.g64surfacechanger.snow", "Snow" )
	language.Add( "tool.g64surfacechanger.sand", "Sand" )
	language.Add( "tool.g64surfacechanger.spooky", "Spooky" )
	language.Add( "tool.g64surfacechanger.water", "Water" )
	language.Add( "tool.g64surfacechanger.slide", "Slide" )
	
	language.Add( "tool.g64surfacechanger.default", "Default" )
	language.Add( "tool.g64surfacechanger.burning", "Burning" )
	language.Add( "tool.g64surfacechanger.hangable", "Hangable" )
	language.Add( "tool.g64surfacechanger.slow", "Slow" )
	language.Add( "tool.g64surfacechanger.very_slippery", "Very Slippery" )
	language.Add( "tool.g64surfacechanger.slippery", "Slippery" )
	language.Add( "tool.g64surfacechanger.not_slippery", "Not Slippery" )
	language.Add( "tool.g64surfacechanger.shallow_quicksand", "Shallow Quicksand" )
	language.Add( "tool.g64surfacechanger.deep_quicksand", "Deep Quicksand" )
	language.Add( "tool.g64surfacechanger.instant_quicksand", "Instant Quicksand" )
	language.Add( "tool.g64surfacechanger.ice", "Ice" )
	language.Add( "tool.g64surfacechanger.hard", "Hard" )
	language.Add( "tool.g64surfacechanger.hard_slippery", "Hard Slippery" )
	language.Add( "tool.g64surfacechanger.hard_very_slippery", "Hard Very Slippery" )
	language.Add( "tool.g64surfacechanger.hard_not_slippery", "Hard Not Slippery" )
	language.Add( "tool.g64surfacechanger.vertical_wind", "Vertical Wind" )
end

local function SetSurfaceInfo( ply, ent, data )
	if( data.SurfaceType ) then ent.G64SurfaceType = data.SurfaceType end
	if( data.TerrainType ) then ent.G64TerrainType = data.TerrainType end
	
	if( SERVER ) then 
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
	if ( IsValid( ent ) && (ent:IsPlayer() || ent == Entity(0)) ) then return end
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return end
	if ( CLIENT ) then return true end
	
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
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.deep_quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_DEEP_QUICKSAND } )  	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.instant_quicksand", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_INSTANT_QUICKSAND } )	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.ice", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_ICE } )             	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD } )            	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_SLIPPERY } )    	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_very_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_VERY_SLIPPERY } )	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.hard_not_slippery", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_HARD_NOT_SLIPPERY } ) 	
list.Set( "SurfaceTypes", "#tool.g64surfacechanger.vertical_wind", { g64surfacechanger_g64surfacetype = g64types.SM64SurfaceType.SURFACE_VERTICAL_WIND } )     	