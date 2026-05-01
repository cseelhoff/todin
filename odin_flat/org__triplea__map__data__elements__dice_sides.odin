package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.DiceSides

Dice_Sides :: struct {
	value: i32,
}

dice_sides_get_value :: proc(self: ^Dice_Sides) -> i32 {
	return self.value
}
