package game

Bombing_Results_Message :: struct {
	battle_id: string,
	dice_data: [dynamic]^I_Display_Die_Roll_Data,
	cost:      i32,
}
