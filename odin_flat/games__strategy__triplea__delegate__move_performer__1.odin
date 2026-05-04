package game

Move_Performer_1 :: struct {
	using i_executable: I_Executable,
	outer:        ^Move_Performer,
	route:        ^Route,
	units:        [dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MovePerformer$1

move_performer_1_new :: proc(this0: ^Move_Performer, route: ^Route, collection: [dynamic]^Unit) -> ^Move_Performer_1 {
	self := new(Move_Performer_1)
	self.outer = this0
	self.route = route
	self.units = collection
	self.execute = move_performer_1_execute
	return self
}

// games.strategy.triplea.delegate.MovePerformer$1#execute(ExecutionStack, IDelegateBridge)
//
// Java preAaFire body: for each pending battle at route.getStart(), for each
// unit in `units`, look up the route the unit used to enter that territory;
// if present, remove that attack (with the single unit) from the battle and
// stage the resulting Change on the bridge.
move_performer_1_execute :: proc(self_base: ^I_Executable, stack: ^Execution_Stack, bridge: ^I_Delegate_Bridge) {
	_ = stack
	self := cast(^Move_Performer_1)self_base
	outer := self.outer
	pending := battle_tracker_get_pending_battles_at_territory(
		move_performer_get_battle_tracker(outer),
		route_get_start(self.route),
	)
	defer delete(pending)
	for battle in pending {
		for unit in self.units {
			optional_route := abstract_move_delegate_get_route_used_to_move_into(
				abstract_move_delegate_get_undoable_moves(outer.move_delegate),
				unit,
				route_get_start(self.route),
			)
			if optional_route != nil {
				removed_units := make([dynamic]^Unit)
				append(&removed_units, unit)
				change := i_battle_remove_attack(battle, optional_route, removed_units)
				i_delegate_bridge_add_change(bridge, change)
				delete(removed_units)
			}
		}
	}
}

