package game

Matches :: struct {}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.Matches



// =====================================================================
// games.strategy.triplea.delegate.Matches — chunk 1 / 4 (54 procs).
// Predicate factories use the project's rawptr-ctx convention:
//   `matches_<name>(...)` returns (proc(rawptr, ^T) -> bool, rawptr).
// Non-capturing predicates pass nil as the userdata. Forward references
// to as-yet-unported helpers (other matches_*, properties_*, relationship_*,
// territory_attachment_*, abstract_move_delegate_*, battle_tracker_*,
// political_action_attachment_get_relationship_changes,
// game_player_is_allied / is_at_war / am_not_dead_yet / is_at_war_with_*
// / is_allied_with_*, unit_attachment_get_targets_aa, etc.) live elsewhere
// in odin_flat/ and resolve at package scope.
// =====================================================================

// ---------------------------------------------------------------------
// Lambda bodies (Java javac synthetics in this chunk).
// Standalone procs per llm-instructions.md: `matches_lambda_<name>_<N>`
// with the captured variables as leading params.
// ---------------------------------------------------------------------

// lambda$territoryHasUnitsThatMatch$153(Predicate, Territory)
// Body: t -> t.anyUnitsMatch(cond)
matches_lambda_territory_has_units_that_match_153 :: proc(
	cond: proc(rawptr, ^Unit) -> bool,
	cond_ctx: rawptr,
	t: ^Territory,
) -> bool {
	for u in t.unit_collection.units {
		if cond(cond_ctx, u) {
			return true
		}
	}
	return false
}

// lambda$territoryIs$150(Territory, Territory)
// Body: t -> t.equals(test)
matches_lambda_territory_is_150 :: proc(test: ^Territory, t: ^Territory) -> bool {
	return t == test
}

// lambda$territoryIsOriginallyOwnedBy$222(GamePlayer, GamePlayer)
// Body (Optional.map step): gamePlayer -> gamePlayer.equals(player)
matches_lambda_territory_is_originally_owned_by_222 :: proc(
	player: ^Game_Player,
	game_player: ^Game_Player,
) -> bool {
	return game_player == player
}

// lambda$territoryIsOriginallyOwnedBy$223(GamePlayer)
// Body (Optional.orElseGet step): () -> player == null
matches_lambda_territory_is_originally_owned_by_223 :: proc(player: ^Game_Player) -> bool {
	return player == nil
}

// lambda$unitCanBeGivenBonusMovementByFacilitiesInItsTerritory$177(Predicate, Territory)
// Body: t -> t.anyUnitsMatch(givesBonusUnitLand)
matches_lambda_unit_can_be_given_bonus_movement_by_facilities_in_its_territory_177 :: proc(
	gives_bonus_unit_land: proc(rawptr, ^Unit) -> bool,
	gives_bonus_unit_land_ctx: rawptr,
	t: ^Territory,
) -> bool {
	for u in t.unit_collection.units {
		if gives_bonus_unit_land(gives_bonus_unit_land_ctx, u) {
			return true
		}
	}
	return false
}

// lambda$unitIsBeingTransportedByOrIsDependentOfSomeUnitInThisList$165(Unit, Collection)
// Body (in carrierMustMoveWith.values().stream().anyMatch): c -> c.contains(dependent)
matches_lambda_unit_is_being_transported_by_or_is_dependent_of_some_unit_in_this_list_165 :: proc(
	dependent: ^Unit,
	c: [dynamic]^Unit,
) -> bool {
	for u in c {
		if u == dependent {
			return true
		}
	}
	return false
}

// lambda$unitIsInTerritory$138(Territory, Unit)
// Body: u -> territory.getUnits().contains(u)
matches_lambda_unit_is_in_territory_138 :: proc(territory: ^Territory, u: ^Unit) -> bool {
	for x in territory.unit_collection.units {
		if x == u {
			return true
		}
	}
	return false
}

// lambda$unitTypeCanBeHitByAaFire$79(Collection, UnitTypeList, UnitType)
// Outer lambda body: unitType -> aaFiringUnits.stream().anyMatch(
//     ut -> ut.getUnitAttachment().getTargetsAa(unitTypeList).contains(unitType))
matches_lambda_unit_type_can_be_hit_by_aa_fire_79 :: proc(
	aa_firing_units: [dynamic]^Unit_Type,
	unit_type_list: ^Unit_Type_List,
	unit_type: ^Unit_Type,
) -> bool {
	for ut in aa_firing_units {
		ua := unit_type_get_unit_attachment(ut)
		targets := unit_attachment_get_targets_aa(ua, unit_type_list)
		if _, ok := targets[unit_type]; ok {
			return true
		}
	}
	return false
}

// ---------------------------------------------------------------------
// Predicate factories.
// ---------------------------------------------------------------------

// abstractUserActionAttachmentCanBeAttempted(Map<ICondition, Boolean>)
//   uaa -> uaa.hasAttemptsLeft() && uaa.canPerform(testedConditions)
Matches_Ctx_abstract_user_action_attachment_can_be_attempted :: struct {
	tested_conditions: map[^I_Condition]bool,
}

matches_pred_abstract_user_action_attachment_can_be_attempted :: proc(
	ctx_ptr: rawptr,
	uaa: ^Abstract_User_Action_Attachment,
) -> bool {
	c := cast(^Matches_Ctx_abstract_user_action_attachment_can_be_attempted)ctx_ptr
	return abstract_user_action_attachment_has_attempts_left(uaa) &&
		abstract_user_action_attachment_can_perform(uaa, c.tested_conditions)
}

matches_abstract_user_action_attachment_can_be_attempted :: proc(
	tested_conditions: map[^I_Condition]bool,
) -> (proc(rawptr, ^Abstract_User_Action_Attachment) -> bool, rawptr) {
	ctx := new(Matches_Ctx_abstract_user_action_attachment_can_be_attempted)
	ctx.tested_conditions = tested_conditions
	return matches_pred_abstract_user_action_attachment_can_be_attempted, rawptr(ctx)
}

// airCanFlyOver(GamePlayer, boolean)
Matches_Ctx_air_can_fly_over :: struct {
	player:                       ^Game_Player,
	are_neutrals_passable_by_air: bool,
}

matches_pred_air_can_fly_over :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_air_can_fly_over)ctx_ptr
	if !c.are_neutrals_passable_by_air {
		nbnw_p, nbnw_c := matches_territory_is_neutral_but_not_water()
		if nbnw_p(nbnw_c, t) {
			return false
		}
	}
	pnr_p, pnr_c := matches_territory_is_passable_and_not_restricted(c.player)
	if !pnr_p(pnr_c, t) {
		return false
	}
	land_p, land_c := matches_territory_is_land()
	if land_p(land_c, t) {
		rt := game_data_get_relationship_tracker(game_player_get_data(c.player))
		if !relationship_tracker_can_move_air_units_over_owned_land(rt, c.player, t.owner) {
			return false
		}
	}
	return true
}

matches_air_can_fly_over :: proc(
	player: ^Game_Player,
	are_neutrals_passable_by_air: bool,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_air_can_fly_over)
	ctx.player = player
	ctx.are_neutrals_passable_by_air = are_neutrals_passable_by_air
	return matches_pred_air_can_fly_over, rawptr(ctx)
}

// airCanLandOnThisAlliedNonConqueredLandTerritory(GamePlayer)
Matches_Ctx_air_can_land_on_this_allied_non_conquered_land_territory :: struct {
	player: ^Game_Player,
}

matches_pred_air_can_land_on_this_allied_non_conquered_land_territory :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_air_can_land_on_this_allied_non_conquered_land_territory)ctx_ptr
	land_p, land_c := matches_territory_is_land()
	if !land_p(land_c, t) {
		return false
	}
	bt := abstract_move_delegate_get_battle_tracker(game_player_get_data(c.player))
	if battle_tracker_was_conquered(bt, t) {
		return false
	}
	owner := t.owner
	if game_player_is_null(owner) {
		return false
	}
	rt := game_data_get_relationship_tracker(game_player_get_data(c.player))
	if !relationship_tracker_can_move_air_units_over_owned_land(rt, c.player, owner) {
		return false
	}
	if !relationship_tracker_can_land_air_units_on_owned_land(rt, c.player, owner) {
		return false
	}
	return true
}

matches_air_can_land_on_this_allied_non_conquered_land_territory :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_air_can_land_on_this_allied_non_conquered_land_territory)
	ctx.player = player
	return matches_pred_air_can_land_on_this_allied_non_conquered_land_territory, rawptr(ctx)
}

// alliedUnit(GamePlayer)
//   unit -> unit.isOwnedBy(player) || player.isAllied(unit.getOwner())
Matches_Ctx_allied_unit :: struct {
	player: ^Game_Player,
}

matches_pred_allied_unit :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_allied_unit)ctx_ptr
	if unit_is_owned_by(unit, c.player) {
		return true
	}
	return game_player_is_allied(c.player, unit_get_owner(unit))
}

matches_allied_unit :: proc(player: ^Game_Player) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_allied_unit)
	ctx.player = player
	return matches_pred_allied_unit, rawptr(ctx)
}

// battleIsAmphibious() — IBattle::isAmphibious
matches_pred_battle_is_amphibious :: proc(_: rawptr, b: ^I_Battle) -> bool {
	return i_battle_is_amphibious(b)
}

matches_battle_is_amphibious :: proc() -> (proc(rawptr, ^I_Battle) -> bool, rawptr) {
	return matches_pred_battle_is_amphibious, nil
}

// battleIsEmpty() — IBattle::isEmpty
matches_pred_battle_is_empty :: proc(_: rawptr, b: ^I_Battle) -> bool {
	return i_battle_is_empty(b)
}

matches_battle_is_empty :: proc() -> (proc(rawptr, ^I_Battle) -> bool, rawptr) {
	return matches_pred_battle_is_empty, nil
}

// enemyUnit(GamePlayer)
//   unit -> player.isAtWar(unit.getOwner())
Matches_Ctx_enemy_unit :: struct {
	player: ^Game_Player,
}

matches_pred_enemy_unit :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_enemy_unit)ctx_ptr
	return game_player_is_at_war(c.player, unit_get_owner(unit))
}

matches_enemy_unit :: proc(player: ^Game_Player) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_enemy_unit)
	ctx.player = player
	return matches_pred_enemy_unit, rawptr(ctx)
}

// isAllied(GamePlayer) — Predicate<GamePlayer>: player::isAllied
Matches_Ctx_is_allied :: struct {
	player: ^Game_Player,
}

matches_pred_is_allied :: proc(ctx_ptr: rawptr, other: ^Game_Player) -> bool {
	c := cast(^Matches_Ctx_is_allied)ctx_ptr
	return game_player_is_allied(c.player, other)
}

matches_is_allied :: proc(player: ^Game_Player) -> (proc(rawptr, ^Game_Player) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_allied)
	ctx.player = player
	return matches_pred_is_allied, rawptr(ctx)
}

// isAlliedAndAlliancesCanChainTogether(GamePlayer)
//   player2 -> relationshipTypeIsAlliedAndAlliancesCanChainTogether()
//                .test(player.getData().getRelationshipTracker()
//                            .getRelationshipType(player, player2))
Matches_Ctx_is_allied_and_alliances_can_chain_together :: struct {
	player: ^Game_Player,
}

matches_pred_is_allied_and_alliances_can_chain_together :: proc(
	ctx_ptr: rawptr,
	player2: ^Game_Player,
) -> bool {
	c := cast(^Matches_Ctx_is_allied_and_alliances_can_chain_together)ctx_ptr
	rt := game_data_get_relationship_tracker(game_player_get_data(c.player))
	rtype := relationship_tracker_get_relationship_type(rt, c.player, player2)
	p, ctx2 := matches_relationship_type_is_allied_and_alliances_can_chain_together()
	return p(ctx2, rtype)
}

matches_is_allied_and_alliances_can_chain_together :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Game_Player) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_allied_and_alliances_can_chain_together)
	ctx.player = player
	return matches_pred_is_allied_and_alliances_can_chain_together, rawptr(ctx)
}

// isAtWar(GamePlayer) — Predicate<GamePlayer>: player::isAtWar
Matches_Ctx_is_at_war :: struct {
	player: ^Game_Player,
}

matches_pred_is_at_war :: proc(ctx_ptr: rawptr, other: ^Game_Player) -> bool {
	c := cast(^Matches_Ctx_is_at_war)ctx_ptr
	return game_player_is_at_war(c.player, other)
}

matches_is_at_war :: proc(player: ^Game_Player) -> (proc(rawptr, ^Game_Player) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_at_war)
	ctx.player = player
	return matches_pred_is_at_war, rawptr(ctx)
}

// isAtWarWithAnyOfThesePlayers(Collection<GamePlayer>)
//   player2 -> player2.isAtWarWithAnyOfThesePlayers(players)
Matches_Ctx_is_at_war_with_any_of_these_players :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_is_at_war_with_any_of_these_players :: proc(
	ctx_ptr: rawptr,
	player2: ^Game_Player,
) -> bool {
	c := cast(^Matches_Ctx_is_at_war_with_any_of_these_players)ctx_ptr
	return game_player_is_at_war_with_any_of_these_players(player2, c.players)
}

matches_is_at_war_with_any_of_these_players :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Game_Player) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_at_war_with_any_of_these_players)
	ctx.players = players
	return matches_pred_is_at_war_with_any_of_these_players, rawptr(ctx)
}

// isTerritoryAllied(GamePlayer) — t -> player.isAllied(t.getOwner())
Matches_Ctx_is_territory_allied :: struct {
	player: ^Game_Player,
}

matches_pred_is_territory_allied :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_allied)ctx_ptr
	return game_player_is_allied(c.player, t.owner)
}

matches_is_territory_allied :: proc(player: ^Game_Player) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_allied)
	ctx.player = player
	return matches_pred_is_territory_allied, rawptr(ctx)
}

// isTerritoryEnemy(GamePlayer)
//   t -> !t.isOwnedBy(player) && player.isAtWar(t.getOwner())
Matches_Ctx_is_territory_enemy :: struct {
	player: ^Game_Player,
}

matches_pred_is_territory_enemy :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_enemy)ctx_ptr
	if territory_is_owned_by(t, c.player) {
		return false
	}
	return game_player_is_at_war(c.player, t.owner)
}

matches_is_territory_enemy :: proc(player: ^Game_Player) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_enemy)
	ctx.player = player
	return matches_pred_is_territory_enemy, rawptr(ctx)
}

// isTerritoryEnemyAndNotUnownedWater(GamePlayer)
//   t -> !t.isOwnedBy(player) && (!t.getOwner().isNull() || !t.isWater())
//          && player.isAtWar(t.getOwner())
Matches_Ctx_is_territory_enemy_and_not_unowned_water :: struct {
	player: ^Game_Player,
}

matches_pred_is_territory_enemy_and_not_unowned_water :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_enemy_and_not_unowned_water)ctx_ptr
	if territory_is_owned_by(t, c.player) {
		return false
	}
	if game_player_is_null(t.owner) && t.water {
		return false
	}
	return game_player_is_at_war(c.player, t.owner)
}

matches_is_territory_enemy_and_not_unowned_water :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_enemy_and_not_unowned_water)
	ctx.player = player
	return matches_pred_is_territory_enemy_and_not_unowned_water, rawptr(ctx)
}

// isTerritoryFriendly(GamePlayer)
//   t -> t.isWater() || t.isOwnedBy(player) || player.isAllied(t.getOwner())
Matches_Ctx_is_territory_friendly :: struct {
	player: ^Game_Player,
}

matches_pred_is_territory_friendly :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_friendly)ctx_ptr
	if t.water {
		return true
	}
	if territory_is_owned_by(t, c.player) {
		return true
	}
	return game_player_is_allied(c.player, t.owner)
}

matches_is_territory_friendly :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_friendly)
	ctx.player = player
	return matches_pred_is_territory_friendly, rawptr(ctx)
}

// isTerritoryNeutral() — t -> t.getOwner().isNull()
matches_pred_is_territory_neutral :: proc(_: rawptr, t: ^Territory) -> bool {
	return game_player_is_null(t.owner)
}

matches_is_territory_neutral :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_is_territory_neutral, nil
}

// isTerritoryOwnedBy(GamePlayer) — t -> t.isOwnedBy(player)
Matches_Ctx_is_territory_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_is_territory_owned_by :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_owned_by)ctx_ptr
	return territory_is_owned_by(t, c.player)
}

matches_is_territory_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_owned_by)
	ctx.player = player
	return matches_pred_is_territory_owned_by, rawptr(ctx)
}

// isTerritoryOwnedByAnyOf(Collection<GamePlayer>)
//   t -> players.contains(t.getOwner())
Matches_Ctx_is_territory_owned_by_any_of :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_is_territory_owned_by_any_of :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_is_territory_owned_by_any_of)ctx_ptr
	for p in c.players {
		if p == t.owner {
			return true
		}
	}
	return false
}

matches_is_territory_owned_by_any_of :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_territory_owned_by_any_of)
	ctx.players = players
	return matches_pred_is_territory_owned_by_any_of, rawptr(ctx)
}

// isUnitAllied(GamePlayer) — u -> player.isAllied(u.getOwner())
Matches_Ctx_is_unit_allied :: struct {
	player: ^Game_Player,
}

matches_pred_is_unit_allied :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_is_unit_allied)ctx_ptr
	return game_player_is_allied(c.player, unit_get_owner(u))
}

matches_is_unit_allied :: proc(player: ^Game_Player) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_unit_allied)
	ctx.player = player
	return matches_pred_is_unit_allied, rawptr(ctx)
}

// politicalActionAffectsAtLeastOneAlivePlayer(GamePlayer)
Matches_Ctx_political_action_affects_at_least_one_alive_player :: struct {
	current_player: ^Game_Player,
}

matches_pred_political_action_affects_at_least_one_alive_player :: proc(
	ctx_ptr: rawptr,
	paa: ^Political_Action_Attachment,
) -> bool {
	c := cast(^Matches_Ctx_political_action_affects_at_least_one_alive_player)ctx_ptr
	for change in political_action_attachment_get_relationship_changes(paa) {
		p1 := change.player1
		p2 := change.player2
		if c.current_player != p1 && game_player_am_not_dead_yet(p1) {
			return true
		}
		if c.current_player != p2 && game_player_am_not_dead_yet(p2) {
			return true
		}
	}
	return false
}

matches_political_action_affects_at_least_one_alive_player :: proc(
	current_player: ^Game_Player,
) -> (proc(rawptr, ^Political_Action_Attachment) -> bool, rawptr) {
	ctx := new(Matches_Ctx_political_action_affects_at_least_one_alive_player)
	ctx.current_player = current_player
	return matches_pred_political_action_affects_at_least_one_alive_player, rawptr(ctx)
}

// politicalActionIsRelationshipChangeOf(GamePlayer, Predicate<RelationshipType>,
//     Predicate<RelationshipType>, RelationshipTracker)
Matches_Ctx_political_action_is_relationship_change_of :: struct {
	player:               ^Game_Player, // may be nil
	current_relation:     proc(rawptr, ^Relationship_Type) -> bool,
	current_relation_ctx: rawptr,
	new_relation:         proc(rawptr, ^Relationship_Type) -> bool,
	new_relation_ctx:     rawptr,
	relationship_tracker: ^Relationship_Tracker,
}

matches_pred_political_action_is_relationship_change_of :: proc(
	ctx_ptr: rawptr,
	paa: ^Political_Action_Attachment,
) -> bool {
	c := cast(^Matches_Ctx_political_action_is_relationship_change_of)ctx_ptr
	for change in political_action_attachment_get_relationship_changes(paa) {
		p1 := change.player1
		p2 := change.player2
		if c.player != nil && !(p1 == c.player || p2 == c.player) {
			continue
		}
		current_type := relationship_tracker_get_relationship_type(c.relationship_tracker, p1, p2)
		new_type := change.relationship_type
		if c.current_relation(c.current_relation_ctx, current_type) &&
			c.new_relation(c.new_relation_ctx, new_type) {
			return true
		}
	}
	return false
}

matches_political_action_is_relationship_change_of :: proc(
	player: ^Game_Player,
	current_relation: proc(rawptr, ^Relationship_Type) -> bool,
	current_relation_ctx: rawptr,
	new_relation: proc(rawptr, ^Relationship_Type) -> bool,
	new_relation_ctx: rawptr,
	relationship_tracker: ^Relationship_Tracker,
) -> (proc(rawptr, ^Political_Action_Attachment) -> bool, rawptr) {
	ctx := new(Matches_Ctx_political_action_is_relationship_change_of)
	ctx.player = player
	ctx.current_relation = current_relation
	ctx.current_relation_ctx = current_relation_ctx
	ctx.new_relation = new_relation
	ctx.new_relation_ctx = new_relation_ctx
	ctx.relationship_tracker = relationship_tracker
	return matches_pred_political_action_is_relationship_change_of, rawptr(ctx)
}

// relationshipIsAtWar()
//   r -> r.getRelationshipType().getRelationshipTypeAttachment().isWar()
matches_pred_relationship_is_at_war :: proc(_: rawptr, r: ^Relationship) -> bool {
	rt := relationship_get_relationship_type(r)
	rta := relationship_type_get_relationship_type_attachment(rt)
	return relationship_type_attachment_is_war(rta)
}

matches_relationship_is_at_war :: proc() -> (proc(rawptr, ^Relationship) -> bool, rawptr) {
	return matches_pred_relationship_is_at_war, nil
}

// Helper: every relationship_type_* predicate factory below has the same shape:
//   relationship -> relationship.getRelationshipTypeAttachment().<flag>()
// We emit one trampoline per flag for clarity.

// relationshipTypeCanLandAirUnitsOnOwnedLand()
matches_pred_relationship_type_can_land_air_units_on_owned_land :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_land_air_units_on_owned_land(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_land_air_units_on_owned_land :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_land_air_units_on_owned_land, nil
}

// relationshipTypeCanMoveAirUnitsOverOwnedLand()
matches_pred_relationship_type_can_move_air_units_over_owned_land :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_move_air_units_over_owned_land(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_move_air_units_over_owned_land :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_move_air_units_over_owned_land, nil
}

// relationshipTypeCanMoveIntoDuringCombatMove()
matches_pred_relationship_type_can_move_into_during_combat_move :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_move_into_during_combat_move(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_move_into_during_combat_move :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_move_into_during_combat_move, nil
}

// relationshipTypeCanMoveLandUnitsOverOwnedLand()
matches_pred_relationship_type_can_move_land_units_over_owned_land :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_move_land_units_over_owned_land(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_move_land_units_over_owned_land :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_move_land_units_over_owned_land, nil
}

// relationshipTypeCanMoveThroughCanals()
matches_pred_relationship_type_can_move_through_canals :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_move_through_canals(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_move_through_canals :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_move_through_canals, nil
}

// relationshipTypeCanTakeOverOwnedTerritory()
matches_pred_relationship_type_can_take_over_owned_territory :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_take_over_owned_territory(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_can_take_over_owned_territory :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_can_take_over_owned_territory, nil
}

// relationshipTypeIsAllied()
matches_pred_relationship_type_is_allied :: proc(_: rawptr, rt: ^Relationship_Type) -> bool {
	return relationship_type_attachment_is_allied(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_is_allied :: proc() -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_is_allied, nil
}

// relationshipTypeIsAlliedAndAlliancesCanChainTogether()
//   rt -> relationshipTypeIsAllied().test(rt)
//          && rt.getRelationshipTypeAttachment().canAlliancesChainTogether()
matches_pred_relationship_type_is_allied_and_alliances_can_chain_together :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	rta := relationship_type_get_relationship_type_attachment(rt)
	if !relationship_type_attachment_is_allied(rta) {
		return false
	}
	return relationship_type_attachment_can_alliances_chain_together(rta)
}

matches_relationship_type_is_allied_and_alliances_can_chain_together :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_is_allied_and_alliances_can_chain_together, nil
}

// relationshipTypeIsAtWar()
matches_pred_relationship_type_is_at_war :: proc(_: rawptr, rt: ^Relationship_Type) -> bool {
	return relationship_type_attachment_is_war(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_is_at_war :: proc() -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_is_at_war, nil
}

// relationshipTypeIsNeutral()
matches_pred_relationship_type_is_neutral :: proc(_: rawptr, rt: ^Relationship_Type) -> bool {
	return relationship_type_attachment_is_neutral(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_is_neutral :: proc() -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_is_neutral, nil
}

// relationshipTypeRocketsCanFlyOver()
matches_pred_relationship_type_rockets_can_fly_over :: proc(
	_: rawptr,
	rt: ^Relationship_Type,
) -> bool {
	return relationship_type_attachment_can_rockets_fly_over(
		relationship_type_get_relationship_type_attachment(rt),
	)
}

matches_relationship_type_rockets_can_fly_over :: proc(
) -> (proc(rawptr, ^Relationship_Type) -> bool, rawptr) {
	return matches_pred_relationship_type_rockets_can_fly_over, nil
}

// seaCanMoveOver(GamePlayer)
//   t -> t.isWater() && territoryIsPassableAndNotRestricted(player).test(t)
Matches_Ctx_sea_can_move_over :: struct {
	player: ^Game_Player,
}

matches_pred_sea_can_move_over :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_sea_can_move_over)ctx_ptr
	if !t.water {
		return false
	}
	p, pc := matches_territory_is_passable_and_not_restricted(c.player)
	return p(pc, t)
}

matches_sea_can_move_over :: proc(player: ^Game_Player) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_sea_can_move_over)
	ctx.player = player
	return matches_pred_sea_can_move_over, rawptr(ctx)
}

// territoryAllowsRocketsCanFlyOver(GamePlayer)
Matches_Ctx_territory_allows_rockets_can_fly_over :: struct {
	player: ^Game_Player,
}

matches_pred_territory_allows_rockets_can_fly_over :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_allows_rockets_can_fly_over)ctx_ptr
	land_p, land_c := matches_territory_is_land()
	if !land_p(land_c, t) {
		return true
	}
	owner := t.owner
	if game_player_is_null(owner) {
		return true
	}
	rt := game_data_get_relationship_tracker(game_player_get_data(c.player))
	return relationship_tracker_rockets_can_fly_over(rt, c.player, owner)
}

matches_territory_allows_rockets_can_fly_over :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_allows_rockets_can_fly_over)
	ctx.player = player
	return matches_pred_territory_allows_rockets_can_fly_over, rawptr(ctx)
}

// territoryDoesNotCostMoneyToEnter(GameProperties)
//   t -> t.isWater() || !t.getOwner().isNull() || Properties.getNeutralCharge(properties) <= 0
Matches_Ctx_territory_does_not_cost_money_to_enter :: struct {
	properties: ^Game_Properties,
}

matches_pred_territory_does_not_cost_money_to_enter :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_does_not_cost_money_to_enter)ctx_ptr
	if t.water {
		return true
	}
	if !game_player_is_null(t.owner) {
		return true
	}
	return properties_get_neutral_charge(c.properties) <= 0
}

matches_territory_does_not_cost_money_to_enter :: proc(
	properties: ^Game_Properties,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_does_not_cost_money_to_enter)
	ctx.properties = properties
	return matches_pred_territory_does_not_cost_money_to_enter, rawptr(ctx)
}

// territoryHasAlliedIsFactoryOrCanProduceUnits(GamePlayer)
//   t -> isTerritoryAllied(player).test(t) && t.anyUnitsMatch(unitCanProduceUnits())
Matches_Ctx_territory_has_allied_is_factory_or_can_produce_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_allied_is_factory_or_can_produce_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_has_allied_is_factory_or_can_produce_units)ctx_ptr
	a_p, a_c := matches_is_territory_allied(c.player)
	if !a_p(a_c, t) {
		return false
	}
	pu_p, pu_c := matches_unit_can_produce_units()
	for u in t.unit_collection.units {
		if pu_p(pu_c, u) {
			return true
		}
	}
	return false
}

matches_territory_has_allied_is_factory_or_can_produce_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_allied_is_factory_or_can_produce_units)
	ctx.player = player
	return matches_pred_territory_has_allied_is_factory_or_can_produce_units, rawptr(ctx)
}

// territoryHasAlliedUnits(GamePlayer) — t -> t.anyUnitsMatch(alliedUnit(player))
Matches_Ctx_territory_has_allied_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_allied_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_allied_units)ctx_ptr
	p, pc := matches_allied_unit(c.player)
	for u in t.unit_collection.units {
		if p(pc, u) {
			return true
		}
	}
	return false
}

matches_territory_has_allied_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_allied_units)
	ctx.player = player
	return matches_pred_territory_has_allied_units, rawptr(ctx)
}

// territoryHasCaptureOwnershipChanges()
//   t -> !TerritoryAttachment.get(t).map(TerritoryAttachment::getCaptureOwnershipChanges)
//          .orElse(List.of()).isEmpty()
matches_pred_territory_has_capture_ownership_changes :: proc(_: rawptr, t: ^Territory) -> bool {
	ta := t.territory_attachment
	if ta == nil {
		return false
	}
	return len(territory_attachment_get_capture_ownership_changes(ta)) > 0
}

matches_territory_has_capture_ownership_changes :: proc(
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_has_capture_ownership_changes, nil
}

// territoryHasEnemyAaForFlyOver(GamePlayer)
//   t -> t.anyUnitsMatch(unitIsEnemyAaForFlyOver(player))
//        where unitIsEnemyAaForFlyOver = unitIsAaForFlyOverOnly().and(enemyUnit(player))
Matches_Ctx_territory_has_enemy_aa_for_fly_over :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_enemy_aa_for_fly_over :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_enemy_aa_for_fly_over)ctx_ptr
	aa_p, aa_c := matches_unit_is_aa_for_fly_over_only()
	en_p, en_c := matches_enemy_unit(c.player)
	for u in t.unit_collection.units {
		if aa_p(aa_c, u) && en_p(en_c, u) {
			return true
		}
	}
	return false
}

matches_territory_has_enemy_aa_for_fly_over :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_enemy_aa_for_fly_over)
	ctx.player = player
	return matches_pred_territory_has_enemy_aa_for_fly_over, rawptr(ctx)
}

// territoryHasEnemySeaUnits(GamePlayer)
//   t -> t.anyUnitsMatch(enemyUnit(player).and(unitIsSea()))
Matches_Ctx_territory_has_enemy_sea_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_enemy_sea_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_enemy_sea_units)ctx_ptr
	en_p, en_c := matches_enemy_unit(c.player)
	se_p, se_c := matches_unit_is_sea()
	for u in t.unit_collection.units {
		if en_p(en_c, u) && se_p(se_c, u) {
			return true
		}
	}
	return false
}

matches_territory_has_enemy_sea_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_enemy_sea_units)
	ctx.player = player
	return matches_pred_territory_has_enemy_sea_units, rawptr(ctx)
}

// territoryHasEnemyUnits(GamePlayer) — t -> t.anyUnitsMatch(enemyUnit(player))
Matches_Ctx_territory_has_enemy_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_enemy_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_enemy_units)ctx_ptr
	p, pc := matches_enemy_unit(c.player)
	for u in t.unit_collection.units {
		if p(pc, u) {
			return true
		}
	}
	return false
}

matches_territory_has_enemy_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_enemy_units)
	ctx.player = player
	return matches_pred_territory_has_enemy_units, rawptr(ctx)
}

// territoryHasEnemyUnitsThatCanCaptureItAndIsOwnedByTheirEnemy(GamePlayer)
Matches_Ctx_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy)ctx_ptr
	en_p, en_c := matches_enemy_unit(c.player)
	na_p, na_c := matches_unit_is_not_air()
	ni_p, ni_c := matches_unit_is_not_infrastructure()
	enemy_players := make([dynamic]^Game_Player)
	seen := make(map[^Game_Player]struct{})
	defer delete(seen)
	for u in t.unit_collection.units {
		if !en_p(en_c, u) {
			continue
		}
		if !na_p(na_c, u) {
			continue
		}
		if !ni_p(ni_c, u) {
			continue
		}
		owner := unit_get_owner(u)
		if _, ok := seen[owner]; !ok {
			seen[owner] = struct{}{}
			append(&enemy_players, owner)
		}
	}
	wp_p, wp_c := matches_is_at_war_with_any_of_these_players(enemy_players)
	return wp_p(wp_c, t.owner)
}

matches_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy)
	ctx.player = player
	return matches_pred_territory_has_enemy_units_that_can_capture_it_and_is_owned_by_their_enemy, rawptr(ctx)
}

// territoryHasNeighborMatching(GameMap, Predicate<Territory>)
//   t -> !gameMap.getNeighbors(t, match).isEmpty()
Matches_Ctx_territory_has_neighbor_matching :: struct {
	game_map:  ^Game_Map,
	match:     proc(rawptr, ^Territory) -> bool,
	match_ctx: rawptr,
}

matches_pred_territory_has_neighbor_matching :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_neighbor_matching)ctx_ptr
	neighbors := game_map_get_neighbors_predicate(c.game_map, t, c.match, c.match_ctx)
	return len(neighbors) > 0
}

matches_territory_has_neighbor_matching :: proc(
	game_map: ^Game_Map,
	match: proc(rawptr, ^Territory) -> bool,
	match_ctx: rawptr,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_neighbor_matching)
	ctx.game_map = game_map
	ctx.match = match
	ctx.match_ctx = match_ctx
	return matches_pred_territory_has_neighbor_matching, rawptr(ctx)
}

// territoryHasNoEnemyUnits(GamePlayer) — t -> !t.anyUnitsMatch(enemyUnit(player))
Matches_Ctx_territory_has_no_enemy_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_no_enemy_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_no_enemy_units)ctx_ptr
	p, pc := matches_enemy_unit(c.player)
	for u in t.unit_collection.units {
		if p(pc, u) {
			return false
		}
	}
	return true
}

matches_territory_has_no_enemy_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_no_enemy_units)
	ctx.player = player
	return matches_pred_territory_has_no_enemy_units, rawptr(ctx)
}

// territoryHasNonSubmergedEnemyUnits(GamePlayer)
//   t -> t.anyUnitsMatch(enemyUnit(player).and(not(unitIsSubmerged())))
Matches_Ctx_territory_has_non_submerged_enemy_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_non_submerged_enemy_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_non_submerged_enemy_units)ctx_ptr
	en_p, en_c := matches_enemy_unit(c.player)
	sm_p, sm_c := matches_unit_is_submerged()
	for u in t.unit_collection.units {
		if en_p(en_c, u) && !sm_p(sm_c, u) {
			return true
		}
	}
	return false
}

matches_territory_has_non_submerged_enemy_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_non_submerged_enemy_units)
	ctx.player = player
	return matches_pred_territory_has_non_submerged_enemy_units, rawptr(ctx)
}

// territoryHasOwnedAtBeginningOfTurnIsFactoryOrCanProduceUnits(GamePlayer)
//   private — checks combinedTurns ownership, has-can-produce, not-conquered.
Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units)ctx_ptr
	data := game_player_get_data(c.player)
	combined := game_step_properties_helper_get_combined_turns(data, c.player)
	owner_in_combined := false
	for p in combined {
		if p == t.owner {
			owner_in_combined = true
			break
		}
	}
	if !owner_in_combined {
		return false
	}
	pu_p, pu_c := matches_unit_can_produce_units()
	any := false
	for u in t.unit_collection.units {
		if pu_p(pu_c, u) {
			any = true
			break
		}
	}
	if !any {
		return false
	}
	bt := abstract_move_delegate_get_battle_tracker(data)
	return !(bt == nil || battle_tracker_was_conquered(bt, t))
}

matches_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units)
	ctx.player = player
	return matches_pred_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units, rawptr(ctx)
}

// =====================================================================
// Matches.java — chunk 2 / 4 (55 procs).
// Continues the rawptr-ctx predicate convention from chunk 1. Forward
// references to as-yet-unported helpers (other matches_*, properties_*,
// territory_attachment_*, transport_tracker_*, unit_attachment_get_*,
// game_player_*, etc.) live elsewhere in odin_flat/ and resolve at
// package scope.
// =====================================================================

// territoryHasOwnedAtBeginningOfTurnIsFactoryOrCanProduceUnitsNeighbor
// (GamePlayer)
//   t -> !player.getData().getMap()
//          .getNeighbors(t, territoryHasOwnedAtBeginningOfTurnIsFactoryOrCanProduceUnits(player))
//          .isEmpty()
Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor)ctx_ptr
	inner_p, inner_c := matches_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units(c.player)
	gm := game_data_get_map(game_player_get_data(c.player))
	neighbors := game_map_get_neighbors_predicate(gm, t, inner_p, inner_c)
	return len(neighbors) > 0
}

matches_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor)
	ctx.player = player
	return matches_pred_territory_has_owned_at_beginning_of_turn_is_factory_or_can_produce_units_neighbor, rawptr(ctx)
}

// territoryHasOwnedCarrier(GamePlayer)
//   t -> t.anyUnitsMatch(unitIsOwnedBy(player).and(unitIsCarrier()))
Matches_Ctx_territory_has_owned_carrier :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_owned_carrier :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_owned_carrier)ctx_ptr
	ca_p, ca_c := matches_unit_is_carrier()
	for u in t.unit_collection.units {
		if unit_is_owned_by(u, c.player) && ca_p(ca_c, u) {
			return true
		}
	}
	return false
}

matches_territory_has_owned_carrier :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_owned_carrier)
	ctx.player = player
	return matches_pred_territory_has_owned_carrier, rawptr(ctx)
}

// territoryHasUnitsOwnedBy(GamePlayer)
//   t -> t.anyUnitsMatch(unitIsOwnedBy(player))
Matches_Ctx_territory_has_units_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_units_owned_by :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_units_owned_by)ctx_ptr
	for u in t.unit_collection.units {
		if unit_is_owned_by(u, c.player) {
			return true
		}
	}
	return false
}

matches_territory_has_units_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_units_owned_by)
	ctx.player = player
	return matches_pred_territory_has_units_owned_by, rawptr(ctx)
}

// territoryHasUnitsThatMatch(Predicate<Unit>) — t -> t.anyUnitsMatch(cond)
Matches_Ctx_territory_has_units_that_match :: struct {
	cond:     proc(rawptr, ^Unit) -> bool,
	cond_ctx: rawptr,
}

matches_pred_territory_has_units_that_match :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_units_that_match)ctx_ptr
	for u in t.unit_collection.units {
		if c.cond(c.cond_ctx, u) {
			return true
		}
	}
	return false
}

matches_territory_has_units_that_match :: proc(
	cond: proc(rawptr, ^Unit) -> bool,
	cond_ctx: rawptr,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_units_that_match)
	ctx.cond = cond
	ctx.cond_ctx = cond_ctx
	return matches_pred_territory_has_units_that_match, rawptr(ctx)
}

// territoryIs(Territory) — t -> t.equals(test)
Matches_Ctx_territory_is :: struct {
	test: ^Territory,
}

matches_pred_territory_is :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_is)ctx_ptr
	return t == c.test
}

matches_territory_is :: proc(
	test: ^Territory,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is)
	ctx.test = test
	return matches_pred_territory_is, rawptr(ctx)
}

// territoryIsBlitzable(GamePlayer)
Matches_Ctx_territory_is_blitzable :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_blitzable :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_is_blitzable)ctx_ptr
	if territory_is_water(t) {
		return false
	}
	data := game_player_get_data(c.player)
	props := game_data_get_properties(data)
	if game_player_is_null(t.owner) && !properties_get_neutrals_blitzable(props) {
		return false
	}
	bt := abstract_move_delegate_get_battle_tracker(data)
	if battle_tracker_was_conquered(bt, t) && !battle_tracker_was_blitzed(bt, t) {
		return false
	}
	allow_infrastructure := !properties_get_w_w2_v2(props) &&
		!properties_get_blitz_through_factories_and_aa_restricted(props)
	en_p, en_c := matches_enemy_unit(c.player)
	in_p, in_c := matches_unit_is_infrastructure()
	for u in t.unit_collection.units {
		if !en_p(en_c, u) {
			continue // not enemy → ok
		}
		if allow_infrastructure && in_p(in_c, u) {
			continue
		}
		return false
	}
	return true
}

matches_territory_is_blitzable :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_blitzable)
	ctx.player = player
	return matches_pred_territory_is_blitzable, rawptr(ctx)
}

// territoryIsBlockadeZone()
//   t -> TerritoryAttachment.get(t).map(getBlockadeZone).orElse(false)
matches_pred_territory_is_blockade_zone :: proc(_: rawptr, t: ^Territory) -> bool {
	ta := territory_attachment_get(t)
	if ta == nil {
		return false
	}
	return territory_attachment_get_blockade_zone(ta)
}

matches_territory_is_blockade_zone :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_blockade_zone, nil
}

// territoryIsEmpty() — t -> t.getUnitCollection().isEmpty()
matches_pred_territory_is_empty :: proc(_: rawptr, t: ^Territory) -> bool {
	return len(t.unit_collection.units) == 0
}

matches_territory_is_empty :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_empty, nil
}

// territoryIsEmptyOfCombatUnits(GamePlayer)
//   t -> t.getUnitCollection().allMatch(unitIsInfrastructure().or(enemyUnit(player).negate()))
Matches_Ctx_territory_is_empty_of_combat_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_empty_of_combat_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_is_empty_of_combat_units)ctx_ptr
	in_p, in_c := matches_unit_is_infrastructure()
	en_p, en_c := matches_enemy_unit(c.player)
	for u in t.unit_collection.units {
		if in_p(in_c, u) {
			continue
		}
		if !en_p(en_c, u) {
			continue
		}
		return false
	}
	return true
}

matches_territory_is_empty_of_combat_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_empty_of_combat_units)
	ctx.player = player
	return matches_pred_territory_is_empty_of_combat_units, rawptr(ctx)
}

// territoryIsEnemyNonNeutralAndHasEnemyUnitMatching(GamePlayer, Predicate<Unit>)
Matches_Ctx_territory_is_enemy_non_neutral_and_has_enemy_unit_matching :: struct {
	player:         ^Game_Player,
	unit_match:     proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
}

matches_pred_territory_is_enemy_non_neutral_and_has_enemy_unit_matching :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_is_enemy_non_neutral_and_has_enemy_unit_matching)ctx_ptr
	if !game_player_is_at_war(c.player, t.owner) {
		return false
	}
	if game_player_is_null(t.owner) {
		return false
	}
	en_p, en_c := matches_enemy_unit(c.player)
	for u in t.unit_collection.units {
		if en_p(en_c, u) && c.unit_match(c.unit_match_ctx, u) {
			return true
		}
	}
	return false
}

matches_territory_is_enemy_non_neutral_and_has_enemy_unit_matching :: proc(
	player: ^Game_Player,
	unit_match: proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_enemy_non_neutral_and_has_enemy_unit_matching)
	ctx.player = player
	ctx.unit_match = unit_match
	ctx.unit_match_ctx = unit_match_ctx
	return matches_pred_territory_is_enemy_non_neutral_and_has_enemy_unit_matching, rawptr(ctx)
}

// territoryIsImpassable()
//   t -> !t.isWater() && TerritoryAttachment.get(t).map(getIsImpassable).orElse(false)
matches_pred_territory_is_impassable :: proc(_: rawptr, t: ^Territory) -> bool {
	if territory_is_water(t) {
		return false
	}
	ta := territory_attachment_get(t)
	if ta == nil {
		return false
	}
	return territory_attachment_get_is_impassable(ta)
}

matches_territory_is_impassable :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_impassable, nil
}

// territoryIsImpassableToLandUnits(GamePlayer)  [package-private]
//   t -> t.isWater() || territoryIsPassableAndNotRestricted(player).negate().test(t)
Matches_Ctx_territory_is_impassable_to_land_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_impassable_to_land_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_is_impassable_to_land_units)ctx_ptr
	if territory_is_water(t) {
		return true
	}
	p, pc := matches_territory_is_passable_and_not_restricted(c.player)
	return !p(pc, t)
}

matches_territory_is_impassable_to_land_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_impassable_to_land_units)
	ctx.player = player
	return matches_pred_territory_is_impassable_to_land_units, rawptr(ctx)
}

// territoryIsIsland()
//   t -> { neighbors = data.map.getNeighbors(t); size==1 && any(neighbors).isWater() }
matches_pred_territory_is_island :: proc(_: rawptr, t: ^Territory) -> bool {
	data := territory_get_data(t)
	gm := game_data_get_map(data)
	neighbors := game_map_get_neighbors(gm, t)
	if len(neighbors) != 1 {
		return false
	}
	for n in neighbors {
		return territory_is_water(n)
	}
	return false
}

matches_territory_is_island :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_island, nil
}

// territoryIsNotImpassableToLandUnits(GamePlayer)
Matches_Ctx_territory_is_not_impassable_to_land_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_not_impassable_to_land_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_is_not_impassable_to_land_units)ctx_ptr
	p, pc := matches_territory_is_impassable_to_land_units(c.player)
	return !p(pc, t)
}

matches_territory_is_not_impassable_to_land_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_not_impassable_to_land_units)
	ctx.player = player
	return matches_pred_territory_is_not_impassable_to_land_units, rawptr(ctx)
}

// territoryIsNotUnownedWater()
//   t -> !(t.isWater() && TerritoryAttachment.get(t).isEmpty() && t.getOwner().isNull())
matches_pred_territory_is_not_unowned_water :: proc(_: rawptr, t: ^Territory) -> bool {
	if !territory_is_water(t) {
		return true
	}
	ta := territory_attachment_get(t)
	if ta != nil {
		return true
	}
	if !game_player_is_null(t.owner) {
		return true
	}
	return false
}

matches_territory_is_not_unowned_water :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_not_unowned_water, nil
}

// territoryIsOriginallyOwnedBy(GamePlayer)
Matches_Ctx_territory_is_originally_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_originally_owned_by :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_is_originally_owned_by)ctx_ptr
	ta := territory_attachment_get(t)
	if ta == nil {
		return false
	}
	orig := territory_attachment_get_original_owner(ta)
	if orig == nil {
		return matches_lambda_territory_is_originally_owned_by_223(c.player)
	}
	return matches_lambda_territory_is_originally_owned_by_222(c.player, orig)
}

matches_territory_is_originally_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_originally_owned_by)
	ctx.player = player
	return matches_pred_territory_is_originally_owned_by, rawptr(ctx)
}

// territoryIsOwnedAndHasOwnedUnitMatching(GamePlayer, Predicate<Unit>)
//   t -> t.isOwnedBy(player) && t.anyUnitsMatch(unitIsOwnedBy(player).and(unitMatch))
Matches_Ctx_territory_is_owned_and_has_owned_unit_matching :: struct {
	player:         ^Game_Player,
	unit_match:     proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
}

matches_pred_territory_is_owned_and_has_owned_unit_matching :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_is_owned_and_has_owned_unit_matching)ctx_ptr
	if !territory_is_owned_by(t, c.player) {
		return false
	}
	for u in t.unit_collection.units {
		if unit_is_owned_by(u, c.player) && c.unit_match(c.unit_match_ctx, u) {
			return true
		}
	}
	return false
}

matches_territory_is_owned_and_has_owned_unit_matching :: proc(
	player: ^Game_Player,
	unit_match: proc(rawptr, ^Unit) -> bool,
	unit_match_ctx: rawptr,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_owned_and_has_owned_unit_matching)
	ctx.player = player
	ctx.unit_match = unit_match
	ctx.unit_match_ctx = unit_match_ctx
	return matches_pred_territory_is_owned_and_has_owned_unit_matching, rawptr(ctx)
}

// territoryIsPassableAndNotRestricted(GamePlayer)
Matches_Ctx_territory_is_passable_and_not_restricted :: struct {
	player: ^Game_Player,
}

matches_pred_territory_is_passable_and_not_restricted :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_is_passable_and_not_restricted)ctx_ptr
	imp_p, imp_c := matches_territory_is_impassable()
	if imp_p(imp_c, t) {
		return false
	}
	props := game_data_get_properties(game_player_get_data(c.player))
	if !properties_get_movement_by_territory_restricted(props) {
		return true
	}
	ra := game_player_get_rules_attachment(c.player)
	if ra == nil {
		return true
	}
	mrt := rules_attachment_get_movement_restriction_territories(ra)
	if mrt == nil || len(mrt) == 0 {
		return true
	}
	listed := rules_attachment_get_listed_territories(ra, mrt, true, true)
	contained := false
	for lt in listed {
		if lt == t {
			contained = true
			break
		}
	}
	return rules_attachment_is_movement_restriction_type_allowed(ra) == contained
}

matches_territory_is_passable_and_not_restricted :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_is_passable_and_not_restricted)
	ctx.player = player
	return matches_pred_territory_is_passable_and_not_restricted, rawptr(ctx)
}

// territoryIsWater() — Territory::isWater
matches_pred_territory_is_water :: proc(_: rawptr, t: ^Territory) -> bool {
	return territory_is_water(t)
}

matches_territory_is_water :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_water, nil
}

// territoryOwnerRelationshipTypeCanMoveIntoDuringCombatMove(GamePlayer)
Matches_Ctx_territory_owner_relationship_type_can_move_into_during_combat_move :: struct {
	moving_player: ^Game_Player,
}

matches_pred_territory_owner_relationship_type_can_move_into_during_combat_move :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_owner_relationship_type_can_move_into_during_combat_move)ctx_ptr
	if territory_is_owned_by(t, c.moving_player) {
		return true
	}
	if game_player_is_null(t.owner) && territory_is_water(t) {
		return true
	}
	rt := game_data_get_relationship_tracker(territory_get_data(t))
	return relationship_tracker_can_move_into_during_combat_move(rt, c.moving_player, t.owner)
}

matches_territory_owner_relationship_type_can_move_into_during_combat_move :: proc(
	moving_player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_owner_relationship_type_can_move_into_during_combat_move)
	ctx.moving_player = moving_player
	return matches_pred_territory_owner_relationship_type_can_move_into_during_combat_move, rawptr(ctx)
}

// territoryWasFoughtOver(BattleTracker)
//   t -> tracker.wasBattleFought(t) || tracker.wasBlitzed(t)
Matches_Ctx_territory_was_fought_over :: struct {
	tracker: ^Battle_Tracker,
}

matches_pred_territory_was_fought_over :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_was_fought_over)ctx_ptr
	return battle_tracker_was_battle_fought(c.tracker, t) ||
		battle_tracker_was_blitzed(c.tracker, t)
}

matches_territory_was_fought_over :: proc(
	tracker: ^Battle_Tracker,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_was_fought_over)
	ctx.tracker = tracker
	return matches_pred_territory_was_fought_over, rawptr(ctx)
}

// transportCannotUnload(Territory)
Matches_Ctx_transport_cannot_unload :: struct {
	territory: ^Territory,
}

matches_pred_transport_cannot_unload :: proc(ctx_ptr: rawptr, transport: ^Unit) -> bool {
	c := cast(^Matches_Ctx_transport_cannot_unload)ctx_ptr
	if transport_tracker_has_transport_unloaded_in_previous_phase(transport) {
		return true
	}
	return transport_tracker_is_transport_unload_restricted_to_another_territory(transport, c.territory) ||
		transport_tracker_is_transport_unload_restricted_in_non_combat(transport)
}

matches_transport_cannot_unload :: proc(
	territory: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_transport_cannot_unload)
	ctx.territory = territory
	return matches_pred_transport_cannot_unload, rawptr(ctx)
}

// unitAaShotDamageableInsteadOfKillingInstantly()
matches_pred_unit_aa_shot_damageable_instead_of_killing_instantly :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_damageable_aa(unit_get_unit_attachment(u))
}

matches_unit_aa_shot_damageable_instead_of_killing_instantly :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_aa_shot_damageable_instead_of_killing_instantly, nil
}

// unitAtMaxHitPointDamageChangesInto()
//   u -> ua.getWhenHitPointsDamagedChangesInto().containsKey(ua.getHitPoints())
matches_pred_unit_at_max_hit_point_damage_changes_into :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	m := unit_attachment_get_when_hit_points_damaged_changes_into(ua)
	hp := unit_attachment_get_hit_points(ua)
	_, ok := m[hp]
	return ok
}

matches_unit_at_max_hit_point_damage_changes_into :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_at_max_hit_point_damage_changes_into, nil
}

// unitAttackAaIsGreaterThanZeroAndMaxAaAttacksIsNotZero()
matches_pred_unit_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_get_attack_aa(ua, unit_get_owner(u)) > 0 &&
		unit_attachment_get_max_aa_attacks(ua) != 0
}

matches_unit_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero, nil
}

// unitCanAirBattle()
matches_pred_unit_can_air_battle :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_air_battle(unit_get_unit_attachment(u))
}

matches_unit_can_air_battle :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_air_battle, nil
}

// unitCanAttack(GamePlayer)
//   u -> ua.movement(p) > 0 && (ua.attack(p) > 0 || ua.offensiveAttackAa(p) > 0)
Matches_Ctx_unit_can_attack :: struct {
	player: ^Game_Player,
}

matches_pred_unit_can_attack :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_attack)ctx_ptr
	ua := unit_get_unit_attachment(u)
	if unit_attachment_get_movement(ua, c.player) <= 0 {
		return false
	}
	return unit_attachment_get_attack(ua, c.player) > 0 ||
		unit_attachment_get_offensive_attack_aa(ua, c.player) > 0
}

matches_unit_can_attack :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_attack)
	ctx.player = player
	return matches_pred_unit_can_attack, rawptr(ctx)
}

// unitCanBeCapturedOnEnteringThisTerritory(GamePlayer, Territory)
Matches_Ctx_unit_can_be_captured_on_entering_this_territory :: struct {
	player: ^Game_Player,
	t:      ^Territory,
}

matches_pred_unit_can_be_captured_on_entering_this_territory :: proc(
	ctx_ptr: rawptr,
	unit: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_can_be_captured_on_entering_this_territory)ctx_ptr
	props := game_data_get_properties(game_player_get_data(c.player))
	if !properties_get_capture_units_on_entering_territory(props) {
		return false
	}
	unit_owner := unit_get_owner(unit)
	ua := unit_get_unit_attachment(unit)
	uc_list := unit_attachment_get_can_be_captured_on_entering_by(ua)
	unit_can_be_captured_by_player := false
	for p in uc_list {
		if p == c.player {
			unit_can_be_captured_by_player = true
			break
		}
	}
	ta := territory_attachment_get(c.t)
	if ta == nil {
		return false
	}
	tc_list := territory_attachment_get_capture_unit_on_entering_by(ta)
	terr_can_have := false
	for p in tc_list {
		if p == c.player {
			terr_can_have = true
			break
		}
	}
	pa := player_attachment_get(unit_owner)
	if pa == nil {
		return false
	}
	pc_list := player_attachment_get_capture_unit_on_entering_by(pa)
	owner_lets := false
	for p in pc_list {
		if p == c.player {
			owner_lets = true
			break
		}
	}
	return unit_can_be_captured_by_player && terr_can_have && owner_lets
}

matches_unit_can_be_captured_on_entering_this_territory :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_be_captured_on_entering_this_territory)
	ctx.player = player
	ctx.t = t
	return matches_pred_unit_can_be_captured_on_entering_this_territory, rawptr(ctx)
}

// unitCanBeDamaged() — u -> unitTypeCanBeDamaged().test(u.getType())
matches_pred_unit_can_be_damaged :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_be_damaged(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_can_be_damaged :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_be_damaged, nil
}

// unitCanBeGivenBonusMovementByFacilitiesInItsTerritory(Territory, GamePlayer)
Matches_Ctx_unit_can_be_given_bonus_movement_by_facilities_in_its_territory :: struct {
	territory: ^Territory,
	player:    ^Game_Player,
}

// helper struct-binding for the and-composed predicate "alliedUnit AND
// unitCanGiveBonusMovementToThisUnit(unitWhichWillGetBonus)"
Matches_Ctx_gives_bonus_unit :: struct {
	allied_p:  proc(rawptr, ^Unit) -> bool,
	allied_c:  rawptr,
	bonus_p:   proc(rawptr, ^Unit) -> bool,
	bonus_c:   rawptr,
}

matches_pred_gives_bonus_unit :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_gives_bonus_unit)ctx_ptr
	return c.allied_p(c.allied_c, u) && c.bonus_p(c.bonus_c, u)
}

matches_pred_unit_can_be_given_bonus_movement_by_facilities_in_its_territory :: proc(
	ctx_ptr: rawptr,
	unit_which_will_get_bonus: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_can_be_given_bonus_movement_by_facilities_in_its_territory)ctx_ptr
	allied_p, allied_c := matches_allied_unit(c.player)
	bonus_p, bonus_c := matches_unit_can_give_bonus_movement_to_this_unit(unit_which_will_get_bonus)
	gb_ctx := new(Matches_Ctx_gives_bonus_unit)
	gb_ctx.allied_p = allied_p
	gb_ctx.allied_c = allied_c
	gb_ctx.bonus_p = bonus_p
	gb_ctx.bonus_c = bonus_c
	for u in c.territory.unit_collection.units {
		if matches_pred_gives_bonus_unit(rawptr(gb_ctx), u) {
			return true
		}
	}
	se_p, se_c := matches_unit_is_sea()
	if se_p(se_c, unit_which_will_get_bonus) {
		ld_p, ld_c := matches_unit_is_land()
		gm := game_data_get_map(game_player_get_data(c.player))
		l_p, l_c := matches_territory_is_land()
		neighbors := game_map_get_neighbors_predicate(gm, c.territory, l_p, l_c)
		for n in neighbors {
			for u in n.unit_collection.units {
				if matches_pred_gives_bonus_unit(rawptr(gb_ctx), u) && ld_p(ld_c, u) {
					return true
				}
			}
		}
	}
	return false
}

matches_unit_can_be_given_bonus_movement_by_facilities_in_its_territory :: proc(
	territory: ^Territory,
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_be_given_bonus_movement_by_facilities_in_its_territory)
	ctx.territory = territory
	ctx.player = player
	return matches_pred_unit_can_be_given_bonus_movement_by_facilities_in_its_territory, rawptr(ctx)
}

// unitCanBeGivenByTerritoryTo(GamePlayer)  [package-private]
//   u -> ua.canBeGivenByTerritoryTo.contains(player)
Matches_Ctx_unit_can_be_given_by_territory_to :: struct {
	player: ^Game_Player,
}

matches_pred_unit_can_be_given_by_territory_to :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_be_given_by_territory_to)ctx_ptr
	list := unit_attachment_get_can_be_given_by_territory_to(unit_get_unit_attachment(u))
	for p in list {
		if p == c.player {
			return true
		}
	}
	return false
}

matches_unit_can_be_given_by_territory_to :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_be_given_by_territory_to)
	ctx.player = player
	return matches_pred_unit_can_be_given_by_territory_to, rawptr(ctx)
}

// unitCanBeInBattle(boolean, boolean, int, boolean, boolean, Collection<UnitType>)
//   u -> unitTypeCanBeInBattle(attack, isLandBattle, u.getOwner(), battleRound,
//                              includeAttackersThatCanNotMove,
//                              doNotIncludeBombardingSeaUnits, firingUnits)
//          .test(u.getType())
Matches_Ctx_unit_can_be_in_battle :: struct {
	attack:                                 bool,
	is_land_battle:                         bool,
	battle_round:                           i32,
	include_attackers_that_can_not_move:    bool,
	do_not_include_bombarding_sea_units:    bool,
	firing_units:                           [dynamic]^Unit_Type,
}

matches_pred_unit_can_be_in_battle :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_be_in_battle)ctx_ptr
	p, pc := matches_unit_type_can_be_in_battle(
		c.attack,
		c.is_land_battle,
		unit_get_owner(u),
		c.battle_round,
		c.include_attackers_that_can_not_move,
		c.do_not_include_bombarding_sea_units,
		c.firing_units,
	)
	return p(pc, unit_get_type(u))
}

matches_unit_can_be_in_battle :: proc(
	attack: bool,
	is_land_battle: bool,
	battle_round: i32,
	include_attackers_that_can_not_move: bool,
	do_not_include_bombarding_sea_units: bool,
	firing_units: [dynamic]^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_be_in_battle)
	ctx.attack = attack
	ctx.is_land_battle = is_land_battle
	ctx.battle_round = battle_round
	ctx.include_attackers_that_can_not_move = include_attackers_that_can_not_move
	ctx.do_not_include_bombarding_sea_units = do_not_include_bombarding_sea_units
	ctx.firing_units = firing_units
	return matches_pred_unit_can_be_in_battle, rawptr(ctx)
}

// unitCanBeMovedThroughByEnemies()
matches_pred_unit_can_be_moved_through_by_enemies :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_can_be_moved_through_by_enemies(unit_get_unit_attachment(u))
}

matches_unit_can_be_moved_through_by_enemies :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_be_moved_through_by_enemies, nil
}

// unitCanBeRepairedByFacilitiesInItsTerritory(Territory, GamePlayer)
Matches_Ctx_unit_can_be_repaired_by_facilities_in_its_territory :: struct {
	territory: ^Territory,
	player:    ^Game_Player,
}

matches_pred_unit_can_be_repaired_by_facilities_in_its_territory :: proc(
	ctx_ptr: rawptr,
	damaged_unit: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_can_be_repaired_by_facilities_in_its_territory)ctx_ptr
	mhp_p, mhp_c := matches_unit_has_more_than_one_hit_point_total()
	tsd_p, tsd_c := matches_unit_has_taken_some_damage()
	if !mhp_p(mhp_c, damaged_unit) || !tsd_p(tsd_c, damaged_unit) {
		return false
	}
	allied_p, allied_c := matches_allied_unit(c.player)
	cro_p, cro_c := matches_unit_can_repair_others()
	cru_p, cru_c := matches_unit_can_repair_this_unit(damaged_unit, c.territory)
	for u in c.territory.unit_collection.units {
		if allied_p(allied_c, u) && cro_p(cro_c, u) && cru_p(cru_c, u) {
			return true
		}
	}
	se_p, se_c := matches_unit_is_sea()
	ld_p, ld_c := matches_unit_is_land()
	if se_p(se_c, damaged_unit) {
		gm := game_data_get_map(game_player_get_data(c.player))
		tl_p, tl_c := matches_territory_is_land()
		neighbors := game_map_get_neighbors_predicate(gm, c.territory, tl_p, tl_c)
		for n in neighbors {
			cru2_p, cru2_c := matches_unit_can_repair_this_unit(damaged_unit, n)
			for u in n.unit_collection.units {
				if !ld_p(ld_c, u) {
					continue
				}
				if allied_p(allied_c, u) && cro_p(cro_c, u) && cru2_p(cru2_c, u) {
					return true
				}
			}
		}
	} else if ld_p(ld_c, damaged_unit) {
		gm := game_data_get_map(game_player_get_data(c.player))
		tw_p, tw_c := matches_territory_is_water()
		neighbors := game_map_get_neighbors_predicate(gm, c.territory, tw_p, tw_c)
		for n in neighbors {
			cru2_p, cru2_c := matches_unit_can_repair_this_unit(damaged_unit, n)
			for u in n.unit_collection.units {
				if !se_p(se_c, u) {
					continue
				}
				if allied_p(allied_c, u) && cro_p(cro_c, u) && cru2_p(cru2_c, u) {
					return true
				}
			}
		}
	}
	return false
}

matches_unit_can_be_repaired_by_facilities_in_its_territory :: proc(
	territory: ^Territory,
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_be_repaired_by_facilities_in_its_territory)
	ctx.territory = territory
	ctx.player = player
	return matches_pred_unit_can_be_repaired_by_facilities_in_its_territory, rawptr(ctx)
}

// unitCanBeTransported() — u -> ua.transportCost != -1
matches_pred_unit_can_be_transported :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_transport_cost(unit_get_unit_attachment(u)) != -1
}

matches_unit_can_be_transported :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_be_transported, nil
}

// unitCanBlitz() — u -> ua.canBlitz(u.getOwner())
matches_pred_unit_can_blitz :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_can_blitz(unit_get_unit_attachment(u), unit_get_owner(u))
}

matches_unit_can_blitz :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_blitz, nil
}

// unitCanBombard(GamePlayer)
Matches_Ctx_unit_can_bombard :: struct {
	player: ^Game_Player,
}

matches_pred_unit_can_bombard :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_bombard)ctx_ptr
	return unit_attachment_get_can_bombard(unit_get_unit_attachment(u), c.player)
}

matches_unit_can_bombard :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_bombard)
	ctx.player = player
	return matches_pred_unit_can_bombard, rawptr(ctx)
}

// unitCanDieFromReachingMaxDamage()
matches_pred_unit_can_die_from_reaching_max_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_can_be_damaged(ua) && unit_attachment_can_die_from_reaching_max_damage(ua)
}

matches_unit_can_die_from_reaching_max_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_die_from_reaching_max_damage, nil
}

// unitCanEscort()  [package-private]
matches_pred_unit_can_escort :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_escort(unit_get_unit_attachment(u))
}

matches_unit_can_escort :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_escort, nil
}

// unitCanEvade() — u -> ua.getCanEvade()
matches_pred_unit_can_evade :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_can_evade(unit_get_unit_attachment(u))
}

matches_unit_can_evade :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_evade, nil
}

// unitCanGiveBonusMovement()  [private]
//   u -> !ua.givesMovement.isEmpty() && !unitIsBeingTransported.test(u)
matches_pred_unit_can_give_bonus_movement :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	if len(unit_attachment_get_gives_movement(ua)) == 0 {
		return false
	}
	return unit_get_transported_by(u) == nil
}

matches_unit_can_give_bonus_movement :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_give_bonus_movement, nil
}

// unitCanGiveBonusMovementToThisUnit(Unit)  [package-private]
Matches_Ctx_unit_can_give_bonus_movement_to_this_unit :: struct {
	unit_which_will_get_bonus: ^Unit,
}

matches_pred_unit_can_give_bonus_movement_to_this_unit :: proc(
	ctx_ptr: rawptr,
	unit_which_can_give_bonus_movement: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_can_give_bonus_movement_to_this_unit)ctx_ptr
	di_p, di_c := matches_unit_is_disabled()
	if di_p(di_c, unit_which_can_give_bonus_movement) {
		return false
	}
	ua := unit_get_unit_attachment(unit_which_can_give_bonus_movement)
	cgm_p, cgm_c := matches_unit_can_give_bonus_movement()
	if !cgm_p(cgm_c, unit_which_can_give_bonus_movement) {
		return false
	}
	gives := unit_attachment_get_gives_movement(ua)
	bonus_for := unit_get_type(c.unit_which_will_get_bonus)
	val, ok := gives[bonus_for]
	if !ok {
		return false
	}
	return val != 0
}

matches_unit_can_give_bonus_movement_to_this_unit :: proc(
	unit_which_will_get_bonus: ^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_give_bonus_movement_to_this_unit)
	ctx.unit_which_will_get_bonus = unit_which_will_get_bonus
	return matches_pred_unit_can_give_bonus_movement_to_this_unit, rawptr(ctx)
}

// unitCanIntercept()
matches_pred_unit_can_intercept :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_intercept(unit_get_unit_attachment(u))
}

matches_unit_can_intercept :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_intercept, nil
}

// unitCanInvade()
matches_pred_unit_can_invade :: proc(_: rawptr, u: ^Unit) -> bool {
	transport := unit_get_transported_by(u)
	if transport == nil {
		return true
	}
	return unit_attachment_can_invade_from(unit_get_unit_attachment(u), transport)
}

matches_unit_can_invade :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_invade, nil
}

// unitCanLandOnCarrier() — u -> ua.carrierCost != -1
matches_pred_unit_can_land_on_carrier :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_carrier_cost(unit_get_unit_attachment(u)) != -1
}

matches_unit_can_land_on_carrier :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_land_on_carrier, nil
}

// unitCanMove() — u -> unitTypeCanMove(u.getOwner()).test(u.getType())
//   ≡ ua.movement(owner) > 0
matches_pred_unit_can_move :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_type_get_unit_attachment(unit_get_type(u))
	return unit_attachment_get_movement(ua, unit_get_owner(u)) > 0
}

matches_unit_can_move :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_move, nil
}

// unitCanMoveThroughEnemies()
matches_pred_unit_can_move_through_enemies :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_can_move_through_enemies(unit_get_unit_attachment(u))
}

matches_unit_can_move_through_enemies :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_move_through_enemies, nil
}

// unitCanNotBeTargetedByAll()
//   u -> !ua.canNotBeTargetedBy().isEmpty()
matches_pred_unit_can_not_be_targeted_by_all :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_can_not_be_targeted_by(unit_get_unit_attachment(u))) > 0
}

matches_unit_can_not_be_targeted_by_all :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_not_be_targeted_by_all, nil
}

// unitCanNotMoveDuringCombatMove() — u -> unitTypeCanNotMoveDuringCombatMove().test(u.getType())
matches_pred_unit_can_not_move_during_combat_move :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_not_move_during_combat_move(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_can_not_move_during_combat_move :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_not_move_during_combat_move, nil
}

// unitCanOnlyPlaceInOriginalTerritories()  [package-private]
//   u -> ua.special.contains("canOnlyPlaceInOriginalTerritories")
matches_pred_unit_can_only_place_in_original_territories :: proc(_: rawptr, u: ^Unit) -> bool {
	special := unit_attachment_get_special(unit_get_unit_attachment(u))
	_, ok := special["canOnlyPlaceInOriginalTerritories"]
	return ok
}

matches_unit_can_only_place_in_original_territories :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_only_place_in_original_territories, nil
}

// unitCanProduceUnits() — u -> unitTypeCanProduceUnits().test(u.getType())
matches_pred_unit_can_produce_units :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_produce_units(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_can_produce_units :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_produce_units, nil
}

// unitCanReceiveAbilityWhenWith()
//   u -> !ua.receivesAbilityWhenWith.isEmpty()
matches_pred_unit_can_receive_ability_when_with :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_receives_ability_when_with(unit_get_unit_attachment(u))) > 0
}

matches_unit_can_receive_ability_when_with :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_receive_ability_when_with, nil
}

// unitCanReceiveAbilityWhenWith(String filterForAbility, String filterForUnitType)
//   for receives in ua.getReceivesAbilityWhenWith():
//     s = receives.split(":", 2)
//     if s[0]==ability && s[1]==unitType: return true
//   return false
Matches_Ctx_unit_can_receive_ability_when_with_filter :: struct {
	filter_for_ability:   string,
	filter_for_unit_type: string,
}

matches_pred_unit_can_receive_ability_when_with_filter :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_receive_ability_when_with_filter)ctx_ptr
	list := unit_attachment_get_receives_ability_when_with(unit_get_unit_attachment(u))
	for receives in list {
		colon := -1
		for i in 0 ..< len(receives) {
			if receives[i] == ':' {
				colon = i
				break
			}
		}
		if colon < 0 {
			continue
		}
		ability := receives[:colon]
		ut := receives[colon + 1:]
		if ability == c.filter_for_ability && ut == c.filter_for_unit_type {
			return true
		}
	}
	return false
}

matches_unit_can_receive_ability_when_with_filter :: proc(
	filter_for_ability: string,
	filter_for_unit_type: string,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_receive_ability_when_with_filter)
	ctx.filter_for_ability = filter_for_ability
	ctx.filter_for_unit_type = filter_for_unit_type
	return matches_pred_unit_can_receive_ability_when_with_filter, rawptr(ctx)
}

// unitCanRepairOthers()  [package-private]
//   if disabled || beingTransported: return false
//   return !ua.repairsUnits.isEmpty()
matches_pred_unit_can_repair_others :: proc(_: rawptr, u: ^Unit) -> bool {
	di_p, di_c := matches_unit_is_disabled()
	bt_p, bt_c := matches_unit_is_being_transported()
	if di_p(di_c, u) || bt_p(bt_c, u) {
		return false
	}
	return len(unit_attachment_get_repairs_units(unit_get_unit_attachment(u))) > 0
}

matches_unit_can_repair_others :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_repair_others, nil
}

// unitCanRepairThisUnit(Unit damagedUnit, Territory territoryOfRepairUnit)  [package-private]
Matches_Ctx_unit_can_repair_this_unit :: struct {
	damaged_unit:             ^Unit,
	territory_of_repair_unit: ^Territory,
}

matches_pred_unit_can_repair_this_unit :: proc(
	ctx_ptr: rawptr,
	unit_can_repair: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_can_repair_this_unit)ctx_ptr
	data := game_player_get_data(unit_get_owner(c.damaged_unit))
	players := game_step_properties_helper_get_combined_turns(data, unit_get_owner(c.damaged_unit))
	gm := game_data_get_map(data)
	if len(players) > 1 {
		at_least_one_player_owns_capital := false
		for player in players {
			own_capital := territory_attachment_do_we_have_enough_capitals_to_produce(player, gm)
			if own_capital {
				at_least_one_player_owns_capital = true
			}
			if !own_capital && territory_is_owned_by(c.territory_of_repair_unit, player) {
				return false
			}
		}
		if !at_least_one_player_owns_capital {
			return false
		}
	} else {
		if !territory_attachment_do_we_have_enough_capitals_to_produce(unit_get_owner(c.damaged_unit), gm) {
			return false
		}
	}
	ua := unit_get_unit_attachment(unit_can_repair)
	repairs := unit_attachment_get_repairs_units(ua)
	dt := unit_get_type(c.damaged_unit)
	_, ok := repairs[dt]
	return ok
}

matches_unit_can_repair_this_unit :: proc(
	damaged_unit: ^Unit,
	territory_of_repair_unit: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_repair_this_unit)
	ctx.damaged_unit = damaged_unit
	ctx.territory_of_repair_unit = territory_of_repair_unit
	return matches_pred_unit_can_repair_this_unit, rawptr(ctx)
}


// =====================================================================
// games.strategy.triplea.delegate.Matches — chunk 2 / 4 (55 procs).
// Continues alphabetical: unitCanScramble … unitIsOfType.
// =====================================================================

// unitCanScramble() — u -> ua.canScramble()
matches_pred_unit_can_scramble :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_can_scramble(unit_get_unit_attachment(u))
}

matches_unit_can_scramble :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_scramble, nil
}

// unitCanScrambleOnRouteDistance(Route route)
//   u -> ua.getMaxScrambleDistance() >= route.numberOfSteps()
Matches_Ctx_unit_can_scramble_on_route_distance :: struct {
	route: ^Route,
}

matches_pred_unit_can_scramble_on_route_distance :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_scramble_on_route_distance)ctx_ptr
	return unit_attachment_get_max_scramble_distance(unit_get_unit_attachment(u)) >= route_number_of_steps(c.route)
}

matches_unit_can_scramble_on_route_distance :: proc(
	route: ^Route,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_scramble_on_route_distance)
	ctx.route = route
	return matches_pred_unit_can_scramble_on_route_distance, rawptr(ctx)
}

// unitCanTransport() — u -> ua.getTransportCapacity() != -1
matches_pred_unit_can_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_transport_capacity(unit_get_unit_attachment(u)) != -1
}

matches_unit_can_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_transport, nil
}

// unitConsumesUnitsOnCreation() — u -> !ua.getConsumesUnits().isEmpty()
matches_pred_unit_consumes_units_on_creation :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_consumes_units(unit_get_unit_attachment(u))) > 0
}

matches_unit_consumes_units_on_creation :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_consumes_units_on_creation, nil
}

// unitCreatesResources() — u -> !ua.getCreatesResourcesList().isEmpty()
matches_pred_unit_creates_resources :: proc(_: rawptr, u: ^Unit) -> bool {
	imr := unit_attachment_get_creates_resources_list(unit_get_unit_attachment(u))
	return len(imr.values) > 0
}

matches_unit_creates_resources :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_creates_resources, nil
}

// unitCreatesUnits() — u -> !ua.getCreatesUnitsList().isEmpty()
matches_pred_unit_creates_units :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_creates_units_list(unit_get_unit_attachment(u))) > 0
}

matches_unit_creates_units :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_creates_units, nil
}

// unitDestroyedWhenCapturedBy(GamePlayer playerBy)
//   for tuple in ua.getDestroyedWhenCapturedBy():
//     if tuple.first == "BY" && tuple.second == playerBy: return true
Matches_Ctx_unit_destroyed_when_captured_by :: struct {
	player_by: ^Game_Player,
}

matches_pred_unit_destroyed_when_captured_by :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_destroyed_when_captured_by)ctx_ptr
	for tuple in unit_attachment_get_destroyed_when_captured_by(unit_get_unit_attachment(u)) {
		if tuple == nil {
			continue
		}
		if tuple.first == "BY" && tuple.second == c.player_by {
			return true
		}
	}
	return false
}

matches_unit_destroyed_when_captured_by :: proc(
	player_by: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_destroyed_when_captured_by)
	ctx.player_by = player_by
	return matches_pred_unit_destroyed_when_captured_by, rawptr(ctx)
}

// unitDestroyedWhenCapturedFrom()
//   for tuple in ua.getDestroyedWhenCapturedBy():
//     if tuple.first == "FROM" && tuple.second == u.getOwner(): return true
matches_pred_unit_destroyed_when_captured_from :: proc(_: rawptr, u: ^Unit) -> bool {
	owner := unit_get_owner(u)
	for tuple in unit_attachment_get_destroyed_when_captured_by(unit_get_unit_attachment(u)) {
		if tuple == nil {
			continue
		}
		if tuple.first == "FROM" && tuple.second == owner {
			return true
		}
	}
	return false
}

matches_unit_destroyed_when_captured_from :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_destroyed_when_captured_from, nil
}

// unitHasAttackValueOfAtLeast(int attackValue)
//   u -> ua.getAttack(u.getOwner()) >= attackValue
Matches_Ctx_unit_has_attack_value_of_at_least :: struct {
	attack_value: i32,
}

matches_pred_unit_has_attack_value_of_at_least :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_has_attack_value_of_at_least)ctx_ptr
	return unit_attachment_get_attack(unit_get_unit_attachment(u), unit_get_owner(u)) >= c.attack_value
}

matches_unit_has_attack_value_of_at_least :: proc(
	attack_value: i32,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_has_attack_value_of_at_least)
	ctx.attack_value = attack_value
	return matches_pred_unit_has_attack_value_of_at_least, rawptr(ctx)
}

// unitHasDefendValueOfAtLeast(int defendValue)
//   u -> ua.getDefense(u.getOwner()) >= defendValue
Matches_Ctx_unit_has_defend_value_of_at_least :: struct {
	defend_value: i32,
}

matches_pred_unit_has_defend_value_of_at_least :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_has_defend_value_of_at_least)ctx_ptr
	return unit_attachment_get_defense(unit_get_unit_attachment(u), unit_get_owner(u)) >= c.defend_value
}

matches_unit_has_defend_value_of_at_least :: proc(
	defend_value: i32,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_has_defend_value_of_at_least)
	ctx.defend_value = defend_value
	return matches_pred_unit_has_defend_value_of_at_least, rawptr(ctx)
}

// unitHasEnoughMovementForRoute(Route route)
Matches_Ctx_unit_has_enough_movement_for_route :: struct {
	route: ^Route,
}

@(private = "file")
matches_has_allied_naval_base :: proc(t: ^Territory, player: ^Game_Player) -> bool {
	return territory_attachment_has_naval_base(t) && game_player_is_allied(t.owner, player)
}

@(private = "file")
matches_has_neighboring_allied_naval_base :: proc(t: ^Territory, player: ^Game_Player) -> bool {
	gm := game_data_get_map(territory_get_data(t))
	for t2 in game_map_get_neighbors(gm, t) {
		if matches_has_allied_naval_base(t2, player) {
			return true
		}
	}
	return false
}

matches_pred_unit_has_enough_movement_for_route :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_has_enough_movement_for_route)ctx_ptr
	left := unit_get_movement_left(u)
	ua := unit_get_unit_attachment(u)
	if unit_attachment_is_air(ua) {
		if territory_attachment_has_air_base(route_get_start(c.route)) {
			left += 1.0
		}
		if territory_attachment_has_air_base(route_get_end(c.route)) {
			left += 1.0
		}
	}
	if unit_attachment_is_sea(ua) &&
	   game_step_is_non_combat(game_sequence_get_step(game_data_get_sequence(unit_get_data(u)))) {
		owner := unit_get_owner(u)
		if matches_has_neighboring_allied_naval_base(route_get_start(c.route), owner) &&
		   matches_has_neighboring_allied_naval_base(route_get_end(c.route), owner) {
			left += 1.0
		}
	}
	if left < 0.0 {
		return false
	}
	move_cost := route_get_movement_cost(c.route, u)
	has_movement_for_route := left >= move_cost
	props := game_data_get_properties(unit_get_data(u))
	if properties_get_enter_territories_with_higher_movement_costs_then_remaining_movement(props) {
		return has_movement_for_route ||
		       left > route_get_movement_cost_ignore_end(c.route, u)
	}
	return has_movement_for_route
}

matches_unit_has_enough_movement_for_route :: proc(
	route: ^Route,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_has_enough_movement_for_route)
	ctx.route = route
	return matches_pred_unit_has_enough_movement_for_route, rawptr(ctx)
}

// unitHasMoreThanOneHitPointTotal()
//   u -> unitTypeHasMoreThanOneHitPointTotal().test(u.getType())
//      ≡ ut.getUnitAttachment().getHitPoints() > 1
matches_pred_unit_has_more_than_one_hit_point_total :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_hit_points(unit_type_get_unit_attachment(unit_get_type(u))) > 1
}

matches_unit_has_more_than_one_hit_point_total :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_more_than_one_hit_point_total, nil
}

// unitHasMoved() — Unit::hasMoved
matches_pred_unit_has_moved :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_has_moved(u)
}

matches_unit_has_moved :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_moved, nil
}

// unitHasMovementLeft() — Unit::hasMovementLeft
matches_pred_unit_has_movement_left :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_has_movement_left(u)
}

matches_unit_has_movement_left :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_movement_left, nil
}

// unitHasNotBeenChargedFlatFuelCost() — u -> !u.getChargedFlatFuelCost()
matches_pred_unit_has_not_been_charged_flat_fuel_cost :: proc(_: rawptr, u: ^Unit) -> bool {
	return !unit_get_charged_flat_fuel_cost(u)
}

matches_unit_has_not_been_charged_flat_fuel_cost :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_not_been_charged_flat_fuel_cost, nil
}

// unitHasRequiredUnitsToMove(Territory t)
Matches_Ctx_unit_has_required_units_to_move :: struct {
	t: ^Territory,
}

matches_pred_unit_has_required_units_to_move :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_has_required_units_to_move)ctx_ptr
	ua := unit_get_unit_attachment(unit)
	requires_lists := unit_attachment_get_requires_units_to_move(ua)
	if len(requires_lists) == 0 {
		return true
	}
	owner := unit_get_owner(unit)
	disabled_p, disabled_c := matches_unit_is_disabled()
	allied: [dynamic]^Unit
	for u in territory_get_units(c.t) {
		if game_player_is_allied(owner, unit_get_owner(u)) && !disabled_p(disabled_c, u) {
			append(&allied, u)
		}
	}
	for combo in requires_lists {
		have_all := true
		for ut in unit_attachment_get_listed_units(ua, combo) {
			found := false
			for u in allied {
				if unit_get_type(u) == ut {
					found = true
					break
				}
			}
			if !found {
				have_all = false
				break
			}
		}
		if have_all {
			return true
		}
	}
	return false
}

matches_unit_has_required_units_to_move :: proc(
	t: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_has_required_units_to_move)
	ctx.t = t
	return matches_pred_unit_has_required_units_to_move, rawptr(ctx)
}

// unitHasTakenSomeBombingUnitDamage() — u -> u.getUnitDamage() > 0
matches_pred_unit_has_taken_some_bombing_unit_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_unit_damage(u) > 0
}

matches_unit_has_taken_some_bombing_unit_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_taken_some_bombing_unit_damage, nil
}

// unitHasTakenSomeDamage() — u -> u.getHits() > 0
matches_pred_unit_has_taken_some_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_hits(u) > 0
}

matches_unit_has_taken_some_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_taken_some_damage, nil
}

// unitHasWhenCombatDamagedEffect()  [no-arg, private]
//   u -> !ua.getWhenCombatDamaged().isEmpty()
matches_pred_unit_has_when_combat_damaged_effect :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_when_combat_damaged(unit_get_unit_attachment(u))) > 0
}

matches_unit_has_when_combat_damaged_effect :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_when_combat_damaged_effect, nil
}

// unitIsAaForAnything()
//   u -> ua.isAaForBombingThisUnitOnly() || ua.isAaForCombatOnly() || ua.isAaForFlyOverOnly()
matches_pred_unit_is_aa_for_anything :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_type_get_unit_attachment(unit_get_type(u))
	return unit_attachment_is_aa_for_bombing_this_unit_only(ua) ||
	       unit_attachment_is_aa_for_combat_only(ua) ||
	       unit_attachment_is_aa_for_fly_over_only(ua)
}

matches_unit_is_aa_for_anything :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_aa_for_anything, nil
}

// unitIsAaForBombingThisUnitOnly()
matches_pred_unit_is_aa_for_bombing_this_unit_only :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_aa_for_bombing_this_unit_only(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_is_aa_for_bombing_this_unit_only :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_aa_for_bombing_this_unit_only, nil
}

// unitIsAaForCombatOnly()
matches_pred_unit_is_aa_for_combat_only :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_aa_for_combat_only(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_is_aa_for_combat_only :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_aa_for_combat_only, nil
}

// unitIsAaForFlyOverOnly() — u -> ua.isAaForFlyOverOnly()
matches_pred_unit_is_aa_for_fly_over_only :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_aa_for_fly_over_only(unit_get_unit_attachment(u))
}

matches_unit_is_aa_for_fly_over_only :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_aa_for_fly_over_only, nil
}

// unitIsAaOfTypeAa(String typeAa) — u -> ua.getTypeAa().equals(typeAa)
Matches_Ctx_unit_is_aa_of_type_aa :: struct {
	type_aa: string,
}

matches_pred_unit_is_aa_of_type_aa :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_aa_of_type_aa)ctx_ptr
	return unit_attachment_get_type_aa(unit_get_unit_attachment(u)) == c.type_aa
}

matches_unit_is_aa_of_type_aa :: proc(
	type_aa: string,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_aa_of_type_aa)
	ctx.type_aa = type_aa
	return matches_pred_unit_is_aa_of_type_aa, rawptr(ctx)
}

// unitIsAaThatCanFireOnRound(int battleRoundNumber)
//   u -> { mr = ua.getMaxRoundsAa(); return mr < 0 || mr >= battleRoundNumber }
Matches_Ctx_unit_is_aa_that_can_fire_on_round :: struct {
	battle_round_number: i32,
}

matches_pred_unit_is_aa_that_can_fire_on_round :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_aa_that_can_fire_on_round)ctx_ptr
	mr := unit_attachment_get_max_rounds_aa(unit_type_get_unit_attachment(unit_get_type(u)))
	return mr < 0 || mr >= c.battle_round_number
}

matches_unit_is_aa_that_can_fire_on_round :: proc(
	battle_round_number: i32,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_aa_that_can_fire_on_round)
	ctx.battle_round_number = battle_round_number
	return matches_pred_unit_is_aa_that_can_fire_on_round, rawptr(ctx)
}

// unitIsAaThatCanHitTheseUnits(Collection<Unit> targets, Predicate<Unit> typeOfAa,
//                              Map<String, Set<UnitType>> airborneTechTargetsAllowed)
Matches_Ctx_unit_is_aa_that_can_hit_these_units :: struct {
	targets:                          [dynamic]^Unit,
	type_of_aa:                       proc(rawptr, ^Unit) -> bool,
	type_of_aa_ctx:                   rawptr,
	airborne_tech_targets_allowed:    map[string]map[^Unit_Type]struct {},
}

matches_pred_unit_is_aa_that_can_hit_these_units :: proc(ctx_ptr: rawptr, obj: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_aa_that_can_hit_these_units)ctx_ptr
	if !c.type_of_aa(c.type_of_aa_ctx, obj) {
		return false
	}
	ua := unit_get_unit_attachment(obj)
	utl := game_data_get_unit_type_list(unit_get_data(obj))
	targets_aa := unit_attachment_get_targets_aa(ua, utl)
	for u in c.targets {
		if _, ok := targets_aa[unit_get_type(u)]; ok {
			return true
		}
	}
	allowed_set, has_set := c.airborne_tech_targets_allowed[unit_attachment_get_type_aa(ua)]
	airborne_p, airborne_c := matches_unit_is_airborne()
	for u in c.targets {
		if !airborne_p(airborne_c, u) {
			continue
		}
		if !has_set || allowed_set == nil || len(allowed_set) == 0 {
			continue
		}
		if _, ok := allowed_set[unit_get_type(u)]; ok {
			return true
		}
	}
	return false
}

matches_unit_is_aa_that_can_hit_these_units :: proc(
	targets: [dynamic]^Unit,
	type_of_aa: proc(rawptr, ^Unit) -> bool,
	type_of_aa_ctx: rawptr,
	airborne_tech_targets_allowed: map[string]map[^Unit_Type]struct {},
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_aa_that_can_hit_these_units)
	ctx.targets = targets
	ctx.type_of_aa = type_of_aa
	ctx.type_of_aa_ctx = type_of_aa_ctx
	ctx.airborne_tech_targets_allowed = airborne_tech_targets_allowed
	return matches_pred_unit_is_aa_that_can_hit_these_units, rawptr(ctx)
}

// unitIsAaThatWillNotFireIfPresentEnemyUnits(Collection<Unit> enemyUnitsPresent)
Matches_Ctx_unit_is_aa_that_will_not_fire_if_present_enemy_units :: struct {
	enemy_units_present: [dynamic]^Unit,
}

matches_pred_unit_is_aa_that_will_not_fire_if_present_enemy_units :: proc(
	ctx_ptr: rawptr,
	obj: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_is_aa_that_will_not_fire_if_present_enemy_units)ctx_ptr
	wnf := unit_attachment_get_will_not_fire_if_present(unit_get_unit_attachment(obj))
	for u in c.enemy_units_present {
		if _, ok := wnf[unit_get_type(u)]; ok {
			return true
		}
	}
	return false
}

matches_unit_is_aa_that_will_not_fire_if_present_enemy_units :: proc(
	enemy_units_present: [dynamic]^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_aa_that_will_not_fire_if_present_enemy_units)
	ctx.enemy_units_present = enemy_units_present
	return matches_pred_unit_is_aa_that_will_not_fire_if_present_enemy_units, rawptr(ctx)
}

// unitIsAir() — u -> ua.isAir()
matches_pred_unit_is_air :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_air(unit_get_unit_attachment(u))
}

matches_unit_is_air :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_air, nil
}

// unitIsAirBase() — u -> ua.isAirBase()
matches_pred_unit_is_air_base :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_air_base(unit_get_unit_attachment(u))
}

matches_unit_is_air_base :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_air_base, nil
}

// unitIsAirTransport()
//   u -> { ta = u.getOwner().getTechAttachment();
//          if (!ta.getParatroopers()) return false;
//          return ua.isAirTransport(); }
matches_pred_unit_is_air_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	ta := game_player_get_tech_attachment(unit_get_owner(u))
	if !tech_attachment_get_paratroopers(ta) {
		return false
	}
	return unit_attachment_is_air_transport(unit_get_unit_attachment(u))
}

matches_unit_is_air_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_air_transport, nil
}

// unitIsAirTransportable() — same shape as unitIsAirTransport but checks isAirTransportable()
matches_pred_unit_is_air_transportable :: proc(_: rawptr, u: ^Unit) -> bool {
	ta := game_player_get_tech_attachment(unit_get_owner(u))
	if !tech_attachment_get_paratroopers(ta) {
		return false
	}
	return unit_attachment_is_air_transportable(unit_get_unit_attachment(u))
}

matches_unit_is_air_transportable :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_air_transportable, nil
}

// unitIsAirborne() — Unit::getAirborne
matches_pred_unit_is_airborne :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_airborne(u)
}

matches_unit_is_airborne :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_airborne, nil
}

// unitIsAlliedCarrier(GamePlayer player)
//   u -> ua.getCarrierCapacity() != -1 && player.isAllied(u.getOwner())
Matches_Ctx_unit_is_allied_carrier :: struct {
	player: ^Game_Player,
}

matches_pred_unit_is_allied_carrier :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_allied_carrier)ctx_ptr
	if unit_attachment_get_carrier_capacity(unit_get_unit_attachment(u)) == -1 {
		return false
	}
	return game_player_is_allied(c.player, unit_get_owner(u))
}

matches_unit_is_allied_carrier :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_allied_carrier)
	ctx.player = player
	return matches_pred_unit_is_allied_carrier, rawptr(ctx)
}

// unitIsAtMaxDamageOrNotCanBeDamaged(Territory t)
Matches_Ctx_unit_is_at_max_damage_or_not_can_be_damaged :: struct {
	t: ^Territory,
}

matches_pred_unit_is_at_max_damage_or_not_can_be_damaged :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_at_max_damage_or_not_can_be_damaged)ctx_ptr
	ua := unit_get_unit_attachment(u)
	if !unit_attachment_can_be_damaged(ua) {
		return true
	}
	props := game_data_get_properties(unit_get_data(u))
	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(props) {
		return unit_get_unit_damage(u) >= unit_how_much_damage_can_this_unit_take_total(u, c.t)
	}
	return false
}

matches_unit_is_at_max_damage_or_not_can_be_damaged :: proc(
	t: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_at_max_damage_or_not_can_be_damaged)
	ctx.t = t
	return matches_pred_unit_is_at_max_damage_or_not_can_be_damaged, rawptr(ctx)
}

// unitIsBeingTransported() — dependent.getTransportedBy() != null
matches_pred_unit_is_being_transported :: proc(_: rawptr, dependent: ^Unit) -> bool {
	return unit_get_transported_by(dependent) != nil
}

matches_unit_is_being_transported :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_being_transported, nil
}

// unitIsCarrier() — u -> ua.getCarrierCapacity() != -1
matches_pred_unit_is_carrier :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_carrier_capacity(unit_get_unit_attachment(u)) != -1
}

matches_unit_is_carrier :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_carrier, nil
}

// unitIsCombatSeaTransport()  [private]
//   u -> ua.isCombatTransport() && ua.isSea()
matches_pred_unit_is_combat_sea_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_is_combat_transport(ua) && unit_attachment_is_sea(ua)
}

matches_unit_is_combat_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_combat_sea_transport, nil
}

// unitIsConstruction()
//   u -> unitTypeIsConstruction().test(u.getType()) ≡ ua.isConstruction()
matches_pred_unit_is_construction :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_construction(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_is_construction :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_construction, nil
}

// unitIsDestroyer() — u -> ua.isDestroyer()
matches_pred_unit_is_destroyer :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_destroyer(unit_get_unit_attachment(u))
}

matches_unit_is_destroyer :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_destroyer, nil
}

// unitIsDisabled()
matches_pred_unit_is_disabled :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	if !unit_attachment_can_be_damaged(ua) {
		return false
	}
	props := game_data_get_properties(unit_get_data(u))
	if !properties_get_damage_from_bombing_done_to_units_instead_of_territories(props) {
		return false
	}
	if unit_attachment_get_max_operational_damage(ua) < 0 {
		return false
	}
	return unit_get_unit_damage(u) > unit_attachment_get_max_operational_damage(ua)
}

matches_unit_is_disabled :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_disabled, nil
}

// unitIsEnemyOf(GamePlayer player) — u -> player.isAtWar(u.getOwner())
Matches_Ctx_unit_is_enemy_of :: struct {
	player: ^Game_Player,
}

matches_pred_unit_is_enemy_of :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_enemy_of)ctx_ptr
	return game_player_is_at_war(c.player, unit_get_owner(u))
}

matches_unit_is_enemy_of :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_enemy_of)
	ctx.player = player
	return matches_pred_unit_is_enemy_of, rawptr(ctx)
}

// unitIsFirstStrike() — u -> ua.getIsFirstStrike()
matches_pred_unit_is_first_strike :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_is_first_strike(unit_get_unit_attachment(u))
}

matches_unit_is_first_strike :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_first_strike, nil
}

// unitIsInTerritory(Territory territory) — u -> territory.getUnits().contains(u)
Matches_Ctx_unit_is_in_territory :: struct {
	territory: ^Territory,
}

matches_pred_unit_is_in_territory :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_in_territory)ctx_ptr
	for x in c.territory.unit_collection.units {
		if x == u {
			return true
		}
	}
	return false
}

matches_unit_is_in_territory :: proc(
	territory: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_in_territory)
	ctx.territory = territory
	return matches_pred_unit_is_in_territory, rawptr(ctx)
}

// unitIsInfrastructure() — u -> ua.isInfrastructure() (via type)
matches_pred_unit_is_infrastructure :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_infrastructure(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_is_infrastructure :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_infrastructure, nil
}

// unitIsKamikaze() — u -> ua.isKamikaze()
matches_pred_unit_is_kamikaze :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_kamikaze(unit_get_unit_attachment(u))
}

matches_unit_is_kamikaze :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_kamikaze, nil
}

// unitIsLandTransport() — u -> ua.isLandTransport()
matches_pred_unit_is_land_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_land_transport(unit_get_unit_attachment(u))
}

matches_unit_is_land_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_land_transport, nil
}

// unitIsLandTransportWithCapacity()
//   u -> isLandTransport && canTransport
matches_pred_unit_is_land_transport_with_capacity :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_is_land_transport(ua) &&
	       unit_attachment_get_transport_capacity(ua) != -1
}

matches_unit_is_land_transport_with_capacity :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_land_transport_with_capacity, nil
}

// unitIsLandTransportWithoutCapacity()
//   u -> isLandTransport && !canTransport
matches_pred_unit_is_land_transport_without_capacity :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_is_land_transport(ua) &&
	       unit_attachment_get_transport_capacity(ua) == -1
}

matches_unit_is_land_transport_without_capacity :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_land_transport_without_capacity, nil
}

// unitIsLandTransportable() — u -> ua.isLandTransportable()
matches_pred_unit_is_land_transportable :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_land_transportable(unit_get_unit_attachment(u))
}

matches_unit_is_land_transportable :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_land_transportable, nil
}

// unitIsLegalBombingTargetBy(Unit bomberOrRocket)
//   u -> bomberUa.getBombingTargets(unitTypeList).contains(u.getType())
Matches_Ctx_unit_is_legal_bombing_target_by :: struct {
	bomber_or_rocket: ^Unit,
}

matches_pred_unit_is_legal_bombing_target_by :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_legal_bombing_target_by)ctx_ptr
	ua := unit_get_unit_attachment(c.bomber_or_rocket)
	utl := game_data_get_unit_type_list(unit_get_data(c.bomber_or_rocket))
	allowed_targets := unit_attachment_get_bombing_targets(ua, utl)
	_, ok := allowed_targets[unit_get_type(unit)]
	return ok
}

matches_unit_is_legal_bombing_target_by :: proc(
	bomber_or_rocket: ^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_legal_bombing_target_by)
	ctx.bomber_or_rocket = bomber_or_rocket
	return matches_pred_unit_is_legal_bombing_target_by, rawptr(ctx)
}

// unitIsNotAir() — u -> !ua.isAir()
matches_pred_unit_is_not_air :: proc(_: rawptr, u: ^Unit) -> bool {
	return !unit_attachment_is_air(unit_get_unit_attachment(u))
}

matches_unit_is_not_air :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_air, nil
}

// unitIsNotInfrastructureAndNotCapturedOnEntering(GamePlayer player, Territory territory)
//   u -> !ua.isInfrastructure() && !unitCanBeCapturedOnEnteringThisTerritory(player, t).test(u)
Matches_Ctx_unit_is_not_infrastructure_and_not_captured_on_entering :: struct {
	player:    ^Game_Player,
	territory: ^Territory,
}

matches_pred_unit_is_not_infrastructure_and_not_captured_on_entering :: proc(
	ctx_ptr: rawptr,
	unit: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_is_not_infrastructure_and_not_captured_on_entering)ctx_ptr
	if unit_attachment_is_infrastructure(unit_get_unit_attachment(unit)) {
		return false
	}
	cap_p, cap_c := matches_unit_can_be_captured_on_entering_this_territory(c.player, c.territory)
	return !cap_p(cap_c, unit)
}

matches_unit_is_not_infrastructure_and_not_captured_on_entering :: proc(
	player: ^Game_Player,
	territory: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_not_infrastructure_and_not_captured_on_entering)
	ctx.player = player
	ctx.territory = territory
	return matches_pred_unit_is_not_infrastructure_and_not_captured_on_entering, rawptr(ctx)
}

// unitIsNotSea() — u -> !ua.isSea()
matches_pred_unit_is_not_sea :: proc(_: rawptr, u: ^Unit) -> bool {
	return !unit_attachment_is_sea(unit_get_unit_attachment(u))
}

matches_unit_is_not_sea :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_sea, nil
}

// unitIsNotSeaTransportButCouldBeCombatSeaTransport()
//   u -> ua.getTransportCapacity() == -1 || (ua.isCombatTransport() && ua.isSea())
matches_pred_unit_is_not_sea_transport_but_could_be_combat_sea_transport :: proc(
	_: rawptr,
	u: ^Unit,
) -> bool {
	ua := unit_get_unit_attachment(u)
	if unit_attachment_get_transport_capacity(ua) == -1 {
		return true
	}
	return unit_attachment_is_combat_transport(ua) && unit_attachment_is_sea(ua)
}

matches_unit_is_not_sea_transport_but_could_be_combat_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_sea_transport_but_could_be_combat_sea_transport, nil
}

// unitIsOfType(UnitType type) — u -> u.getType().equals(type)
Matches_Ctx_unit_is_of_type :: struct {
	type: ^Unit_Type,
}

matches_pred_unit_is_of_type :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_of_type)ctx_ptr
	return unit_get_type(u) == c.type
}

matches_unit_is_of_type :: proc(
	type: ^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_of_type)
	ctx.type = type
	return matches_pred_unit_is_of_type, rawptr(ctx)
}


// =====================================================================
// games.strategy.triplea.delegate.Matches — chunk 4 / 4 (54 procs).
// Same conventions as chunks 1/2/3.
// =====================================================================

// unitIsOfTypes(Set<UnitType> types)
//   unit -> types != null && !types.isEmpty() && types.contains(unit.getType())
Matches_Ctx_unit_is_of_types :: struct {
	types: map[^Unit_Type]struct {},
}

matches_pred_unit_is_of_types :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_of_types)ctx_ptr
	if c.types == nil || len(c.types) == 0 {
		return false
	}
	_, ok := c.types[unit_get_type(unit)]
	return ok
}

matches_unit_is_of_types :: proc(
	types: map[^Unit_Type]struct {},
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_of_types)
	ctx.types = types
	return matches_pred_unit_is_of_types, rawptr(ctx)
}

// unitIsOwnedAndIsFactoryOrCanProduceUnits(GamePlayer player)
//   unit -> unitCanProduceUnits().test(unit) && unitIsOwnedBy(player).test(unit)
Matches_Ctx_unit_is_owned_and_is_factory_or_can_produce_units :: struct {
	player: ^Game_Player,
}

matches_pred_unit_is_owned_and_is_factory_or_can_produce_units :: proc(
	ctx_ptr: rawptr,
	unit: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_is_owned_and_is_factory_or_can_produce_units)ctx_ptr
	cpu_p, cpu_c := matches_unit_can_produce_units()
	if !cpu_p(cpu_c, unit) {
		return false
	}
	return unit_is_owned_by(unit, c.player)
}

matches_unit_is_owned_and_is_factory_or_can_produce_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_owned_and_is_factory_or_can_produce_units)
	ctx.player = player
	return matches_pred_unit_is_owned_and_is_factory_or_can_produce_units, rawptr(ctx)
}

// unitIsOwnedBy(GamePlayer player) — unit -> unit.isOwnedBy(player)
Matches_Ctx_unit_is_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_unit_is_owned_by :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_owned_by)ctx_ptr
	return unit_is_owned_by(unit, c.player)
}

matches_unit_is_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_owned_by)
	ctx.player = player
	return matches_pred_unit_is_owned_by, rawptr(ctx)
}

// unitIsOwnedByAnyOf(Collection<GamePlayer> players)
//   unit -> players.contains(unit.getOwner())
Matches_Ctx_unit_is_owned_by_any_of :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_unit_is_owned_by_any_of :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_owned_by_any_of)ctx_ptr
	owner := unit_get_owner(unit)
	for p in c.players {
		if p == owner {
			return true
		}
	}
	return false
}

matches_unit_is_owned_by_any_of :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_owned_by_any_of)
	ctx.players = players
	return matches_pred_unit_is_owned_by_any_of, rawptr(ctx)
}

// unitIsRocket() — obj -> unitTypeIsRocket().test(obj.getType())
matches_pred_unit_is_rocket :: proc(_: rawptr, obj: ^Unit) -> bool {
	return unit_attachment_is_rocket(unit_type_get_unit_attachment(unit_get_type(obj)))
}

matches_unit_is_rocket :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_rocket, nil
}

// unitIsSea() — unit -> ua.isSea()
matches_pred_unit_is_sea :: proc(_: rawptr, unit: ^Unit) -> bool {
	return unit_attachment_is_sea(unit_get_unit_attachment(unit))
}

matches_unit_is_sea :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_sea, nil
}

// unitIsSeaTransport()
//   unit -> ua.getTransportCapacity() != -1 && ua.isSea()
matches_pred_unit_is_sea_transport :: proc(_: rawptr, unit: ^Unit) -> bool {
	ua := unit_get_unit_attachment(unit)
	return unit_attachment_get_transport_capacity(ua) != -1 && unit_attachment_is_sea(ua)
}

matches_unit_is_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_sea_transport, nil
}

// unitIsSeaTransportAndNotDestroyer()
//   unit -> !isDestroyer && ua.getTransportCapacity() != -1 && ua.isSea()
matches_pred_unit_is_sea_transport_and_not_destroyer :: proc(_: rawptr, unit: ^Unit) -> bool {
	ua := unit_get_unit_attachment(unit)
	if unit_attachment_is_destroyer(ua) {
		return false
	}
	return unit_attachment_get_transport_capacity(ua) != -1 && unit_attachment_is_sea(ua)
}

matches_unit_is_sea_transport_and_not_destroyer :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_sea_transport_and_not_destroyer, nil
}

// unitIsSeaTransportButNotCombatSeaTransport()
//   unit -> ua.getTransportCapacity() != -1 && ua.isSea() && !ua.isCombatTransport()
matches_pred_unit_is_sea_transport_but_not_combat_sea_transport :: proc(
	_: rawptr,
	unit: ^Unit,
) -> bool {
	ua := unit_get_unit_attachment(unit)
	return unit_attachment_get_transport_capacity(ua) != -1 &&
	       unit_attachment_is_sea(ua) &&
	       !unit_attachment_is_combat_transport(ua)
}

matches_unit_is_sea_transport_but_not_combat_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_sea_transport_but_not_combat_sea_transport, nil
}

// unitIsStrategicBomber() — u -> unitTypeIsStrategicBomber().test(u.getType())
matches_pred_unit_is_strategic_bomber :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_is_strategic_bomber(unit_type_get_unit_attachment(unit_get_type(u)))
}

matches_unit_is_strategic_bomber :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_strategic_bomber, nil
}

// unitIsSubmerged() — Unit::getSubmerged
matches_pred_unit_is_submerged :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_submerged(u)
}

matches_unit_is_submerged :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_submerged, nil
}

// unitIsSuicideOnAttack() — unit -> ua.getIsSuicideOnAttack()
matches_pred_unit_is_suicide_on_attack :: proc(_: rawptr, unit: ^Unit) -> bool {
	return unit_attachment_get_is_suicide_on_attack(unit_get_unit_attachment(unit))
}

matches_unit_is_suicide_on_attack :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_suicide_on_attack, nil
}

// unitIsSuicideOnDefense() — unit -> ua.getIsSuicideOnDefense()
matches_pred_unit_is_suicide_on_defense :: proc(_: rawptr, unit: ^Unit) -> bool {
	return unit_attachment_get_is_suicide_on_defense(unit_get_unit_attachment(unit))
}

matches_unit_is_suicide_on_defense :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_suicide_on_defense, nil
}

// unitIsSuicideOnHit() — unit -> ua.isSuicideOnHit()
matches_pred_unit_is_suicide_on_hit :: proc(_: rawptr, unit: ^Unit) -> bool {
	return unit_attachment_is_suicide_on_hit(unit_get_unit_attachment(unit))
}

matches_unit_is_suicide_on_hit :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_suicide_on_hit, nil
}

// unitIsSupporterOrHasCombatAbility(boolean attack)
//   u -> unitTypeIsSupporterOrHasCombatAbility(attack, u.getOwner()).test(u.getType())
Matches_Ctx_unit_is_supporter_or_has_combat_ability :: struct {
	attack: bool,
}

matches_pred_unit_is_supporter_or_has_combat_ability :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_supporter_or_has_combat_ability)ctx_ptr
	p, pc := matches_unit_type_is_supporter_or_has_combat_ability(c.attack, unit_get_owner(u))
	return p(pc, unit_get_type(u))
}

matches_unit_is_supporter_or_has_combat_ability :: proc(
	attack: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_supporter_or_has_combat_ability)
	ctx.attack = attack
	return matches_pred_unit_is_supporter_or_has_combat_ability, rawptr(ctx)
}

// unitMaxAaAttacksIsInfinite() — u -> ua.getMaxAaAttacks() == -1
matches_pred_unit_max_aa_attacks_is_infinite :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_max_aa_attacks(unit_get_unit_attachment(u)) == -1
}

matches_unit_max_aa_attacks_is_infinite :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_max_aa_attacks_is_infinite, nil
}

// unitMayOverStackAa() — u -> ua.getMayOverStackAa()
matches_pred_unit_may_over_stack_aa :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_may_over_stack_aa(unit_get_unit_attachment(u))
}

matches_unit_may_over_stack_aa :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_may_over_stack_aa, nil
}

// unitOffensiveAttackAaIsGreaterThanZeroAndMaxAaAttacksIsNotZero()
//   u -> ua.getOffensiveAttackAa(owner) > 0 && ua.getMaxAaAttacks() != 0
matches_pred_unit_offensive_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero :: proc(
	_: rawptr,
	u: ^Unit,
) -> bool {
	ua := unit_get_unit_attachment(u)
	return unit_attachment_get_offensive_attack_aa(ua, unit_get_owner(u)) > 0 &&
	       unit_attachment_get_max_aa_attacks(ua) != 0
}

matches_unit_offensive_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_offensive_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero, nil
}

// unitOwnerHasImprovedArtillerySupportTech()
//   u -> TechTracker.hasImprovedArtillerySupport(u.getOwner())
matches_pred_unit_owner_has_improved_artillery_support_tech :: proc(_: rawptr, u: ^Unit) -> bool {
	return tech_tracker_has_improved_artillery_support(unit_get_owner(u))
}

matches_unit_owner_has_improved_artillery_support_tech :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_owner_has_improved_artillery_support_tech, nil
}

// unitRequiresUnitsOnCreation() — unit -> !ua.getRequiresUnits().isEmpty()
matches_pred_unit_requires_units_on_creation :: proc(_: rawptr, unit: ^Unit) -> bool {
	return len(unit_attachment_get_requires_units(unit_get_unit_attachment(unit))) > 0
}

matches_unit_requires_units_on_creation :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_requires_units_on_creation, nil
}

// unitTypeCanBeDamaged() — ut -> ua.canBeDamaged()
matches_pred_unit_type_can_be_damaged :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_can_be_damaged(unit_type_get_unit_attachment(ut))
}

matches_unit_type_can_be_damaged :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_can_be_damaged, nil
}

// unitTypeCanMove(GamePlayer player)
//   unitType -> ua.getMovement(player) > 0
Matches_Ctx_unit_type_can_move :: struct {
	player: ^Game_Player,
}

matches_pred_unit_type_can_move :: proc(ctx_ptr: rawptr, ut: ^Unit_Type) -> bool {
	c := cast(^Matches_Ctx_unit_type_can_move)ctx_ptr
	return unit_attachment_get_movement(unit_type_get_unit_attachment(ut), c.player) > 0
}

matches_unit_type_can_move :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_type_can_move)
	ctx.player = player
	return matches_pred_unit_type_can_move, rawptr(ctx)
}

// unitTypeCanNotMoveDuringCombatMove()
//   u -> ua.canNotMoveDuringCombatMove()
matches_pred_unit_type_can_not_move_during_combat_move :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_can_not_move_during_combat_move(unit_type_get_unit_attachment(ut))
}

matches_unit_type_can_not_move_during_combat_move :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_can_not_move_during_combat_move, nil
}

// unitTypeCanProduceUnits() — ut -> ua.canProduceUnits()
matches_pred_unit_type_can_produce_units :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_can_produce_units(unit_type_get_unit_attachment(ut))
}

matches_unit_type_can_produce_units :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_can_produce_units, nil
}

// unitTypeConsumesUnitsOnCreation()
//   unit -> !ua.getConsumesUnits().isEmpty()
matches_pred_unit_type_consumes_units_on_creation :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return len(unit_attachment_get_consumes_units(unit_type_get_unit_attachment(ut))) > 0
}

matches_unit_type_consumes_units_on_creation :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_consumes_units_on_creation, nil
}

// unitTypeHasMoreThanOneHitPointTotal() — ut -> ua.getHitPoints() > 1
matches_pred_unit_type_has_more_than_one_hit_point_total :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_get_hit_points(unit_type_get_unit_attachment(ut)) > 1
}

matches_unit_type_has_more_than_one_hit_point_total :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_has_more_than_one_hit_point_total, nil
}

// unitTypeIsAaForAnything()
//   ut -> ua.isAaForBombingThisUnitOnly() || ua.isAaForCombatOnly() || ua.isAaForFlyOverOnly()
matches_pred_unit_type_is_aa_for_anything :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	ua := unit_type_get_unit_attachment(ut)
	return unit_attachment_is_aa_for_bombing_this_unit_only(ua) ||
	       unit_attachment_is_aa_for_combat_only(ua) ||
	       unit_attachment_is_aa_for_fly_over_only(ua)
}

matches_unit_type_is_aa_for_anything :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_aa_for_anything, nil
}

// unitTypeIsAaForBombingThisUnitOnly() — ut -> ua.isAaForBombingThisUnitOnly()
matches_pred_unit_type_is_aa_for_bombing_this_unit_only :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_aa_for_bombing_this_unit_only(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_aa_for_bombing_this_unit_only :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_aa_for_bombing_this_unit_only, nil
}

// unitTypeIsAaForCombatOnly() — ut -> ua.isAaForCombatOnly()
matches_pred_unit_type_is_aa_for_combat_only :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_aa_for_combat_only(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_aa_for_combat_only :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_aa_for_combat_only, nil
}

// unitTypeIsAaThatCanFireOnRound(int battleRoundNumber)
//   obj -> { mr = ua.getMaxRoundsAa(); return mr < 0 || mr >= battleRoundNumber }
Matches_Ctx_unit_type_is_aa_that_can_fire_on_round :: struct {
	battle_round_number: i32,
}

matches_pred_unit_type_is_aa_that_can_fire_on_round :: proc(ctx_ptr: rawptr, ut: ^Unit_Type) -> bool {
	c := cast(^Matches_Ctx_unit_type_is_aa_that_can_fire_on_round)ctx_ptr
	mr := unit_attachment_get_max_rounds_aa(unit_type_get_unit_attachment(ut))
	return mr < 0 || mr >= c.battle_round_number
}

matches_unit_type_is_aa_that_can_fire_on_round :: proc(
	battle_round_number: i32,
) -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_type_is_aa_that_can_fire_on_round)
	ctx.battle_round_number = battle_round_number
	return matches_pred_unit_type_is_aa_that_can_fire_on_round, rawptr(ctx)
}

// unitTypeIsAir() — type -> ua.isAir()
matches_pred_unit_type_is_air :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_air(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_air :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_air, nil
}

// unitTypeIsConstruction() — type -> ua.isConstruction()
matches_pred_unit_type_is_construction :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_construction(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_construction :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_construction, nil
}

// unitTypeIsDestroyer() — type -> ua.isDestroyer()
matches_pred_unit_type_is_destroyer :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_destroyer(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_destroyer :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_destroyer, nil
}

// unitTypeIsFirstStrike() — type -> ua.getIsFirstStrike()
matches_pred_unit_type_is_first_strike :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_get_is_first_strike(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_first_strike :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_first_strike, nil
}

// unitTypeIsInfrastructure() — ut -> ua.isInfrastructure()
matches_pred_unit_type_is_infrastructure :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_infrastructure(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_infrastructure :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_infrastructure, nil
}

// unitTypeIsNotAir() — type -> !ua.isAir()
matches_pred_unit_type_is_not_air :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return !unit_attachment_is_air(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_not_air :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_not_air, nil
}

// unitTypeIsNotSea() — unitTypeIsSea().negate()
matches_pred_unit_type_is_not_sea :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return !unit_attachment_is_sea(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_not_sea :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_not_sea, nil
}

// unitTypeIsRocket() — ut -> ua.isRocket()
matches_pred_unit_type_is_rocket :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_rocket(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_rocket :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_rocket, nil
}

// unitTypeIsSea() — type -> ua.isSea()
matches_pred_unit_type_is_sea :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_sea(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_sea :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_sea, nil
}

// unitTypeIsStrategicBomber() — unitType -> ua.isStrategicBomber()
matches_pred_unit_type_is_strategic_bomber :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_is_strategic_bomber(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_strategic_bomber :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_strategic_bomber, nil
}

// unitTypeIsSuicideOnAttack() — type -> ua.getIsSuicideOnAttack()
matches_pred_unit_type_is_suicide_on_attack :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_get_is_suicide_on_attack(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_suicide_on_attack :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_suicide_on_attack, nil
}

// unitTypeIsSuicideOnDefense() — type -> ua.getIsSuicideOnDefense()
matches_pred_unit_type_is_suicide_on_defense :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_get_is_suicide_on_defense(unit_type_get_unit_attachment(ut))
}

matches_unit_type_is_suicide_on_defense :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_suicide_on_defense, nil
}

// unitTypeIsSupporterOrHasCombatAbility(boolean attack, GamePlayer player) [private]
//   ut -> { if attack && ua.getAttack(player) > 0 return true;
//           if !attack && ua.getDefense(player) > 0 return true;
//           return !UnitSupportAttachment.get(ut).isEmpty() }
Matches_Ctx_unit_type_is_supporter_or_has_combat_ability :: struct {
	attack: bool,
	player: ^Game_Player,
}

matches_pred_unit_type_is_supporter_or_has_combat_ability :: proc(
	ctx_ptr: rawptr,
	ut: ^Unit_Type,
) -> bool {
	c := cast(^Matches_Ctx_unit_type_is_supporter_or_has_combat_ability)ctx_ptr
	ua := unit_type_get_unit_attachment(ut)
	if c.attack && unit_attachment_get_attack(ua, c.player) > 0 {
		return true
	}
	if !c.attack && unit_attachment_get_defense(ua, c.player) > 0 {
		return true
	}
	return len(unit_support_attachment_get(ut)) > 0
}

matches_unit_type_is_supporter_or_has_combat_ability :: proc(
	attack: bool,
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_type_is_supporter_or_has_combat_ability)
	ctx.attack = attack
	ctx.player = player
	return matches_pred_unit_type_is_supporter_or_has_combat_ability, rawptr(ctx)
}

// unitWasAmphibious() — Unit::getWasAmphibious
matches_pred_unit_was_amphibious :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_was_amphibious(u)
}

matches_unit_was_amphibious :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_amphibious, nil
}

// unitWasInAirBattle() — Unit::getWasInAirBattle
matches_pred_unit_was_in_air_battle :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_was_in_air_battle(u)
}

matches_unit_was_in_air_battle :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_in_air_battle, nil
}

// unitWasInCombat() — Unit::getWasInCombat
matches_pred_unit_was_in_combat :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_was_in_combat(u)
}

matches_unit_was_in_combat :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_in_combat, nil
}

// unitWasScrambled() — Unit::getWasScrambled
matches_pred_unit_was_scrambled :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_was_scrambled(u)
}

matches_unit_was_scrambled :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_scrambled, nil
}

// unitWasUnloadedThisTurn() — u -> u.getUnloadedTo() != null
matches_pred_unit_was_unloaded_this_turn :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_unloaded_to(u) != nil
}

matches_unit_was_unloaded_this_turn :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_unloaded_this_turn, nil
}

// unitWhenCapturedChangesIntoDifferentUnitType()
//   u -> !ua.getWhenCapturedChangesInto().isEmpty()
matches_pred_unit_when_captured_changes_into_different_unit_type :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_when_captured_changes_into(unit_get_unit_attachment(u))) > 0
}

matches_unit_when_captured_changes_into_different_unit_type :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_when_captured_changes_into_different_unit_type, nil
}

// unitWhenCapturedSustainsDamage()
//   u -> ua.getWhenCapturedSustainsDamage() > 0
matches_pred_unit_when_captured_sustains_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_attachment_get_when_captured_sustains_damage(unit_get_unit_attachment(u)) > 0
}

matches_unit_when_captured_sustains_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_when_captured_sustains_damage, nil
}

// unitWhenHitPointsDamagedChangesInto()
//   u -> !ua.getWhenHitPointsDamagedChangesInto().isEmpty()
matches_pred_unit_when_hit_points_damaged_changes_into :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_when_hit_points_damaged_changes_into(unit_get_unit_attachment(u))) > 0
}

matches_unit_when_hit_points_damaged_changes_into :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_when_hit_points_damaged_changes_into, nil
}

// unitWhenHitPointsRepairedChangesInto()
//   u -> !ua.getWhenHitPointsRepairedChangesInto().isEmpty()
matches_pred_unit_when_hit_points_repaired_changes_into :: proc(_: rawptr, u: ^Unit) -> bool {
	return len(unit_attachment_get_when_hit_points_repaired_changes_into(unit_get_unit_attachment(u))) > 0
}

matches_unit_when_hit_points_repaired_changes_into :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_when_hit_points_repaired_changes_into, nil
}

// unitWhichConsumesUnitsHasRequiredUnits(Collection<Unit> unitsInTerritoryAtStartOfTurn)
//   eligibleUnitToConsume(owner, ut) inlined =
//     unitIsOwnedBy(owner) && unitIsOfType(ut)
//     && unit.getUnitDamage() == 0 (not bombing-damaged)
//     && unit.getHits() == 0      (not damaged)
//     && !unitIsDisabled().test(unit)
Matches_Ctx_unit_which_consumes_units_has_required_units :: struct {
	units_in_territory: [dynamic]^Unit,
}

matches_pred_unit_which_consumes_units_has_required_units :: proc(
	ctx_ptr: rawptr,
	uwru: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_which_consumes_units_has_required_units)ctx_ptr
	cuoc_p, cuoc_c := matches_unit_consumes_units_on_creation()
	if !cuoc_p(cuoc_c, uwru) {
		return true
	}
	ua := unit_get_unit_attachment(uwru)
	required := unit_attachment_get_consumes_units(ua)
	owner := unit_get_owner(uwru)
	disabled_p, disabled_c := matches_unit_is_disabled()
	for ut, required_number in required {
		number_in_territory: i32 = 0
		for u in c.units_in_territory {
			if !unit_is_owned_by(u, owner) {
				continue
			}
			if unit_get_type(u) != ut {
				continue
			}
			if unit_get_unit_damage(u) != 0 {
				continue
			}
			if unit_get_hits(u) != 0 {
				continue
			}
			if disabled_p(disabled_c, u) {
				continue
			}
			number_in_territory += 1
		}
		if number_in_territory < required_number {
			return false
		}
	}
	return true
}

matches_unit_which_consumes_units_has_required_units :: proc(
	units_in_territory: [dynamic]^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_which_consumes_units_has_required_units)
	ctx.units_in_territory = units_in_territory
	return matches_pred_unit_which_consumes_units_has_required_units, rawptr(ctx)
}

// unitWhichRequiresUnitsHasRequiredUnitsInList(Collection<Unit> unitsInTerritoryAtStartOfTurn)
Matches_Ctx_unit_which_requires_units_has_required_units_in_list :: struct {
	units_in_territory: [dynamic]^Unit,
}

matches_pred_unit_which_requires_units_has_required_units_in_list :: proc(
	ctx_ptr: rawptr,
	uwru: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_which_requires_units_has_required_units_in_list)ctx_ptr
	ruoc_p, ruoc_c := matches_unit_requires_units_on_creation()
	if !ruoc_p(ruoc_c, uwru) {
		return true
	}
	owner := unit_get_owner(uwru)
	disabled_p, disabled_c := matches_unit_is_disabled()
	matched: [dynamic]^Unit
	for u in c.units_in_territory {
		if !unit_is_owned_by(u, owner) {
			continue
		}
		if disabled_p(disabled_c, u) {
			continue
		}
		append(&matched, u)
	}
	ua := unit_get_unit_attachment(uwru)
	for combo in unit_attachment_get_requires_units(ua) {
		listed := unit_attachment_get_listed_units(ua, combo)
		have_all := true
		for ut in listed {
			found := false
			for m in matched {
				if unit_get_type(m) == ut {
					found = true
					break
				}
			}
			if !found {
				have_all = false
				break
			}
		}
		if have_all {
			return true
		}
	}
	return false
}

matches_unit_which_requires_units_has_required_units_in_list :: proc(
	units_in_territory: [dynamic]^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_which_requires_units_has_required_units_in_list)
	ctx.units_in_territory = units_in_territory
	return matches_pred_unit_which_requires_units_has_required_units_in_list, rawptr(ctx)
}

// =====================================================================
// Phase B layer 1 batch (74 entries).
// Pure-lambda procs (matches_lambda_<name>_<N>) translate javac
// synthetics directly; new factories below them combine layer-0
// helpers via the rawptr-ctx convention.
// =====================================================================

// lambda$abstractUserActionAttachmentCanBeAttempted$220
//   uaa -> uaa.hasAttemptsLeft() && uaa.canPerform(testedConditions)
matches_lambda_abstract_user_action_attachment_can_be_attempted_220 :: proc(
	tested_conditions: map[^I_Condition]bool,
	uaa: ^Abstract_User_Action_Attachment,
) -> bool {
	return abstract_user_action_attachment_has_attempts_left(uaa) &&
		abstract_user_action_attachment_can_perform(uaa, tested_conditions)
}

// lambda$battleIsAmphibiousWithUnitsAttackingFrom$122
//   b -> (b instanceof DependentBattle) && ((DependentBattle) b).getAmphibiousAttackTerritories().contains(from)
// In the Odin port the DependentBattle hierarchy (MustFightBattle,
// NonFightingBattle) embeds Dependent_Battle as the first field of
// Abstract_Battle's family. The outer battleIsAmphibious filter
// guarantees the battle is a MustFightBattle (the only TripleA
// concrete subclass that sets isAmphibious on dependent battles), so
// the cast is structurally safe.
matches_lambda_battle_is_amphibious_with_units_attacking_from_122 :: proc(
	from: ^Territory,
	b: ^I_Battle,
) -> bool {
	db := cast(^Dependent_Battle)b
	for tt in dependent_battle_get_amphibious_attack_territories(db) {
		if tt == from {
			return true
		}
	}
	return false
}

// lambda$isTerritoryNeutral$134 — t -> t.getOwner().isNull()
matches_lambda_is_territory_neutral_134 :: proc(t: ^Territory) -> bool {
	return game_player_is_null(t.owner)
}

// lambda$isTerritoryOwnedByAnyOf$135 — t -> players.contains(t.getOwner())
matches_lambda_is_territory_owned_by_any_of_135 :: proc(
	players: [dynamic]^Game_Player,
	t: ^Territory,
) -> bool {
	owner := t.owner
	for p in players {
		if p == owner {
			return true
		}
	}
	return false
}

// lambda$isValidRelationshipName$206 —
//   relationshipName -> relationshipTypeList.getRelationshipType(relationshipName) != null
matches_lambda_is_valid_relationship_name_206 :: proc(
	relationship_type_list: ^Relationship_Type_List,
	relationship_name: string,
) -> bool {
	return relationship_type_list_get_relationship_type(relationship_type_list, relationship_name) != nil
}

// lambda$seaCanMoveOver$116 —
//   t -> t.isWater() && territoryIsPassableAndNotRestricted(player).test(t)
matches_lambda_sea_can_move_over_116 :: proc(player: ^Game_Player, t: ^Territory) -> bool {
	if !territory_is_water(t) {
		return false
	}
	p, c := matches_territory_is_passable_and_not_restricted(player)
	return p(c, t)
}

// lambda$territoryHasAlliedIsFactoryOrCanProduceUnits$111 —
//   t -> isTerritoryAllied(player).test(t) && t.anyUnitsMatch(unitCanProduceUnits())
matches_lambda_territory_has_allied_is_factory_or_can_produce_units_111 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	ap, ac := matches_is_territory_allied(player)
	if !ap(ac, t) {
		return false
	}
	cp, cc := matches_unit_can_produce_units()
	for u in t.unit_collection.units {
		if cp(cc, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasAlliedUnits$156 — t -> t.anyUnitsMatch(alliedUnit(player))
matches_lambda_territory_has_allied_units_156 :: proc(player: ^Game_Player, t: ^Territory) -> bool {
	ap, ac := matches_allied_unit(player)
	for u in t.unit_collection.units {
		if ap(ac, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasEnemySeaUnits$159 —
//   t -> t.anyUnitsMatch(enemyUnit(player).and(unitIsSea()))
matches_lambda_territory_has_enemy_sea_units_159 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	ep, ec := matches_enemy_unit(player)
	sp, sc := matches_unit_is_sea()
	for u in t.unit_collection.units {
		if ep(ec, u) && sp(sc, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasEnemyUnits$160 — t -> t.anyUnitsMatch(enemyUnit(player))
matches_lambda_territory_has_enemy_units_160 :: proc(player: ^Game_Player, t: ^Territory) -> bool {
	ep, ec := matches_enemy_unit(player)
	for u in t.unit_collection.units {
		if ep(ec, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasNoEnemyUnits$155 — t -> !t.anyUnitsMatch(enemyUnit(player))
matches_lambda_territory_has_no_enemy_units_155 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	ep, ec := matches_enemy_unit(player)
	for u in t.unit_collection.units {
		if ep(ec, u) {
			return false
		}
	}
	return true
}

// lambda$territoryHasNonSubmergedEnemyUnits$157 —
//   t -> t.anyUnitsMatch(enemyUnit(player).and(not(unitIsSubmerged())))
matches_lambda_territory_has_non_submerged_enemy_units_157 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	ep, ec := matches_enemy_unit(player)
	sp, sc := matches_unit_is_submerged()
	for u in t.unit_collection.units {
		if ep(ec, u) && !sp(sc, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasOwnedCarrier$65 —
//   t -> t.anyUnitsMatch(unitIsOwnedBy(player).and(unitIsCarrier()))
matches_lambda_territory_has_owned_carrier_65 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	cp, cc := matches_unit_is_carrier()
	for u in t.unit_collection.units {
		if unit_is_owned_by(u, player) && cp(cc, u) {
			return true
		}
	}
	return false
}

// lambda$territoryHasRequiredUnitsToMove$187 —
//   t -> units.stream().allMatch(unitHasRequiredUnitsToMove(t))
matches_lambda_territory_has_required_units_to_move_187 :: proc(
	units: [dynamic]^Unit,
	t: ^Territory,
) -> bool {
	rp, rc := matches_unit_has_required_units_to_move(t)
	for u in units {
		if !rp(rc, u) {
			return false
		}
	}
	return true
}

// lambda$territoryHasUnitsOwnedBy$152 —
//   t -> t.anyUnitsMatch(unitIsOwnedBy(player))
matches_lambda_territory_has_units_owned_by_152 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	for u in t.unit_collection.units {
		if unit_is_owned_by(u, player) {
			return true
		}
	}
	return false
}

// lambda$territoryIsEmpty$103 — t -> t.getUnitCollection().isEmpty()
matches_lambda_territory_is_empty_103 :: proc(t: ^Territory) -> bool {
	return unit_collection_is_empty(t.unit_collection)
}

// lambda$territoryIsEmptyOfCombatUnits$113 —
//   t -> t.getUnitCollection().allMatch(unitIsInfrastructure().or(enemyUnit(player).negate()))
matches_lambda_territory_is_empty_of_combat_units_113 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	ip, ic := matches_unit_is_infrastructure()
	ep, ec := matches_enemy_unit(player)
	for u in t.unit_collection.units {
		if !(ip(ic, u) || !ep(ec, u)) {
			return false
		}
	}
	return true
}

// lambda$territoryIsImpassableToLandUnits$119 —
//   t -> t.isWater() || territoryIsPassableAndNotRestricted(player).negate().test(t)
matches_lambda_territory_is_impassable_to_land_units_119 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	if territory_is_water(t) {
		return true
	}
	pp, pc := matches_territory_is_passable_and_not_restricted(player)
	return !pp(pc, t)
}

// lambda$territoryIsIsland$101 —
//   t -> { neighbors = t.getData().getMap().getNeighbors(t);
//          return neighbors.size() == 1 && CollectionUtils.getAny(neighbors).isWater(); }
matches_lambda_territory_is_island_101 :: proc(t: ^Territory) -> bool {
	gm := game_data_get_map(territory_get_data(t))
	neighbors := game_map_get_neighbors(gm, t)
	if len(neighbors) != 1 {
		return false
	}
	for n, _ in neighbors {
		return territory_is_water(n)
	}
	return false
}

// lambda$territoryIsNotImpassableToLandUnits$120 —
//   t -> territoryIsImpassableToLandUnits(player).negate().test(t)
matches_lambda_territory_is_not_impassable_to_land_units_120 :: proc(
	player: ^Game_Player,
	t: ^Territory,
) -> bool {
	return !matches_lambda_territory_is_impassable_to_land_units_119(player, t)
}

// lambda$territoryWasFoughtOver$169 —
//   t -> tracker.wasBattleFought(t) || tracker.wasBlitzed(t)
matches_lambda_territory_was_fought_over_169 :: proc(
	tracker: ^Battle_Tracker,
	t: ^Territory,
) -> bool {
	return battle_tracker_was_battle_fought(tracker, t) || battle_tracker_was_blitzed(tracker, t)
}

// lambda$unitCanBeDamaged$37 — unit -> unitTypeCanBeDamaged().test(unit.getType())
matches_lambda_unit_can_be_damaged_37 :: proc(unit: ^Unit) -> bool {
	p, c := matches_unit_type_can_be_damaged()
	return p(c, unit_get_type(unit))
}

// lambda$unitCanMove$125 — u -> unitTypeCanMove(u.getOwner()).test(u.getType())
matches_lambda_unit_can_move_125 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_can_move(unit_get_owner(u))
	return p(c, unit_get_type(u))
}

// lambda$unitCanNotMoveDuringCombatMove$76 —
//   u -> unitTypeCanNotMoveDuringCombatMove().test(u.getType())
matches_lambda_unit_can_not_move_during_combat_move_76 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_can_not_move_during_combat_move()
	return p(c, unit_get_type(u))
}

// lambda$unitCanProduceUnits$71 — u -> unitTypeCanProduceUnits().test(u.getType())
matches_lambda_unit_can_produce_units_71 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_can_produce_units()
	return p(c, unit_get_type(u))
}

// lambda$unitHasMoreThanOneHitPointTotal$1 —
//   unit -> unitTypeHasMoreThanOneHitPointTotal().test(unit.getType())
matches_lambda_unit_has_more_than_one_hit_point_total_1 :: proc(unit: ^Unit) -> bool {
	p, c := matches_unit_type_has_more_than_one_hit_point_total()
	return p(c, unit_get_type(unit))
}

// lambda$unitHasNotBeenChargedFlatFuelCost$18 — unit -> !unit.getChargedFlatFuelCost()
matches_lambda_unit_has_not_been_charged_flat_fuel_cost_18 :: proc(unit: ^Unit) -> bool {
	return !unit_get_charged_flat_fuel_cost(unit)
}

// lambda$unitHasTakenSomeBombingUnitDamage$40 — unit -> unit.getUnitDamage() > 0
matches_lambda_unit_has_taken_some_bombing_unit_damage_40 :: proc(unit: ^Unit) -> bool {
	return unit_get_unit_damage(unit) > 0
}

// lambda$unitHasTakenSomeDamage$2 — unit -> unit.getHits() > 0
matches_lambda_unit_has_taken_some_damage_2 :: proc(unit: ^Unit) -> bool {
	return unit_get_hits(unit) > 0
}

// lambda$unitIsAaForAnything$91 — u -> unitTypeIsAaForAnything().test(u.getType())
matches_lambda_unit_is_aa_for_anything_91 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_is_aa_for_anything()
	return p(c, unit_get_type(u))
}

// lambda$unitIsAaForBombingThisUnitOnly$88 —
//   u -> unitTypeIsAaForBombingThisUnitOnly().test(u.getType())
matches_lambda_unit_is_aa_for_bombing_this_unit_only_88 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_is_aa_for_bombing_this_unit_only()
	return p(c, unit_get_type(u))
}

// lambda$unitIsAaForCombatOnly$86 —
//   ut -> unitTypeIsAaForCombatOnly().test(ut.getType())
matches_lambda_unit_is_aa_for_combat_only_86 :: proc(ut: ^Unit) -> bool {
	p, c := matches_unit_type_is_aa_for_combat_only()
	return p(c, unit_get_type(ut))
}

// lambda$unitIsAaThatCanFireOnRound$84 —
//   u -> unitTypeIsAaThatCanFireOnRound(battleRoundNumber).test(u.getType())
matches_lambda_unit_is_aa_that_can_fire_on_round_84 :: proc(
	battle_round_number: i32,
	u: ^Unit,
) -> bool {
	p, c := matches_unit_type_is_aa_that_can_fire_on_round(battle_round_number)
	return p(c, unit_get_type(u))
}

// lambda$unitIsBeingTransported$164 — dependent -> dependent.getTransportedBy() != null
matches_lambda_unit_is_being_transported_164 :: proc(dependent: ^Unit) -> bool {
	return unit_get_transported_by(dependent) != nil
}

// lambda$unitIsConstruction$190 — obj -> unitTypeIsConstruction().test(obj.getType())
matches_lambda_unit_is_construction_190 :: proc(obj: ^Unit) -> bool {
	p, c := matches_unit_type_is_construction()
	return p(c, unit_get_type(obj))
}

// lambda$unitIsInfrastructure$44 — unit -> unitTypeIsInfrastructure().test(unit.getType())
matches_lambda_unit_is_infrastructure_44 :: proc(unit: ^Unit) -> bool {
	p, c := matches_unit_type_is_infrastructure()
	return p(c, unit_get_type(unit))
}

// lambda$unitIsLandTransportWithCapacity$52 —
//   unit -> unitIsLandTransport().and(unitCanTransport()).test(unit)
matches_lambda_unit_is_land_transport_with_capacity_52 :: proc(unit: ^Unit) -> bool {
	lp, lc := matches_unit_is_land_transport()
	cp, cc := matches_unit_can_transport()
	return lp(lc, unit) && cp(cc, unit)
}

// lambda$unitIsLandTransportWithoutCapacity$53 —
//   unit -> unitIsLandTransport().and(unitCanTransport().negate()).test(unit)
matches_lambda_unit_is_land_transport_without_capacity_53 :: proc(unit: ^Unit) -> bool {
	lp, lc := matches_unit_is_land_transport()
	cp, cc := matches_unit_can_transport()
	return lp(lc, unit) && !cp(cc, unit)
}

// lambda$unitIsOfType$167 — unit -> unit.getType().equals(type)
matches_lambda_unit_is_of_type_167 :: proc(type: ^Unit_Type, unit: ^Unit) -> bool {
	return unit_get_type(unit) == type
}

// lambda$unitIsOfTypes$168 —
//   unit -> types != null && !types.isEmpty() && types.contains(unit.getType())
matches_lambda_unit_is_of_types_168 :: proc(
	types: map[^Unit_Type]struct {},
	unit: ^Unit,
) -> bool {
	if len(types) == 0 {
		return false
	}
	_, ok := types[unit_get_type(unit)]
	return ok
}

// lambda$unitIsOwnedAndIsFactoryOrCanProduceUnits$209 —
//   unit -> unitCanProduceUnits().test(unit) && unitIsOwnedBy(player).test(unit)
matches_lambda_unit_is_owned_and_is_factory_or_can_produce_units_209 :: proc(
	player: ^Game_Player,
	unit: ^Unit,
) -> bool {
	cp, cc := matches_unit_can_produce_units()
	if !cp(cc, unit) {
		return false
	}
	return unit_is_owned_by(unit, player)
}

// lambda$unitIsOwnedByAnyOf$130 — unit -> players.contains(unit.getOwner())
matches_lambda_unit_is_owned_by_any_of_130 :: proc(
	players: [dynamic]^Game_Player,
	unit: ^Unit,
) -> bool {
	owner := unit_get_owner(unit)
	for p in players {
		if p == owner {
			return true
		}
	}
	return false
}

// lambda$unitIsRocket$74 — obj -> unitTypeIsRocket().test(obj.getType())
matches_lambda_unit_is_rocket_74 :: proc(obj: ^Unit) -> bool {
	p, c := matches_unit_type_is_rocket()
	return p(c, unit_get_type(obj))
}

// lambda$unitIsStrategicBomber$17 — u -> unitTypeIsStrategicBomber().test(u.getType())
matches_lambda_unit_is_strategic_bomber_17 :: proc(u: ^Unit) -> bool {
	p, c := matches_unit_type_is_strategic_bomber()
	return p(c, unit_get_type(u))
}

// lambda$unitIsSupporterOrHasCombatAbility$45 —
//   u -> unitTypeIsSupporterOrHasCombatAbility(attack, u.getOwner()).test(u.getType())
matches_lambda_unit_is_supporter_or_has_combat_ability_45 :: proc(
	attack: bool,
	u: ^Unit,
) -> bool {
	p, c := matches_unit_type_is_supporter_or_has_combat_ability(attack, unit_get_owner(u))
	return p(c, unit_get_type(u))
}

// lambda$unitSupportAttachmentCanBeUsedByPlayer$47 —
//   usa -> usa.getPlayers().contains(player)
matches_lambda_unit_support_attachment_can_be_used_by_player_47 :: proc(
	player: ^Game_Player,
	usa: ^Unit_Support_Attachment,
) -> bool {
	for p in unit_support_attachment_get_players(usa) {
		if p == player {
			return true
		}
	}
	return false
}

// lambda$unitTypeIsStatic$127 —
//   unitType -> !unitTypeCanMove(gamePlayer).test(unitType)
matches_lambda_unit_type_is_static_127 :: proc(
	game_player: ^Game_Player,
	unit_type: ^Unit_Type,
) -> bool {
	p, c := matches_unit_type_can_move(game_player)
	return !p(c, unit_type)
}

// lambda$unitWasUnloadedThisTurn$68 — u -> u.getUnloadedTo() != null
matches_lambda_unit_was_unloaded_this_turn_68 :: proc(u: ^Unit) -> bool {
	return unit_get_unloaded_to(u) != nil
}

// =====================================================================
// Static factories at method_layer 1.
// =====================================================================

// battleIsAmphibiousWithUnitsAttackingFrom(Territory)
//   battleIsAmphibious().and(b -> instanceof DependentBattle && contains(from))
Matches_Ctx_battle_is_amphibious_with_units_attacking_from :: struct {
	from: ^Territory,
}

matches_pred_battle_is_amphibious_with_units_attacking_from :: proc(
	ctx_ptr: rawptr,
	b: ^I_Battle,
) -> bool {
	c := cast(^Matches_Ctx_battle_is_amphibious_with_units_attacking_from)ctx_ptr
	if !i_battle_is_amphibious(b) {
		return false
	}
	return matches_lambda_battle_is_amphibious_with_units_attacking_from_122(c.from, b)
}

matches_battle_is_amphibious_with_units_attacking_from :: proc(
	from: ^Territory,
) -> (proc(rawptr, ^I_Battle) -> bool, rawptr) {
	ctx := new(Matches_Ctx_battle_is_amphibious_with_units_attacking_from)
	ctx.from = from
	return matches_pred_battle_is_amphibious_with_units_attacking_from, rawptr(ctx)
}

// territoryIsLand() — territoryIsWater().negate()
matches_pred_territory_is_land :: proc(_: rawptr, t: ^Territory) -> bool {
	return !territory_is_water(t)
}

matches_territory_is_land :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_land, nil
}

// territoryIsNeutralButNotWater() —
//   isTerritoryNeutral().and(territoryIsWater().negate())
matches_pred_territory_is_neutral_but_not_water :: proc(_: rawptr, t: ^Territory) -> bool {
	if territory_is_water(t) {
		return false
	}
	return matches_lambda_is_territory_neutral_134(t)
}

matches_territory_is_neutral_but_not_water :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_neutral_but_not_water, nil
}

// territoryIsNotImpassable() — territoryIsImpassable().negate()
matches_pred_territory_is_not_impassable :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	p, c := matches_territory_is_impassable()
	return !p(c, t)
}

matches_territory_is_not_impassable :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_not_impassable, nil
}

// territoryIsUnownedWater() — isTerritoryNeutral().and(territoryIsWater())
matches_pred_territory_is_unowned_water :: proc(_: rawptr, t: ^Territory) -> bool {
	if !territory_is_water(t) {
		return false
	}
	return matches_lambda_is_territory_neutral_134(t)
}

matches_territory_is_unowned_water :: proc() -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	return matches_pred_territory_is_unowned_water, nil
}

// unitIsLand() — unitIsNotSea().and(unitIsNotAir())
matches_pred_unit_is_land :: proc(_: rawptr, u: ^Unit) -> bool {
	ua := unit_get_unit_attachment(u)
	return !unit_attachment_is_sea(ua) && !unit_attachment_is_air(ua)
}

matches_unit_is_land :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_land, nil
}

// unitTypeIsLand() — unitTypeIsNotSea().and(unitTypeIsNotAir())
matches_pred_unit_type_is_land :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	ua := unit_type_get_unit_attachment(ut)
	return !unit_attachment_is_sea(ua) && !unit_attachment_is_air(ua)
}

matches_unit_type_is_land :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_land, nil
}

// unitIsNotCombatSeaTransport() — unitIsCombatSeaTransport().negate()
matches_pred_unit_is_not_combat_sea_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_combat_sea_transport()
	return !p(c, u)
}

matches_unit_is_not_combat_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_combat_sea_transport, nil
}

// unitIsNotConstruction() — unitIsConstruction().negate()
matches_pred_unit_is_not_construction :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_construction()
	return !p(c, u)
}

matches_unit_is_not_construction :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_construction, nil
}

// unitIsNotDisabled() — unitIsDisabled().negate()
matches_pred_unit_is_not_disabled :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_disabled()
	return !p(c, u)
}

matches_unit_is_not_disabled :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_disabled, nil
}

// unitIsNotInfrastructure() — unitIsInfrastructure().negate()
matches_pred_unit_is_not_infrastructure :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_infrastructure()
	return !p(c, u)
}

matches_unit_is_not_infrastructure :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_infrastructure, nil
}

// unitIsNotSeaTransport() — unitIsSeaTransport().negate()
matches_pred_unit_is_not_sea_transport :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_sea_transport()
	return !p(c, u)
}

matches_unit_is_not_sea_transport :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_sea_transport, nil
}

// unitHasNotMoved() — unitHasMoved().negate()
matches_pred_unit_has_not_moved :: proc(_: rawptr, u: ^Unit) -> bool {
	return !unit_has_moved(u)
}

matches_unit_has_not_moved :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_not_moved, nil
}

// unitHasNotTakenAnyBombingUnitDamage() — unitHasTakenSomeBombingUnitDamage().negate()
matches_pred_unit_has_not_taken_any_bombing_unit_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_unit_damage(u) <= 0
}

matches_unit_has_not_taken_any_bombing_unit_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_not_taken_any_bombing_unit_damage, nil
}

// unitHasNotTakenAnyDamage() — unitHasTakenSomeDamage().negate()
matches_pred_unit_has_not_taken_any_damage :: proc(_: rawptr, u: ^Unit) -> bool {
	return unit_get_hits(u) <= 0
}

matches_unit_has_not_taken_any_damage :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_not_taken_any_damage, nil
}

// unitWasNotAmphibious() — unitWasAmphibious().negate()
matches_pred_unit_was_not_amphibious :: proc(_: rawptr, u: ^Unit) -> bool {
	return !unit_get_was_amphibious(u)
}

matches_unit_was_not_amphibious :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_was_not_amphibious, nil
}

// unitHasSubBattleAbilities() —
//   unitCanEvade().or(unitIsFirstStrike()).or(unitCanNotBeTargetedByAll())
matches_pred_unit_has_sub_battle_abilities :: proc(_: rawptr, u: ^Unit) -> bool {
	ep, ec := matches_unit_can_evade()
	if ep(ec, u) {
		return true
	}
	fp, fc := matches_unit_is_first_strike()
	if fp(fc, u) {
		return true
	}
	tp, tc := matches_unit_can_not_be_targeted_by_all()
	return tp(tc, u)
}

matches_unit_has_sub_battle_abilities :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_has_sub_battle_abilities, nil
}

// unitCanProduceUnitsAndCanBeDamaged() — unitCanProduceUnits().and(unitCanBeDamaged())
matches_pred_unit_can_produce_units_and_can_be_damaged :: proc(_: rawptr, u: ^Unit) -> bool {
	cp, cc := matches_unit_can_produce_units()
	if !cp(cc, u) {
		return false
	}
	dp, dc := matches_unit_can_be_damaged()
	return dp(dc, u)
}

matches_unit_can_produce_units_and_can_be_damaged :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_produce_units_and_can_be_damaged, nil
}

// unitCanProduceUnitsAndIsInfrastructure() — unitCanProduceUnits().and(unitIsInfrastructure())
matches_pred_unit_can_produce_units_and_is_infrastructure :: proc(_: rawptr, u: ^Unit) -> bool {
	cp, cc := matches_unit_can_produce_units()
	if !cp(cc, u) {
		return false
	}
	ip, ic := matches_unit_is_infrastructure()
	return ip(ic, u)
}

matches_unit_can_produce_units_and_is_infrastructure :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_can_produce_units_and_is_infrastructure, nil
}

// unitDestroyedWhenCapturedByOrFrom(GamePlayer) —
//   unitDestroyedWhenCapturedBy(playerBy).or(unitDestroyedWhenCapturedFrom())
Matches_Ctx_unit_destroyed_when_captured_by_or_from :: struct {
	player_by: ^Game_Player,
}

matches_pred_unit_destroyed_when_captured_by_or_from :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_destroyed_when_captured_by_or_from)ctx_ptr
	bp, bc := matches_unit_destroyed_when_captured_by(c.player_by)
	if bp(bc, u) {
		return true
	}
	fp, fc := matches_unit_destroyed_when_captured_from()
	return fp(fc, u)
}

matches_unit_destroyed_when_captured_by_or_from :: proc(
	player_by: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_destroyed_when_captured_by_or_from)
	ctx.player_by = player_by
	return matches_pred_unit_destroyed_when_captured_by_or_from, rawptr(ctx)
}

// unitIsEnemyAaForFlyOver(GamePlayer)  [package-private] —
//   unitIsAaForFlyOverOnly().and(enemyUnit(player))
Matches_Ctx_unit_is_enemy_aa_for_fly_over :: struct {
	player: ^Game_Player,
}

matches_pred_unit_is_enemy_aa_for_fly_over :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_enemy_aa_for_fly_over)ctx_ptr
	fp, fc := matches_unit_is_aa_for_fly_over_only()
	if !fp(fc, u) {
		return false
	}
	ep, ec := matches_enemy_unit(c.player)
	return ep(ec, u)
}

matches_unit_is_enemy_aa_for_fly_over :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_enemy_aa_for_fly_over)
	ctx.player = player
	return matches_pred_unit_is_enemy_aa_for_fly_over, rawptr(ctx)
}

// unitHasWhenCombatDamagedEffect(String filterForEffect) —
//   unitHasWhenCombatDamagedEffect().and(unit -> { for whenCombatDamaged matching effect/range: true; else false })
Matches_Ctx_unit_has_when_combat_damaged_effect_filter :: struct {
	filter_for_effect: string,
}

matches_pred_unit_has_when_combat_damaged_effect_filter :: proc(
	ctx_ptr: rawptr,
	unit: ^Unit,
) -> bool {
	c := cast(^Matches_Ctx_unit_has_when_combat_damaged_effect_filter)ctx_ptr
	hp, hc := matches_unit_has_when_combat_damaged_effect()
	if !hp(hc, unit) {
		return false
	}
	current_damage := unit_get_hits(unit)
	for key in unit_attachment_get_when_combat_damaged(unit_get_unit_attachment(unit)) {
		if unit_attachment_when_combat_damaged_get_effect(key) != c.filter_for_effect {
			continue
		}
		dmin := unit_attachment_when_combat_damaged_get_damage_min(key)
		dmax := unit_attachment_when_combat_damaged_get_damage_max(key)
		if current_damage >= dmin && current_damage <= dmax {
			return true
		}
	}
	return false
}

matches_unit_has_when_combat_damaged_effect_filter :: proc(
	filter_for_effect: string,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_has_when_combat_damaged_effect_filter)
	ctx.filter_for_effect = filter_for_effect
	return matches_pred_unit_has_when_combat_damaged_effect_filter, rawptr(ctx)
}

// unitIsAaThatCanFire(Collection<Unit>, Map<String, Set<UnitType>>, GamePlayer,
//                     Predicate<Unit>, int, boolean)
Matches_Ctx_unit_is_aa_that_can_fire :: struct {
	units_moving_or_attacking:        [dynamic]^Unit,
	airborne_tech_targets_allowed:    map[string]map[^Unit_Type]struct {},
	player_moving_or_attacking:       ^Game_Player,
	type_of_aa:                       proc(rawptr, ^Unit) -> bool,
	type_of_aa_ctx:                   rawptr,
	battle_round_number:              i32,
	defending:                        bool,
}

matches_pred_unit_is_aa_that_can_fire :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_aa_that_can_fire)ctx_ptr
	ep, ec := matches_enemy_unit(c.player_moving_or_attacking)
	if !ep(ec, u) {
		return false
	}
	bp, bc := matches_unit_is_being_transported()
	if bp(bc, u) {
		return false
	}
	hp, hc := matches_unit_is_aa_that_can_hit_these_units(
		c.units_moving_or_attacking,
		c.type_of_aa,
		c.type_of_aa_ctx,
		c.airborne_tech_targets_allowed,
	)
	if !hp(hc, u) {
		return false
	}
	wp, wc := matches_unit_is_aa_that_will_not_fire_if_present_enemy_units(c.units_moving_or_attacking)
	if wp(wc, u) {
		return false
	}
	rp, rc := matches_unit_is_aa_that_can_fire_on_round(c.battle_round_number)
	if !rp(rc, u) {
		return false
	}
	if c.defending {
		ap, ac := matches_unit_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero()
		return ap(ac, u)
	}
	op, oc := matches_unit_offensive_attack_aa_is_greater_than_zero_and_max_aa_attacks_is_not_zero()
	return op(oc, u)
}

matches_unit_is_aa_that_can_fire :: proc(
	units_moving_or_attacking: [dynamic]^Unit,
	airborne_tech_targets_allowed: map[string]map[^Unit_Type]struct {},
	player_moving_or_attacking: ^Game_Player,
	type_of_aa: proc(rawptr, ^Unit) -> bool,
	type_of_aa_ctx: rawptr,
	battle_round_number: i32,
	defending: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_aa_that_can_fire)
	ctx.units_moving_or_attacking = units_moving_or_attacking
	ctx.airborne_tech_targets_allowed = airborne_tech_targets_allowed
	ctx.player_moving_or_attacking = player_moving_or_attacking
	ctx.type_of_aa = type_of_aa
	ctx.type_of_aa_ctx = type_of_aa_ctx
	ctx.battle_round_number = battle_round_number
	ctx.defending = defending
	return matches_pred_unit_is_aa_that_can_fire, rawptr(ctx)
}

// unitCanBeInBattle(boolean attack, boolean isLandBattle, int battleRound,
//                   boolean doNotIncludeBombardingSeaUnits,
//                   Collection<UnitType> firingUnits)
//   = unitCanBeInBattle(attack, isLandBattle, battleRound, true,
//                       doNotIncludeBombardingSeaUnits, firingUnits)
matches_unit_can_be_in_battle_with_firing_units :: proc(
	attack: bool,
	is_land_battle: bool,
	battle_round: i32,
	do_not_include_bombarding_sea_units: bool,
	firing_units: [dynamic]^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_unit_can_be_in_battle(
		attack,
		is_land_battle,
		battle_round,
		true,
		do_not_include_bombarding_sea_units,
		firing_units,
	)
}

// unitCanParticipateInCombat(boolean attack, GamePlayer attacker,
//                            Territory battleSite, int battleRound,
//                            Collection<Unit> enemyUnits)
Matches_Ctx_unit_can_participate_in_combat :: struct {
	attack:           bool,
	attacker:         ^Game_Player,
	battle_site:      ^Territory,
	battle_round:     i32,
	enemy_unit_types: [dynamic]^Unit_Type,
}

matches_pred_unit_can_participate_in_combat :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_can_participate_in_combat)ctx_ptr
	land_battle := !territory_is_water(c.battle_site)
	if !land_battle {
		lp, lc := matches_unit_is_land()
		if lp(lc, u) {
			return false
		}
	}
	bp, bc := matches_unit_can_be_in_battle_with_firing_units(
		c.attack,
		land_battle,
		c.battle_round,
		false,
		c.enemy_unit_types,
	)
	if !bp(bc, u) {
		return false
	}
	cp, cc := matches_unit_can_be_captured_on_entering_this_territory(c.attacker, c.battle_site)
	if cp(cc, u) {
		return false
	}
	tp, tc := matches_unit_is_being_transported()
	ap, ac := matches_unit_is_air()
	clp, clc := matches_unit_can_land_on_carrier()
	if tp(tc, u) && ap(ac, u) && clp(clc, u) {
		return false
	}
	wp, wc := matches_unit_was_in_air_battle()
	return !wp(wc, u)
}

matches_unit_can_participate_in_combat :: proc(
	attack: bool,
	attacker: ^Game_Player,
	battle_site: ^Territory,
	battle_round: i32,
	enemy_units: [dynamic]^Unit,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_can_participate_in_combat)
	ctx.attack = attack
	ctx.attacker = attacker
	ctx.battle_site = battle_site
	ctx.battle_round = battle_round
	// UnitUtils.getUnitTypesFromUnitList(enemyUnits) — distinct unit types
	seen: map[^Unit_Type]struct {}
	defer delete(seen)
	for u in enemy_units {
		ut := unit_get_type(u)
		if _, ok := seen[ut]; ok {
			continue
		}
		seen[ut] = struct {}{}
		append(&ctx.enemy_unit_types, ut)
	}
	return matches_pred_unit_can_participate_in_combat, rawptr(ctx)
}


// =====================================================================
// games.strategy.triplea.delegate.Matches — chunk 4 / 4.
// Static helpers and lambda bodies missing from earlier chunks.
// Forward references to other matches_* / unit_* / territory_* helpers
// resolve at package scope.
// =====================================================================

// eligibleUnitToConsume(GamePlayer owner, UnitType ut)
//   = unitIsOwnedBy(owner)
//       .and(unitIsOfType(ut))
//       .and(unitHasNotTakenAnyBombingUnitDamage())
//       .and(unitHasNotTakenAnyDamage())
//       .and(unitIsNotDisabled())
Matches_Ctx_eligible_unit_to_consume :: struct {
	owner: ^Game_Player,
	ut:    ^Unit_Type,
}

matches_pred_eligible_unit_to_consume :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_eligible_unit_to_consume)ctx_ptr
	if !unit_is_owned_by(u, c.owner) {
		return false
	}
	if unit_get_type(u) != c.ut {
		return false
	}
	bp, bc := matches_unit_has_not_taken_any_bombing_unit_damage()
	if !bp(bc, u) {
		return false
	}
	dp, dc := matches_unit_has_not_taken_any_damage()
	if !dp(dc, u) {
		return false
	}
	np, nc := matches_unit_is_not_disabled()
	return np(nc, u)
}

matches_eligible_unit_to_consume :: proc(
	owner: ^Game_Player,
	ut: ^Unit_Type,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_eligible_unit_to_consume)
	ctx.owner = owner
	ctx.ut = ut
	return matches_pred_eligible_unit_to_consume, rawptr(ctx)
}

// alliedUnitOfAnyOfThesePlayers(Collection<GamePlayer> players)
//   unit ->
//     unitIsOwnedByAnyOf(players).test(unit)
//       || unit.getOwner().isAlliedWithAnyOfThesePlayers(players)
// (lambda$alliedUnitOfAnyOfThesePlayers$149)
Matches_Ctx_allied_unit_of_any_of_these_players :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_allied_unit_of_any_of_these_players :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_allied_unit_of_any_of_these_players)ctx_ptr
	owner := unit_get_owner(unit)
	for p in c.players {
		if p == owner {
			return true
		}
	}
	return game_player_is_allied_with_any_of_these_players(owner, c.players)
}

matches_allied_unit_of_any_of_these_players :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_allied_unit_of_any_of_these_players)
	ctx.players = players
	return matches_pred_allied_unit_of_any_of_these_players, rawptr(ctx)
}

// enemyUnitOfAnyOfThesePlayers(Collection<GamePlayer> players)
//   unit -> unit.getOwner().isAtWarWithAnyOfThesePlayers(players)
// (lambda$enemyUnitOfAnyOfThesePlayers$147)
Matches_Ctx_enemy_unit_of_any_of_these_players :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_enemy_unit_of_any_of_these_players :: proc(ctx_ptr: rawptr, unit: ^Unit) -> bool {
	c := cast(^Matches_Ctx_enemy_unit_of_any_of_these_players)ctx_ptr
	return game_player_is_at_war_with_any_of_these_players(unit_get_owner(unit), c.players)
}

matches_enemy_unit_of_any_of_these_players :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_enemy_unit_of_any_of_these_players)
	ctx.players = players
	return matches_pred_enemy_unit_of_any_of_these_players, rawptr(ctx)
}

// isAlliedWithAnyOfThesePlayers(Collection<GamePlayer> players)
//   player2 -> player2.isAlliedWithAnyOfThesePlayers(players)
// (lambda$isAlliedWithAnyOfThesePlayers$208)
Matches_Ctx_is_allied_with_any_of_these_players :: struct {
	players: [dynamic]^Game_Player,
}

matches_pred_is_allied_with_any_of_these_players :: proc(
	ctx_ptr: rawptr,
	player2: ^Game_Player,
) -> bool {
	c := cast(^Matches_Ctx_is_allied_with_any_of_these_players)ctx_ptr
	return game_player_is_allied_with_any_of_these_players(player2, c.players)
}

matches_is_allied_with_any_of_these_players :: proc(
	players: [dynamic]^Game_Player,
) -> (proc(rawptr, ^Game_Player) -> bool, rawptr) {
	ctx := new(Matches_Ctx_is_allied_with_any_of_these_players)
	ctx.players = players
	return matches_pred_is_allied_with_any_of_these_players, rawptr(ctx)
}

// territoryHasEnemyLandUnits(GamePlayer player)
//   t -> t.anyUnitsMatch(enemyUnit(player).and(unitIsLand()))
// (lambda$territoryHasEnemyLandUnits$158)
Matches_Ctx_territory_has_enemy_land_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_enemy_land_units :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_enemy_land_units)ctx_ptr
	ep, ec := matches_enemy_unit(c.player)
	lp, lc := matches_unit_is_land()
	for u in t.unit_collection.units {
		if ep(ec, u) && lp(lc, u) {
			return true
		}
	}
	return false
}

matches_territory_has_enemy_land_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_enemy_land_units)
	ctx.player = player
	return matches_pred_territory_has_enemy_land_units, rawptr(ctx)
}

// territoryHasLandUnitsOwnedBy(GamePlayer player)
//   t -> t.anyUnitsMatch(unitIsOwnedBy(player).and(unitIsLand()))
// (lambda$territoryHasLandUnitsOwnedBy$151)
Matches_Ctx_territory_has_land_units_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_land_units_owned_by :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Matches_Ctx_territory_has_land_units_owned_by)ctx_ptr
	op, oc := matches_unit_is_owned_by(c.player)
	lp, lc := matches_unit_is_land()
	for u in t.unit_collection.units {
		if op(oc, u) && lp(lc, u) {
			return true
		}
	}
	return false
}

matches_territory_has_land_units_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_land_units_owned_by)
	ctx.player = player
	return matches_pred_territory_has_land_units_owned_by, rawptr(ctx)
}

// territoryHasOwnedIsFactoryOrCanProduceUnits(GamePlayer player)
//   t -> t.anyUnitsMatch(unitIsOwnedAndIsFactoryOrCanProduceUnits(player))
// (lambda$territoryHasOwnedIsFactoryOrCanProduceUnits$109)
Matches_Ctx_territory_has_owned_is_factory_or_can_produce_units :: struct {
	player: ^Game_Player,
}

matches_pred_territory_has_owned_is_factory_or_can_produce_units :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_has_owned_is_factory_or_can_produce_units)ctx_ptr
	p, pc := matches_unit_is_owned_and_is_factory_or_can_produce_units(c.player)
	for u in t.unit_collection.units {
		if p(pc, u) {
			return true
		}
	}
	return false
}

matches_territory_has_owned_is_factory_or_can_produce_units :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_has_owned_is_factory_or_can_produce_units)
	ctx.player = player
	return matches_pred_territory_has_owned_is_factory_or_can_produce_units, rawptr(ctx)
}

// unitTypeHasMaxBuildRestrictions()
//   ut -> ut.getUnitAttachment().getMaxBuiltPerPlayer() >= 0
// (lambda$unitTypeHasMaxBuildRestrictions$72)
matches_pred_unit_type_has_max_build_restrictions :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	return unit_attachment_get_max_built_per_player(unit_type_get_unit_attachment(ut)) >= 0
}

matches_unit_type_has_max_build_restrictions :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_has_max_build_restrictions, nil
}

// unitTypeIsSeaOrAir()
//   = unitTypeIsSea().or(unitTypeIsAir())
// (lambda$unitTypeIsSeaOrAir$27)
matches_pred_unit_type_is_sea_or_air :: proc(_: rawptr, ut: ^Unit_Type) -> bool {
	ua := unit_type_get_unit_attachment(ut)
	return unit_attachment_is_sea(ua) || unit_attachment_is_air(ua)
}

matches_unit_type_is_sea_or_air :: proc() -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	return matches_pred_unit_type_is_sea_or_air, nil
}

// territoryNotImpassibleOrRestrictedOrNeutralWaterAndNotOwnedBy(GamePlayer player)
//   = not(isTerritoryOwnedBy(player))
//       .and(not(territoryIsUnownedWater()))
//       .and(territoryIsPassableAndNotRestricted(player))
Matches_Ctx_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by :: struct {
	player: ^Game_Player,
}

matches_pred_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^Matches_Ctx_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by)ctx_ptr
	op, oc := matches_is_territory_owned_by(c.player)
	if op(oc, t) {
		return false
	}
	uwp, uwc := matches_territory_is_unowned_water()
	if uwp(uwc, t) {
		return false
	}
	pp, pc := matches_territory_is_passable_and_not_restricted(c.player)
	return pp(pc, t)
}

matches_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Territory) -> bool, rawptr) {
	ctx := new(Matches_Ctx_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by)
	ctx.player = player
	return matches_pred_territory_not_impassible_or_restricted_or_neutral_water_and_not_owned_by, rawptr(ctx)
}

// unitIsNotLand() — Predicate<Unit>: unitIsLand().negate()
matches_pred_unit_is_not_land :: proc(_: rawptr, u: ^Unit) -> bool {
	p, c := matches_unit_is_land()
	return !p(c, u)
}

matches_unit_is_not_land :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_pred_unit_is_not_land, nil
}

// unitIsActiveInTerritory(Territory battleSite)
//   = unitIsSubmerged().negate()
//       .and(territoryIsLand().test(battleSite)
//                ? unitIsSea().negate()
//                : unitIsLand().negate())
Matches_Ctx_unit_is_active_in_territory :: struct {
	battle_site_is_land: bool,
}

matches_pred_unit_is_active_in_territory :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Matches_Ctx_unit_is_active_in_territory)ctx_ptr
	sp, sc := matches_unit_is_submerged()
	if sp(sc, u) {
		return false
	}
	if c.battle_site_is_land {
		seap, seac := matches_unit_is_sea()
		return !seap(seac, u)
	}
	lp, lc := matches_unit_is_land()
	return !lp(lc, u)
}

matches_unit_is_active_in_territory :: proc(
	battle_site: ^Territory,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_is_active_in_territory)
	ctx.battle_site_is_land = !territory_is_water(battle_site)
	return matches_pred_unit_is_active_in_territory, rawptr(ctx)
}

// unitTypeCanBeHitByAaFire(Collection<UnitType> firingUnits,
//                          UnitTypeList unitTypeList,
//                          int battleRound)
//   final Collection<UnitType> aaFiringUnits =
//       CollectionUtils.getMatches(
//           firingUnits,
//           unitTypeIsAaForCombatOnly().and(unitTypeIsAaThatCanFireOnRound(battleRound)));
//   return unitType ->
//       aaFiringUnits.stream()
//           .anyMatch(ut -> ut.getUnitAttachment().getTargetsAa(unitTypeList).contains(unitType));
Matches_Ctx_unit_type_can_be_hit_by_aa_fire :: struct {
	aa_firing_units: [dynamic]^Unit_Type,
	unit_type_list:  ^Unit_Type_List,
}

matches_pred_unit_type_can_be_hit_by_aa_fire :: proc(ctx_ptr: rawptr, ut: ^Unit_Type) -> bool {
	c := cast(^Matches_Ctx_unit_type_can_be_hit_by_aa_fire)ctx_ptr
	return matches_lambda_unit_type_can_be_hit_by_aa_fire_79(c.aa_firing_units, c.unit_type_list, ut)
}

matches_unit_type_can_be_hit_by_aa_fire :: proc(
	firing_units: [dynamic]^Unit_Type,
	unit_type_list: ^Unit_Type_List,
	battle_round: i32,
) -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_type_can_be_hit_by_aa_fire)
	ctx.unit_type_list = unit_type_list
	combat_p, combat_c := matches_unit_type_is_aa_for_combat_only()
	round_p, round_c := matches_unit_type_is_aa_that_can_fire_on_round(battle_round)
	for ft in firing_units {
		if combat_p(combat_c, ft) && round_p(round_c, ft) {
			append(&ctx.aa_firing_units, ft)
		}
	}
	return matches_pred_unit_type_can_be_hit_by_aa_fire, rawptr(ctx)
}

// unitTypeCanBeInBattle(boolean attack, boolean isLandBattle, GamePlayer player,
//                       int battleRound, boolean includeAttackersThatCanNotMove,
//                       boolean doNotIncludeBombardingSeaUnits,
//                       Collection<UnitType> firingUnits)
Matches_Ctx_unit_type_can_be_in_battle :: struct {
	attack:                              bool,
	is_land_battle:                      bool,
	player:                              ^Game_Player,
	battle_round:                        i32,
	include_attackers_that_can_not_move: bool,
	do_not_include_bombarding_sea_units: bool,
	firing_units:                        [dynamic]^Unit_Type,
}

matches_pred_unit_type_can_be_in_battle :: proc(ctx_ptr: rawptr, ut: ^Unit_Type) -> bool {
	c := cast(^Matches_Ctx_unit_type_can_be_in_battle)ctx_ptr

	// PredicateBuilder.of(...).or(...).or(...).or(...): at least one
	// of the four base clauses must hold.
	any_ok := false
	{
		ip, ic := matches_unit_type_is_infrastructure()
		if !ip(ic, ut) {
			any_ok = true
		}
	}
	if !any_ok {
		sp, sc := matches_unit_type_is_supporter_or_has_combat_ability(c.attack, c.player)
		if sp(sc, ut) {
			any_ok = true
		}
	}
	if !any_ok {
		ap, ac := matches_unit_type_is_aa_for_combat_only()
		rp, rc := matches_unit_type_is_aa_that_can_fire_on_round(c.battle_round)
		if ap(ac, ut) && rp(rc, ut) {
			any_ok = true
		}
	}
	if !any_ok {
		hp, hc := matches_unit_type_can_be_hit_by_aa_fire(
			c.firing_units,
			game_data_get_unit_type_list(game_data_component_get_data(&ut.game_data_component)),
			c.battle_round,
		)
		if hp(hc, ut) {
			any_ok = true
		}
	}
	if !any_ok {
		return false
	}

	if c.attack {
		if !c.include_attackers_that_can_not_move {
			cnp, cnc := matches_unit_type_can_not_move_during_combat_move()
			if cnp(cnc, ut) {
				return false
			}
			mp, mc := matches_unit_type_can_move(c.player)
			if !mp(mc, ut) {
				return false
			}
		}
		if c.is_land_battle {
			if c.do_not_include_bombarding_sea_units {
				sp, sc := matches_unit_type_is_sea()
				if sp(sc, ut) {
					return false
				}
			}
		} else {
			lp, lc := matches_unit_type_is_land()
			if lp(lc, ut) {
				return false
			}
		}
	} else {
		if c.is_land_battle {
			sp, sc := matches_unit_type_is_sea()
			if sp(sc, ut) {
				return false
			}
		} else {
			lp, lc := matches_unit_type_is_land()
			if lp(lc, ut) {
				return false
			}
		}
	}
	return true
}

matches_unit_type_can_be_in_battle :: proc(
	attack: bool,
	is_land_battle: bool,
	player: ^Game_Player,
	battle_round: i32,
	include_attackers_that_can_not_move: bool,
	do_not_include_bombarding_sea_units: bool,
	firing_units: [dynamic]^Unit_Type,
) -> (proc(rawptr, ^Unit_Type) -> bool, rawptr) {
	ctx := new(Matches_Ctx_unit_type_can_be_in_battle)
	ctx.attack = attack
	ctx.is_land_battle = is_land_battle
	ctx.player = player
	ctx.battle_round = battle_round
	ctx.include_attackers_that_can_not_move = include_attackers_that_can_not_move
	ctx.do_not_include_bombarding_sea_units = do_not_include_bombarding_sea_units
	ctx.firing_units = firing_units
	return matches_pred_unit_type_can_be_in_battle, rawptr(ctx)
}

// unitCanBeInBattle(boolean attack, boolean isLandBattle, int battleRound,
//                   boolean doNotIncludeBombardingSeaUnits)
//   = unitCanBeInBattle(attack, isLandBattle, battleRound,
//                       doNotIncludeBombardingSeaUnits, List.of())
matches_unit_can_be_in_battle_no_firing_units :: proc(
	attack: bool,
	is_land_battle: bool,
	battle_round: i32,
	do_not_include_bombarding_sea_units: bool,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	empty: [dynamic]^Unit_Type
	return matches_unit_can_be_in_battle_with_firing_units(
		attack,
		is_land_battle,
		battle_round,
		do_not_include_bombarding_sea_units,
		empty,
	)
}
