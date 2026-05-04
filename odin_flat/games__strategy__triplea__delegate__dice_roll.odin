package game

import "core:fmt"
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

dice_roll_get_annotation :: proc(
	units: [dynamic]^Unit,
	player: ^Game_Player,
	territory: ^Territory,
	battle_round: i32,
) -> string {
	player_name := default_named_get_name(&player.named_attachable.default_named)
	territory_name := default_named_get_name(&territory.named_attachable.default_named)
	units_text := my_formatter_units_to_text_no_owner(units, nil)
	return fmt.aprintf(
		"%s roll dice for %s in %s, round %d",
		player_name,
		units_text,
		territory_name,
		battle_round + 1,
	)
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

dice_roll_lambda__get_rolls__1 :: proc(roll_at: i32, d: ^Die) -> bool {
	return die_get_rolled_at(d) == roll_at
}

dice_roll_lambda__new__0 :: proc(hit_only_if_equals: bool, roll_at: i32, element: i32) -> ^Die {
	hit := (roll_at == element) if hit_only_if_equals else (element <= roll_at)
	d := new(Die)
	dt: Die_Die_Type = .HIT if hit else .MISS
	d^ = die_new(element, roll_at, dt)
	return d
}

dice_roll_write_external :: proc(self: ^Dice_Roll, out: ^Object_Output) {
	object_output_write_int(out, 1)
	dice := make([dynamic]i32, 0, len(self.rolls))
	defer delete(dice)
	for r in self.rolls {
		append(&dice, die_get_compressed_value(r))
	}
	object_output_write_object(out, raw_data(dice[:]))
	object_output_write_int(out, self.hits)
	object_output_write_double(out, self.expected_hits)
	player_name := self.player_name
	object_output_write_object(out, &player_name)
}

