package game

import "core:strings"

Abstract_Place_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	produced:   map[^Territory][dynamic]^Unit,
	placements: [dynamic]^Undoable_Placement,
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getAlreadyProduced(Territory)
// Returns a fresh ArrayList copy of the units produced at `t` this turn,
// or an empty list if `t` has not produced anything.
abstract_place_delegate_get_already_produced :: proc(self: ^Abstract_Place_Delegate, t: ^Territory) -> [dynamic]^Unit {
	already_produced_units := make([dynamic]^Unit)
	if existing, ok := self.produced[t]; ok {
		for u in existing {
			append(&already_produced_units, u)
		}
	}
	return already_produced_units
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getPlacementsMade()
// Java returns `placements.size()`.
abstract_place_delegate_get_placements_made :: proc(self: ^Abstract_Place_Delegate) -> i32 {
	return i32(len(self.placements))
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getRemoteType()
// Java returns `IAbstractPlaceDelegate.class`; Odin mirrors IDelegate#getRemoteType
// and returns the corresponding `typeid`.
abstract_place_delegate_get_remote_type :: proc(self: ^Abstract_Place_Delegate) -> typeid {
	return I_Abstract_Place_Delegate
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getErrorMessageYouDoNotOwn(Territory)
// Java: `return "You don't own " + to.getName();`
abstract_place_delegate_get_error_message_you_do_not_own :: proc(to: ^Territory) -> string {
	return strings.concatenate({"You don't own ", default_named_get_name(&to.named_attachable.default_named)})
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#playerHasEnoughUnits(Collection,GamePlayer)
// Static helper. Returns Optional.of("Not enough units") when the player's
// hand does not contain every requested unit; otherwise Optional.empty().
abstract_place_delegate_player_has_enough_units :: proc(units: [dynamic]^Unit, player: ^Game_Player) -> Maybe(string) {
	if !unit_collection_contains_all(game_player_get_unit_collection(player), units) {
		return "Not enough units"
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$placeUnits$1(Unit)
// Body of `it -> true` passed to CollectionUtils.getNMatches inside placeUnits;
// accepts every unit unconditionally.
abstract_place_delegate_lambda_place_units_1 :: proc(it: ^Unit) -> bool {
	return true
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$getUnitsThatCantBePlacedThatRequireUnits$3(Unit)
// Body of `it -> true` passed to CollectionUtils.getNMatches inside
// getUnitsThatCantBePlacedThatRequireUnits; accepts every unit unconditionally.
abstract_place_delegate_lambda_get_units_that_cant_be_placed_that_require_units_3 :: proc(it: ^Unit) -> bool {
	return true
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$updateUndoablePlacementIndexes$0(int)
// Body of `i -> placements.get(i).setIndex(i)` from updateUndoablePlacementIndexes.
abstract_place_delegate_lambda_update_undoable_placement_indexes_0 :: proc(self: ^Abstract_Place_Delegate, i: i32) {
	placement := self.placements[i]
	abstract_undoable_move_set_index(&placement.abstract_undoable_move, i)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#updateUndoablePlacementIndexes()
// Reassigns the `index` field of every placement to its current list position
// via IntStream.range(0, placements.size()).forEach(i -> placements.get(i).setIndex(i)).
abstract_place_delegate_update_undoable_placement_indexes :: proc(self: ^Abstract_Place_Delegate) {
	n := i32(len(self.placements))
	for i: i32 = 0; i < n; i += 1 {
		abstract_place_delegate_lambda_update_undoable_placement_indexes_0(self, i)
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getUnitConstructionComparator()
// Three-way comparator (Java Comparator<Unit>): construction units sort first.
// Returned as a plain (non-capturing) proc value mirroring Java's static lambda.
abstract_place_delegate_unit_construction_compare :: proc(u1: ^Unit, u2: ^Unit) -> i32 {
	construction_1 := matches_unit_is_construction(u1)
	construction_2 := matches_unit_is_construction(u2)
	if construction_1 == construction_2 {
		return 0
	}
	if construction_1 {
		return -1
	}
	return 1
}

abstract_place_delegate_get_unit_construction_comparator :: proc() -> proc(^Unit, ^Unit) -> i32 {
	return abstract_place_delegate_unit_construction_compare
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getHardestToPlaceWithRequiresUnitsRestrictions()
// Three-way comparator: units that are hardest to place (fewer requiresUnits
// alternatives) come first; constructions then break further ties via the
// construction comparator above. Static, non-capturing.
abstract_place_delegate_hardest_to_place_compare :: proc(u1: ^Unit, u2: ^Unit) -> i32 {
	if u1 == u2 {
		return 0
	}
	ua_1 := unit_get_unit_attachment(u1)
	ua_2 := unit_get_unit_attachment(u2)
	if ua_1 == nil && ua_2 == nil {
		return 0
	}
	if ua_1 != nil && ua_2 == nil {
		return -1
	}
	if ua_1 == nil {
		return 1
	}
	construction_sort := abstract_place_delegate_unit_construction_compare(u1, u2)
	if construction_sort != 0 {
		return construction_sort
	}
	ru_1 := unit_attachment_get_requires_units(ua_1)
	ru_2 := unit_attachment_get_requires_units(ua_2)
	rus_1: i32 = max(i32) if len(ru_1) == 0 else i32(len(ru_1))
	rus_2: i32 = max(i32) if len(ru_2) == 0 else i32(len(ru_2))
	if rus_1 < rus_2 {
		return -1
	}
	if rus_1 > rus_2 {
		return 1
	}
	return 0
}

abstract_place_delegate_get_hardest_to_place_with_requires_units_restrictions :: proc() -> proc(^Unit, ^Unit) -> i32 {
	return abstract_place_delegate_hardest_to_place_compare
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getBestProducerComparator(Territory,Collection,GamePlayer)
// Capturing Comparator<Territory>. The lambda closes over `to`, `units`, `player`,
// and `self` (for getMaxUnitsToBePlacedFrom). Per the rawptr-ctx convention in
// llm-instructions.md, the comparator is returned as `(fn, ctx)`.
Abstract_Place_Delegate_Best_Producer_Comparator_Ctx :: struct {
	self:   ^Abstract_Place_Delegate,
	to:     ^Territory,
	units:  [dynamic]^Unit,
	player: ^Game_Player,
}

abstract_place_delegate_best_producer_compare :: proc(ctx: rawptr, t1: ^Territory, t2: ^Territory) -> i32 {
	c := cast(^Abstract_Place_Delegate_Best_Producer_Comparator_Ctx)ctx
	if t1 == t2 {
		return 0
	}
	// producing-to territory comes first
	if c.to == t1 {
		return -1
	}
	if c.to == t2 {
		return 1
	}
	left_1 := abstract_place_delegate_get_max_units_to_be_placed_from(c.self, t1, c.units, c.to, c.player)
	left_2 := abstract_place_delegate_get_max_units_to_be_placed_from(c.self, t2, c.units, c.to, c.player)
	if left_1 == left_2 {
		return 0
	}
	// production of -1 == infinite
	if left_1 == -1 {
		return -1
	}
	if left_2 == -1 {
		return 1
	}
	if left_1 > left_2 {
		return -1
	}
	return 1
}

abstract_place_delegate_get_best_producer_comparator :: proc(
	self: ^Abstract_Place_Delegate,
	to: ^Territory,
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> (
	proc(rawptr, ^Territory, ^Territory) -> i32,
	rawptr,
) {
	ctx := new(Abstract_Place_Delegate_Best_Producer_Comparator_Ctx)
	ctx.self = self
	ctx.to = to
	ctx.units = units
	ctx.player = player
	return abstract_place_delegate_best_producer_compare, rawptr(ctx)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#unitWhichRequiresUnitsHasRequiredUnits(Territory,boolean)
// Capturing Predicate<Unit>. The lambda closes over `to`, `countNeighbors`, and
// `self` (for unitsAtStartOfStepInTerritory / getAllProducers / self.player).
// Returned as `(fn, ctx)` per the rawptr-ctx convention.
Abstract_Place_Delegate_Unit_Requires_Predicate_Ctx :: struct {
	self:            ^Abstract_Place_Delegate,
	to:              ^Territory,
	count_neighbors: bool,
}

abstract_place_delegate_unit_which_requires_units_has_required_units_test :: proc(ctx: rawptr, unit_which_requires_units: ^Unit) -> bool {
	c := cast(^Abstract_Place_Delegate_Unit_Requires_Predicate_Ctx)ctx
	if !matches_unit_requires_units_on_creation(unit_which_requires_units) {
		return true
	}
	// Do not need to remove unowned here; the in-list match excludes unowned.
	units_at_start_of_turn_in_producer := abstract_place_delegate_units_at_start_of_step_in_territory(c.self, c.to)
	if matches_unit_which_requires_units_has_required_units_in_list(unit_which_requires_units, units_at_start_of_turn_in_producer) {
		return true
	}
	if c.count_neighbors && territory_is_water(c.to) {
		single := make([dynamic]^Unit)
		defer delete(single)
		append(&single, unit_which_requires_units)
		producers := abstract_place_delegate_get_all_producers(c.self, c.to, c.self.player, single, true)
		for current in producers {
			units_at_start_of_turn_in_current := abstract_place_delegate_units_at_start_of_step_in_territory(c.self, current)
			if matches_unit_which_requires_units_has_required_units_in_list(unit_which_requires_units, units_at_start_of_turn_in_current) {
				return true
			}
		}
	}
	return false
}

abstract_place_delegate_unit_which_requires_units_has_required_units :: proc(
	self: ^Abstract_Place_Delegate,
	to: ^Territory,
	count_neighbors: bool,
) -> (
	proc(rawptr, ^Unit) -> bool,
	rawptr,
) {
	ctx := new(Abstract_Place_Delegate_Unit_Requires_Predicate_Ctx)
	ctx.self = self
	ctx.to = to
	ctx.count_neighbors = count_neighbors
	return abstract_place_delegate_unit_which_requires_units_has_required_units_test, rawptr(ctx)
}
