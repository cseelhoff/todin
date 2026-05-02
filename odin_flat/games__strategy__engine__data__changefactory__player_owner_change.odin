package game

import "core:fmt"

Player_Owner_Change :: struct {
	using change: Change,
	old_owner_names_by_unit_id: map[Uuid]string,
	new_owner_names_by_unit_id: map[Uuid]string,
	territory_name: string,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.PlayerOwnerChange

// Java: PlayerOwnerChange(Collection<Unit>, GamePlayer, Territory) —
// records the territory name and, for each unit in `units`, the unit's
// current owner name (so the change can be inverted) and the new owner's
// name. Mirrors the package-private Java constructor.
player_owner_change_new :: proc(units: [dynamic]^Unit, new_owner: ^Game_Player, territory: ^Territory) -> ^Player_Owner_Change {
	self := new(Player_Owner_Change)
	self.kind = .Player_Owner_Change
	self.old_owner_names_by_unit_id = make(map[Uuid]string)
	self.new_owner_names_by_unit_id = make(map[Uuid]string)
	self.territory_name = territory.named.base.name
	for unit in units {
		self.old_owner_names_by_unit_id[unit.id] = unit.owner.named.base.name
		self.new_owner_names_by_unit_id[unit.id] = new_owner.named.base.name
	}
	return self
}

// Java: PlayerOwnerChange#lambda$perform$0(GameState, UUID, String)
//   (uuid, newOwnerName) -> {
//     final Unit unit = data.getUnits().get(uuid);
//     if (!oldOwnerNamesByUnitId.get(uuid).equals(unit.getOwner().getName())) {
//       throw new IllegalStateException("Wrong " + unit.getType().getName()
//           + " owner, expecting " + oldOwnerNamesByUnitId.get(uuid)
//           + " but got " + unit.getOwner());
//     }
//     final GamePlayer newOwner = data.getPlayerList().getPlayerId(newOwnerName);
//     unit.setOwner(newOwner);
//   }
// Captured: `data`, `oldOwnerNamesByUnitId`. Hoisted to a free proc; the
// captured map is passed explicitly.
player_owner_change_lambda_perform_0 :: proc(data: ^Game_State, old_owner_names_by_unit_id: map[Uuid]string, uuid: Uuid, new_owner_name: string) {
	unit := units_list_get(game_state_get_units(data), uuid)
	expected_old := old_owner_names_by_unit_id[uuid]
	current_owner := unit_get_owner(unit)
	if expected_old != current_owner.named.base.name {
		fmt.panicf("Wrong %s owner, expecting %s but got %s",
			unit_get_type(unit).named.base.name,
			expected_old,
			current_owner.named.base.name)
	}
	new_owner := player_list_get_player_id(game_state_get_player_list(data), new_owner_name)
	unit_set_owner(unit, new_owner)
}

// Java: PlayerOwnerChange#perform(GameState)
//   newOwnerNamesByUnitId.forEach((uuid, newOwnerName) -> { ... });
//   data.getMap().getTerritoryOrThrow(territoryName).notifyChanged();
player_owner_change_perform :: proc(self: ^Player_Owner_Change, data: ^Game_State) {
	for uuid, new_owner_name in self.new_owner_names_by_unit_id {
		player_owner_change_lambda_perform_0(data, self.old_owner_names_by_unit_id, uuid, new_owner_name)
	}
	territory_notify_changed(game_map_get_territory_or_throw(game_state_get_map(data), self.territory_name))
}

