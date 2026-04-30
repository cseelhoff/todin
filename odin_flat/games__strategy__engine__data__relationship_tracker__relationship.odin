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

relationship_get_relationship_type :: proc(self: ^Relationship) -> ^Relationship_Type {
	return self.relationship_type
}

relationship_get_round_created :: proc(self: ^Relationship) -> i32 {
	return self.round_created
}
