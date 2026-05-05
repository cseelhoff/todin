package game

I_Display_Die_Roll_Data :: struct {
	type:      string,
	rolled_at: i32,
	value:     i32,
}

die_roll_data_get_rolled_at :: proc(self: ^I_Display_Die_Roll_Data) -> i32 {
	return self.rolled_at
}

die_roll_data_get_type :: proc(self: ^I_Display_Die_Roll_Data) -> string {
	return self.type
}

die_roll_data_get_value :: proc(self: ^I_Display_Die_Roll_Data) -> i32 {
	return self.value
}

// Constructor used by IDisplay BombingResults / NotifyDice messages
// to wrap a Die into the wire-format die-roll data record.
make_I_Display_Die_Roll_Data :: proc(d: ^Die) -> ^I_Display_Die_Roll_Data {
	self := new(I_Display_Die_Roll_Data)
	self.rolled_at = d.rolled_at
	self.value = d.value
	switch d.type {
	case .MISS:    self.type = "MISS"
	case .HIT:     self.type = "HIT"
	case .IGNORED: self.type = "IGNORED"
	}
	return self
}

die_roll_data_to_die_list :: proc(dice_roll_data: [dynamic]^I_Display_Die_Roll_Data) -> [dynamic]^Die {
	result: [dynamic]^Die
	for d in dice_roll_data {
		die := new(Die)
		die.rolled_at = d.rolled_at
		die.value = d.value
		switch d.type {
		case "MISS":
			die.type = .MISS
		case "HIT":
			die.type = .HIT
		case "IGNORED":
			die.type = .IGNORED
		}
		append(&result, die)
	}
	return result
}

