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

// games.strategy.engine.data.RelationshipTracker#getRelationships(GamePlayer)
//
//   public Set<Relationship> getRelationships(@Nonnull final GamePlayer player1) {
//     final Set<Relationship> relationships = new HashSet<>();
//     for (final GamePlayer player2 : getData().getPlayerList().getPlayers()) {
//       if (player2 == null || player2.equals(player1)) continue;
//       relationships.add(getRelationship(player1, player2));
//     }
//     return relationships;
//   }
relationship_tracker_get_relationships :: proc(self: ^Relationship_Tracker, player1: ^Game_Player) -> map[^Relationship]struct{} {
	result := make(map[^Relationship]struct{})
	players := player_list_get_players(game_data_get_player_list(self.game_data_component.game_data))
	defer delete(players)
	for player2 in players {
		if player2 == nil || player2 == player1 {
			continue
		}
		rel := relationship_tracker_get_relationship_players(self, player1, player2)
		result[rel] = {}
	}
	return result
}

// games.strategy.engine.data.RelationshipTracker#getSelfRelationshipType()
//
//   private RelationshipType getSelfRelationshipType() {
//     return getData().getRelationshipTypeList().getSelfRelation();
//   }
relationship_tracker_get_self_relationship_type :: proc(self: ^Relationship_Tracker) -> ^Relationship_Type {
	return relationship_type_list_get_self_relation(game_data_get_relationship_type_list(self.game_data_component.game_data))
}

// games.strategy.engine.data.RelationshipTracker#getNullRelationshipType()
//
//   private RelationshipType getNullRelationshipType() {
//     return getData().getRelationshipTypeList().getNullRelation();
//   }
relationship_tracker_get_null_relationship_type :: proc(self: ^Relationship_Tracker) -> ^Relationship_Type {
	return relationship_type_list_get_null_relation(game_data_get_relationship_type_list(self.game_data_component.game_data))
}

// games.strategy.engine.data.RelationshipTracker#isAllied(GamePlayer, GamePlayer)
//
//   public boolean isAllied(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeIsAllied().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_is_allied :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_allied()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#isAtWar(GamePlayer, GamePlayer)
//
//   public boolean isAtWar(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeIsAtWar().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_is_at_war :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_at_war()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canMoveLandUnitsOverOwnedLand(GamePlayer, GamePlayer)
//
//   public boolean canMoveLandUnitsOverOwnedLand(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanMoveLandUnitsOverOwnedLand()
//         .test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_move_land_units_over_owned_land :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_move_land_units_over_owned_land()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canMoveAirUnitsOverOwnedLand(GamePlayer, GamePlayer)
//
//   public boolean canMoveAirUnitsOverOwnedLand(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanMoveAirUnitsOverOwnedLand().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_move_air_units_over_owned_land :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_move_air_units_over_owned_land()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canLandAirUnitsOnOwnedLand(GamePlayer, GamePlayer)
//
//   public boolean canLandAirUnitsOnOwnedLand(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanLandAirUnitsOnOwnedLand().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_land_air_units_on_owned_land :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_land_air_units_on_owned_land()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canTakeOverOwnedTerritory(GamePlayer, GamePlayer)
//
//   public boolean canTakeOverOwnedTerritory(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanTakeOverOwnedTerritory().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_take_over_owned_territory :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_take_over_owned_territory()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canMoveIntoDuringCombatMove(GamePlayer, GamePlayer)
//
//   public boolean canMoveIntoDuringCombatMove(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanMoveIntoDuringCombatMove().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_move_into_during_combat_move :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_move_into_during_combat_move()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#canMoveThroughCanals(GamePlayer, GamePlayer)
//
//   public boolean canMoveThroughCanals(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeCanMoveThroughCanals().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_can_move_through_canals :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_can_move_through_canals()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#rocketsCanFlyOver(GamePlayer, GamePlayer)
//
//   public boolean rocketsCanFlyOver(final GamePlayer p1, final GamePlayer p2) {
//     return Matches.relationshipTypeRocketsCanFlyOver().test(getRelationshipType(p1, p2));
//   }
relationship_tracker_rockets_can_fly_over :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_rockets_can_fly_over()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#setSelfRelations()
//
//   public void setSelfRelations() {
//     for (final GamePlayer p : getData().getPlayerList().getPlayers()) {
//       setRelationship(p, p, getSelfRelationshipType());
//     }
//     setRelationship(
//         getData().getPlayerList().getNullPlayer(),
//         getData().getPlayerList().getNullPlayer(),
//         getSelfRelationshipType());
//   }
relationship_tracker_set_self_relations :: proc(self: ^Relationship_Tracker) {
	player_list := game_data_get_player_list(self.game_data_component.game_data)
	players := player_list_get_players(player_list)
	defer delete(players)
	self_rel := relationship_tracker_get_self_relationship_type(self)
	for p in players {
		relationship_tracker_set_relationship(self, p, p, self_rel)
	}
	null_player := player_list_get_null_player(player_list)
	relationship_tracker_set_relationship(self, null_player, null_player, self_rel)
}

// games.strategy.engine.data.RelationshipTracker#setNullPlayerRelations()
//
//   public void setNullPlayerRelations() {
//     for (final GamePlayer p : getData().getPlayerList().getPlayers()) {
//       setRelationship(p, getData().getPlayerList().getNullPlayer(), getNullRelationshipType());
//     }
//   }
relationship_tracker_set_null_player_relations :: proc(self: ^Relationship_Tracker) {
	player_list := game_data_get_player_list(self.game_data_component.game_data)
	players := player_list_get_players(player_list)
	defer delete(players)
	null_player := player_list_get_null_player(player_list)
	null_rel := relationship_tracker_get_null_relationship_type(self)
	for p in players {
		relationship_tracker_set_relationship(self, p, null_player, null_rel)
	}
}

// games.strategy.engine.data.RelationshipTracker#lambda$isAlliedWithAnyOfThesePlayers$0(GamePlayer, GamePlayer)
//
//   p2 -> Matches.relationshipTypeIsAllied().test(getRelationshipType(gamePlayer, p2))
relationship_tracker_lambda_is_allied_with_any_of_these_players_0 :: proc(self: ^Relationship_Tracker, game_player: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_allied()
	return pred(ctx, relationship_tracker_get_relationship_type(self, game_player, p2))
}

// games.strategy.engine.data.RelationshipTracker#lambda$getAllies$1(GamePlayer, GamePlayer)
//
//   player -> Matches.relationshipTypeIsAllied().test(getRelationshipType(gamePlayer, player))
relationship_tracker_lambda_get_allies_1 :: proc(self: ^Relationship_Tracker, game_player: ^Game_Player, player: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_allied()
	return pred(ctx, relationship_tracker_get_relationship_type(self, game_player, player))
}

// games.strategy.engine.data.RelationshipTracker#lambda$isAtWarWithAnyOfThesePlayers$2(GamePlayer, GamePlayer)
//
//   p2 -> Matches.relationshipTypeIsAtWar().test(getRelationshipType(p1, p2))
relationship_tracker_lambda_is_at_war_with_any_of_these_players_2 :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, p2: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_at_war()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, p2))
}

// games.strategy.engine.data.RelationshipTracker#lambda$getEnemies$3(GamePlayer, GamePlayer)
//
//   player -> Matches.relationshipTypeIsAtWar().test(getRelationshipType(p1, player))
relationship_tracker_lambda_get_enemies_3 :: proc(self: ^Relationship_Tracker, p1: ^Game_Player, player: ^Game_Player) -> bool {
	pred, ctx := matches_relationship_type_is_at_war()
	return pred(ctx, relationship_tracker_get_relationship_type(self, p1, player))
}
