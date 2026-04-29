package game

Land_Paratroopers :: struct {
	using parent: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

Land_Paratroopers_Transports_And_Paratroopers :: struct {
	air_transports: [dynamic]^Unit,
	paratroopers:   [dynamic]^Unit,
}
