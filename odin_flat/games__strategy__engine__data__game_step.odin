package game

import "core:strings"

// games.strategy.engine.data.GameStep
//
// One delegate step within a GameSequence (e.g. "russianBid", "germanCombatMove").

Game_Step :: struct {
	using game_data_component: Game_Data_Component,
	name:          string,
	display_name:  string,
	player:        ^Game_Player,
	delegate_name: string,
	run_count:     i32,
	max_run_count: i32,
	properties:    map[string]string,
}

// games.strategy.engine.data.GameStep.PropertyKeys
Game_Step_Property_Keys :: struct {}

game_step_get_player_id :: proc(self: ^Game_Step) -> ^Game_Player {
	return self.player
}

game_step_has_reached_max_run_count :: proc(self: ^Game_Step) -> bool {
	return self.max_run_count != -1 && self.max_run_count <= self.run_count
}

game_step_increment_run_count :: proc(self: ^Game_Step) {
	self.run_count += 1
}

game_step_get_display_name :: proc(self: ^Game_Step) -> string {
	if self.display_name == "" {
		data := game_data_component_get_data(&self.game_data_component)
		optional_delegate := game_data_get_delegate_optional(data, self.delegate_name)
		if optional_delegate != nil {
			return (^Abstract_Delegate)(optional_delegate).display_name
		}
		return self.delegate_name
	}
	return self.display_name
}

game_step_is_move_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Move")
}

game_step_is_non_combat_move_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "NonCombatMove")
}

game_step_is_combat_move_step_name :: proc(step_name: string) -> bool {
	// NonCombatMove endsWith CombatMove so check for NCM first.
	return !game_step_is_non_combat_move_step_name(step_name) && strings.has_suffix(step_name, "CombatMove")
}

game_step_is_airborne_combat_move_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "AirborneCombatMove")
}

game_step_is_battle_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Battle")
}

game_step_is_politics_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Politics")
}

game_step_is_end_turn_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "EndTurn")
}

game_step_is_purchase_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Purchase")
}

game_step_is_bid_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Bid")
}

game_step_is_bid_place_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "BidPlace")
}

game_step_is_place_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Place")
}

game_step_is_non_combat :: proc(self: ^Game_Step) -> bool {
	value, ok := self.properties["nonCombatMove"]
	if ok && strings.equal_fold(value, "true") {
		return true
	}
	return game_step_is_non_combat_move_step_name(self.name)
}

game_step_is_tech_step_name :: proc(step_name: string) -> bool {
	return step_name != "" && strings.has_suffix(step_name, "Tech")
}

game_step_set_max_run_count :: proc(self: ^Game_Step, count: i32) {
	self.max_run_count = count
}
