package game

// games.strategy.engine.data.RelationshipTracker
//
// Pairwise diplomatic relationships keyed by Related_Players (unordered pair).
// Related_Players and Relationship are inner classes in Java; defined as
// top-level structs here in their own files.

Relationship_Tracker :: struct {
	relationships: map[Related_Players]^Relationship,
}
