package game

Move_Validator :: struct {
	data:          ^Game_Data,
	is_non_combat: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.move.validation.MoveValidator

// Java: @AllArgsConstructor MoveValidator(GameData data, boolean isNonCombat).
move_validator_new :: proc(data: ^Game_Data, is_non_combat: bool) -> ^Move_Validator {
	self := new(Move_Validator)
	self.data = data
	self.is_non_combat = is_non_combat
	return self
}

// Java: addToMapping computeIfAbsent mapping function:
//   key -> new ArrayList<>()
// Returns a freshly allocated empty dynamic array of ^Unit (caller owns it).
move_validator_lambda_add_to_mapping_10 :: proc(key: ^Unit) -> [dynamic]^Unit {
	_ = key
	return make([dynamic]^Unit)
}

// Java: getBestRoute fallback predicate `it -> true` over Territory.
move_validator_lambda_get_best_route_11 :: proc(it: ^Territory) -> bool {
	_ = it
	return true
}

// Java: validateAirborneMovements over-capacity slice predicate `it -> true`
// over Unit (passed to CollectionUtils.getNMatches).
move_validator_lambda_validate_airborne_movements_12 :: proc(it: ^Unit) -> bool {
	_ = it
	return true
}

// games.strategy.triplea.delegate.move.validation.MoveValidator#lambda$enemyDestroyerOnPath$9
// Java: (Predicate<Unit> destroyerMatch, Territory t) -> t.anyUnitsMatch(destroyerMatch)
// The captured Predicate<Unit> is carried as a (fn, ctx) pair per the
// rawptr-ctx convention in llm-instructions.md.
Move_Validator_Enemy_Destroyer_On_Path_9_Ctx :: struct {
	destroyer_match:     proc(rawptr, ^Unit) -> bool,
	destroyer_match_ctx: rawptr,
}

move_validator_lambda_enemy_destroyer_on_path_9 :: proc(ctx: rawptr, t: ^Territory) -> bool {
	c := cast(^Move_Validator_Enemy_Destroyer_On_Path_9_Ctx)ctx
	return territory_any_units_match(t, c.destroyer_match, c.destroyer_match_ctx)
}

