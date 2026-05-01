package game

import "core:fmt"

I_Display_Bombing_Results_Message :: struct {
	battle_id: string,
	dice_data: [dynamic]^I_Display_Die_Roll_Data,
	cost:      i32,
}

make_I_Display_Bombing_Results_Message :: proc(
	battle_id: Uuid,
	dice: [dynamic]^Die,
	total: i32,
) -> ^I_Display_Bombing_Results_Message {
	self := new(I_Display_Bombing_Results_Message)
	self.battle_id = fmt.aprintf(
		"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
		battle_id[0], battle_id[1], battle_id[2], battle_id[3],
		battle_id[4], battle_id[5],
		battle_id[6], battle_id[7],
		battle_id[8], battle_id[9],
		battle_id[10], battle_id[11], battle_id[12], battle_id[13], battle_id[14], battle_id[15],
	)
	self.dice_data = make([dynamic]^I_Display_Die_Roll_Data, 0, len(dice))
	for d in dice {
		append(&self.dice_data, make_I_Display_Die_Roll_Data(d))
	}
	self.cost = total
	return self
}

// games.strategy.engine.display.IDisplay$BombingResultsMessage#accept(games.strategy.engine.display.IDisplay)
i_display_bombing_results_message_accept :: proc(self: ^I_Display_Bombing_Results_Message, display: ^I_Display) {
	hex_nibble :: proc(c: u8) -> u8 {
		switch c {
		case '0'..='9': return c - '0'
		case 'a'..='f': return c - 'a' + 10
		case 'A'..='F': return c - 'A' + 10
		}
		return 0
	}
	bytes := transmute([]u8)self.battle_id
	uuid: Uuid
	bi := 0
	for i := 0; i < len(bytes) && bi < 16; i += 1 {
		if bytes[i] == '-' { continue }
		hi := hex_nibble(bytes[i])
		i += 1
		lo := hex_nibble(bytes[i])
		uuid[bi] = (hi << 4) | lo
		bi += 1
	}
	dice := die_roll_data_to_die_list(self.dice_data)
	i_display_bombing_results(display, uuid, dice, int(self.cost))
}
