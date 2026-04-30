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
