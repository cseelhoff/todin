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
