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

roll_value_of :: proc(value: i32, choose_best_roll: bool) -> ^Roll_Value {
	return roll_value_new(value, choose_best_roll)
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

