package game

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

