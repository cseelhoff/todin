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
	value := relationship_tracker_relationship_new(self, relationship_type)
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

// games.strategy.engine.data.RelationshipTracker#<init>(GameData)
//
//   public RelationshipTracker(final GameData data) {
//     super(data);
//   }
relationship_tracker_new :: proc(data: ^Game_Data) -> ^Relationship_Tracker {
	self := new(Relationship_Tracker)
	self.game_data_component = make_Game_Data_Component(data)
	self.relationships = make(map[^Related_Players]^Relationship)
	return self
}

// games.strategy.engine.data.RelationshipTracker#setRelationship(GamePlayer, GamePlayer, RelationshipType, int)
//
//   public void setRelationship(
//       final GamePlayer p1, final GamePlayer p2, final RelationshipType r, final int roundValue) {
//     relationships.put(new RelatedPlayers(p1, p2), new Relationship(r, roundValue));
//   }
relationship_tracker_set_relationship_with_round :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player, r: ^Relationship_Type, round_value: i32) {
	key := new(Related_Players)
	key^ = make_Relationship_Tracker_Related_Players(p1, p2)
	value := relationship_new(self, r, round_value)
	self.relationships[key] = value
}

// games.strategy.engine.data.RelationshipTracker#getAllies(GamePlayer, boolean)
//
//   public Set<GamePlayer> getAllies(final GamePlayer gamePlayer, final boolean includeSelf) {
//     final Set<GamePlayer> allies =
//         getData().getPlayerList().getPlayers().stream()
//             .filter(p -> Matches.relationshipTypeIsAllied()
//                              .test(getRelationshipType(gamePlayer, p)))
//             .collect(Collectors.toSet());
//     if (includeSelf) allies.add(gamePlayer); else allies.remove(gamePlayer);
//     return allies;
//   }
relationship_tracker_get_allies :: proc(self: ^Relationship_Tracker, game_player: ^Game_Player, include_self: bool) -> map[^Game_Player]struct{} {
	allies := make(map[^Game_Player]struct{})
	pred, ctx := matches_relationship_type_is_allied()
	players := player_list_get_players(game_data_get_player_list(self.game_data_component.game_data))
	defer delete(players)
	for p in players {
		if pred(ctx, relationship_tracker_get_relationship_type(self, game_player, p)) {
			allies[p] = {}
		}
	}
	if include_self {
		allies[game_player] = {}
	} else {
		delete_key(&allies, game_player)
	}
	return allies
}

// games.strategy.engine.data.RelationshipTracker#getEnemies(GamePlayer)
//
//   public Set<GamePlayer> getEnemies(final GamePlayer p1) {
//     final Set<GamePlayer> enemies =
//         getData().getPlayerList().getPlayers().stream()
//             .filter(p -> Matches.relationshipTypeIsAtWar()
//                              .test(getRelationshipType(p1, p)))
//             .collect(Collectors.toSet());
//     enemies.remove(p1);
//     return enemies;
//   }
relationship_tracker_get_enemies :: proc(self: ^Relationship_Tracker, p1: ^Game_Player) -> map[^Game_Player]struct{} {
	enemies := make(map[^Game_Player]struct{})
	pred, ctx := matches_relationship_type_is_at_war()
	players := player_list_get_players(game_data_get_player_list(self.game_data_component.game_data))
	defer delete(players)
	for p in players {
		if pred(ctx, relationship_tracker_get_relationship_type(self, p1, p)) {
			enemies[p] = {}
		}
	}
	delete_key(&enemies, p1)
	return enemies
}
