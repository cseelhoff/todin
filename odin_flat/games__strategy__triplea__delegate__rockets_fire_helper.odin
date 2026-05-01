package game

Rockets_Fire_Helper :: struct {
	attacking_from_territories:  map[^Territory]struct{},
	attacked_territories:        map[^Territory]^Territory,
	attacked_units:              map[^Territory]^Unit,
	need_to_find_rocket_targets: bool,
}

rockets_fire_helper_new :: proc() -> ^Rockets_Fire_Helper {
	helper := new(Rockets_Fire_Helper)
	helper.attacking_from_territories = make(map[^Territory]struct{})
	helper.attacked_territories = make(map[^Territory]^Territory)
	helper.attacked_units = make(map[^Territory]^Unit)
	helper.need_to_find_rocket_targets = false
	return helper
}

