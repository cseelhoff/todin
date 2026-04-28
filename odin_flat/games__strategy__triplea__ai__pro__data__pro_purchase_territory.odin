package game

Pro_Purchase_Territory :: struct {
	territory:             ^Territory,
	unit_production:       i32,
	can_place_territories: [dynamic]^Pro_Place_Territory,
}

