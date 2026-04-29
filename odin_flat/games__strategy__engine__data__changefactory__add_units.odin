package game

Add_Units :: struct {
	using change: Change,
	name:           string,
	units:          [dynamic]^Unit,
	type:           string,
	unit_owner_map: map[Uuid]string,
}

