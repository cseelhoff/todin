package game

// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.util.ProMatches
//
// Static factory methods that produce Java Predicate<T> / BiPredicate<T1,T2>
// closures are translated to Odin via the project's predicate-pair convention:
// each factory allocates a per-call context struct holding the captured
// variables, and returns the pair (proc(rawptr, ^T) -> bool, rawptr).
// Forward references to as-yet-unported helpers (`matches_*`, `properties_*`,
// `territory_effect_helper_*`, `move_validator_*`, `route_new`,
// `abstract_move_delegate_*`, `battle_tracker_*`, `pro_utils_*`,
// `unit_get_movement_left`, `unit_get_unit_attachment`,
// `unit_attachment_get_carrier_capacity`, `unit_attachment_can_invade_from`)
// are intentional — they live elsewhere in odin_flat/ and are resolved by
// Odin's package-level scope.

Pro_Matches :: struct {}

// ---------------------------------------------------------------------------
// noCanalsBetweenTerritories(player) -> BiPredicate<Territory, Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_no_canals_between_territories :: struct {
	player: ^Game_Player,
}

pro_matches_pred_no_canals_between_territories :: proc(
	ctx_ptr: rawptr,
	start_territory: ^Territory,
	end_territory: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_no_canals_between_territories)ctx_ptr
	r := route_new(start_territory, end_territory)
	validator := move_validator_new(game_player_get_data(ctx.player), false)
	return move_validator_validate_canal(validator, r, nil, ctx.player) == nil
}

pro_matches_no_canals_between_territories :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_no_canals_between_territories)
	ctx.player = player
	return pro_matches_pred_no_canals_between_territories, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveSpecificLandUnit(player, isCombatMove, unit) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_specific_land_unit :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
	unit:           ^Unit,
}

pro_matches_pred_territory_can_move_specific_land_unit :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_specific_land_unit)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		ctx.player, ctx.is_combat_move, true, false, false, false,
	)
	if !p2(c2, t) {
		return false
	}
	disallowed := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(t)
	pu, cu := matches_unit_is_of_types(disallowed)
	return !pu(cu, ctx.unit)
}

pro_matches_territory_can_move_specific_land_unit :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
	unit: ^Unit,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_specific_land_unit)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	ctx.unit = unit
	return pro_matches_pred_territory_can_move_specific_land_unit, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanPotentiallyMoveSpecificLandUnit(player, u) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_potentially_move_specific_land_unit :: struct {
	player: ^Game_Player,
	u:      ^Unit,
}

pro_matches_pred_territory_can_potentially_move_specific_land_unit :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_potentially_move_specific_land_unit)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted(ctx.player)
	if !p2(c2, t) {
		return false
	}
	disallowed := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(t)
	pu, cu := matches_unit_is_of_types(disallowed)
	return !pu(cu, ctx.u)
}

pro_matches_territory_can_potentially_move_specific_land_unit :: proc(
	player: ^Game_Player,
	u: ^Unit,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_potentially_move_specific_land_unit)
	ctx.player = player
	ctx.u = u
	return pro_matches_pred_territory_can_potentially_move_specific_land_unit, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveLandUnitsThrough(player, u, startTerritory, isCombatMove,
//                                  enemyTerritories) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_land_units_through :: struct {
	player:            ^Game_Player,
	u:                 ^Unit,
	start_territory:   ^Territory,
	is_combat_move:    bool,
	enemy_territories: [dynamic]^Territory,
}

pro_matches_pred_territory_can_move_land_units_through :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_land_units_through)ctx_ptr
	for et in ctx.enemy_territories {
		if et == t {
			return false
		}
	}
	cm_p, cm_c := pro_matches_territory_can_move_specific_land_unit(ctx.player, ctx.is_combat_move, ctx.u)
	if !cm_p(cm_c, t) {
		return false
	}
	if ctx.is_combat_move {
		ucb_p, ucb_c := matches_unit_can_blitz()
		if ucb_p(ucb_c, ctx.u) && territory_effect_helper_unit_keeps_blitz(ctx.u, ctx.start_territory) {
			at_p, at_c := matches_is_territory_allied(ctx.player)
			ne_p, ne_c := matches_territory_has_no_enemy_units(ctx.player)
			if at_p(at_c, t) && ne_p(ne_c, t) {
				return true
			}
			tib_p, tib_c := pro_matches_territory_is_blitzable(ctx.player, ctx.u)
			return tib_p(tib_c, t)
		}
	}
	at_p, at_c := matches_is_territory_allied(ctx.player)
	if !at_p(at_c, t) {
		return false
	}
	ne_p, ne_c := matches_territory_has_no_enemy_units(ctx.player)
	return ne_p(ne_c, t)
}

pro_matches_territory_can_move_land_units_through :: proc(
	player: ^Game_Player,
	u: ^Unit,
	start_territory: ^Territory,
	is_combat_move: bool,
	enemy_territories: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_land_units_through)
	ctx.player = player
	ctx.u = u
	ctx.start_territory = start_territory
	ctx.is_combat_move = is_combat_move
	ctx.enemy_territories = enemy_territories
	return pro_matches_pred_territory_can_move_land_units_through, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveSeaUnits(player, isCombatMove) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_sea_units :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_territory_can_move_sea_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_sea_units)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	naval_may_not_non_com_into_controlled :=
		properties_get_ww2_v2(props) ||
		properties_get_naval_units_may_not_non_combat_move_into_controlled_sea_zones(props)
	if !ctx.is_combat_move && naval_may_not_non_com_into_controlled {
		ew_p, ew_c := matches_is_territory_enemy_and_not_unowned_water(ctx.player)
		if ew_p(ew_c, t) {
			return false
		}
	}
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		ctx.player, ctx.is_combat_move, false, true, false, false,
	)
	return p2(c2, t)
}

pro_matches_territory_can_move_sea_units :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_sea_units)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_territory_can_move_sea_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasOnlyIgnoredUnits(player) -> Predicate<Territory>     [package-private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_only_ignored_units :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_only_ignored_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_only_ignored_units)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	ignore_transport := properties_get_ignore_transport_in_movement(props)
	uc := territory_get_unit_collection(t)
	all_match := true
	for unit_in in uc.units {
		p_inf, c_inf := matches_unit_is_infrastructure()
		p_btb, c_btb := matches_unit_can_be_moved_through_by_enemies()
		p_eu, c_eu := matches_enemy_unit(ctx.player)
		non_blocking := p_inf(c_inf, unit_in) || p_btb(c_btb, unit_in) || !p_eu(c_eu, unit_in)
		if !non_blocking && ignore_transport {
			p_st, c_st := matches_unit_is_sea_transport_but_not_combat_sea_transport()
			p_l, c_l := matches_unit_is_land()
			non_blocking = p_st(c_st, unit_in) || p_l(c_l, unit_in)
		}
		if !non_blocking {
			all_match = false
			break
		}
	}
	if all_match {
		return true
	}
	hne_p, hne_c := matches_territory_has_no_enemy_units(ctx.player)
	return hne_p(hne_c, t)
}

pro_matches_territory_has_only_ignored_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_only_ignored_units)
	ctx.player = player
	return pro_matches_pred_territory_has_only_ignored_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsBlitzable(player, u) -> Predicate<Territory>          [private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_blitzable :: struct {
	player: ^Game_Player,
	u:      ^Unit,
}

pro_matches_pred_territory_is_blitzable :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_blitzable)ctx_ptr
	tib_p, tib_c := matches_territory_is_blitzable(ctx.player)
	return tib_p(tib_c, t) && territory_effect_helper_unit_keeps_blitz(ctx.u, t)
}

pro_matches_territory_is_blitzable :: proc(
	player: ^Game_Player,
	u: ^Unit,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_blitzable)
	ctx.player = player
	ctx.u = u
	return pro_matches_pred_territory_is_blitzable, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsNotConqueredOwnedLand(player) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_not_conquered_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_not_conquered_owned_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_not_conquered_owned_land)ctx_ptr
	tracker := abstract_move_delegate_get_battle_tracker(game_player_get_data(ctx.player))
	if battle_tracker_was_conquered(tracker, t) {
		return false
	}
	ob_p, ob_c := matches_is_territory_owned_by(ctx.player)
	if !ob_p(ob_c, t) {
		return false
	}
	il_p, il_c := matches_territory_is_land()
	return il_p(il_c, t)
}

pro_matches_territory_is_not_conquered_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_not_conquered_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_is_not_conquered_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwnedAir(player, isCombatMove) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_air :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_unit_can_be_moved_and_is_owned_air :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_air)ctx_ptr
	if ctx.is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	a_p, a_c := matches_unit_is_air()
	return a_p(a_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned_air :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_air)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_unit_can_be_moved_and_is_owned_air, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwnedBombard(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_bombard :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_can_be_moved_and_is_owned_bombard :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_bombard)ctx_ptr
	nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
	if nm_p(nm_c, u) {
		return false
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	b_p, b_c := matches_unit_can_bombard(ctx.player)
	return b_p(b_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned_bombard :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_bombard)
	ctx.player = player
	return pro_matches_pred_unit_can_be_moved_and_is_owned_bombard, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwnedLand(player, isCombatMove) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_land :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_unit_can_be_moved_and_is_owned_land :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_land)ctx_ptr
	if ctx.is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	l_p, l_c := matches_unit_is_land()
	if !l_p(l_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	return !bt_p(bt_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned_land :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_land)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_unit_can_be_moved_and_is_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwnedSea(player, isCombatMove) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_sea :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_unit_can_be_moved_and_is_owned_sea :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_sea)ctx_ptr
	if ctx.is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	s_p, s_c := matches_unit_is_sea()
	return s_p(s_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned_sea :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_sea)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_unit_can_be_moved_and_is_owned_sea, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwnedTransport(player, isCombatMove) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_transport :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_unit_can_be_moved_and_is_owned_transport :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_transport)ctx_ptr
	if ctx.is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	t_p, t_c := matches_unit_is_sea_transport()
	return t_p(t_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned_transport :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned_transport)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_unit_can_be_moved_and_is_owned_transport, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitHasLessMovementThan(unit) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_has_less_movement_than :: struct {
	unit: ^Unit,
}

pro_matches_pred_unit_has_less_movement_than :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_has_less_movement_than)ctx_ptr
	return unit_get_movement_left(u) < unit_get_movement_left(ctx.unit)
}

pro_matches_unit_has_less_movement_than :: proc(
	unit: ^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_has_less_movement_than)
	ctx.unit = unit
	return pro_matches_pred_unit_has_less_movement_than, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsNeutral() -> Predicate<Unit>                                [private]
// ---------------------------------------------------------------------------

pro_matches_pred_unit_is_neutral :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	_ = ctx_ptr
	return pro_utils_is_neutral_player(unit_get_owner(u))
}

pro_matches_unit_is_neutral :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return pro_matches_pred_unit_is_neutral, nil
}

// ---------------------------------------------------------------------------
// unitIsOwnedCarrier(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_carrier :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_carrier :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_carrier)ctx_ptr
	if unit_attachment_get_carrier_capacity(unit_get_unit_attachment(unit)) == -1 {
		return false
	}
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	return o_p(o_c, unit)
}

pro_matches_unit_is_owned_carrier :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_carrier)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_carrier, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedTransportableUnitAndCanBeLoaded(player, transport, isCombatMove)
//   -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_transportable_unit_and_can_be_loaded :: struct {
	player:         ^Game_Player,
	transport:      ^Unit,
	is_combat_move: bool,
}

pro_matches_pred_unit_is_owned_transportable_unit_and_can_be_loaded :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_transportable_unit_and_can_be_loaded)ctx_ptr
	if ctx.is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
		if !unit_attachment_can_invade_from(unit_get_unit_attachment(u), ctx.transport) {
			return false
		}
	}
	tu_p, tu_c := pro_matches_unit_is_owned_transportable_unit(ctx.player)
	if !tu_p(tu_c, u) {
		return false
	}
	hnm_p, hnm_c := matches_unit_has_not_moved()
	if !hnm_p(hnm_c, u) {
		return false
	}
	hml_p, hml_c := matches_unit_has_movement_left()
	if !hml_p(hml_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	return !bt_p(bt_c, u)
}

pro_matches_unit_is_owned_transportable_unit_and_can_be_loaded :: proc(
	player: ^Game_Player,
	transport: ^Unit,
	is_combat_move: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_transportable_unit_and_can_be_loaded)
	ctx.player = player
	ctx.transport = transport
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_unit_is_owned_transportable_unit_and_can_be_loaded, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveSeaUnitsThrough(player, isCombatMove) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_sea_units_through :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_territory_can_move_sea_units_through :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_sea_units_through)ctx_ptr
	sea_p, sea_c := pro_matches_territory_can_move_sea_units(ctx.player, ctx.is_combat_move)
	if !sea_p(sea_c, t) {
		return false
	}
	ig_p, ig_c := pro_matches_territory_has_only_ignored_units(ctx.player)
	return ig_p(ig_c, t)
}

pro_matches_territory_can_move_sea_units_through :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_sea_units_through)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_territory_can_move_sea_units_through, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveSeaUnitsThroughOrClearedAndNotInList(
//   player, isCombatMove, clearedTerritories, notTerritories) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_sea_units_through_or_cleared_and_not_in_list :: struct {
	player:              ^Game_Player,
	is_combat_move:      bool,
	cleared_territories: [dynamic]^Territory,
	not_territories:     [dynamic]^Territory,
}

pro_matches_pred_territory_can_move_sea_units_through_or_cleared_and_not_in_list :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_sea_units_through_or_cleared_and_not_in_list)ctx_ptr
	sea_p, sea_c := pro_matches_territory_can_move_sea_units(ctx.player, ctx.is_combat_move)
	if !sea_p(sea_c, t) {
		return false
	}
	ig_p, ig_c := pro_matches_territory_has_only_ignored_units(ctx.player)
	in_cleared := false
	for ct in ctx.cleared_territories {
		if ct == t {
			in_cleared = true
			break
		}
	}
	if !ig_p(ig_c, t) && !in_cleared {
		return false
	}
	for nt in ctx.not_territories {
		if nt == t {
			return false
		}
	}
	return true
}

pro_matches_territory_can_move_sea_units_through_or_cleared_and_not_in_list :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
	cleared_territories: [dynamic]^Territory,
	not_territories: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_sea_units_through_or_cleared_and_not_in_list)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	ctx.cleared_territories = cleared_territories
	ctx.not_territories = not_territories
	return pro_matches_pred_territory_can_move_sea_units_through_or_cleared_and_not_in_list, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanPotentiallyMoveAirUnits(player) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_potentially_move_air_units :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_can_potentially_move_air_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_potentially_move_air_units)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	c_p, c_c := matches_territory_does_not_cost_money_to_enter(props)
	if !c_p(c_c, t) {
		return false
	}
	pr_p, pr_c := matches_territory_is_passable_and_not_restricted(ctx.player)
	return pr_p(pr_c, t)
}

pro_matches_territory_can_potentially_move_air_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_potentially_move_air_units)
	ctx.player = player
	return pro_matches_pred_territory_can_potentially_move_air_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasEnemyUnitsOrCantBeHeld(player, territoriesThatCantBeHeld) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_enemy_units_or_cant_be_held :: struct {
	player:                       ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
}

pro_matches_pred_territory_has_enemy_units_or_cant_be_held :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_enemy_units_or_cant_be_held)ctx_ptr
	eu_p, eu_c := matches_territory_has_enemy_units(ctx.player)
	if eu_p(eu_c, t) {
		return true
	}
	for tt in ctx.territories_that_cant_be_held {
		if tt == t {
			return true
		}
	}
	return false
}

pro_matches_territory_has_enemy_units_or_cant_be_held :: proc(
	player: ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_enemy_units_or_cant_be_held)
	ctx.player = player
	ctx.territories_that_cant_be_held = territories_that_cant_be_held
	return pro_matches_pred_territory_has_enemy_units_or_cant_be_held, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasNoEnemyUnitsOrCleared(player, clearedTerritories) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_no_enemy_units_or_cleared :: struct {
	player:              ^Game_Player,
	cleared_territories: [dynamic]^Territory,
}

pro_matches_pred_territory_has_no_enemy_units_or_cleared :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_no_enemy_units_or_cleared)ctx_ptr
	ne_p, ne_c := matches_territory_has_no_enemy_units(ctx.player)
	if ne_p(ne_c, t) {
		return true
	}
	for ct in ctx.cleared_territories {
		if ct == t {
			return true
		}
	}
	return false
}

pro_matches_territory_has_no_enemy_units_or_cleared :: proc(
	player: ^Game_Player,
	cleared_territories: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_no_enemy_units_or_cleared)
	ctx.player = player
	ctx.cleared_territories = cleared_territories
	return pro_matches_pred_territory_has_no_enemy_units_or_cleared, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasNonMobileInfraFactory() -> Predicate<Territory>      [private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_non_mobile_infra_factory_unit :: struct {}

pro_matches_pred_territory_has_non_mobile_infra_factory_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	_ = ctx_ptr
	cp_p, cp_c := matches_unit_can_produce_units()
	if !cp_p(cp_c, u) {
		return false
	}
	inf_p, inf_c := matches_unit_is_infrastructure()
	if !inf_p(inf_c, u) {
		return false
	}
	hm_p, hm_c := matches_unit_has_movement_left()
	return !hm_p(hm_c, u)
}

pro_matches_territory_has_non_mobile_infra_factory :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_territory_has_units_that_match(
		pro_matches_pred_territory_has_non_mobile_infra_factory_unit, nil,
	)
}

// ---------------------------------------------------------------------------
// territoryHasPotentialEnemyUnits(player, players) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_potential_enemy_units :: struct {
	player:  ^Game_Player,
	players: [dynamic]^Game_Player,
}

pro_matches_pred_territory_has_potential_enemy_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_potential_enemy_units)ctx_ptr
	eu_p, eu_c := matches_territory_has_enemy_units(ctx.player)
	if eu_p(eu_c, t) {
		return true
	}
	uoa_p, uoa_c := matches_unit_is_owned_by_any_of(ctx.players)
	tum_p, tum_c := matches_territory_has_units_that_match(uoa_p, uoa_c)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_potential_enemy_units :: proc(
	player: ^Game_Player,
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_potential_enemy_units)
	ctx.player = player
	ctx.players = players
	return pro_matches_pred_territory_has_potential_enemy_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyOrCantBeHeld(player, territoriesThatCantBeHeld) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held :: struct {
	player:                        ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
}

pro_matches_pred_territory_is_enemy_or_cant_be_held :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held)ctx_ptr
	ew_p, ew_c := matches_is_territory_enemy_and_not_unowned_water(ctx.player)
	if ew_p(ew_c, t) {
		return true
	}
	for tt in ctx.territories_that_cant_be_held {
		if tt == t {
			return true
		}
	}
	return false
}

pro_matches_territory_is_enemy_or_cant_be_held :: proc(
	player: ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held)
	ctx.player = player
	ctx.territories_that_cant_be_held = territories_that_cant_be_held
	return pro_matches_pred_territory_is_enemy_or_cant_be_held, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyOrHasEnemyUnitsOrCantBeHeld(player, territoriesThatCantBeHeld)
//   -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_or_has_enemy_units_or_cant_be_held :: struct {
	player:                        ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
}

pro_matches_pred_territory_is_enemy_or_has_enemy_units_or_cant_be_held :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_or_has_enemy_units_or_cant_be_held)ctx_ptr
	ew_p, ew_c := matches_is_territory_enemy_and_not_unowned_water(ctx.player)
	if ew_p(ew_c, t) {
		return true
	}
	eu_p, eu_c := matches_territory_has_enemy_units(ctx.player)
	if eu_p(eu_c, t) {
		return true
	}
	for tt in ctx.territories_that_cant_be_held {
		if tt == t {
			return true
		}
	}
	return false
}

pro_matches_territory_is_enemy_or_has_enemy_units_or_cant_be_held :: proc(
	player: ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_or_has_enemy_units_or_cant_be_held)
	ctx.player = player
	ctx.territories_that_cant_be_held = territories_that_cant_be_held
	return pro_matches_pred_territory_is_enemy_or_has_enemy_units_or_cant_be_held, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsPotentialEnemy(player, players) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_potential_enemy :: struct {
	player:  ^Game_Player,
	players: [dynamic]^Game_Player,
}

pro_matches_pred_territory_is_potential_enemy :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_potential_enemy)ctx_ptr
	ew_p, ew_c := matches_is_territory_enemy_and_not_unowned_water(ctx.player)
	if ew_p(ew_c, t) {
		return true
	}
	oa_p, oa_c := matches_is_territory_owned_by_any_of(ctx.players)
	return oa_p(oa_c, t)
}

pro_matches_territory_is_potential_enemy :: proc(
	player: ^Game_Player,
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_potential_enemy)
	ctx.player = player
	ctx.players = players
	return pro_matches_pred_territory_is_potential_enemy, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitCanBeMovedAndIsOwned(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_can_be_moved_and_is_owned :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_can_be_moved_and_is_owned :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_can_be_moved_and_is_owned)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	m_p, m_c := matches_unit_has_movement_left()
	return m_p(m_c, u)
}

pro_matches_unit_can_be_moved_and_is_owned :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_can_be_moved_and_is_owned)
	ctx.player = player
	return pro_matches_pred_unit_can_be_moved_and_is_owned, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsAlliedAir(player) -> Predicate<Unit>                       [package-private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_allied_air :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_allied_air :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_allied_air)ctx_ptr
	a_p, a_c := matches_is_unit_allied(ctx.player)
	if !a_p(a_c, u) {
		return false
	}
	air_p, air_c := matches_unit_is_air()
	return air_p(air_c, u)
}

pro_matches_unit_is_allied_air :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_allied_air)
	ctx.player = player
	return pro_matches_pred_unit_is_allied_air, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsAlliedNotOwned(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_allied_not_owned :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_allied_not_owned :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_allied_not_owned)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if o_p(o_c, u) {
		return false
	}
	a_p, a_c := matches_is_unit_allied(ctx.player)
	return a_p(a_c, u)
}

pro_matches_unit_is_allied_not_owned :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_allied_not_owned)
	ctx.player = player
	return pro_matches_pred_unit_is_allied_not_owned, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsEnemyAir(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_enemy_air :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_enemy_air :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_enemy_air)ctx_ptr
	e_p, e_c := matches_enemy_unit(ctx.player)
	if !e_p(e_c, u) {
		return false
	}
	a_p, a_c := matches_unit_is_air()
	return a_p(a_c, u)
}

pro_matches_unit_is_enemy_air :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_enemy_air)
	ctx.player = player
	return pro_matches_pred_unit_is_enemy_air, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsEnemyNotNeutral(player) -> Predicate<Unit>                 [package-private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_enemy_not_neutral :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_enemy_not_neutral :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_enemy_not_neutral)ctx_ptr
	e_p, e_c := matches_enemy_unit(ctx.player)
	if !e_p(e_c, u) {
		return false
	}
	n_p, n_c := pro_matches_unit_is_neutral()
	return !n_p(n_c, u)
}

pro_matches_unit_is_enemy_not_neutral :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_enemy_not_neutral)
	ctx.player = player
	return pro_matches_pred_unit_is_enemy_not_neutral, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedAir(player) -> Predicate<Unit>                        [package-private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_air :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_air :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_air)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	a_p, a_c := matches_unit_is_air()
	return a_p(a_c, u)
}

pro_matches_unit_is_owned_air :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_air)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_air, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedAndMatchesTypeAndIsTransporting(player, unitType) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_is_transporting :: struct {
	player:    ^Game_Player,
	unit_type: ^Unit_Type,
}

pro_matches_pred_unit_is_owned_and_matches_type_and_is_transporting :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_is_transporting)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	t_p, t_c := matches_unit_is_of_type(ctx.unit_type)
	if !t_p(t_c, u) {
		return false
	}
	return unit_is_transporting_any(u)
}

pro_matches_unit_is_owned_and_matches_type_and_is_transporting :: proc(
	player: ^Game_Player,
	unit_type: ^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_is_transporting)
	ctx.player = player
	ctx.unit_type = unit_type
	return pro_matches_pred_unit_is_owned_and_matches_type_and_is_transporting, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedAndMatchesTypeAndNotTransporting(player, unitType) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_not_transporting :: struct {
	player:    ^Game_Player,
	unit_type: ^Unit_Type,
}

pro_matches_pred_unit_is_owned_and_matches_type_and_not_transporting :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_not_transporting)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	t_p, t_c := matches_unit_is_of_type(ctx.unit_type)
	if !t_p(t_c, u) {
		return false
	}
	return !unit_is_transporting_any(u)
}

pro_matches_unit_is_owned_and_matches_type_and_not_transporting :: proc(
	player: ^Game_Player,
	unit_type: ^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_and_matches_type_and_not_transporting)
	ctx.player = player
	ctx.unit_type = unit_type
	return pro_matches_pred_unit_is_owned_and_matches_type_and_not_transporting, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedTransport(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_transport :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_transport :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_transport)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	t_p, t_c := matches_unit_is_sea_transport()
	return t_p(t_c, u)
}

pro_matches_unit_is_owned_transport :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_transport)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_transport, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedTransportableUnit(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_transportable_unit :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_transportable_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_transportable_unit)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	cb_p, cb_c := matches_unit_can_be_transported()
	if !cb_p(cb_c, u) {
		return false
	}
	cm_p, cm_c := matches_unit_can_move()
	return cm_p(cm_c, u)
}

pro_matches_unit_is_owned_transportable_unit :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_transportable_unit)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_transportable_unit, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// lambda$territoryIsEnemyNotPassiveNeutralLand$7(t)
//   == t -> !ProUtils.isPassiveNeutralPlayer(t.getOwner())
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_is_enemy_not_passive_neutral_land :: proc(t: ^Territory) -> bool {
	return !pro_utils_is_passive_neutral_player(territory_get_owner(t))
}

// ---------------------------------------------------------------------------
// lambda$territoryIsOrAdjacentToEnemyNotNeutralLand$9(t)
//   == t -> !ProUtils.isPassiveNeutralPlayer(t.getOwner())
// (the inner `isMatch` lambda inside territoryIsOrAdjacentToEnemyNotNeutralLand)
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_is_or_adjacent_to_enemy_not_neutral_land :: proc(t: ^Territory) -> bool {
	return !pro_utils_is_passive_neutral_player(territory_get_owner(t))
}

// ---------------------------------------------------------------------------
// lambda$unitCanBeMovedAndIsOwnedAir$11(isCombatMove, player, u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_can_be_moved_and_is_owned_air :: proc(
	is_combat_move: bool,
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	if is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(player)
	if !o_p(o_c, u) {
		return false
	}
	a_p, a_c := matches_unit_is_air()
	return a_p(a_c, u)
}

// ---------------------------------------------------------------------------
// lambda$unitCanBeMovedAndIsOwnedBombard$15(player, u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_can_be_moved_and_is_owned_bombard :: proc(
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
	if nm_p(nm_c, u) {
		return false
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(player)
	if !o_p(o_c, u) {
		return false
	}
	b_p, b_c := matches_unit_can_bombard(player)
	return b_p(b_c, u)
}

// ---------------------------------------------------------------------------
// lambda$unitCanBeMovedAndIsOwnedLand$12(isCombatMove, player, u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_can_be_moved_and_is_owned_land :: proc(
	is_combat_move: bool,
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	if is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(player)
	if !o_p(o_c, u) {
		return false
	}
	l_p, l_c := matches_unit_is_land()
	if !l_p(l_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	return !bt_p(bt_c, u)
}

// ---------------------------------------------------------------------------
// lambda$unitCanBeMovedAndIsOwnedSea$13(isCombatMove, player, u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_can_be_moved_and_is_owned_sea :: proc(
	is_combat_move: bool,
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	if is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(player)
	if !o_p(o_c, u) {
		return false
	}
	s_p, s_c := matches_unit_is_sea()
	return s_p(s_c, u)
}

// ---------------------------------------------------------------------------
// lambda$unitCanBeMovedAndIsOwnedTransport$14(isCombatMove, player, u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_can_be_moved_and_is_owned_transport :: proc(
	is_combat_move: bool,
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	if is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
	}
	o_p, o_c := pro_matches_unit_can_be_moved_and_is_owned(player)
	if !o_p(o_c, u) {
		return false
	}
	t_p, t_c := matches_unit_is_sea_transport()
	return t_p(t_c, u)
}

// ---------------------------------------------------------------------------
// territoryCanPotentiallyMoveLandUnits(player) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_potentially_move_land_units :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_can_potentially_move_land_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_potentially_move_land_units)ctx_ptr
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	props := game_data_get_properties(game_player_get_data(ctx.player))
	c_p, c_c := matches_territory_does_not_cost_money_to_enter(props)
	if !c_p(c_c, t) {
		return false
	}
	pr_p, pr_c := matches_territory_is_passable_and_not_restricted(ctx.player)
	return pr_p(pr_c, t)
}

pro_matches_territory_can_potentially_move_land_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_potentially_move_land_units)
	ctx.player = player
	return pro_matches_pred_territory_can_potentially_move_land_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasFactoryAndIsOwnedLand(player) -> Predicate<Territory>  [private]
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_factory_and_is_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_factory_and_is_owned_land_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_factory_and_is_owned_land)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	cp_p, cp_c := matches_unit_can_produce_units()
	return cp_p(cp_c, u)
}

pro_matches_pred_territory_has_factory_and_is_owned_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_factory_and_is_owned_land)ctx_ptr
	ob_p, ob_c := matches_is_territory_owned_by(ctx.player)
	if !ob_p(ob_c, t) {
		return false
	}
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	tum_p, tum_c := matches_territory_has_units_that_match(
		pro_matches_pred_territory_has_factory_and_is_owned_land_unit, rawptr(ctx),
	)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_factory_and_is_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_factory_and_is_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_has_factory_and_is_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsLand() -> Predicate<Territory>
// ---------------------------------------------------------------------------

pro_matches_pred_territory_has_infra_factory_and_is_land_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	_ = ctx_ptr
	cp_p, cp_c := matches_unit_can_produce_units()
	if !cp_p(cp_c, u) {
		return false
	}
	inf_p, inf_c := matches_unit_is_infrastructure()
	return inf_p(inf_c, u)
}

pro_matches_pred_territory_has_infra_factory_and_is_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	_ = ctx_ptr
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	tum_p, tum_c := matches_territory_has_units_that_match(
		pro_matches_pred_territory_has_infra_factory_and_is_land_unit, nil,
	)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_infra_factory_and_is_land :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return pro_matches_pred_territory_has_infra_factory_and_is_land, nil
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsOwnedLand(player) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_infra_factory_and_is_owned_land_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	cp_p, cp_c := matches_unit_can_produce_units()
	if !cp_p(cp_c, u) {
		return false
	}
	inf_p, inf_c := matches_unit_is_infrastructure()
	return inf_p(inf_c, u)
}

pro_matches_pred_territory_has_infra_factory_and_is_owned_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land)ctx_ptr
	ob_p, ob_c := matches_is_territory_owned_by(ctx.player)
	if !ob_p(ob_c, t) {
		return false
	}
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	tum_p, tum_c := matches_territory_has_units_that_match(
		pro_matches_pred_territory_has_infra_factory_and_is_owned_land_unit, rawptr(ctx),
	)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_infra_factory_and_is_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_has_infra_factory_and_is_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsAlliedLand(player) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_infra_factory_and_is_allied_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_infra_factory_and_is_allied_land :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_allied_land)ctx_ptr
	a_p, a_c := matches_is_territory_allied(ctx.player)
	if !a_p(a_c, t) {
		return false
	}
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	tum_p, tum_c := matches_territory_has_units_that_match(
		pro_matches_pred_territory_has_infra_factory_and_is_land_unit, nil,
	)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_infra_factory_and_is_allied_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_infra_factory_and_is_allied_land)
	ctx.player = player
	return pro_matches_pred_territory_has_infra_factory_and_is_allied_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasNeighborOwnedByAndHasLandUnit(gameMap, players) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_neighbor_owned_by_and_has_land_unit :: struct {
	players: [dynamic]^Game_Player,
}

pro_matches_pred_territory_has_neighbor_owned_by_and_has_land_unit_inner :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_neighbor_owned_by_and_has_land_unit)ctx_ptr
	oa_p, oa_c := matches_is_territory_owned_by_any_of(ctx.players)
	if !oa_p(oa_c, t) {
		return false
	}
	land_p, land_c := matches_unit_is_land()
	tum_p, tum_c := matches_territory_has_units_that_match(land_p, land_c)
	return tum_p(tum_c, t)
}

pro_matches_territory_has_neighbor_owned_by_and_has_land_unit :: proc(
	game_map: ^Game_Map,
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_neighbor_owned_by_and_has_land_unit)
	ctx.players = players
	return matches_territory_has_neighbor_matching(
		game_map,
		pro_matches_pred_territory_has_neighbor_owned_by_and_has_land_unit_inner,
		rawptr(ctx),
	)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyOrCantBeHeldAndIsAdjacentToMyLandUnits(player, territoriesThatCantBeHeld)
//   -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units :: struct {
	player:                        ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
}

// Inner unit predicate: my unit AND land
pro_matches_pred_te_oc_adj_my_unit_is_land :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	if !o_p(o_c, u) {
		return false
	}
	l_p, l_c := matches_unit_is_land()
	return l_p(l_c, u)
}

// Inner territory predicate: territoryHasUnitsThatMatch(myUnitIsLand)
pro_matches_pred_te_oc_adj_neighbor :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units)ctx_ptr
	tum_p, tum_c := matches_territory_has_units_that_match(
		pro_matches_pred_te_oc_adj_my_unit_is_land, rawptr(ctx),
	)
	return tum_p(tum_c, t)
}

pro_matches_pred_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units)ctx_ptr
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	game_map := game_data_get_map(game_player_get_data(ctx.player))
	hn_p, hn_c := matches_territory_has_neighbor_matching(
		game_map, pro_matches_pred_te_oc_adj_neighbor, rawptr(ctx),
	)
	if !hn_p(hn_c, t) {
		return false
	}
	eh_p, eh_c := pro_matches_territory_is_enemy_or_cant_be_held(ctx.player, ctx.territories_that_cant_be_held)
	return eh_p(eh_c, t)
}

pro_matches_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units :: proc(
	player: ^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units)
	ctx.player = player
	ctx.territories_that_cant_be_held = territories_that_cant_be_held
	return pro_matches_pred_territory_is_enemy_or_cant_be_held_and_is_adjacent_to_my_land_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsPotentialEnemyOrHasPotentialEnemyUnits(player, players) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_potential_enemy_or_has_potential_enemy_units :: struct {
	player:  ^Game_Player,
	players: [dynamic]^Game_Player,
}

pro_matches_pred_territory_is_potential_enemy_or_has_potential_enemy_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_potential_enemy_or_has_potential_enemy_units)ctx_ptr
	pe_p, pe_c := pro_matches_territory_is_potential_enemy(ctx.player, ctx.players)
	if pe_p(pe_c, t) {
		return true
	}
	hp_p, hp_c := pro_matches_territory_has_potential_enemy_units(ctx.player, ctx.players)
	return hp_p(hp_c, t)
}

pro_matches_territory_is_potential_enemy_or_has_potential_enemy_units :: proc(
	player: ^Game_Player,
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_potential_enemy_or_has_potential_enemy_units)
	ctx.player = player
	ctx.players = players
	return pro_matches_pred_territory_is_potential_enemy_or_has_potential_enemy_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsAlliedLandAndNotInfra(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_allied_land_and_not_infra :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_allied_land_and_not_infra :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_allied_land_and_not_infra)ctx_ptr
	l_p, l_c := matches_unit_is_land()
	if !l_p(l_c, u) {
		return false
	}
	a_p, a_c := matches_is_unit_allied(ctx.player)
	if !a_p(a_c, u) {
		return false
	}
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	return ni_p(ni_c, u)
}

pro_matches_unit_is_allied_land_and_not_infra :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_allied_land_and_not_infra)
	ctx.player = player
	return pro_matches_pred_unit_is_allied_land_and_not_infra, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsAlliedNotOwnedAir(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_allied_not_owned_air :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_allied_not_owned_air :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_allied_not_owned_air)ctx_ptr
	an_p, an_c := pro_matches_unit_is_allied_not_owned(ctx.player)
	if !an_p(an_c, u) {
		return false
	}
	a_p, a_c := matches_unit_is_air()
	return a_p(a_c, u)
}

pro_matches_unit_is_allied_not_owned_air :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_allied_not_owned_air)
	ctx.player = player
	return pro_matches_pred_unit_is_allied_not_owned_air, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsEnemyAndNotInfa(player) -> Predicate<Unit>     (sic — Java spelling)
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_enemy_and_not_infa :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_enemy_and_not_infa :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_enemy_and_not_infa)ctx_ptr
	e_p, e_c := matches_enemy_unit(ctx.player)
	if !e_p(e_c, u) {
		return false
	}
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	return ni_p(ni_c, u)
}

pro_matches_unit_is_enemy_and_not_infa :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_enemy_and_not_infa)
	ctx.player = player
	return pro_matches_pred_unit_is_enemy_and_not_infa, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedCombatTransportableUnit(player) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_combat_transportable_unit :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_combat_transportable_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_combat_transportable_unit)ctx_ptr
	tu_p, tu_c := pro_matches_unit_is_owned_transportable_unit(ctx.player)
	if !tu_p(tu_c, u) {
		return false
	}
	nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
	return !nm_p(nm_c, u)
}

pro_matches_unit_is_owned_combat_transportable_unit :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_combat_transportable_unit)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_combat_transportable_unit, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// lambda$territoryIsEnemyNotNeutralLand$8(t)
//   == t -> !ProUtils.isNeutralPlayer(t.getOwner())
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_is_enemy_not_neutral_land :: proc(t: ^Territory) -> bool {
	return !pro_utils_is_neutral_player(territory_get_owner(t))
}

// ---------------------------------------------------------------------------
// lambda$unitIsNeutral$16(u)
//   == u -> ProUtils.isNeutralPlayer(u.getOwner())
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_is_neutral :: proc(u: ^Unit) -> bool {
	return pro_utils_is_neutral_player(unit_get_owner(u))
}

// ---------------------------------------------------------------------------
// lambda$unitIsOwnedCarrier$17(player, unit)
//   == unit -> unit.getUnitAttachment().getCarrierCapacity() != -1
//              && Matches.unitIsOwnedBy(player).test(unit)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_is_owned_carrier :: proc(player: ^Game_Player, unit: ^Unit) -> bool {
	if unit_attachment_get_carrier_capacity(unit_get_unit_attachment(unit)) == -1 {
		return false
	}
	o_p, o_c := matches_unit_is_owned_by(player)
	return o_p(o_c, unit)
}

// ---------------------------------------------------------------------------
// lambda$unitIsOwnedTransportableUnitAndCanBeLoaded$18(isCombatMove, transport, player, u)
//   == u -> (!isCombatMove
//              || (!Matches.unitCanNotMoveDuringCombatMove().test(u)
//                  && u.getUnitAttachment().canInvadeFrom(transport)))
//           && unitIsOwnedTransportableUnit(player)
//                .and(Matches.unitHasNotMoved())
//                .and(Matches.unitHasMovementLeft())
//                .and(Matches.unitIsBeingTransported().negate())
//                .test(u)
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_is_owned_transportable_unit_and_can_be_loaded :: proc(
	is_combat_move: bool,
	transport: ^Unit,
	player: ^Game_Player,
	u: ^Unit,
) -> bool {
	if is_combat_move {
		nm_p, nm_c := matches_unit_can_not_move_during_combat_move()
		if nm_p(nm_c, u) {
			return false
		}
		if !unit_attachment_can_invade_from(unit_get_unit_attachment(u), transport) {
			return false
		}
	}
	tu_p, tu_c := pro_matches_unit_is_owned_transportable_unit(player)
	if !tu_p(tu_c, u) {
		return false
	}
	hnm_p, hnm_c := matches_unit_has_not_moved()
	if !hnm_p(hnm_c, u) {
		return false
	}
	hml_p, hml_c := matches_unit_has_movement_left()
	if !hml_p(hml_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	return !bt_p(bt_c, u)
}

// ---------------------------------------------------------------------------
// territoryHasFactoryAndIsNotConqueredOwnedLand(player) -> Predicate<Territory>
//   == territoryIsNotConqueredOwnedLand(player)
//        .and(territoryHasFactoryAndIsOwnedLand(player))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_factory_and_is_not_conquered_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_factory_and_is_not_conquered_owned_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_factory_and_is_not_conquered_owned_land)ctx_ptr
	nc_p, nc_c := pro_matches_territory_is_not_conquered_owned_land(ctx.player)
	if !nc_p(nc_c, t) {
		return false
	}
	hf_p, hf_c := pro_matches_territory_has_factory_and_is_owned_land(ctx.player)
	return hf_p(hf_c, t)
}

pro_matches_territory_has_factory_and_is_not_conquered_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_factory_and_is_not_conquered_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_has_factory_and_is_not_conquered_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsEnemyLand(player) -> Predicate<Territory>
//   == territoryHasInfraFactoryAndIsLand().and(Matches.isTerritoryEnemy(player))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_infra_factory_and_is_enemy_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_infra_factory_and_is_enemy_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_enemy_land)ctx_ptr
	if_p, if_c := pro_matches_territory_has_infra_factory_and_is_land()
	if !if_p(if_c, t) {
		return false
	}
	en_p, en_c := matches_is_territory_enemy(ctx.player)
	return en_p(en_c, t)
}

pro_matches_territory_has_infra_factory_and_is_enemy_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_infra_factory_and_is_enemy_land)
	ctx.player = player
	return pro_matches_pred_territory_has_infra_factory_and_is_enemy_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsOwnedByPlayersOrCantBeHeld(
//   player, players, territoriesThatCantBeHeld) -> Predicate<Territory>
//
//   ownedAndCantBeHeld   = isTerritoryOwnedBy(player).and(territoriesThatCantBeHeld::contains)
//   enemyOrOwnedCantHeld = isTerritoryOwnedByAnyOf(players).or(ownedAndCantBeHeld)
//   return territoryHasInfraFactoryAndIsLand().and(enemyOrOwnedCantHeld)
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held :: struct {
	player:                        ^Game_Player,
	players:                       [dynamic]^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
}

pro_matches_pred_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held)ctx_ptr
	if_p, if_c := pro_matches_territory_has_infra_factory_and_is_land()
	if !if_p(if_c, t) {
		return false
	}
	oa_p, oa_c := matches_is_territory_owned_by_any_of(ctx.players)
	if oa_p(oa_c, t) {
		return true
	}
	ob_p, ob_c := matches_is_territory_owned_by(ctx.player)
	if !ob_p(ob_c, t) {
		return false
	}
	for ct in ctx.territories_that_cant_be_held {
		if ct == t {
			return true
		}
	}
	return false
}

pro_matches_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held :: proc(
	player: ^Game_Player,
	players: [dynamic]^Game_Player,
	territories_that_cant_be_held: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held)
	ctx.player = player
	ctx.players = players
	ctx.territories_that_cant_be_held = territories_that_cant_be_held
	return pro_matches_pred_territory_has_infra_factory_and_is_owned_by_players_or_cant_be_held, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasInfraFactoryAndIsOwnedLandAdjacentToSea(player) -> Predicate<Territory>
//   == territoryHasInfraFactoryAndIsOwnedLand(player)
//        .and(Matches.territoryHasNeighborMatching(
//               player.getData().getMap(), Matches.territoryIsWater()))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea)ctx_ptr
	if_p, if_c := pro_matches_territory_has_infra_factory_and_is_owned_land(ctx.player)
	if !if_p(if_c, t) {
		return false
	}
	water_p, water_c := matches_territory_is_water()
	game_map := game_data_get_map(game_player_get_data(ctx.player))
	hn_p, hn_c := matches_territory_has_neighbor_matching(game_map, water_p, water_c)
	return hn_p(hn_c, t)
}

pro_matches_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea)
	ctx.player = player
	return pro_matches_pred_territory_has_infra_factory_and_is_owned_land_adjacent_to_sea, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasNoInfraFactoryAndIsNotConqueredOwnedLand(player) -> Predicate<Territory>
//   == territoryIsNotConqueredOwnedLand(player)
//        .and(territoryHasInfraFactoryAndIsOwnedLand(player).negate())
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_no_infra_factory_and_is_not_conquered_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_no_infra_factory_and_is_not_conquered_owned_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_no_infra_factory_and_is_not_conquered_owned_land)ctx_ptr
	nc_p, nc_c := pro_matches_territory_is_not_conquered_owned_land(ctx.player)
	if !nc_p(nc_c, t) {
		return false
	}
	if_p, if_c := pro_matches_territory_has_infra_factory_and_is_owned_land(ctx.player)
	return !if_p(if_c, t)
}

pro_matches_territory_has_no_infra_factory_and_is_not_conquered_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_no_infra_factory_and_is_not_conquered_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_has_no_infra_factory_and_is_not_conquered_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsWaterAndAdjacentToOwnedFactory(player) -> Predicate<Territory>
//
//   hasOwnedFactoryNeighbor = Matches.territoryHasNeighborMatching(
//       player.getData().getMap(),
//       ProMatches.territoryHasInfraFactoryAndIsOwnedLand(player));
//   return hasOwnedFactoryNeighbor.and(territoryCanMoveSeaUnits(player, true));
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_water_and_adjacent_to_owned_factory :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_water_and_adjacent_to_owned_factory :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_water_and_adjacent_to_owned_factory)ctx_ptr
	inner_p, inner_c := pro_matches_territory_has_infra_factory_and_is_owned_land(ctx.player)
	game_map := game_data_get_map(game_player_get_data(ctx.player))
	hn_p, hn_c := matches_territory_has_neighbor_matching(game_map, inner_p, inner_c)
	if !hn_p(hn_c, t) {
		return false
	}
	sea_p, sea_c := pro_matches_territory_can_move_sea_units(ctx.player, true)
	return sea_p(sea_c, t)
}

pro_matches_territory_is_water_and_adjacent_to_owned_factory :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_water_and_adjacent_to_owned_factory)
	ctx.player = player
	return pro_matches_pred_territory_is_water_and_adjacent_to_owned_factory, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsEnemyNotLand(player) -> Predicate<Unit>
//   == Matches.enemyUnit(player).and(Matches.unitIsNotLand())
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_enemy_not_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_enemy_not_land :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_enemy_not_land)ctx_ptr
	e_p, e_c := matches_enemy_unit(ctx.player)
	if !e_p(e_c, u) {
		return false
	}
	nl_p, nl_c := matches_unit_is_not_land()
	return nl_p(nl_c, u)
}

pro_matches_unit_is_enemy_not_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_enemy_not_land)
	ctx.player = player
	return pro_matches_pred_unit_is_enemy_not_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// unitIsOwnedNotLand(player) -> Predicate<Unit>
//   == Matches.unitIsNotLand().and(Matches.unitIsOwnedBy(player))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_is_owned_not_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_unit_is_owned_not_land :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_is_owned_not_land)ctx_ptr
	nl_p, nl_c := matches_unit_is_not_land()
	if !nl_p(nl_c, u) {
		return false
	}
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	return o_p(o_c, u)
}

pro_matches_unit_is_owned_not_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_is_owned_not_land)
	ctx.player = player
	return pro_matches_pred_unit_is_owned_not_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryHasNonMobileFactoryAndIsNotConqueredOwnedLand(player) -> Predicate<Territory>
//   == territoryHasNonMobileInfraFactory()
//        .and(territoryHasFactoryAndIsNotConqueredOwnedLand(player))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_has_non_mobile_factory_and_is_not_conquered_owned_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_has_non_mobile_factory_and_is_not_conquered_owned_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_has_non_mobile_factory_and_is_not_conquered_owned_land)ctx_ptr
	nm_p, nm_c := pro_matches_territory_has_non_mobile_infra_factory()
	if !nm_p(nm_c, t) {
		return false
	}
	hf_p, hf_c := pro_matches_territory_has_factory_and_is_not_conquered_owned_land(ctx.player)
	return hf_p(hf_c, t)
}

pro_matches_territory_has_non_mobile_factory_and_is_not_conquered_owned_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_has_non_mobile_factory_and_is_not_conquered_owned_land)
	ctx.player = player
	return pro_matches_pred_territory_has_non_mobile_factory_and_is_not_conquered_owned_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// lambda$territoryCanMoveSeaUnits$5(player, isCombatMove, t)
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_can_move_sea_units :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
	t: ^Territory,
) -> bool {
	props := game_data_get_properties(game_player_get_data(player))
	naval_may_not_non_com_into_controlled :=
		properties_get_ww2_v2(props) ||
		properties_get_naval_units_may_not_non_combat_move_into_controlled_sea_zones(props)
	if !is_combat_move && naval_may_not_non_com_into_controlled {
		ew_p, ew_c := matches_is_territory_enemy_and_not_unowned_water(player)
		if ew_p(ew_c, t) {
			return false
		}
	}
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		player, is_combat_move, false, true, false, false,
	)
	return p2(c2, t)
}

// ---------------------------------------------------------------------------
// lambda$territoryCanMoveSpecificLandUnit$1(player, isCombatMove, unit, t)
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_can_move_specific_land_unit :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
	unit: ^Unit,
	t: ^Territory,
) -> bool {
	props := game_data_get_properties(game_player_get_data(player))
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		player, is_combat_move, true, false, false, false,
	)
	if !p2(c2, t) {
		return false
	}
	disallowed := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(t)
	pu, cu := matches_unit_is_of_types(disallowed)
	return !pu(cu, unit)
}

// ---------------------------------------------------------------------------
// lambda$territoryCanPotentiallyMoveSpecificLandUnit$2(player, u, t)
// ---------------------------------------------------------------------------

pro_matches_lambda_territory_can_potentially_move_specific_land_unit :: proc(
	player: ^Game_Player,
	u: ^Unit,
	t: ^Territory,
) -> bool {
	props := game_data_get_properties(game_player_get_data(player))
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted(player)
	if !p2(c2, t) {
		return false
	}
	disallowed := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(t)
	pu, cu := matches_unit_is_of_types(disallowed)
	return !pu(cu, u)
}

// ---------------------------------------------------------------------------
// lambda$unitHasLessMovementThan$19(unit, u)
//   == u -> u.getMovementLeft().compareTo(unit.getMovementLeft()) < 0
// ---------------------------------------------------------------------------

pro_matches_lambda_unit_has_less_movement_than :: proc(unit: ^Unit, u: ^Unit) -> bool {
	return unit_get_movement_left(u) < unit_get_movement_left(unit)
}

// ---------------------------------------------------------------------------
// territoryCanLandAirUnits(player, isCombatMove, enemyTerritories,
//                          alliedTerritories) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_land_air_units :: struct {
	player:             ^Game_Player,
	is_combat_move:     bool,
	enemy_territories:  [dynamic]^Territory,
	allied_territories: [dynamic]^Territory,
}

pro_matches_pred_territory_can_land_air_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_land_air_units)ctx_ptr
	for at in ctx.allied_territories {
		if at == t {
			return true
		}
	}
	land_p, land_c := matches_air_can_land_on_this_allied_non_conquered_land_territory(ctx.player)
	if !land_p(land_c, t) {
		return false
	}
	pass_p, pass_c := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		ctx.player, ctx.is_combat_move, false, false, true, true,
	)
	if !pass_p(pass_c, t) {
		return false
	}
	for et in ctx.enemy_territories {
		if et == t {
			return false
		}
	}
	if !ctx.is_combat_move {
		nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
		eu_p, eu_c := matches_is_territory_enemy_and_not_unowned_water_or_impassable_or_restricted(ctx.player)
		if nbnw_p(nbnw_c, t) || eu_p(eu_c, t) {
			return false
		}
	}
	return true
}

pro_matches_territory_can_land_air_units :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
	enemy_territories: [dynamic]^Territory,
	allied_territories: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_land_air_units)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	ctx.enemy_territories = enemy_territories
	ctx.allied_territories = allied_territories
	return pro_matches_pred_territory_can_land_air_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveAirUnits(data, player, isCombatMove) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_air_units :: struct {
	data:           ^Game_State,
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_territory_can_move_air_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_air_units)ctx_ptr
	props := game_state_get_properties(ctx.data)
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		ctx.player, ctx.is_combat_move, false, false, true, false,
	)
	return p2(c2, t)
}

pro_matches_territory_can_move_air_units :: proc(
	data: ^Game_State,
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_air_units)
	ctx.data = data
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_territory_can_move_air_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveLandUnits(player, isCombatMove) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_land_units :: struct {
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_territory_can_move_land_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_land_units)ctx_ptr
	props := game_data_get_properties(game_player_get_data(ctx.player))
	p1, c1 := matches_territory_does_not_cost_money_to_enter(props)
	if !p1(c1, t) {
		return false
	}
	p2, c2 := matches_territory_is_passable_and_not_restricted_and_ok_by_relationships(
		ctx.player, ctx.is_combat_move, true, false, false, false,
	)
	return p2(c2, t)
}

pro_matches_territory_can_move_land_units :: proc(
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_land_units)
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_territory_can_move_land_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveAirUnitsAndNoAa(data, player, isCombatMove) -> Predicate<Territory>
//   == territoryCanMoveAirUnits(data, player, isCombatMove)
//        .and(Matches.territoryHasEnemyAaForFlyOver(player).negate())
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_air_units_and_no_aa :: struct {
	data:           ^Game_State,
	player:         ^Game_Player,
	is_combat_move: bool,
}

pro_matches_pred_territory_can_move_air_units_and_no_aa :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_air_units_and_no_aa)ctx_ptr
	air_p, air_c := pro_matches_territory_can_move_air_units(ctx.data, ctx.player, ctx.is_combat_move)
	if !air_p(air_c, t) {
		return false
	}
	aa_p, aa_c := matches_territory_has_enemy_aa_for_fly_over(ctx.player)
	return !aa_p(aa_c, t)
}

pro_matches_territory_can_move_air_units_and_no_aa :: proc(
	data: ^Game_State,
	player: ^Game_Player,
	is_combat_move: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_air_units_and_no_aa)
	ctx.data = data
	ctx.player = player
	ctx.is_combat_move = is_combat_move
	return pro_matches_pred_territory_can_move_air_units_and_no_aa, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveLandUnitsAndIsAllied(player) -> Predicate<Territory>
//   == Matches.isTerritoryAllied(player).and(territoryCanMoveLandUnits(player, false))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_land_units_and_is_allied :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_can_move_land_units_and_is_allied :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_land_units_and_is_allied)ctx_ptr
	a_p, a_c := matches_is_territory_allied(ctx.player)
	if !a_p(a_c, t) {
		return false
	}
	l_p, l_c := pro_matches_territory_can_move_land_units(ctx.player, false)
	return l_p(l_c, t)
}

pro_matches_territory_can_move_land_units_and_is_allied :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_land_units_and_is_allied)
	ctx.player = player
	return pro_matches_pred_territory_can_move_land_units_and_is_allied, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyLand(player) -> Predicate<Territory>
//   == territoryCanMoveLandUnits(player, false).and(Matches.isTerritoryEnemy(player))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_enemy_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_land)ctx_ptr
	l_p, l_c := pro_matches_territory_can_move_land_units(ctx.player, false)
	if !l_p(l_c, t) {
		return false
	}
	e_p, e_c := matches_is_territory_enemy(ctx.player)
	return e_p(e_c, t)
}

pro_matches_territory_is_enemy_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_land)
	ctx.player = player
	return pro_matches_pred_territory_is_enemy_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryCanMoveLandUnitsThroughIgnoreEnemyUnits(player, u, startTerritory,
//     isCombatMove, blockedTerritories, clearedTerritories) -> Predicate<Territory>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_can_move_land_units_through_ignore_enemy_units :: struct {
	player:               ^Game_Player,
	u:                    ^Unit,
	start_territory:      ^Territory,
	is_combat_move:       bool,
	blocked_territories:  [dynamic]^Territory,
	cleared_territories:  [dynamic]^Territory,
}

pro_matches_pred_territory_can_move_land_units_through_ignore_enemy_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_can_move_land_units_through_ignore_enemy_units)ctx_ptr
	for bt in ctx.blocked_territories {
		if bt == t {
			return false
		}
	}
	cm_p, cm_c := pro_matches_territory_can_move_specific_land_unit(ctx.player, ctx.is_combat_move, ctx.u)
	if !cm_p(cm_c, t) {
		return false
	}
	at_p, at_c := matches_is_territory_allied(ctx.player)
	if at_p(at_c, t) {
		return true
	}
	for ct in ctx.cleared_territories {
		if ct == t {
			return true
		}
	}
	if ctx.is_combat_move {
		ucb_p, ucb_c := matches_unit_can_blitz()
		if ucb_p(ucb_c, ctx.u) && territory_effect_helper_unit_keeps_blitz(ctx.u, ctx.start_territory) {
			tib_p, tib_c := pro_matches_territory_is_blitzable(ctx.player, ctx.u)
			if tib_p(tib_c, t) {
				return true
			}
		}
	}
	return false
}

pro_matches_territory_can_move_land_units_through_ignore_enemy_units :: proc(
	player: ^Game_Player,
	u: ^Unit,
	start_territory: ^Territory,
	is_combat_move: bool,
	blocked_territories: [dynamic]^Territory,
	cleared_territories: [dynamic]^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_can_move_land_units_through_ignore_enemy_units)
	ctx.player = player
	ctx.u = u
	ctx.start_territory = start_territory
	ctx.is_combat_move = is_combat_move
	ctx.blocked_territories = blocked_territories
	ctx.cleared_territories = cleared_territories
	return pro_matches_pred_territory_can_move_land_units_through_ignore_enemy_units, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyNotPassiveNeutralLand(player) -> Predicate<Territory>
//   == territoryIsEnemyLand(player)
//        .and(Matches.territoryIsNeutralButNotWater().negate())
//        .and(t -> !ProUtils.isPassiveNeutralPlayer(t.getOwner()))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_enemy_not_passive_neutral_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_land)ctx_ptr
	el_p, el_c := pro_matches_territory_is_enemy_land(ctx.player)
	if !el_p(el_c, t) {
		return false
	}
	nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
	if nbnw_p(nbnw_c, t) {
		return false
	}
	return !pro_utils_is_passive_neutral_player(territory_get_owner(t))
}

pro_matches_territory_is_enemy_not_passive_neutral_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_land)
	ctx.player = player
	return pro_matches_pred_territory_is_enemy_not_passive_neutral_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyNotNeutralLand(player) -> Predicate<Territory>
//   == territoryIsEnemyLand(player)
//        .and(Matches.territoryIsNeutralButNotWater().negate())
//        .and(t -> !ProUtils.isNeutralPlayer(t.getOwner()))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_not_neutral_land :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_enemy_not_neutral_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_not_neutral_land)ctx_ptr
	el_p, el_c := pro_matches_territory_is_enemy_land(ctx.player)
	if !el_p(el_c, t) {
		return false
	}
	nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
	if nbnw_p(nbnw_c, t) {
		return false
	}
	return !pro_utils_is_neutral_player(territory_get_owner(t))
}

pro_matches_territory_is_enemy_not_neutral_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_not_neutral_land)
	ctx.player = player
	return pro_matches_pred_territory_is_enemy_not_neutral_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsOrAdjacentToEnemyNotNeutralLand(player) -> Predicate<Territory>
//   isMatch    = territoryIsEnemyLand
//                  .and(territoryIsNeutralButNotWater().negate())
//                  .and(t -> !ProUtils.isPassiveNeutralPlayer(t.getOwner()))
//   adjacent   = territoryCanMoveLandUnits(player, false)
//                  .and(territoryHasNeighborMatching(map, isMatch))
//   return     isMatch.or(adjacent)
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_or_adjacent_to_enemy_not_neutral_land :: struct {
	player: ^Game_Player,
}

// inner: same as territoryIsEnemyNotPassiveNeutralLand body
pro_matches_pred_toa_enemy_not_neutral_inner :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_or_adjacent_to_enemy_not_neutral_land)ctx_ptr
	el_p, el_c := pro_matches_territory_is_enemy_land(ctx.player)
	if !el_p(el_c, t) {
		return false
	}
	nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
	if nbnw_p(nbnw_c, t) {
		return false
	}
	return !pro_utils_is_passive_neutral_player(territory_get_owner(t))
}

pro_matches_pred_territory_is_or_adjacent_to_enemy_not_neutral_land :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_or_adjacent_to_enemy_not_neutral_land)ctx_ptr
	if pro_matches_pred_toa_enemy_not_neutral_inner(ctx_ptr, t) {
		return true
	}
	l_p, l_c := pro_matches_territory_can_move_land_units(ctx.player, false)
	if !l_p(l_c, t) {
		return false
	}
	game_map := game_data_get_map(game_player_get_data(ctx.player))
	hn_p, hn_c := matches_territory_has_neighbor_matching(
		game_map, pro_matches_pred_toa_enemy_not_neutral_inner, ctx_ptr,
	)
	return hn_p(hn_c, t)
}

pro_matches_territory_is_or_adjacent_to_enemy_not_neutral_land :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_or_adjacent_to_enemy_not_neutral_land)
	ctx.player = player
	return pro_matches_pred_territory_is_or_adjacent_to_enemy_not_neutral_land, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsAlliedLandAndHasNoEnemyNeighbors(player) -> Predicate<Territory>
//   alliedLand        = territoryCanMoveLandUnits(player, false)
//                          .and(Matches.isTerritoryAllied(player))
//   hasNoEnemyNeighbors = territoryHasNeighborMatching(
//                            map, territoryIsEnemyNotPassiveNeutralLand(player)
//                         ).negate()
//   return alliedLand.and(hasNoEnemyNeighbors)
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_allied_land_and_has_no_enemy_neighbors :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_allied_land_and_has_no_enemy_neighbors :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_allied_land_and_has_no_enemy_neighbors)ctx_ptr
	l_p, l_c := pro_matches_territory_can_move_land_units(ctx.player, false)
	if !l_p(l_c, t) {
		return false
	}
	a_p, a_c := matches_is_territory_allied(ctx.player)
	if !a_p(a_c, t) {
		return false
	}
	game_map := game_data_get_map(game_player_get_data(ctx.player))
	inner_p, inner_c := pro_matches_territory_is_enemy_not_passive_neutral_land(ctx.player)
	hn_p, hn_c := matches_territory_has_neighbor_matching(game_map, inner_p, inner_c)
	return !hn_p(hn_c, t)
}

pro_matches_territory_is_allied_land_and_has_no_enemy_neighbors :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_allied_land_and_has_no_enemy_neighbors)
	ctx.player = player
	return pro_matches_pred_territory_is_allied_land_and_has_no_enemy_neighbors, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// territoryIsEnemyNotPassiveNeutralOrAllied(player) -> Predicate<Territory>
//   == territoryIsEnemyNotPassiveNeutralLand(player)
//        .or(Matches.territoryIsLand().and(Matches.isTerritoryAllied(player)))
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_or_allied :: struct {
	player: ^Game_Player,
}

pro_matches_pred_territory_is_enemy_not_passive_neutral_or_allied :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_or_allied)ctx_ptr
	enpn_p, enpn_c := pro_matches_territory_is_enemy_not_passive_neutral_land(ctx.player)
	if enpn_p(enpn_c, t) {
		return true
	}
	il_p, il_c := matches_territory_is_land()
	if !il_p(il_c, t) {
		return false
	}
	a_p, a_c := matches_is_territory_allied(ctx.player)
	return a_p(a_c, t)
}

pro_matches_territory_is_enemy_not_passive_neutral_or_allied :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_territory_is_enemy_not_passive_neutral_or_allied)
	ctx.player = player
	return pro_matches_pred_territory_is_enemy_not_passive_neutral_or_allied, rawptr(ctx)
}

// ---------------------------------------------------------------------------
// lambda$noCanalsBetweenTerritories$0(player, startTerritory, endTerritory)
// Desugared body of the BiPredicate returned by noCanalsBetweenTerritories.
// ---------------------------------------------------------------------------

pro_matches_lambda_no_canals_between_territories :: proc(
	player: ^Game_Player,
	start_territory: ^Territory,
	end_territory: ^Territory,
) -> bool {
	r := route_new(start_territory, end_territory)
	validator := move_validator_new(game_player_get_data(player), false)
	return move_validator_validate_canal(validator, r, nil, player) == nil
}

// ---------------------------------------------------------------------------
// unitCantBeMovedAndIsAlliedDefender(player, t) -> Predicate<Unit>
// ---------------------------------------------------------------------------

Pro_Matches_Ctx_unit_cant_be_moved_and_is_allied_defender :: struct {
	player: ^Game_Player,
	t:      ^Territory,
}

pro_matches_pred_unit_cant_be_moved_and_is_allied_defender :: proc(
	ctx_ptr: rawptr,
	u: ^Unit,
) -> bool {
	ctx := cast(^Pro_Matches_Ctx_unit_cant_be_moved_and_is_allied_defender)ctx_ptr
	o_p, o_c := matches_unit_is_owned_by(ctx.player)
	is_owned := o_p(o_c, u)
	// myUnitHasNoMovementMatch: owned-by(player) AND !hasMovementLeft
	if is_owned {
		hml_p, hml_c := matches_unit_has_movement_left()
		if !hml_p(hml_c, u) {
			return true
		}
	}
	// alliedUnitMatch: !owned-by(player) AND isUnitAllied(player)
	//                  AND !isBeingTransportedByOrIsDependentOfSomeUnitInThisList(t.units, player, false)
	if is_owned {
		return false
	}
	a_p, a_c := matches_is_unit_allied(ctx.player)
	if !a_p(a_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported_by_or_is_dependent_of_some_unit_in_this_list(
		territory_get_units(ctx.t), ctx.player, false,
	)
	return !bt_p(bt_c, u)
}

pro_matches_unit_cant_be_moved_and_is_allied_defender :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Pro_Matches_Ctx_unit_cant_be_moved_and_is_allied_defender)
	ctx.player = player
	ctx.t = t
	return pro_matches_pred_unit_cant_be_moved_and_is_allied_defender, rawptr(ctx)
}

