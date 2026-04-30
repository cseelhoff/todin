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

