package game

import "core:fmt"
import "core:strconv"

Pro_Utils :: struct {}

// Port of ProUtils.isPlayersTurnFirst — walks the player turn order and
// returns true iff player1 appears before player2 (or neither is present).
pro_utils_is_players_turn_first :: proc(
	players_in_order: [dynamic]^Game_Player,
	player1: ^Game_Player,
	player2: ^Game_Player,
) -> bool {
	for p in players_in_order {
		if p == player1 {
			return true
		} else if p == player2 {
			return false
		}
	}
	return true
}

// Port of ProUtils#lambda$summarizeUnits$7. The Java lambda receives a
// Map.Entry<String, Integer> from IntegerMap<String>.entrySet() and
// produces either the bare key (count == 1) or "<count> <key>".
pro_utils_lambda_summarize_units_7 :: proc(key: string, value: i32) -> string {
	if value == 1 {
		return key
	}
	buf: [32]u8
	count_str := strconv.itoa(buf[:], int(value))
	return fmt.aprintf("%s %s", count_str, key)
}

