package game

// Java owner: games.strategy.engine.display.IDisplay
//
// IDisplay is a pure-callback interface (extends IChannelSubscriber).
// Each abstract method is modeled as a proc-typed field; concrete
// implementers install their function at construction time. Dispatch
// procs (`i_display_*`) are the public entry points.

I_Display :: struct {
	battle_end:           proc(self: ^I_Display, battle_id: Uuid, message: string),
	bombing_results:      proc(self: ^I_Display, battle_id: Uuid, dice: [dynamic]^Die, cost: int),
	casualty_notification: proc(self: ^I_Display, battle_id: Uuid, step: string, dice: ^Dice_Roll, player: ^Game_Player, killed: [dynamic]^Unit, damaged: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit),
	changed_units_notification: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, removed_units: [dynamic]^Unit, added_units: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit),
	dead_unit_notification: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, dead: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit),
	goto_battle_step:     proc(self: ^I_Display, battle_id: Uuid, step: string),
	list_battle_steps:    proc(self: ^I_Display, battle_id: Uuid, steps: [dynamic]string),
	notify_dice:          proc(self: ^I_Display, dice_roll: ^Dice_Roll, step_name: string),
	notify_retreat:       proc(self: ^I_Display, short_message: string, message: string, step: string, retreating_player: ^Game_Player),
	notify_retreat_units: proc(self: ^I_Display, battle_id: Uuid, retreating: [dynamic]^Unit),
	report_message_to_all: proc(self: ^I_Display, message: string, title: string, do_not_include_host: bool, do_not_include_clients: bool, do_not_include_observers: bool),
	report_message_to_players: proc(self: ^I_Display, players_to_send_to: [dynamic]^Game_Player, players_to_exclude: [dynamic]^Game_Player, message: string, title: string),
}

// games.strategy.engine.display.IDisplay#battleEnd(java.util.UUID,java.lang.String)
i_display_battle_end :: proc(self: ^I_Display, battle_id: Uuid, message: string) {
	self.battle_end(self, battle_id, message)
}

// games.strategy.engine.display.IDisplay#bombingResults(java.util.UUID,java.util.List,int)
i_display_bombing_results :: proc(self: ^I_Display, battle_id: Uuid, dice: [dynamic]^Die, cost: int) {
	self.bombing_results(self, battle_id, dice, cost)
}

// games.strategy.engine.display.IDisplay#casualtyNotification(java.util.UUID,java.lang.String,games.strategy.triplea.delegate.DiceRoll,games.strategy.engine.data.GamePlayer,java.util.Collection,java.util.Collection,java.util.Map)
i_display_casualty_notification :: proc(self: ^I_Display, battle_id: Uuid, step: string, dice: ^Dice_Roll, player: ^Game_Player, killed: [dynamic]^Unit, damaged: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	self.casualty_notification(self, battle_id, step, dice, player, killed, damaged, dependents)
}

// games.strategy.engine.display.IDisplay#changedUnitsNotification(java.util.UUID,games.strategy.engine.data.GamePlayer,java.util.Collection,java.util.Collection,java.util.Map)
i_display_changed_units_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, removed_units: [dynamic]^Unit, added_units: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	self.changed_units_notification(self, battle_id, player, removed_units, added_units, dependents)
}

// games.strategy.engine.display.IDisplay#deadUnitNotification(java.util.UUID,games.strategy.engine.data.GamePlayer,java.util.Collection,java.util.Map)
i_display_dead_unit_notification :: proc(self: ^I_Display, battle_id: Uuid, player: ^Game_Player, dead: [dynamic]^Unit, dependents: map[^Unit][dynamic]^Unit) {
	self.dead_unit_notification(self, battle_id, player, dead, dependents)
}

// games.strategy.engine.display.IDisplay#gotoBattleStep(java.util.UUID,java.lang.String)
i_display_goto_battle_step :: proc(self: ^I_Display, battle_id: Uuid, step: string) {
	self.goto_battle_step(self, battle_id, step)
}

// games.strategy.engine.display.IDisplay#listBattleSteps(java.util.UUID,java.util.List)
i_display_list_battle_steps :: proc(self: ^I_Display, battle_id: Uuid, steps: [dynamic]string) {
	self.list_battle_steps(self, battle_id, steps)
}

// games.strategy.engine.display.IDisplay#notifyDice(games.strategy.triplea.delegate.DiceRoll,java.lang.String)
i_display_notify_dice :: proc(self: ^I_Display, dice_roll: ^Dice_Roll, step_name: string) {
	self.notify_dice(self, dice_roll, step_name)
}

// games.strategy.engine.display.IDisplay#notifyRetreat(java.lang.String,java.lang.String,java.lang.String,games.strategy.engine.data.GamePlayer)
i_display_notify_retreat :: proc(self: ^I_Display, short_message: string, message: string, step: string, retreating_player: ^Game_Player) {
	self.notify_retreat(self, short_message, message, step, retreating_player)
}

// games.strategy.engine.display.IDisplay#notifyRetreat(java.util.UUID,java.util.Collection)
i_display_notify_retreat_units :: proc(self: ^I_Display, battle_id: Uuid, retreating: [dynamic]^Unit) {
	self.notify_retreat_units(self, battle_id, retreating)
}

// games.strategy.engine.display.IDisplay#reportMessageToAll(java.lang.String,java.lang.String,boolean,boolean,boolean)
i_display_report_message_to_all :: proc(self: ^I_Display, message: string, title: string, do_not_include_host: bool, do_not_include_clients: bool, do_not_include_observers: bool) {
	self.report_message_to_all(self, message, title, do_not_include_host, do_not_include_clients, do_not_include_observers)
}

// games.strategy.engine.display.IDisplay#reportMessageToPlayers(java.util.Collection,java.util.Collection,java.lang.String,java.lang.String)
i_display_report_message_to_players :: proc(self: ^I_Display, players_to_send_to: [dynamic]^Game_Player, players_to_exclude: [dynamic]^Game_Player, message: string, title: string) {
	self.report_message_to_players(self, players_to_send_to, players_to_exclude, message, title)
}

