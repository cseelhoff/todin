package game

Land_Paratroopers :: struct {
	using battle_step: Battle_Step,
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
}

land_paratroopers_v_get_all_step_details :: proc(self: ^Battle_Step) -> [dynamic]^Battle_Step_Step_Details {
	return land_paratroopers_get_all_step_details(cast(^Land_Paratroopers)self)
}

land_paratroopers_v_execute :: proc(self: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	land_paratroopers_execute(cast(^Land_Paratroopers)self, stack, bridge)
}

land_paratroopers_new :: proc(battle_state: ^Battle_State, battle_actions: ^Battle_Actions) -> ^Land_Paratroopers {
	self := new(Land_Paratroopers)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.get_all_step_details = land_paratroopers_v_get_all_step_details
	self.get_order = land_paratroopers_v_get_order
	self.execute = land_paratroopers_v_execute
	return self
}

land_paratroopers_v_get_order :: proc(self: ^Battle_Step) -> Battle_Step_Order {
	return land_paratroopers_get_order(cast(^Land_Paratroopers)self)
}

land_paratroopers_get_order :: proc(self: ^Land_Paratroopers) -> Battle_Step_Order {
	return .LAND_PARATROOPERS
}

// Java: public List<StepDetails> getAllStepDetails() {
//   return new TransportsAndParatroopers().hasParatroopers()
//       ? List.of(new StepDetails(LAND_PARATROOPS, this))
//       : List.of();
// }
land_paratroopers_get_all_step_details :: proc(self: ^Land_Paratroopers) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	tap := land_paratroopers_transports_and_paratroopers_new(self)
	if land_paratroopers_transports_and_paratroopers_has_paratroopers(tap) {
		append(&out, battle_step_step_details_new(BATTLE_STEP_LAND_PARATROOPS, &self.battle_step))
	}
	return out
}

// Java: public void execute(final ExecutionStack stack, final IDelegateBridge bridge) {
//   final TransportsAndParatroopers transportsAndParatroopers = new TransportsAndParatroopers();
//   if (transportsAndParatroopers.hasParatroopers()) {
//     final CompositeChange change = new CompositeChange();
//     for (final Unit unit : transportsAndParatroopers.paratroopers) {
//       change.add(
//           TransportTracker.unloadAirTransportChange(unit, battleState.getBattleSite(), false));
//     }
//     bridge.addChange(change);
//   }
// }
land_paratroopers_execute :: proc(
	self: ^Land_Paratroopers,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	tap := land_paratroopers_transports_and_paratroopers_new(self)
	if !land_paratroopers_transports_and_paratroopers_has_paratroopers(tap) {
		return
	}
	change := composite_change_new()
	site := battle_state_get_battle_site(self.battle_state)
	for unit in tap.paratroopers {
		composite_change_add(
			change,
			transport_tracker_unload_air_transport_change(unit, site, false),
		)
	}
	i_delegate_bridge_add_change(bridge, &change.change)
}
