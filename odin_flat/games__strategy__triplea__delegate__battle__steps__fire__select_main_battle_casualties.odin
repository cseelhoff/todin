package game

Select_Main_Battle_Casualties :: struct {
	select_function: ^Select_Main_Battle_Casualties_Select,
}

// Java: lambda$limitTransportsToSelect$0(GamePlayer)
// Source: alliedHitPlayer.computeIfAbsent(unit.getOwner(), (owner) -> new ArrayList<>())
select_main_battle_casualties_lambda_limit_transports_to_select_0 :: proc(owner: ^Game_Player) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

