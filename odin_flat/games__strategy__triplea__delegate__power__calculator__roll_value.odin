package game

Roll_Value :: struct {
	value:       i32,
	is_infinite: bool,
}

roll_value_new :: proc(value: i32, is_infinite: bool) -> ^Roll_Value {
	r := new(Roll_Value)
	r.value = value
	r.is_infinite = is_infinite
	return r
}

roll_value_of_full :: proc(value: i32, is_infinite: bool) -> ^Roll_Value {
	return roll_value_new(value, is_infinite)
}

roll_value_of :: proc(value: i32) -> ^Roll_Value {
	return roll_value_of_full(value, value == -1)
}

roll_value_to_value :: proc(self: ^Roll_Value, value: i32) -> ^Roll_Value {
	return roll_value_of_full(value, false)
}

roll_value_add :: proc(self: ^Roll_Value, extra_value: i32) -> ^Roll_Value {
	if self.is_infinite {
		return self
	}
	return roll_value_of_full(self.value + extra_value, false)
}

roll_value_get_value :: proc(self: ^Roll_Value) -> i32 {
	if self.is_infinite {
		return -1
	}
	if self.value < 0 {
		return 0
	}
	return self.value
}

roll_value_is_zero :: proc(self: ^Roll_Value) -> bool {
	return self.value == 0
}

