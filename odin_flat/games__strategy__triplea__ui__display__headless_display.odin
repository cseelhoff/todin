package game

Headless_Display :: struct {
	using i_display: I_Display,
}

headless_display_new :: proc() -> ^Headless_Display {
	self := new(Headless_Display)
	return self
}

headless_display_show_battle :: proc(
	self: ^Headless_Display,
	battle_id: Uuid,
	location: ^Territory,
	battle_title: string,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	killed_units: [dynamic]^Unit,
	attacking_waiting_to_die: [dynamic]^Unit,
	defending_waiting_to_die: [dynamic]^Unit,
	dependent_units: map[^Unit][dynamic]^Unit,
	attacker: ^Game_Player,
	defender: ^Game_Player,
	is_amphibious: bool,
	battle_type: I_Battle_Battle_Type,
	amphibious_land_attackers: [dynamic]^Unit,
) {
}

headless_display_list_battle_steps :: proc(self: ^Headless_Display, battle_id: Uuid, steps: [dynamic]string) {
}

headless_display_battle_end :: proc(self: ^Headless_Display, battle_id: Uuid, message: string) {
}

headless_display_casualty_notification :: proc(
	self: ^Headless_Display,
	battle_id: Uuid,
	step: string,
	dice: ^Dice_Roll,
	player: ^Game_Player,
	killed: [dynamic]^Unit,
	damaged: [dynamic]^Unit,
	dependents: map[^Unit][dynamic]^Unit,
) {
}

headless_display_dead_unit_notification :: proc(
	self: ^Headless_Display,
	battle_id: Uuid,
	player: ^Game_Player,
	dead: [dynamic]^Unit,
	dependents: map[^Unit][dynamic]^Unit,
) {
}

headless_display_changed_units_notification :: proc(
	self: ^Headless_Display,
	battle_id: Uuid,
	player: ^Game_Player,
	removed_units: [dynamic]^Unit,
	added_units: [dynamic]^Unit,
	dependents: map[^Unit][dynamic]^Unit,
) {
}

headless_display_bombing_results :: proc(self: ^Headless_Display, battle_id: Uuid, dice: [dynamic]^Die, cost: i32) {
}

headless_display_notify_retreat_string :: proc(
	self: ^Headless_Display,
	short_message: string,
	message: string,
	step: string,
	retreating_player: ^Game_Player,
) {
}

headless_display_notify_retreat_uuid :: proc(self: ^Headless_Display, battle_id: Uuid, retreating: [dynamic]^Unit) {
}

headless_display_notify_dice :: proc(self: ^Headless_Display, dice: ^Dice_Roll, step_name: string) {
}

headless_display_goto_battle_step :: proc(self: ^Headless_Display, battle_id: Uuid, step: string) {
}
