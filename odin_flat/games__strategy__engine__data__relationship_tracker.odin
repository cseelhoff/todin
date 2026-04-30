package game

// games.strategy.engine.data.RelationshipTracker
//
// Pairwise diplomatic relationships keyed by Related_Players (unordered pair).
// Related_Players and Relationship are inner classes in Java; defined as
// top-level structs here in their own files.

Relationship_Tracker :: struct {
	using game_data_component: Game_Data_Component,
	relationships: map[^Related_Players]^Relationship,
}

relationship_tracker_get_relationship_related :: proc(self: ^Relationship_Tracker, p1p2: ^Related_Players) -> ^Relationship {
	return self.relationships[p1p2]
}

relationship_tracker_get_relationship_type :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> ^Relationship_Type {
	return relationship_tracker_get_relationship(self, p1, p2).relationship_type
}

// games.strategy.engine.data.RelationshipTracker#getRelationship(GamePlayer, GamePlayer)
//
//   public Relationship getRelationship(GamePlayer p1, GamePlayer p2) {
//     return getRelationship(new RelatedPlayers(p1, p2));
//   }
//
// Map keys are ^Related_Players, so a freshly allocated probe key would never
// match by pointer identity. Honor Java's value-equality semantics by scanning
// the map with related_players_equals.
relationship_tracker_get_relationship_players :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> ^Relationship {
	probe := Related_Players{player1 = p1, player2 = p2}
	for key, value in self.relationships {
		if related_players_equals(key, &probe) {
			return value
		}
	}
	return nil
}

// games.strategy.engine.data.RelationshipTracker#setRelationship(GamePlayer, GamePlayer, RelationshipType)
//
//   public void setRelationship(GamePlayer p1, GamePlayer p2, RelationshipType relationshipType) {
//     relationships.put(new RelatedPlayers(p1, p2), new Relationship(relationshipType));
//   }
relationship_tracker_set_relationship :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player, relationship_type: ^Relationship_Type) {
	key := relationship_tracker_related_players_new(p1, p2)
	value := relationship_tracker_relationship_new(relationship_type)
	self.relationships[key] = value
}

// games.strategy.engine.data.RelationshipTracker#isAtWarWithAnyOfThesePlayers(GamePlayer, Collection<GamePlayer>)
//
//   public boolean isAtWarWithAnyOfThesePlayers(
//       final GamePlayer p1, final Collection<GamePlayer> p2s) {
//     return p2s.stream()
//         .anyMatch(p2 -> Matches.relationshipTypeIsAtWar().test(getRelationshipType(p1, p2)));
//   }
relationship_tracker_is_at_war_with_any_of_these_players :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2s: [dynamic]^Game_Player) -> bool {
	predicate := matches_relationship_type_is_at_war()
	for p2 in p2s {
		if predicate(relationship_tracker_get_relationship_type(self, p1, p2)) {
			return true
		}
	}
	return false
}

// games.strategy.engine.data.RelationshipTracker#isAlliedWithAnyOfThesePlayers(GamePlayer, Collection<GamePlayer>)
//
//   public boolean isAlliedWithAnyOfThesePlayers(
//       final GamePlayer gamePlayer, final Collection<GamePlayer> possibleAllies) {
//     return possibleAllies.stream()
//         .anyMatch(
//             p2 -> Matches.relationshipTypeIsAllied().test(getRelationshipType(gamePlayer, p2)));
//   }
relationship_tracker_is_allied_with_any_of_these_players :: proc(self: ^Relationship_Tracker, player: ^Game_Player, others: [dynamic]^Game_Player) -> bool {
	predicate := matches_relationship_type_is_allied()
	for p2 in others {
		if predicate(relationship_tracker_get_relationship_type(self, player, p2)) {
			return true
		}
	}
	return false
}
