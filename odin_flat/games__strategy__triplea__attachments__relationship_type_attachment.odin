package game

// Java owners covered by this file:
//   - games.strategy.triplea.attachments.RelationshipTypeAttachment

Relationship_Type_Attachment :: struct {
	using parent: Default_Attachment,
	arche_type: string,
	can_move_land_units_over_owned_land: string,
	can_move_air_units_over_owned_land: string,
	alliances_can_chain_together: string,
	is_default_war_position: string,
	upkeep_cost: string,
	can_land_air_units_on_owned_land: string,
	can_take_over_owned_territory: string,
	gives_back_original_territories: string,
	can_move_into_during_combat_move: string,
	can_move_through_canals: string,
	rockets_can_fly_over: string,
}
