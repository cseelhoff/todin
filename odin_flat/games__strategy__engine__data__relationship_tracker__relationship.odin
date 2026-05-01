package game

// games.strategy.engine.data.RelationshipTracker$Relationship

Relationship :: struct {
	relationship_type: ^Relationship_Type,
	round_created:     i32,
}

relationship_new :: proc(tracker: ^Relationship_Tracker, type: ^Relationship_Type, round_created: i32) -> ^Relationship {
	_ = tracker
	r := new(Relationship)
	r.relationship_type = type
	r.round_created = round_created
	return r
}

// games.strategy.engine.data.RelationshipTracker$Relationship#<init>(RelationshipTracker, RelationshipType)
//
//   public Relationship(final RelationshipType relationshipType) {
//     this.relationshipType = relationshipType;
//     this.roundCreated = getData().getSequence().getRound();
//   }
//
// `tracker` is the implicit outer-class reference Java synthesises for the
// inner class. `getData()` lives on Game_Data_Component, embedded in
// Relationship_Tracker via `using`.
relationship_tracker_relationship_new :: proc(tracker: ^Relationship_Tracker, relationship_type: ^Relationship_Type) -> ^Relationship {
	r := new(Relationship)
	r.relationship_type = relationship_type
	data := game_data_component_get_data(&tracker.game_data_component)
	r.round_created = game_sequence_get_round(game_data_get_sequence(data))
	return r
}

relationship_get_relationship_type :: proc(self: ^Relationship) -> ^Relationship_Type {
	return self.relationship_type
}

relationship_get_round_created :: proc(self: ^Relationship) -> i32 {
	return self.round_created
}
