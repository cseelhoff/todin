package game

import "core:fmt"

// Java owners covered by this file:
//   - games.strategy.engine.display.IDisplay$NotifyUnitsRetreatingMessage

I_Display_Notify_Units_Retreating_Message :: struct {
	battle_id:           string,
	retreating_unit_ids: [dynamic]string,
}

// Backwards-compat alias for the bare simple name used elsewhere.
Notify_Units_Retreating_Message :: I_Display_Notify_Units_Retreating_Message

make_I_Display_Notify_Units_Retreating_Message :: proc(
	battle_id: Uuid,
	units: [dynamic]^Unit,
) -> I_Display_Notify_Units_Retreating_Message {
	msg: I_Display_Notify_Units_Retreating_Message
	msg.battle_id = fmt.aprintf(
		"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
		battle_id[0], battle_id[1], battle_id[2], battle_id[3],
		battle_id[4], battle_id[5],
		battle_id[6], battle_id[7],
		battle_id[8], battle_id[9],
		battle_id[10], battle_id[11], battle_id[12], battle_id[13], battle_id[14], battle_id[15],
	)
	msg.retreating_unit_ids = make([dynamic]string, 0, len(units))
	for u in units {
		id := u.id
		append(&msg.retreating_unit_ids, fmt.aprintf(
			"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
			id[0], id[1], id[2], id[3],
			id[4], id[5],
			id[6], id[7],
			id[8], id[9],
			id[10], id[11], id[12], id[13], id[14], id[15],
		))
	}
	return msg
}

// games.strategy.engine.display.IDisplay$NotifyUnitsRetreatingMessage#accept(games.strategy.engine.display.IDisplay,games.strategy.engine.data.UnitsList)
i_display_notify_units_retreating_message_accept :: proc(
	self: ^I_Display_Notify_Units_Retreating_Message,
	display: ^I_Display,
	units_list: ^Units_List,
) {
	hex_nibble :: proc(c: u8) -> u8 {
		switch c {
		case '0'..='9': return c - '0'
		case 'a'..='f': return c - 'a' + 10
		case 'A'..='F': return c - 'A' + 10
		}
		return 0
	}
	parse_uuid :: proc(s: string) -> Uuid {
		bytes := transmute([]u8)s
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
		return uuid
	}
	battle_id := parse_uuid(self.battle_id)
	retreating := make([dynamic]^Unit, 0, len(self.retreating_unit_ids))
	for id_str in self.retreating_unit_ids {
		uid := parse_uuid(id_str)
		append(&retreating, units_list_get(units_list, uid))
	}
	i_display_notify_retreat_units(display, battle_id, retreating)
}

