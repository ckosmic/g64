AddCSLuaFile()

CreateConVar("g64_vanishcap_timer", "600", FCVAR_CHEAT, "Timer for the vanish cap (default: 600)", 0, 65535)
CreateConVar("g64_metalcap_timer", "600", FCVAR_CHEAT, "Timer for the metal cap (default: 600)", 0, 65535)
CreateConVar("g64_wingcap_timer", "1800", FCVAR_CHEAT, "Timer for the wing cap (default: 1800)", 0, 65535)
CreateConVar("g64_process_displacements", "1", FCVAR_CHEAT)
CreateConVar("g64_process_static_props", "1", FCVAR_CHEAT)
CreateConVar("g64_scale_factor", "2.5", bit.bor(FCVAR_CHEAT, FCVAR_REPLICATED), "The scale factor of Mario (default: 2.5)", 0.1, 8)
CreateConVar("g64_respawn_mario_on_death", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_USERINFO))

if CLIENT then
    CreateClientConVar("g64_debug_collision", "0", true, false)
	CreateClientConVar("g64_debug_rays", "0", true, false)
	CreateClientConVar("g64_interpolation", "1", true, false)
	CreateClientConVar("g64_rompath", "", true, false)
	CreateClientConVar("g64_lib_version", "", true, false)
	CreateClientConVar("g64_upd_col_flag", "0", true, false)
	CreateClientConVar("g64_cap_music", "1", true, false)
	CreateClientConVar("g64_global_volume", "1.0", true, false, "", 0.0, 1.0)
	CreateClientConVar("g64_auto_update", "1", true, false)
	CreateClientConVar("g64_active_emotes", "", true, false)
    CreateClientConVar("g64_disable_cache", "0", true, false)
	CreateClientConVar("g64_hud_scale", "4", true, false)
	CreateClientConVar("g64_hud_enable", "1", true, false)

	CreateClientConVar("g64_forward", KEY_W, true)
	CreateClientConVar("g64_back", KEY_S, true)
	CreateClientConVar("g64_moveleft", KEY_A, true)
	CreateClientConVar("g64_moveright", KEY_D, true)
	CreateClientConVar("g64_jump", KEY_SPACE, true)
	CreateClientConVar("g64_duck", KEY_LCONTROL, true)
	CreateClientConVar("g64_attack", MOUSE_LEFT, true)
	CreateClientConVar("g64_pickup", MOUSE_RIGHT, true)
	CreateClientConVar("g64_remove", KEY_R, true)
	CreateClientConVar("g64_emotemenu", KEY_LALT, true)
	CreateClientConVar("g64_freemove", KEY_V, true)

	CreateClientConVar("g64_gp_sensitivity", "75", true, false)
else
	local function fixupProp( ply, ent, hitpos, mins, maxs )
		local entPos = ent:GetPos()
		local endposD = ent:LocalToWorld( mins )
		local tr_down = util.TraceLine( {
			start = entPos,
			endpos = endposD,
			filter = { ent, ply }
		} )
	
		local endposU = ent:LocalToWorld( maxs )
		local tr_up = util.TraceLine( {
			start = entPos,
			endpos = endposU,
			filter = { ent, ply }
		} )
	
		-- Both traces hit meaning we are probably inside a wall on both sides, do nothing
		if ( tr_up.Hit && tr_down.Hit ) then return end
	
		if ( tr_down.Hit ) then ent:SetPos( entPos + ( tr_down.HitPos - endposD ) ) end
		if ( tr_up.Hit ) then ent:SetPos( entPos + ( tr_up.HitPos - endposU ) ) end
	end

	local function TryFixPropPosition( ply, ent, hitpos )
		fixupProp( ply, ent, hitpos, Vector( ent:OBBMins().x, 0, 0 ), Vector( ent:OBBMaxs().x, 0, 0 ) )
		fixupProp( ply, ent, hitpos, Vector( 0, ent:OBBMins().y, 0 ), Vector( 0, ent:OBBMaxs().y, 0 ) )
		fixupProp( ply, ent, hitpos, Vector( 0, 0, ent:OBBMins().z ), Vector( 0, 0, ent:OBBMaxs().z ) )
	end

	local function CanPlayerSpawnSENT( ply, EntityName )

		--local isAdmin = ( IsValid( ply ) && ply:IsAdmin() ) || game.SinglePlayer()
	
		-- Make sure this is a SWEP
		local sent = scripted_ents.GetStored( EntityName )
		if ( sent == nil ) then
	
			-- Is this in the SpawnableEntities list?
			local SpawnableEntities = list.Get( "SpawnableG64Entities" )
			if ( !SpawnableEntities ) then return false end
			local EntTable = SpawnableEntities[ EntityName ]
			if ( !EntTable ) then return false end
			--if ( EntTable.AdminOnly && !isAdmin ) then return false end
			return true
	
		end
	
		-- We need a spawn function. The SENT can then spawn itself properly
		local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )
		if ( !isfunction( SpawnFunction ) ) then return false end
	
		-- You're not allowed to spawn this unless you're an admin!
		--if ( !scripted_ents.GetMember( EntityName, "G64Spawnable" ) && !isAdmin ) then return false end
		--if ( scripted_ents.GetMember( EntityName, "AdminOnly" ) && !isAdmin ) then return false end
	
		return true
	
	end
	
	--[[---------------------------------------------------------
		Name: Spawn_SENT
		Desc: Console Command for a player to spawn different items
	-----------------------------------------------------------]]
	local function G64_Spawn_SENT( ply, EntityName, tr )
		print(ply, EntityName)
	
		-- We don't support this command from dedicated server console
		if ( !IsValid( ply ) ) then return end
	
		if ( EntityName == nil ) then return end
	
		if ( !CanPlayerSpawnSENT( ply, EntityName ) ) then return end
	
		-- Ask the gamemode if it's ok to spawn this
		if ( !gamemode.Call( "PlayerSpawnSENT", ply, EntityName ) ) then return end
	
		if ( !tr ) then
	
			local vStart = ply:EyePos()
			local vForward = ply:GetAimVector()
	
			tr = util.TraceLine( {
				start = vStart,
				endpos = vStart + ( vForward * 4096 ),
				filter = ply
			} )
	
		end
	
		local entity = nil
		local PrintName = nil
		local sent = scripted_ents.GetStored( EntityName )
	
		if ( sent ) then
	
			local sent = sent.t
	
			ClassName = EntityName
	
				local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )
				if ( !SpawnFunction ) then return end -- Fallback to default behavior below?
	
				entity = SpawnFunction( sent, ply, tr, EntityName )
	
				if ( IsValid( entity ) ) then
					entity:SetCreator( ply )
				end
	
			ClassName = nil
	
			PrintName = sent.PrintName
	
		else
	
			-- Spawn from list table
			local SpawnableEntities = list.Get( "SpawnableG64Entities" )
			if ( !SpawnableEntities ) then return end
	
			local EntTable = SpawnableEntities[ EntityName ]
			if ( !EntTable ) then return end
	
			PrintName = EntTable.PrintName
	
			local SpawnPos = tr.HitPos + tr.HitNormal * 16
			if ( EntTable.NormalOffset ) then SpawnPos = SpawnPos + tr.HitNormal * EntTable.NormalOffset end
	
			-- Make sure the spawn position is not out of bounds
			local oobTr = util.TraceLine( {
				start = tr.HitPos,
				endpos = SpawnPos,
				mask = MASK_SOLID_BRUSHONLY
			} )
	
			if ( oobTr.Hit ) then
				SpawnPos = oobTr.HitPos + oobTr.HitNormal * ( tr.HitPos:Distance( oobTr.HitPos ) / 2 )
			end
	
			entity = ents.Create( EntTable.ClassName )
			entity:SetPos( SpawnPos )
	
			if ( EntTable.KeyValues ) then
				for k, v in pairs( EntTable.KeyValues ) do
					entity:SetKeyValue( k, v )
				end
			end
	
			if ( EntTable.Material ) then
				entity:SetMaterial( EntTable.Material )
			end
	
			entity:Spawn()
			entity:Activate()
	
			DoPropSpawnedEffect( entity )
	
			if ( EntTable.DropToFloor ) then
				entity:DropToFloor()
			end
	
		end
	
		if ( !IsValid( entity ) ) then return end
	
		TryFixPropPosition( ply, entity, tr.HitPos )
	
		if ( IsValid( ply ) ) then
			gamemode.Call( "PlayerSpawnedSENT", ply, entity )
		end
	
		undo.Create( "SENT" )
			undo.SetPlayer( ply )
			undo.AddEntity( entity )
			if ( PrintName ) then
				undo.SetCustomUndoText( "Undone " .. PrintName )
			end
		undo.Finish( "Scripted Entity (" .. tostring( EntityName ) .. ")" )
	
		ply:AddCleanup( "sents", entity )
		entity:SetVar( "Player", ply )
	
	end
	concommand.Add( "g64_spawnsent", function( ply, cmd, args ) G64_Spawn_SENT( ply, args[ 1 ] ) end)
end

function RegisterG64Entity(t, name)
	list.Set("SpawnableG64Entities", name, {
		PrintName = t.PrintName,
		ClassName = name,
		Category = t.Category,
		G64Spawnable = t.G64Spawnable,

		NormalOffset	= t.NormalOffset,
		DropToFloor		= t.DropToFloor,
		Author			= t.Author,
		AdminOnly		= t.AdminOnly,
		Information		= t.Information,
		ScriptedEntityType = t.ScriptedEntityType,
		IconOverride	= t.IconOverride
	})
end