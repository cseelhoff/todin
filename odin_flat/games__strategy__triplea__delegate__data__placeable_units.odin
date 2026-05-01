package game

Placeable_Units :: struct {
	error_message: string,
	units:         [dynamic]^Unit,
	max_units:     i32,
	has_error:     bool,
}

placeable_units_init_error :: proc(self: ^Placeable_Units, error_message: string) {
	self.error_message = error_message
	self.units = make([dynamic]^Unit)
	self.max_units = 0
	self.has_error = true
}

placeable_units_init_units :: proc(self: ^Placeable_Units, units: [dynamic]^Unit, max_units: i32) {
	self.error_message = ""
	self.units = units
	self.max_units = max_units
	self.has_error = false
}

placeable_units_get_error_message :: proc(self: ^Placeable_Units) -> string {
	return self.error_message
}

placeable_units_get_max_units :: proc(self: ^Placeable_Units) -> i32 {
	return self.max_units
}

placeable_units_get_units :: proc(self: ^Placeable_Units) -> [dynamic]^Unit {
	return self.units
}

placeable_units_is_error :: proc(self: ^Placeable_Units) -> bool {
	return self.has_error
}

