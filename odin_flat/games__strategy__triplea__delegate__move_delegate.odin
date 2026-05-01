package game

Move_Delegate :: struct {
	using abstract_move_delegate: Abstract_Move_Delegate,
	need_to_initialize: bool,
	need_to_do_rockets: bool,
	pus_lost: map[^Territory]i32,
}

// games.strategy.triplea.delegate.MoveDelegate#lambda$delegateCurrentlyRequiresUserInput$0
// Java: t -> t.anyUnitsMatch(moveableUnitOwnedByMe)
// Captures the `moveableUnitOwnedByMe` Predicate<Unit> from the enclosing
// delegateCurrentlyRequiresUserInput method. Per the rawptr-ctx convention,
// the captured predicate is carried as a (fn, ctx) pair.
Move_Delegate_Delegate_Currently_Requires_User_Input_0_Ctx :: struct {
	moveable_unit_owned_by_me:     proc(rawptr, ^Unit) -> bool,
	moveable_unit_owned_by_me_ctx: rawptr,
}

move_delegate_lambda_delegate_currently_requires_user_input_0 :: proc(ctx: rawptr, t: ^Territory) -> bool {
	c := cast(^Move_Delegate_Delegate_Currently_Requires_User_Input_0_Ctx)ctx
	return territory_any_units_match(t, c.moveable_unit_owned_by_me, c.moveable_unit_owned_by_me_ctx)
}
