package game

import "core:slice"

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
	return unit_attachment_get_attack(att, current_player)
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

// Lambda $11 in `getComparatorUnitCategories(...)`:
//   `uc -> uc.getUnitAttachment().getAttack((currentPlayer == null ? uc.getOwner() : currentPlayer))`
// Captures `currentPlayer`. `unit_attachment_get_attack` in the Odin port
// is a plain getter that does not consult the player argument, but we
// still mirror the Java null-coalescing of the captured player to the
// category owner so the call shape matches.
unit_separator_lambda_get_comparator_unit_categories_11 :: proc(
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
	player := current_player
	if player == nil {
		player = unit_category_get_owner(uc)
	}
	return unit_attachment_get_attack(att, player)
}

// Java:
//   public static Set<UnitCategory> categorize(
//       final Collection<Unit> units, final SeparatorCategories separatorCategories) {
//     final Map<UnitCategory, UnitCategory> categories = new HashMap<>();
//     for (final Unit current : units) { ... }
//     return new TreeSet<>(categories.keySet());
//   }
//
// HashMap<UnitCategory,UnitCategory> uses UnitCategory.equals/hashCode for
// keying; the Odin port does the same lookup with a linear scan keyed off
// `unit_category_equals`. The Java method returns a TreeSet ordered by
// `UnitCategory.compareTo`; the Odin port returns a [dynamic]^Unit_Category
// sorted with `unit_category_compare_to`.
unit_separator_lambda_categorize_sort :: proc(a, b: ^Unit_Category) -> bool {
	return unit_category_compare_to(a, b) < 0
}

// Java:
//   public static Set<UnitCategory> categorize(final Collection<Unit> units) {
//     return categorize(units, SeparatorCategories.builder().build());
//   }
unit_separator_categorize_default :: proc(units: [dynamic]^Unit) -> [dynamic]^Unit_Category {
	defaults := unit_separator_separator_categories_separator_categories_builder_build(
		unit_separator_separator_categories_builder(),
	)
	return unit_separator_categorize_with_options(units, defaults)
}

unit_separator_categorize :: proc {
	unit_separator_categorize_default,
	unit_separator_categorize_with_options,
}

unit_separator_categorize_with_options :: proc(
	units: [dynamic]^Unit,
	separator_categories: ^Unit_Separator_Separator_Categories,
) -> [dynamic]^Unit_Category {
	categories := make([dynamic]^Unit_Category)
	sea_pred, sea_ctx := matches_unit_is_sea_transport()
	dis_pred, dis_ctx := matches_unit_is_disabled()
	for current in units {
		unit_movement: f64 = -1
		if separator_categories.movement ||
		   (separator_categories.transport_movement && sea_pred(sea_ctx, current)) ||
		   (separator_categories.movement_for_air_units_only &&
				   unit_separator_is_air_with_hit_points_remaining(current)) {
			unit_movement = unit_get_movement_left(current)
		}
		unit_transport_cost: i32 = -1
		if separator_categories.transport_cost {
			unit_transport_cost = unit_attachment_get_transport_cost(
				unit_get_unit_attachment(current),
			)
		}
		current_dependents: [dynamic]^Unit
		if separator_categories.dependents != nil {
			if deps, ok := separator_categories.dependents[current]; ok {
				current_dependents = deps
			}
		}
		can_retreat := true
		if separator_categories.retreat_possibility {
			// only time a unit can't retreat is if the unit was amphibious
			can_retreat = !unit_get_was_amphibious(current)
		}
		disabled := dis_pred(dis_ctx, current)
		entry := unit_category_new(
			current,
			current_dependents,
			unit_movement,
			unit_get_hits(current),
			unit_get_unit_damage(current),
			disabled,
			unit_transport_cost,
			can_retreat,
		)
		stored: ^Unit_Category = nil
		for c in categories {
			if unit_category_equals(c, entry) {
				stored = c
				break
			}
		}
		if stored != nil {
			unit_category_add_unit(stored, current)
		} else {
			append(&categories, entry)
		}
	}
	slice.sort_by(categories[:], unit_separator_lambda_categorize_sort)
	return categories
}

