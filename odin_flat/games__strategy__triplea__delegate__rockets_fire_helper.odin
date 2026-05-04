package game

Rockets_Fire_Helper :: struct {
	attacking_from_territories:  map[^Territory]struct{},
	attacked_territories:        map[^Territory]^Territory,
	attacked_units:              map[^Territory]^Unit,
	need_to_find_rocket_targets: bool,
}

rockets_fire_helper_new :: proc() -> ^Rockets_Fire_Helper {
	helper := new(Rockets_Fire_Helper)
	helper.attacking_from_territories = make(map[^Territory]struct{})
	helper.attacked_territories = make(map[^Territory]^Territory)
	helper.attacked_units = make(map[^Territory]^Unit)
	helper.need_to_find_rocket_targets = false
	return helper
}

// games.strategy.triplea.delegate.RocketsFireHelper#getRemote(IDelegateBridge)
//
//   private static Player getRemote(final IDelegateBridge bridge) {
//     return bridge.getRemotePlayer();
//   }
rockets_fire_helper_get_remote :: proc(bridge: ^I_Delegate_Bridge) -> ^Player {
	return i_delegate_bridge_get_remote_player(bridge)
}

// games.strategy.triplea.delegate.RocketsFireHelper#getTarget(Collection,IDelegateBridge,Territory)
//
//   private static Territory getTarget(
//       final Collection<Territory> targets,
//       final IDelegateBridge bridge,
//       final Territory from) {
//     return bridge.getRemotePlayer().whereShouldRocketsAttack(targets, from);
//   }
rockets_fire_helper_get_target :: proc(
	targets: [dynamic]^Territory,
	bridge:  ^I_Delegate_Bridge,
	from:    ^Territory,
) -> ^Territory {
	remote := i_delegate_bridge_get_remote_player(bridge)
	return player_where_should_rockets_attack(remote, targets, from)
}

// games.strategy.triplea.delegate.RocketsFireHelper#rocketMatch(GamePlayer)
//
//   private static Predicate<Unit> rocketMatch(final GamePlayer player) {
//     return Matches.unitIsRocket()
//         .and(Matches.unitIsOwnedBy(player))
//         .and(Matches.unitIsNotDisabled())
//         .and(Matches.unitIsBeingTransported().negate())
//         .and(Matches.unitIsSubmerged().negate())
//         .and(Matches.unitHasNotMoved());
//   }
Rockets_Fire_Helper_Ctx_rocket_match :: struct {
	player: ^Game_Player,
}

rockets_fire_helper_pred_rocket_match :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Rockets_Fire_Helper_Ctx_rocket_match)ctx_ptr
	rp, rc := matches_unit_is_rocket()
	if !rp(rc, u) {
		return false
	}
	op, oc := matches_unit_is_owned_by(c.player)
	if !op(oc, u) {
		return false
	}
	np, nc := matches_unit_is_not_disabled()
	if !np(nc, u) {
		return false
	}
	bp, bc := matches_unit_is_being_transported()
	if bp(bc, u) {
		return false
	}
	sp, sc := matches_unit_is_submerged()
	if sp(sc, u) {
		return false
	}
	mp, mc := matches_unit_has_not_moved()
	return mp(mc, u)
}

rockets_fire_helper_rocket_match :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Rockets_Fire_Helper_Ctx_rocket_match)
	ctx.player = player
	return rockets_fire_helper_pred_rocket_match, rawptr(ctx)
}

// games.strategy.triplea.delegate.RocketsFireHelper#getTerritoriesWithRockets(GameData,GamePlayer)
//
//   static Set<Territory> getTerritoriesWithRockets(final GameData data, final GamePlayer player) {
//     final Set<Territory> territories = new HashSet<>();
//     final Predicate<Unit> ownedRockets = rocketMatch(player);
//     final BattleTracker tracker = AbstractMoveDelegate.getBattleTracker(data);
//     for (final Territory current : data.getMap()) {
//       if (tracker.wasConquered(current)) {
//         continue;
//       }
//       if (current.anyUnitsMatch(ownedRockets)) {
//         territories.add(current);
//       }
//     }
//     return territories;
//   }
rockets_fire_helper_get_territories_with_rockets :: proc(
	data:   ^Game_Data,
	player: ^Game_Player,
) -> map[^Territory]struct{} {
	territories := make(map[^Territory]struct{})
	owned_rockets_fn, owned_rockets_ctx := rockets_fire_helper_rocket_match(player)
	tracker := abstract_move_delegate_get_battle_tracker(data)
	for current in game_map_get_territories(game_data_get_map(data)) {
		if battle_tracker_was_conquered(tracker, current) {
			continue
		}
		if territory_any_units_match(current, owned_rockets_fn, owned_rockets_ctx) {
			territories[current] = {}
		}
	}
	return territories
}
