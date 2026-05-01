package game

Map_Territory :: struct {
	name:  string,
	water: bool,
}

map_territory_get_name :: proc(self: ^Map_Territory) -> string {
	return self.name
}

map_territory_get_water :: proc(self: ^Map_Territory) -> bool {
	return self.water
}

