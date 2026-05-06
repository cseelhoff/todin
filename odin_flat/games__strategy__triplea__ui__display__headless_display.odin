package game

Headless_Display :: struct {
	using i_display: I_Display,
}

headless_display_v_battle_end :: proc(self: ^I_Display, battle_id: Uuid, message: string) {
	headless_display_battle_end(cast(^Headless_Display)self, battle_id, message)
}

headless_display_v_bombing_results :: proc(self: ^I_Display, battle_id: Uuid, dice: [dynamic]^Die, cost: int) {
	headless_display_bombing_results(cast(^Headless_Display)self, battle_id, dice, i32(cost))
}

headless_display_v_casualty_notification :: proc(self: ^I_Display, battle_id: Uuid, step: string, dice: ^Dice_Roll, player: ^Game_Player, killed: [dynamic]^Unit, damaged: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	headless_display_casualty_notification(cast(^Headless_Display)self, battle_id, step, dice, player, killed, damaged, dependents)
}

headless_display_v_changed_units_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, removed_units: [dynamic]^Unit, added_units: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	headless_display_changed_units_notification(cast(^Headless_Display)self, battle_id, player, removed_units, added_units, dependents)
}

headless_display_v_dead_unit_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, dead: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	headless_display_dead_unit_notification(cast(^Headless_Display)self, battle_id, player, dead, dependents)
}

headless_display_v_goto_battle_step :: proc(self: ^I_Display, battle_id: Uuid, step: string) {
	headless_display_goto_battle_step(cast(^Headless_Display)self, battle_id, step)
}

headless_display_v_list_battle_steps :: proc(self: ^I_Display, battle_id: Uuid, steps: [dynamic]string) {
	headless_display_list_battle_steps(cast(^Headless_Display)self, battle_id, steps)
}

headless_display_v_notify_dice :: proc(self: ^I_Display, dice_roll: ^Dice_Roll, step_name: string) {
	headless_display_notify_dice(cast(^Headless_Display)self, dice_roll, step_name)
}

headless_display_new :: proc() -> ^Headless_Display {
	self := new(Headless_Display)
	self.i_display.battle_end = headless_display_v_battle_end
	self.i_display.bombing_results = headless_display_v_bombing_results
	self.i_display.casualty_notification = headless_display_v_casualty_notification
	self.i_display.changed_units_notification = headless_display_v_changed_units_notification
	self.i_display.dead_unit_notification = headless_display_v_dead_unit_notification
	self.i_display.goto_battle_step = headless_display_v_goto_battle_step
	self.i_display.list_battle_steps = headless_display_v_list_battle_steps
	self.i_display.notify_dice = headless_display_v_notify_dice
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
