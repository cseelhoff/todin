package game

Die :: struct {
	value:     i32,
	rolled_at: i32,
	type:      Die_Die_Type,
}

die_new :: proc(value: i32, rolled_at: i32, type: Die_Die_Type) -> Die {
	return Die{value = value, rolled_at = rolled_at, type = type}
}

die_get_compressed_value :: proc(self: ^Die) -> i32 {
	assert(self.value <= 255 && self.rolled_at <= 255, "too big to serialize")
	return (self.rolled_at << 8) + (self.value << 16) + i32(self.type)
}

die_get_rolled_at :: proc(self: ^Die) -> i32 {
	return self.rolled_at
}

die_get_type :: proc(self: ^Die) -> Die_Die_Type {
	return self.type
}

die_get_value :: proc(self: ^Die) -> i32 {
	return self.value
}

