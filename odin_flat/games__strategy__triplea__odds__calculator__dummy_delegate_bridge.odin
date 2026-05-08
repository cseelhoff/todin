package game

Dummy_Delegate_Bridge :: struct {
	using i_delegate_bridge: I_Delegate_Bridge,
	random_source:    ^Plain_Random_Source,
	display:          ^Headless_Display,
	sound_channel:    ^Headless_Sound_Channel,
	attacking_player: ^Dummy_Player,
	defending_player: ^Dummy_Player,
	attacker:         ^Game_Player,
	writer:           ^Delegate_History_Writer,
	all_changes:      ^Composite_Change,
	game_data:        ^Game_Data,
	battle:           ^Must_Fight_Battle,
	tuv_calculator:   ^Tuv_Costs_Calculator,
}

// Vtable adapters: AI snapshot harness dispatches I_Delegate_Bridge proc-fields
// directly. Without these, Dummy's leading bytes are read as garbage proc-pointers.
@(private="file")
dummy_v_get_history_writer :: proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer {
	return transmute(^I_Delegate_History_Writer)(cast(^Dummy_Delegate_Bridge)self).writer
}
@(private="file")
dummy_v_get_data :: proc(self: ^I_Delegate_Bridge) -> ^Game_Data {
	return (cast(^Dummy_Delegate_Bridge)self).game_data
}
@(private="file")
dummy_v_get_display :: proc(self: ^I_Delegate_Bridge) -> ^I_Display {
	return transmute(^I_Display)(cast(^Dummy_Delegate_Bridge)self).display
}
@(private="file")
dummy_v_get_sound :: proc(self: ^I_Delegate_Bridge) -> ^Headless_Sound_Channel {
	return (cast(^Dummy_Delegate_Bridge)self).sound_channel
}
@(private="file")
dummy_v_get_game_player :: proc(self: ^I_Delegate_Bridge) -> ^Game_Player {
	return (cast(^Dummy_Delegate_Bridge)self).attacker
}
@(private="file")
dummy_v_get_remote_player :: proc(self: ^I_Delegate_Bridge, player: ^Game_Player) -> ^Player {
	dd := cast(^Dummy_Delegate_Bridge)self
	dp := dummy_delegate_bridge_get_remote_player(dd, player)
	return cast(^Player)dp
}
@(private="file")
dummy_v_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
	dummy_delegate_bridge_add_change(cast(^Dummy_Delegate_Bridge)self, change)
}
@(private="file")
dummy_v_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) {}
@(private="file")
dummy_v_get_resource_loader :: proc(self: ^I_Delegate_Bridge) -> ^Resource_Loader {
	return nil
}
@(private="file")
dummy_v_send_message :: proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message) {}
@(private="file")
dummy_v_stop_game_sequence :: proc(self: ^I_Delegate_Bridge, status: string, title: string) {}
@(private="file")
dummy_v_get_random :: proc(
	self: ^I_Delegate_Bridge,
	max: i32,
	count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	dd := cast(^Dummy_Delegate_Bridge)self
	return plain_random_source_get_random_array(dd.random_source, max, count, annotation)
}

// games.strategy.triplea.odds.calculator.DummyDelegateBridge#<init>(
//   GamePlayer, GameData, CompositeChange, List<Unit>, List<Unit>,
//   boolean, int, int, boolean, TuvCostsCalculator)
dummy_delegate_bridge_new :: proc(
	attacker: ^Game_Player,
	data: ^Game_Data,
	all_changes: ^Composite_Change,
	attacker_order_of_losses: [dynamic]^Unit,
	defender_order_of_losses: [dynamic]^Unit,
	attacker_keep_one_land_unit: bool,
	retreat_after_round: i32,
	retreat_after_x_units_left: i32,
	retreat_when_only_air_left: bool,
	tuv_calculator: ^Tuv_Costs_Calculator,
) -> ^Dummy_Delegate_Bridge {
	self := new(Dummy_Delegate_Bridge)
	self.random_source = plain_random_source_new()
	self.display = headless_display_new()
	self.sound_channel = headless_sound_channel_new()
	self.writer = delegate_history_writer_create_no_op_implementation()
	self.attacking_player = dummy_player_new(
		self,
		true,
		"battle calc dummy",
		attacker_order_of_losses,
		attacker_keep_one_land_unit,
		retreat_after_round,
		retreat_after_x_units_left,
		retreat_when_only_air_left,
	)
	self.defending_player = dummy_player_new(
		self,
		false,
		"battle calc dummy",
		defender_order_of_losses,
		false,
		retreat_after_round,
		-1,
		false,
	)
	self.game_data = data
	self.attacker = attacker
	self.all_changes = all_changes
	self.tuv_calculator = tuv_calculator
	self.get_history_writer = dummy_v_get_history_writer
	self.get_data = dummy_v_get_data
	self.get_display_channel_broadcaster = dummy_v_get_display
	self.get_sound_channel_broadcaster = dummy_v_get_sound
	self.get_game_player = dummy_v_get_game_player
	self.get_remote_player = dummy_v_get_remote_player
	self.add_change = dummy_v_add_change
	self.enter_delegate_execution = dummy_v_enter_delegate_execution
	self.get_resource_loader = dummy_v_get_resource_loader
	self.send_message = dummy_v_send_message
	self.stop_game_sequence = dummy_v_stop_game_sequence
	self.get_random = dummy_v_get_random
	return self
}

dummy_delegate_bridge_get_battle :: proc(self: ^Dummy_Delegate_Bridge) -> ^Must_Fight_Battle {
	return self.battle
}

dummy_delegate_bridge_get_data :: proc(self: ^Dummy_Delegate_Bridge) -> ^Game_Data {
	return self.game_data
}

dummy_delegate_bridge_get_display_channel_broadcaster :: proc(self: ^Dummy_Delegate_Bridge) -> ^Headless_Display {
	return self.display
}

dummy_delegate_bridge_get_history_writer :: proc(self: ^Dummy_Delegate_Bridge) -> ^Delegate_History_Writer {
	return self.writer
}

dummy_delegate_bridge_get_remote_player :: proc(self: ^Dummy_Delegate_Bridge, game_player: ^Game_Player) -> ^Dummy_Player {
	if game_player == self.attacker {
		return self.attacking_player
	}
	return self.defending_player
}

dummy_delegate_bridge_get_sound_channel_broadcaster :: proc(self: ^Dummy_Delegate_Bridge) -> ^Headless_Sound_Channel {
	return self.sound_channel
}

// games.strategy.triplea.odds.calculator.DummyDelegateBridge#getResourceLoader()
// Java: throw new UnsupportedOperationException("should never be called");
// The battle-calculator dummy has no UI/resources surface; AI snapshot
// callers test the loader for absence (politics_delegate skips when
// nil), so returning nil is the Optional.empty() equivalent.
dummy_delegate_bridge_get_resource_loader :: proc(self: ^Dummy_Delegate_Bridge) -> ^Resource_Loader {
	return nil
}

dummy_delegate_bridge_set_battle :: proc(self: ^Dummy_Delegate_Bridge, battle: ^Must_Fight_Battle) {
	self.battle = battle
}

dummy_delegate_bridge_get_random :: proc(
	self: ^Dummy_Delegate_Bridge,
	max: i32,
	count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	return plain_random_source_get_random_array(self.random_source, max, count, annotation)
}

dummy_delegate_bridge_get_costs_for_tuv :: proc(
	self: ^Dummy_Delegate_Bridge,
	player: ^Game_Player,
) -> map[^Unit_Type]i32 {
	return tuv_costs_calculator_get_costs_for_tuv(self.tuv_calculator, player)
}

// Java: DummyDelegateBridge#addChange(Change)
//   if (change instanceof UnitDamageReceivedChange) {
//     allChanges.add(change);
//     gameData.performChange(change);
//   } else if (change instanceof CompositeChange compositeChange) {
//     compositeChange.getChanges().forEach(this::addChange);
//   }
dummy_delegate_bridge_add_change :: proc(self: ^Dummy_Delegate_Bridge, change: ^Change) {
	if change == nil {
		return
	}
	if change.kind == .Unit_Damage_Received_Change {
		composite_change_add(self.all_changes, change)
		game_data_perform_change(self.game_data, change)
	} else if change.kind == .Composite_Change {
		composite_change := cast(^Composite_Change)change
		for child in composite_change_get_changes(composite_change) {
			dummy_delegate_bridge_add_change(self, child)
		}
	}
}
