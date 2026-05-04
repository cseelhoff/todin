package game

import "core:fmt"
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

// games.strategy.triplea.delegate.AbstractPlaceDelegate#delegateCurrentlyRequiresUserInput()
// Java: return !(player == null || (player.getUnitCollection().isEmpty() && getPlacementsMade() == 0));
abstract_place_delegate_delegate_currently_requires_user_input :: proc(self: ^Abstract_Place_Delegate) -> bool {
	if self.player == nil {
		return false
	}
	if unit_collection_is_empty(game_player_get_unit_collection(self.player)) &&
	   abstract_place_delegate_get_placements_made(self) == 0 {
		return false
	}
	return true
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#loadState(java.io.Serializable)
// Java casts the state to PlaceExtendedDelegateState, forwards superState to
// super.loadState, then restores produced + placements.
abstract_place_delegate_load_state :: proc(self: ^Abstract_Place_Delegate, state: rawptr) {
	s := cast(^Place_Extended_Delegate_State)state
	base_triple_a_delegate_load_state(&self.base_triple_a_delegate, cast(^Base_Delegate_State)s.super_state)
	self.produced = s.produced
	self.placements = s.placements
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#updateProducedMap(Territory,Collection)
// Java: get the existing produced list, append everything in
// additionallyProducedUnits, then put the merged list back.
abstract_place_delegate_update_produced_map :: proc(
	self: ^Abstract_Place_Delegate,
	producer: ^Territory,
	additionally_produced_units: [dynamic]^Unit,
) {
	new_produced_units := abstract_place_delegate_get_already_produced(self, producer)
	for u in additionally_produced_units {
		append(&new_produced_units, u)
	}
	self.produced[producer] = new_produced_units
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#removeFromProducedMap(Territory,Collection)
// Java semantics mirror Collection.removeAll: drop every element of the
// producer's already-produced list that appears in unitsToRemove. If nothing
// is left, drop the producer's entry; otherwise replace it.
abstract_place_delegate_remove_from_produced_map :: proc(
	self: ^Abstract_Place_Delegate,
	producer: ^Territory,
	units_to_remove: [dynamic]^Unit,
) {
	new_produced_units := abstract_place_delegate_get_already_produced(self, producer)
	for i := len(new_produced_units) - 1; i >= 0; i -= 1 {
		for r in units_to_remove {
			if new_produced_units[i] == r {
				ordered_remove(&new_produced_units, i)
				break
			}
		}
	}
	if len(new_produced_units) == 0 {
		delete(new_produced_units)
		delete_key(&self.produced, producer)
	} else {
		self.produced[producer] = new_produced_units
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getOriginalFactoryOwner(Territory)
// Java throws IllegalStateException when there is no factory; mirrored as panic.
// If `self.player` originally owned any factory, that owner wins; otherwise
// fall back to the original owner of an arbitrary factory.
abstract_place_delegate_get_original_factory_owner :: proc(
	self: ^Abstract_Place_Delegate,
	territory: ^Territory,
) -> ^Game_Player {
	pred, ctx := matches_unit_can_produce_units()
	factory_units: [dynamic]^Unit
	defer delete(factory_units)
	for u in territory.unit_collection.units {
		if pred(ctx, u) {
			append(&factory_units, u)
		}
	}
	if len(factory_units) == 0 {
		panic(fmt.tprintf("No factory in territory: %s", territory_to_string(territory)))
	}
	for factory in factory_units {
		if self.player == unit_get_original_owner(factory) {
			return unit_get_original_owner(factory)
		}
	}
	return unit_get_original_owner(factory_units[0])
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#isPlacementAllowedInCapturedTerritory(GamePlayer)
// Java: ra != null && ra.getPlacementCapturedTerritory().
abstract_place_delegate_is_placement_allowed_in_captured_territory :: proc(player: ^Game_Player) -> bool {
	ra := game_player_get_rules_attachment(player)
	return ra != nil && ra.placement_captured_territory
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#isPlacementInCapitalRestricted(GamePlayer)
// Java: ra != null && ra.getPlacementInCapitalRestricted().
abstract_place_delegate_is_placement_in_capital_restricted :: proc(player: ^Game_Player) -> bool {
	ra := game_player_get_rules_attachment(player)
	return ra != nil && ra.placement_in_capital_restricted
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$getUnitConstructionComparator$5(Unit,Unit)
// Body of the (u1, u2) -> ... lambda inside getUnitConstructionComparator.
// The reusable implementation already lives in
// abstract_place_delegate_unit_construction_compare; this is the canonically
// named lambda entry point referenced by the methods table.
abstract_place_delegate_lambda__get_unit_construction_comparator__5 :: proc(u1: ^Unit, u2: ^Unit) -> i32 {
	return abstract_place_delegate_unit_construction_compare(u1, u2)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#undoMove(int)
// Java:
//   if (moveIndex < placements.size() && moveIndex >= 0) {
//     UndoablePlacement undoPlace = placements.get(moveIndex);
//     undoPlace.undo(bridge);
//     placements.remove(moveIndex);
//     updateUndoablePlacementIndexes();
//   }
//   return null;
abstract_place_delegate_undo_move :: proc(self: ^Abstract_Place_Delegate, move_index: i32) -> Maybe(string) {
        n := i32(len(self.placements))
        if move_index < n && move_index >= 0 {
                undo_place := self.placements[move_index]
                abstract_undoable_move_undo(&undo_place.abstract_undoable_move, self.bridge)
                ordered_remove(&self.placements, int(move_index))
                abstract_place_delegate_update_undoable_placement_indexes(self)
        }
        return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#<init>()
// Java's implicit no-arg constructor. Mirrors the field initializers
// `produced = new HashMap<>()` and `placements = new ArrayList<>()`.
abstract_place_delegate_new :: proc() -> ^Abstract_Place_Delegate {
	self := new(Abstract_Place_Delegate)
	self.produced = make(map[^Territory][dynamic]^Unit)
	self.placements = make([dynamic]^Undoable_Placement)
	return self
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#saveState()
// Java builds a PlaceExtendedDelegateState whose superState is the parent's
// saveState() result, then copies `produced` and `placements` references.
abstract_place_delegate_save_state :: proc(self: ^Abstract_Place_Delegate) -> ^Place_Extended_Delegate_State {
	state := place_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.produced = self.produced
	state.placements = self.placements
	return state
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#howManyOfConstructionUnit(UnitType, IntegerMap<String>)
// Static. Java consults the unit's UnitAttachment: only true constructions with
// positive per-turn / per-territory caps may place; the count is then the
// remaining quota for that construction_type, floored at 0. Java's
// IntegerMap<String> uses value-based string equality, modeled here as a
// `map[string]i32` per the existing convention in pro_purchase_utils.
abstract_place_delegate_how_many_of_construction_unit :: proc(
	ut: ^Unit_Type,
	constructions_map: map[string]i32,
) -> i32 {
	ua := unit_type_get_unit_attachment(ut)
	if !unit_attachment_is_construction(ua) ||
	   unit_attachment_get_constructions_per_terr_per_type_per_turn(ua) < 1 ||
	   unit_attachment_get_max_constructions_per_type_per_terr(ua) < 1 {
		return 0
	}
	val: i32 = 0
	if v, ok := constructions_map[unit_attachment_get_construction_type(ua)]; ok {
		val = v
	}
	if val < 0 {
		return 0
	}
	return val
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$getHardestToPlaceWithRequiresUnitsRestrictions$6(Unit,Unit)
// Synthetic body of the static `(u1, u2) -> { ... }` lambda inside
// getHardestToPlaceWithRequiresUnitsRestrictions(); delegates to the named
// comparator helper that already implements the full ordering rule.
abstract_place_delegate_lambda_get_hardest_to_place_with_requires_units_restrictions_6 :: proc(u1: ^Unit, u2: ^Unit) -> i32 {
	return abstract_place_delegate_hardest_to_place_compare(u1, u2)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#wasConquered(Territory)
// Java: `return getData().getBattleDelegate().getBattleTracker().wasConquered(t);`
abstract_place_delegate_was_conquered :: proc(self: ^Abstract_Place_Delegate, t: ^Territory) -> bool {
	tracker := battle_delegate_get_battle_tracker(game_data_get_battle_delegate(abstract_delegate_get_data(&self.abstract_delegate)))
	return battle_tracker_was_conquered(tracker, t)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#hasUnitPlacementRestrictions()
// Java: `return Properties.getUnitPlacementRestrictions(getProperties());`
abstract_place_delegate_has_unit_placement_restrictions :: proc(self: ^Abstract_Place_Delegate) -> bool {
	return properties_get_unit_placement_restrictions(abstract_delegate_get_properties(&self.abstract_delegate))
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#isPlayerAllowedToPlacementAnyTerritoryOwnedLand(GamePlayer)
// Java:
//   if (Properties.getPlaceInAnyTerritory(getProperties())) {
//     final RulesAttachment ra = player.getRulesAttachment();
//     return ra != null && ra.getPlacementAnyTerritory();
//   }
//   return false;
abstract_place_delegate_is_player_allowed_to_placement_any_territory_owned_land :: proc(
	self:   ^Abstract_Place_Delegate,
	player: ^Game_Player,
) -> bool {
	if properties_get_place_in_any_territory(abstract_delegate_get_properties(&self.abstract_delegate)) {
		ra := game_player_get_rules_attachment(player)
		return ra != nil && ra.placement_any_territory
	}
	return false
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#isPlayerAllowedToPlacementAnySeaZoneByOwnedLand(GamePlayer)
// Java:
//   if (Properties.getPlaceInAnyTerritory(getProperties())) {
//     final RulesAttachment ra = player.getRulesAttachment();
//     return ra != null && ra.getPlacementAnySeaZone();
//   }
//   return false;
abstract_place_delegate_is_player_allowed_to_placement_any_sea_zone_by_owned_land :: proc(
	self:   ^Abstract_Place_Delegate,
	player: ^Game_Player,
) -> bool {
	if properties_get_place_in_any_territory(abstract_delegate_get_properties(&self.abstract_delegate)) {
		ra := game_player_get_rules_attachment(player)
		return ra != nil && ra.placement_any_sea_zone
	}
	return false
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#unitIsCarrierOwnedByCombinedPlayers(GamePlayer)
// Java:
//   final Predicate<Unit> ownedByMatcher =
//       Matches.unitIsOwnedByAnyOf(GameStepPropertiesHelper.getCombinedTurns(getData(), player));
//   return Matches.unitIsCarrier().and(ownedByMatcher);
Abstract_Place_Delegate_Carrier_Owned_By_Combined_Ctx :: struct {
	players: [dynamic]^Game_Player,
}

abstract_place_delegate_pred_unit_is_carrier_owned_by_combined_players :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Abstract_Place_Delegate_Carrier_Owned_By_Combined_Ctx)ctx_ptr
	carrier_p, carrier_c := matches_unit_is_carrier()
	if !carrier_p(carrier_c, u) {
		return false
	}
	owned_p, owned_c := matches_unit_is_owned_by_any_of(c.players)
	return owned_p(owned_c, u)
}

abstract_place_delegate_unit_is_carrier_owned_by_combined_players :: proc(
	self:   ^Abstract_Place_Delegate,
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	combined := game_step_properties_helper_get_combined_turns(abstract_delegate_get_data(&self.abstract_delegate), player)
	players := make([dynamic]^Game_Player)
	for p in combined {
		append(&players, p)
	}
	ctx := new(Abstract_Place_Delegate_Carrier_Owned_By_Combined_Ctx)
	ctx.players = players
	return abstract_place_delegate_pred_unit_is_carrier_owned_by_combined_players, rawptr(ctx)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#unitsAtStartOfStepInTerritory(Territory)
// Java:
//   if (to == null) return new ArrayList<>();
//   final Collection<Unit> unitsPlacedAlready = getAlreadyProduced(to);
//   if (to.isWater()) {
//     for (final Territory current : getAllProducers(to, player, null, true)) {
//       unitsPlacedAlready.addAll(getAlreadyProduced(current));
//     }
//   }
//   final Collection<Unit> unitsAtStartOfTurnInTo = new ArrayList<>(to.getUnits());
//   unitsAtStartOfTurnInTo.removeAll(unitsPlacedAlready);
//   return unitsAtStartOfTurnInTo;
abstract_place_delegate_units_at_start_of_step_in_territory :: proc(
	self: ^Abstract_Place_Delegate,
	to: ^Territory,
) -> [dynamic]^Unit {
	if to == nil {
		return make([dynamic]^Unit)
	}
	units_placed_already := abstract_place_delegate_get_already_produced(self, to)
	if territory_is_water(to) {
		empty_units: [dynamic]^Unit
		producers := abstract_place_delegate_get_all_producers(self, to, self.player, empty_units, true)
		defer delete(producers)
		for current in producers {
			extra := abstract_place_delegate_get_already_produced(self, current)
			for u in extra {
				append(&units_placed_already, u)
			}
			delete(extra)
		}
	}
	result := make([dynamic]^Unit)
	for u in to.unit_collection.units {
		in_placed := false
		for p in units_placed_already {
			if u == p {
				in_placed = true
				break
			}
		}
		if !in_placed {
			append(&result, u)
		}
	}
	delete(units_placed_already)
	return result
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#wasOwnedUnitThatCanProduceUnitsOrIsFactoryInTerritoryAtStartOfStep(Territory,GamePlayer)
// Java: build factoryMatch = unitIsOwnedAndIsFactoryOrCanProduceUnits(player)
//                  .and(unitIsBeingTransported().negate())
//                  .and(to.isWater() ? unitIsLand().negate() : unitIsSea().negate());
//       return unitsAtStartOfStepInTerritory(to).stream().anyMatch(factoryMatch);
abstract_place_delegate_was_owned_unit_that_can_produce_units_or_is_factory_in_territory_at_start_of_step :: proc(
	self: ^Abstract_Place_Delegate,
	to: ^Territory,
	player: ^Game_Player,
) -> bool {
	units_at_start := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start)
	fact_p, fact_c := matches_unit_is_owned_and_is_factory_or_can_produce_units(player)
	trans_p, trans_c := matches_unit_is_being_transported()
	water_to := territory_is_water(to)
	side_p: proc(rawptr, ^Unit) -> bool
	side_c: rawptr
	if water_to {
		side_p, side_c = matches_unit_is_not_land()
	} else {
		side_p, side_c = matches_unit_is_not_sea()
	}
	for u in units_at_start {
		if fact_p(fact_c, u) && !trans_p(trans_c, u) && side_p(side_c, u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#validateNewAirCanLandOnCarriers(Territory,Collection)
// Static. Java:
//   final int cost = AirMovementValidator.carrierCost(units);
//   int capacity = AirMovementValidator.carrierCapacity(units, to);
//   capacity += AirMovementValidator.carrierCapacity(to.getUnits(), to);
//   if (cost > capacity) return Optional.of("Not enough new carriers to land all the fighters");
//   return Optional.empty();
abstract_place_delegate_validate_new_air_can_land_on_carriers :: proc(
	to: ^Territory,
	units: [dynamic]^Unit,
) -> Maybe(string) {
	cost := air_movement_validator_carrier_cost(units[:])
	capacity := air_movement_validator_carrier_capacity(units[:], to)
	capacity += air_movement_validator_carrier_capacity(to.unit_collection.units[:], to)
	if cost > capacity {
		return "Not enough new carriers to land all the fighters"
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#canProduce(Territory,Territory,Collection,GamePlayer,boolean)
// Private 5-arg variant; mirrors the Java method body line-by-line.
abstract_place_delegate_can_produce :: proc(
	self:         ^Abstract_Place_Delegate,
	producer:     ^Territory,
	to:           ^Territory,
	units:        [dynamic]^Unit,
	player:       ^Game_Player,
	simple_check: bool,
) -> Maybe(string) {
	test_units := units
	can_produce_in_conquered := abstract_place_delegate_is_placement_allowed_in_captured_territory(player)
	if !territory_is_owned_by(producer, player) {
		if territory_is_water(producer) {
			sea_p, sea_c := matches_unit_is_sea()
			con_p, con_c := matches_unit_is_construction()
			any_sea_construction := false
			for u in test_units {
				if sea_p(sea_c, u) && con_p(con_c, u) {
					any_sea_construction = true
					break
				}
			}
			if any_sea_construction {
				owned_neighbor := false
				land_p, land_c := matches_territory_is_land()
				neighbors := game_map_get_neighbors_predicate(
					game_data_get_map(abstract_delegate_get_data(&self.abstract_delegate)),
					to,
					land_p,
					land_c,
				)
				for current in neighbors {
					if territory_is_owned_by(current, player) &&
					   (can_produce_in_conquered || !abstract_place_delegate_was_conquered(self, current)) {
						owned_neighbor = true
						break
					}
				}
				if !owned_neighbor {
					return fmt.aprintf(
						"%s is not owned by you, and you have no owned neighbors which can produce",
						territory_to_string(producer),
					)
				}
			} else {
				return fmt.aprintf("%s is not owned by you", territory_to_string(producer))
			}
		} else {
			return fmt.aprintf("%s is not owned by you", territory_to_string(producer))
		}
	}
	if !can_produce_in_conquered && abstract_place_delegate_was_conquered(self, producer) {
		return fmt.aprintf(
			"%s was conquered this turn and cannot produce till next turn",
			territory_to_string(producer),
		)
	}
	if abstract_place_delegate_is_player_allowed_to_placement_any_territory_owned_land(self, player) {
		land_p, land_c := matches_territory_is_land()
		owned_p, owned_c := matches_is_territory_owned_by(player)
		if land_p(land_c, to) && owned_p(owned_c, to) {
			return nil
		}
	}
	if abstract_place_delegate_is_player_allowed_to_placement_any_sea_zone_by_owned_land(self, player) {
		water_p, water_c := matches_territory_is_water()
		owned_p, owned_c := matches_is_territory_owned_by(player)
		if water_p(water_c, to) && owned_p(owned_c, producer) {
			return nil
		}
	}
	if simple_check {
		return nil
	}
	if abstract_place_delegate_has_unit_placement_restrictions(self) && len(test_units) > 0 {
		req_p, req_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, producer, false)
		any_req := false
		for u in test_units {
			if req_p(req_c, u) {
				any_req = true
				break
			}
		}
		if !any_req {
			return fmt.aprintf(
				"You do not have the required units to build in %s",
				territory_to_string(producer),
			)
		}
	}
	if territory_is_water(to) {
		props := abstract_delegate_get_properties(&self.abstract_delegate)
		if !properties_get_ww2_v2(props) && !properties_get_unit_placement_in_enemy_seas(props) {
			enemy_p, enemy_c := matches_enemy_unit(player)
			for u in to.unit_collection.units {
				if enemy_p(enemy_c, u) {
					return "Cannot place sea units with enemy naval units"
				}
			}
		}
	}
	if abstract_place_delegate_was_owned_unit_that_can_produce_units_or_is_factory_in_territory_at_start_of_step(self, producer, player) {
		return nil
	}
	con_p, con_c := matches_unit_is_construction()
	any_construction := false
	for u in test_units {
		if con_p(con_c, u) {
			any_construction = true
			break
		}
	}
	if any_construction {
		constructions_map := abstract_place_delegate_how_many_of_each_construction_can_place(self, to, producer, test_units, player)
		defer delete(constructions_map)
		total: i32 = 0
		for _, v in constructions_map {
			total += v
		}
		if total > 0 {
			return nil
		}
		return fmt.aprintf("No more constructions allowed in %s", territory_to_string(producer))
	}
	cu_p, cu_c := matches_unit_can_produce_units()
	already_in_producer := abstract_place_delegate_get_already_produced(self, producer)
	for u in already_in_producer {
		if cu_p(cu_c, u) {
			delete(already_in_producer)
			return fmt.aprintf(
				"Factory in %s can''t produce until 1 turn after it is created",
				territory_to_string(producer),
			)
		}
	}
	delete(already_in_producer)
	already_in_to := abstract_place_delegate_get_already_produced(self, to)
	for u in already_in_to {
		if cu_p(cu_c, u) {
			delete(already_in_to)
			return fmt.aprintf(
				"Factory in %s can''t produce until 1 turn after it is created",
				territory_to_string(producer),
			)
		}
	}
	delete(already_in_to)
	return fmt.aprintf("No factory in %s", territory_to_string(producer))
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getAllProducers(Territory,GamePlayer,Collection,boolean)
// Private 4-arg variant. The Java code mirrors the body 1:1.
abstract_place_delegate_get_all_producers :: proc(
	self:           ^Abstract_Place_Delegate,
	to:             ^Territory,
	player:         ^Game_Player,
	units_to_place: [dynamic]^Unit,
	simple_check:   bool,
) -> [dynamic]^Territory {
	producers := make([dynamic]^Territory)
	if !territory_is_water(to) {
		if simple_check {
			append(&producers, to)
		} else {
			err := abstract_place_delegate_can_produce(self, to, to, units_to_place, player, false)
			_, has_err := err.?
			if !has_err {
				append(&producers, to)
			}
		}
		return producers
	}
	err_self := abstract_place_delegate_can_produce(self, to, to, units_to_place, player, simple_check)
	_, has_err_self := err_self.?
	if !has_err_self {
		append(&producers, to)
	}
	land_p, land_c := matches_territory_is_land()
	neighbors := game_map_get_neighbors_predicate(
		game_data_get_map(abstract_delegate_get_data(&self.abstract_delegate)),
		to,
		land_p,
		land_c,
	)
	for current in neighbors {
		err_n := abstract_place_delegate_can_produce(self, current, to, units_to_place, player, simple_check)
		_, has := err_n.?
		if !has {
			append(&producers, current)
		}
	}
	return producers
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#howManyOfEachConstructionCanPlace(Territory,Territory,Collection,GamePlayer)
// Translates the Java IntegerMap<String> arithmetic to map[string]i32. Returns
// an empty map (never nil) when no constructions can be placed.
abstract_place_delegate_how_many_of_each_construction_can_place :: proc(
	self:     ^Abstract_Place_Delegate,
	to:       ^Territory,
	producer: ^Territory,
	units:    [dynamic]^Unit,
	player:   ^Game_Player,
) -> map[string]i32 {
	units_allowed := make(map[string]i32)
	if to != producer || len(units) == 0 {
		return units_allowed
	}
	con_p, con_c := matches_unit_is_construction()
	any_con := false
	for u in units {
		if con_p(con_c, u) {
			any_con = true
			break
		}
	}
	if !any_con {
		return units_allowed
	}
	units_at_start_of_turn_in_to := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start_of_turn_in_to)
	units_placed_already := abstract_place_delegate_get_already_produced(self, to)
	defer delete(units_placed_already)

	unit_map_held := make(map[string]i32)
	defer delete(unit_map_held)
	unit_map_max_type := make(map[string]i32)
	defer delete(unit_map_max_type)
	unit_map_type_per_turn := make(map[string]i32)
	defer delete(unit_map_type_per_turn)

	props := abstract_delegate_get_properties(&self.abstract_delegate)
	max_factory := properties_get_factories_per_country(props)
	territory_production: i32 = 0
	if ta := territory_attachment_get(to); ta != nil {
		territory_production = territory_attachment_get_production(ta)
	}

	for current_unit in units {
		if !con_p(con_c, current_unit) {
			continue
		}
		ua := unit_get_unit_attachment(current_unit)
		if abstract_place_delegate_has_unit_placement_restrictions(self) {
			if unit_attachment_unit_placement_restrictions_contain(ua, to) {
				continue
			}
			required_production := unit_attachment_get_can_only_be_placed_in_territory_valued_at_x(ua)
			if required_production != -1 && required_production > territory_production {
				continue
			}
			req_p, req_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, to, true)
			if !req_p(req_c, current_unit) {
				continue
			}
		}
		cons_p, cons_c := matches_unit_which_consumes_units_has_required_units(units_at_start_of_turn_in_to)
		if !cons_p(cons_c, current_unit) {
			continue
		}
		ct := unit_attachment_get_construction_type(ua)
		unit_map_held[ct] = unit_map_held[ct] + 1
		unit_map_type_per_turn[ct] = unit_attachment_get_constructions_per_terr_per_type_per_turn(ua)
		if ct == "factory" {
			unit_map_max_type[ct] = max_factory
		} else {
			unit_map_max_type[ct] = unit_attachment_get_max_constructions_per_type_per_terr(ua)
		}
	}

	more_without_factory := properties_get_more_constructions_without_factory(props)
	more_with_factory := properties_get_more_constructions_with_factory(props)
	unlimited_constructions := properties_get_unlimited_constructions(props)
	was_factory_there_at_start := abstract_place_delegate_was_owned_unit_that_can_produce_units_or_is_factory_in_territory_at_start_of_step(self, to, player)

	unit_map_to := make(map[string]i32)
	defer delete(unit_map_to)
	existing_construction := make([dynamic]^Unit)
	defer delete(existing_construction)
	for u in to.unit_collection.units {
		if con_p(con_c, u) {
			append(&existing_construction, u)
		}
	}
	if len(existing_construction) > 0 {
		for u in existing_construction {
			ua := unit_get_unit_attachment(u)
			ct := unit_attachment_get_construction_type(ua)
			unit_map_to[ct] = unit_map_to[ct] + 1
		}
		held_keys := make([dynamic]string)
		defer delete(held_keys)
		for k in unit_map_held {
			append(&held_keys, k)
		}
		for ct in held_keys {
			unit_max := unit_map_max_type[ct]
			if ct != "factory" && !strings.has_suffix(ct, "structure") {
				more := more_without_factory
				if was_factory_there_at_start {
					more = more_with_factory
				}
				production: i32 = 0
				if more {
					production = territory_production
				}
				v_a := unit_max
				if production > v_a {
					v_a = production
				}
				v_b: i32 = 0
				if unlimited_constructions {
					v_b = 10000
				}
				if v_b > v_a {
					unit_max = v_b
				} else {
					unit_max = v_a
				}
			}
			existing_count := unit_map_to[ct]
			held_val := unit_map_held[ct]
			value := unit_max - existing_count
			if held_val < value {
				value = held_val
			}
			if value < 0 {
				value = 0
			}
			unit_map_held[ct] = value
		}
	}

	for u in units_placed_already {
		con_p2, con_c2 := matches_unit_is_construction()
		if !con_p2(con_c2, u) {
			continue
		}
		ua := unit_get_unit_attachment(u)
		ct := unit_attachment_get_construction_type(ua)
		unit_map_type_per_turn[ct] = unit_map_type_per_turn[ct] - 1
	}

	for ct, _ in unit_map_held {
		per_turn := unit_map_type_per_turn[ct]
		held := unit_map_held[ct]
		unit_allowed := per_turn
		if held < unit_allowed {
			unit_allowed = held
		}
		if unit_allowed < 0 {
			unit_allowed = 0
		}
		if unit_allowed > 0 {
			units_allowed[ct] = unit_allowed
		}
	}
	return units_allowed
}
