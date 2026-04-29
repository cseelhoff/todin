package game

Battle_Tracker :: struct {
	pending_battles:                       map[^I_Battle]struct{},
	dependencies:                          map[^I_Battle]map[^I_Battle]struct{},
	conquered:                             map[^Territory]struct{},
	blitzed:                               map[^Territory]struct{},
	fought_battles:                        map[^Territory]struct{},
	finished_battles_unit_attack_from_map: map[^Territory]map[^Territory][dynamic]^Unit,
	no_bombard_allowed:                    map[^Territory]struct{},
	defending_air_that_can_not_land:       map[^Territory][dynamic]^Unit,
	battle_records:                        ^Battle_Records,
	relationship_changes_this_turn:        [dynamic]^Tuple(rawptr, rawptr),
}

