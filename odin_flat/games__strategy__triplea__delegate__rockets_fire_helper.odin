package game

Rockets_Fire_Helper :: struct {
	attacking_from_territories:  map[^Territory]struct{},
	attacked_territories:        map[^Territory]^Territory,
	attacked_units:              map[^Territory]^Unit,
	need_to_find_rocket_targets: bool,
}

