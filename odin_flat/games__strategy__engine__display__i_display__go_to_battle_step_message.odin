package game

Go_To_Battle_Step_Message :: struct {
	battle_step_uuid: string,
	battle_step_name: string,
}

make_I_Display_Go_To_Battle_Step_Message :: proc(battle_id_str: string, step: string) -> Go_To_Battle_Step_Message {
	return Go_To_Battle_Step_Message{
		battle_step_uuid = battle_id_str,
		battle_step_name = step,
	}
}

// games.strategy.engine.display.IDisplay$GoToBattleStepMessage#accept(games.strategy.engine.display.IDisplay)
i_display_go_to_battle_step_message_accept :: proc(self: ^Go_To_Battle_Step_Message, display: ^I_Display) {
	hex_nibble :: proc(c: u8) -> u8 {
		switch c {
		case '0'..='9': return c - '0'
		case 'a'..='f': return c - 'a' + 10
		case 'A'..='F': return c - 'A' + 10
		}
		return 0
	}
	bytes := transmute([]u8)self.battle_step_uuid
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
	i_display_goto_battle_step(display, uuid, self.battle_step_name)
}
