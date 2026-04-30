package game

Pro_Purchase_Territory :: struct {
	territory:             ^Territory,
	unit_production:       i32,
	can_place_territories: [dynamic]^Pro_Place_Territory,
}

pro_purchase_territory_get_territory :: proc(self: ^Pro_Purchase_Territory) -> ^Territory {
	return self.territory
}

pro_purchase_territory_get_unit_production :: proc(self: ^Pro_Purchase_Territory) -> i32 {
	return self.unit_production
}

pro_purchase_territory_set_unit_production :: proc(self: ^Pro_Purchase_Territory, unit_production: i32) {
	self.unit_production = unit_production
}

pro_purchase_territory_get_can_place_territories :: proc(self: ^Pro_Purchase_Territory) -> [dynamic]^Pro_Place_Territory {
	return self.can_place_territories
}

