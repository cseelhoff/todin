package game

Pro_Place_Territory :: struct {
	territory:         ^Territory,
	place_units:       [dynamic]^Unit,
	defending_units:   [dynamic]^Unit,
	min_battle_result: ^Pro_Battle_Result,
	defense_value:     f64,
	strategic_value:   f64,
	can_hold:          bool,
}

pro_place_territory_can_equal :: proc(self: ^Pro_Place_Territory, other: rawptr) -> bool {
	return other != nil
}

pro_place_territory_get_territory :: proc(self: ^Pro_Place_Territory) -> ^Territory {
	return self.territory
}

pro_place_territory_get_place_units :: proc(self: ^Pro_Place_Territory) -> [dynamic]^Unit {
	return self.place_units
}

pro_place_territory_get_defending_units :: proc(self: ^Pro_Place_Territory) -> [dynamic]^Unit {
	return self.defending_units
}

pro_place_territory_get_min_battle_result :: proc(self: ^Pro_Place_Territory) -> ^Pro_Battle_Result {
	return self.min_battle_result
}

pro_place_territory_get_defense_value :: proc(self: ^Pro_Place_Territory) -> f64 {
	return self.defense_value
}

pro_place_territory_get_strategic_value :: proc(self: ^Pro_Place_Territory) -> f64 {
	return self.strategic_value
}

pro_place_territory_is_can_hold :: proc(self: ^Pro_Place_Territory) -> bool {
	return self.can_hold
}

pro_place_territory_set_defending_units :: proc(self: ^Pro_Place_Territory, defending_units: [dynamic]^Unit) {
	self.defending_units = defending_units
}

pro_place_territory_set_min_battle_result :: proc(self: ^Pro_Place_Territory, min_battle_result: ^Pro_Battle_Result) {
	self.min_battle_result = min_battle_result
}

pro_place_territory_set_defense_value :: proc(self: ^Pro_Place_Territory, defense_value: f64) {
	self.defense_value = defense_value
}

pro_place_territory_set_strategic_value :: proc(self: ^Pro_Place_Territory, strategic_value: f64) {
	self.strategic_value = strategic_value
}

pro_place_territory_set_can_hold :: proc(self: ^Pro_Place_Territory, can_hold: bool) {
	self.can_hold = can_hold
}

pro_place_territory_equals :: proc(self: ^Pro_Place_Territory, other: ^Pro_Place_Territory) -> bool {
	if self == other {
		return true
	}
	if self == nil || other == nil {
		return false
	}
	return self.territory == other.territory
}

pro_place_territory_to_string :: proc(self: ^Pro_Place_Territory) -> string {
	return territory_to_string(self.territory)
}

