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
