package game

Strength_Value :: struct {
	dice_sides: i32,
	value:      i32,
}

strength_value_new :: proc(dice_sides: i32, value: i32) -> ^Strength_Value {
	sv := new(Strength_Value)
	sv.dice_sides = dice_sides
	sv.value = value
	return sv
}

strength_value_of :: proc(dice_sides: i32, value: i32) -> ^Strength_Value {
	return strength_value_new(dice_sides, value)
}

strength_value_get_value :: proc(self: ^Strength_Value) -> i32 {
	v := self.value
	if v < 0 {
		v = 0
	}
	if v > self.dice_sides {
		v = self.dice_sides
	}
	return v
}

strength_value_is_zero :: proc(self: ^Strength_Value) -> bool {
	return self.value == 0
}

strength_value_add :: proc(self: ^Strength_Value, extra_value: i32) -> ^Strength_Value {
	return strength_value_of(self.dice_sides, self.value + extra_value)
}

strength_value_to_value :: proc(self: ^Strength_Value, value: i32) -> ^Strength_Value {
	return strength_value_of(self.dice_sides, value)
}

