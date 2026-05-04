package game

// games.strategy.triplea.util.UnitSeparator
//
// Utility class with a private constructor and no instance fields.
// All members are static; the Phase A inner classes
// `SeparatorCategories` and its `*Builder` live in their own files.

Unit_Separator :: struct {}

// Lambdas $0..$2 in `getSortedUnitCategories(...)`:
//   `categories.removeIf(uc -> !mapData.shouldDrawUnit(uc.getType().getName()));`
// `MapData.shouldDrawUnit(name)` returns `!undrawnUnits.contains(name)`,
// so `!shouldDrawUnit(name)` is `undrawnUnits.contains(name)`. The lambda
// returns true when the category should be removed (i.e. it's in the
// undrawn set).
unit_separator_lambda_get_sorted_unit_categories_0 :: proc(
	map_data: ^Map_Data,
	uc: ^Unit_Category,
) -> bool {
	if map_data == nil || uc == nil || uc.type == nil {
		return false
	}
	name := default_named_get_name(&uc.type.named_attachable.default_named)
	_, present := map_data.undrawn_units[name]
	return present
}

unit_separator_lambda_get_sorted_unit_categories_1 :: proc(
	map_data: ^Map_Data,
	uc: ^Unit_Category,
) -> bool {
	return unit_separator_lambda_get_sorted_unit_categories_0(map_data, uc)
}

unit_separator_lambda_get_sorted_unit_categories_2 :: proc(
	map_data: ^Map_Data,
	uc: ^Unit_Category,
) -> bool {
	return unit_separator_lambda_get_sorted_unit_categories_0(map_data, uc)
}

// Lambda $3 in `getComparatorUnitCategories(...)`:
//   `(final GamePlayer p) -> !(territory != null && p.equals(territory.getOwner()))`
// Comparator key: `false` (== 0) when `p` is the territory owner so it
// sorts first; `true` (== 1) otherwise.
unit_separator_lambda_get_comparator_unit_categories_3 :: proc(
	territory: ^Territory,
	p: ^Game_Player,
) -> bool {
	return !(territory != nil && p == territory_get_owner(territory))
}

// Lambda $4 in `getComparatorUnitCategories(...)`:
//   `p -> (territory != null && Matches.isAtWar(p).test(territory.getOwner()))`
unit_separator_lambda_get_comparator_unit_categories_4 :: proc(
	territory: ^Territory,
	p: ^Game_Player,
) -> bool {
	if territory == nil {
		return false
	}
	pred, ctx := matches_is_at_war(p)
	return pred(ctx, territory_get_owner(territory))
}

// Lambda $5 in `getComparatorUnitCategories(...)`:
//   `uc -> Matches.unitTypeCanMove(uc.getOwner()).test(uc.getType())`
unit_separator_lambda_get_comparator_unit_categories_5 :: proc(uc: ^Unit_Category) -> bool {
	pred, ctx := matches_unit_type_can_move(unit_category_get_owner(uc))
	return pred(ctx, unit_category_get_type(uc))
}

// Lambda $6 in `getComparatorUnitCategories(...)`:
//   `(final UnitType ut) -> !Matches.unitTypeCanNotMoveDuringCombatMove().test(ut)`
unit_separator_lambda_get_comparator_unit_categories_6 :: proc(ut: ^Unit_Type) -> bool {
	pred, ctx := matches_unit_type_can_not_move_during_combat_move()
	return !pred(ctx, ut)
}

// Lambda $7 in `getComparatorUnitCategories(...)`:
//   `ut -> !Matches.unitTypeIsSea().test(ut)`
unit_separator_lambda_get_comparator_unit_categories_7 :: proc(ut: ^Unit_Type) -> bool {
	pred, ctx := matches_unit_type_is_sea()
	return !pred(ctx, ut)
}

// Lambda $8 in `getComparatorUnitCategories(...)`:
//   `ut -> !(territory != null && territory.isWater() && Matches.unitTypeIsAir().test(ut))`
unit_separator_lambda_get_comparator_unit_categories_8 :: proc(
	territory: ^Territory,
	ut: ^Unit_Type,
) -> bool {
	if territory == nil {
		return true
	}
	if !territory_is_water(territory) {
		return true
	}
	pred, ctx := matches_unit_type_is_air()
	return !pred(ctx, ut)
}

// Lambda $9 in `getComparatorUnitCategories(...)`:
//   `ut -> !Matches.unitTypeIsLand().test(ut)`
unit_separator_lambda_get_comparator_unit_categories_9 :: proc(ut: ^Unit_Type) -> bool {
	pred, ctx := matches_unit_type_is_land()
	return !pred(ctx, ut)
}

// Lambda $10 in `getComparatorUnitCategories(...)`:
//   `uc -> uc.getUnitAttachment().getAttack((currentPlayer == null ? uc.getOwner() : currentPlayer))`
unit_separator_lambda_get_comparator_unit_categories_10 :: proc(
	current_player: ^Game_Player,
	uc: ^Unit_Category,
) -> i32 {
	if uc == nil {
		return 0
	}
	att := unit_category_get_unit_attachment(uc)
	if att == nil {
		return 0
	}
	// `unit_attachment_get_attack` is a plain getter in the Odin port; the
	// player argument from the Java side has no effect on the returned value.
	_ = current_player
	return unit_attachment_get_attack(att)
}

// Predicate used by `categorize(...)`:
//   `unit.getUnitAttachment().isAir() && unit.getUnitAttachment().getHitPoints() > 1`
unit_separator_is_air_with_hit_points_remaining :: proc(unit: ^Unit) -> bool {
	if unit == nil {
		return false
	}
	att := unit_get_unit_attachment(unit)
	if att == nil {
		return false
	}
	return unit_attachment_is_air(att) && unit_attachment_get_hit_points(att) > 1
}

