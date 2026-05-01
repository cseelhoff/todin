package game

import "core:strings"

Dice_Roll :: struct {
	rolls:         [dynamic]^Die,
	hits:          i32,
	expected_hits: f64,
	player_name:   string,
}

dice_roll_new :: proc(
	dice: [dynamic]^Die,
	hits: i32,
	expected_hits: f64,
	player_name: string,
) -> ^Dice_Roll {
	self := new(Dice_Roll)
	self.rolls = make([dynamic]^Die, 0, len(dice))
	for d in dice {
		append(&self.rolls, d)
	}
	self.hits = hits
	self.expected_hits = expected_hits
	self.player_name = player_name
	return self
}

dice_roll_get_player_name_from_annotation :: proc(annotation: string) -> string {
	idx := strings.index_byte(annotation, ' ')
	if idx < 0 {
		return annotation
	}
	return annotation[:idx]
}

dice_roll_get_rolls :: proc(self: ^Dice_Roll, roll_at: i32) -> [dynamic]^Die {
	result := make([dynamic]^Die, 0)
	for d in self.rolls {
		if die_get_rolled_at(d) == roll_at {
			append(&result, d)
		}
	}
	return result
}

dice_roll_size :: proc(self: ^Dice_Roll) -> i32 {
	return i32(len(self.rolls))
}

dice_roll_is_empty :: proc(self: ^Dice_Roll) -> bool {
	return len(self.rolls) == 0
}

dice_roll_get_die :: proc(self: ^Dice_Roll, index: i32) -> ^Die {
	return self.rolls[index]
}

dice_roll_get_hits :: proc(self: ^Dice_Roll) -> i32 {
	return self.hits
}

dice_roll_get_expected_hits :: proc(self: ^Dice_Roll) -> f64 {
	return self.expected_hits
}

dice_roll_get_player_name :: proc(self: ^Dice_Roll) -> string {
	return self.player_name
}

