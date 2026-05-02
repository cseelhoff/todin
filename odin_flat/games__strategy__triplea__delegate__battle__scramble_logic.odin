package game

Scramble_Logic :: struct {
	data:                                ^Game_State,
	player:                              ^Game_Player,
	territories_with_battles:            map[^Territory]struct{},
	battle_tracker:                      ^Battle_Tracker,
	airbase_that_can_scramble_predicate: proc(u: ^Unit) -> bool,
	can_scramble_from_predicate:         proc(t: ^Territory) -> bool,
	max_scramble_distance:               i32,
}
// One file per Java class. Replace this header when the
// class's structs and procs are fully ported.
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.ScrambleLogic

scramble_logic_get_airbase_that_can_scramble_predicate :: proc(self: ^Scramble_Logic) -> proc(u: ^Unit) -> bool {
	return self.airbase_that_can_scramble_predicate
}

// private static int computeMaxScrambleDistance(final GameState data)
scramble_logic_compute_max_scramble_distance :: proc(data: ^Game_State) -> i32 {
	max_scramble_distance: i32 = 0
	for ut in unit_type_list_iterator(game_state_get_unit_type_list(data)) {
		ua := unit_type_get_unit_attachment(ut)
		if unit_attachment_can_scramble(ua) &&
		   max_scramble_distance < unit_attachment_get_max_scramble_distance(ua) {
			max_scramble_distance = unit_attachment_get_max_scramble_distance(ua)
		}
	}
	return max_scramble_distance
}

// public static int getMaxScrambleCount(final Collection<Unit> airbases)
scramble_logic_get_max_scramble_count :: proc(airbases: [dynamic]^Unit) -> i32 {
	is_air_base_fn, is_air_base_ctx := matches_unit_is_air_base()
	not_disabled_fn, not_disabled_ctx := matches_unit_is_not_disabled()
	if len(airbases) == 0 {
		panic("All units must be viable airbases")
	}
	for u in airbases {
		if !is_air_base_fn(is_air_base_ctx, u) || !not_disabled_fn(not_disabled_ctx, u) {
			panic("All units must be viable airbases")
		}
	}
	max_scrambled: i32 = 0
	for airbase in airbases {
		base_max := unit_get_max_scramble_count(airbase)
		if base_max == -1 {
			return max(i32)
		}
		max_scrambled += base_max
	}
	return max_scrambled
}

