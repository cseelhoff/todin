package game

Move_Description :: struct {
	using abstract_move_description: Abstract_Move_Description,
	route: ^Route,
	units_to_sea_transports: map[^Unit]^Unit,
	air_transports_dependents: map[^Unit]map[^Unit]struct{},
}

