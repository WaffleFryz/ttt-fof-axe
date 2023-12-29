hook.Add("PlayerLoadout", "ReplaceCrowbar", function(ply)
	if(ply:HasWeapon("weapon_ttt_fof_fists")) then
		ply:Give("weapon_ttt_fof_axe")
	else
		ply:StripWeapon("weapon_zm_improvised")
		ply:Give("weapon_ttt_fof_fists")
	end
end)

-- Allows player to pickup axe when they have fists
hook.Add("PlayerCanPickupWeapon", "PickupAxe", function( ply, weapon )
    if ((ply:HasWeapon("weapon_ttt_fof_fists") or ply:HasWeapon("weapon_ttt_fof_brass"))
		and weapon:GetClass() == "weapon_ttt_fof_axe") then
			return true
	end
end)

-- Replace Fists with Brass
hook.Add("PlayerCanPickupWeapon", "ReplaceFistsWithBrass", function( ply, weapon )
    if ply:HasWeapon("weapon_ttt_fof_fists") and weapon:GetClass() == "weapon_ttt_fof_brass" then
		return true
	end
end)