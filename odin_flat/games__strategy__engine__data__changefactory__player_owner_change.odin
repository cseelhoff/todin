package game

Player_Owner_Change :: struct {
	using change: Change,
	old_owner_names_by_unit_id: map[Uuid]string,
	new_owner_names_by_unit_id: map[Uuid]string,
	territory_name: string,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.PlayerOwnerChange

