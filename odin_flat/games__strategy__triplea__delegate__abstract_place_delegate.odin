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

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getAllProducers(Territory,GamePlayer,Collection)
// Java: return getAllProducers(to, player, unitsToPlace, false);
abstract_place_delegate_get_all_producers_3 :: proc(
	self:           ^Abstract_Place_Delegate,
	to:             ^Territory,
	player:         ^Game_Player,
	units_to_place: [dynamic]^Unit,
) -> [dynamic]^Territory {
	return abstract_place_delegate_get_all_producers(self, to, player, units_to_place, false)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#canProduce(Territory,Territory,Collection,GamePlayer)
// Java: return canProduce(producer, to, units, player, false);
abstract_place_delegate_can_produce_4 :: proc(
	self:     ^Abstract_Place_Delegate,
	producer: ^Territory,
	to:       ^Territory,
	units:    [dynamic]^Unit,
	player:   ^Game_Player,
) -> Maybe(string) {
	return abstract_place_delegate_can_produce(self, producer, to, units, player, false)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#canProduce(Territory,Collection,GamePlayer)
// Java body translated 1:1.
abstract_place_delegate_can_produce_to :: proc(
	self:   ^Abstract_Place_Delegate,
	to:     ^Territory,
	units:  [dynamic]^Unit,
	player: ^Game_Player,
) -> Maybe(string) {
	producers := abstract_place_delegate_get_all_producers(self, to, player, units, true)
	defer delete(producers)
	if len(producers) == 0 {
		return fmt.aprintf("No factory in or adjacent to %s", territory_to_string(to))
	}
	if len(producers) == 1 {
		return abstract_place_delegate_can_produce_4(self, producers[0], to, units, player)
	}
	failing_count := 0
	error_buf := strings.builder_make()
	defer strings.builder_destroy(&error_buf)
	for producer in producers {
		err_p := abstract_place_delegate_can_produce_4(self, producer, to, units, player)
		if msg, has := err_p.?; has {
			failing_count += 1
			// do not include the error for same territory, if water
			if !(producer == to && territory_is_water(producer)) {
				strings.write_string(&error_buf, msg)
				strings.write_string(&error_buf, ".\n")
			}
		}
	}
	if len(producers) == failing_count {
		return fmt.aprintf(
			"Adjacent territories to %s cannot produce because:\n\n%s",
			territory_to_string(to),
			strings.to_string(error_buf),
		)
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#unitsPlacedInTerritorySoFar(Territory)
// Java:
//   final Collection<Unit> unitsInTo = new ArrayList<>(to.getUnits());
//   final Collection<Unit> unitsAtStartOfStep = unitsAtStartOfStepInTerritory(to);
//   unitsInTo.removeAll(unitsAtStartOfStep);
//   return unitsInTo;
abstract_place_delegate_units_placed_in_territory_so_far :: proc(
	self: ^Abstract_Place_Delegate,
	to:   ^Territory,
) -> [dynamic]^Unit {
	units_at_start_of_step := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start_of_step)
	result := make([dynamic]^Unit)
	for u in to.unit_collection.units {
		in_start := false
		for s in units_at_start_of_step {
			if u == s {
				in_start = true
				break
			}
		}
		if !in_start {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$unitWhichRequiresUnitsHasRequiredUnits$2(Territory,boolean,Unit)
// Synthetic body of the inner Predicate<Unit> lambda. Captures `to`,
// `countNeighbors`, and `self` (for unitsAtStartOfStepInTerritory /
// getAllProducers / self.player). Mirrors the per-call behaviour of
// abstract_place_delegate_unit_which_requires_units_has_required_units_test
// without requiring a heap-allocated ctx, since this is the canonically
// named lambda entry point referenced by the methods table.
abstract_place_delegate_lambda_unit_which_requires_units_has_required_units_2 :: proc(
	self:                       ^Abstract_Place_Delegate,
	to:                         ^Territory,
	count_neighbors:            bool,
	unit_which_requires_units:  ^Unit,
) -> bool {
	if !matches_unit_requires_units_on_creation(unit_which_requires_units) {
		return true
	}
	units_at_start_of_turn_in_producer := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start_of_turn_in_producer)
	if matches_unit_which_requires_units_has_required_units_in_list(unit_which_requires_units, units_at_start_of_turn_in_producer) {
		return true
	}
	if count_neighbors && territory_is_water(to) {
		single := make([dynamic]^Unit)
		defer delete(single)
		append(&single, unit_which_requires_units)
		producers := abstract_place_delegate_get_all_producers(self, to, self.player, single, true)
		defer delete(producers)
		for current in producers {
			units_at_start_of_turn_in_current := abstract_place_delegate_units_at_start_of_step_in_territory(self, current)
			defer delete(units_at_start_of_turn_in_current)
			if matches_unit_which_requires_units_has_required_units_in_list(unit_which_requires_units, units_at_start_of_turn_in_current) {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#addConstructionUnits(Collection,Territory,Collection)
// Java filters `units` to constructions, then for each UnitType present
// appends up to `howManyOfConstructionUnit(...)` of-type units to
// `placeableUnits`.
abstract_place_delegate_add_construction_units :: proc(
	self:           ^Abstract_Place_Delegate,
	units:          [dynamic]^Unit,
	to:             ^Territory,
	placeable_units: ^[dynamic]^Unit,
) {
	con_p, con_c := matches_unit_is_construction()
	construction_units := make([dynamic]^Unit)
	defer delete(construction_units)
	for u in units {
		if con_p(con_c, u) {
			append(&construction_units, u)
		}
	}
	if len(construction_units) == 0 {
		return
	}
	constructions_map := abstract_place_delegate_how_many_of_each_construction_can_place(self, to, to, construction_units, self.player)
	defer delete(constructions_map)
	unit_types := unit_utils_get_unit_types_from_unit_list(construction_units)
	defer delete(unit_types)
	for ut in unit_types {
		max_count := abstract_place_delegate_how_many_of_construction_unit(ut, constructions_map)
		taken: i32 = 0
		for u in construction_units {
			if taken >= max_count {
				break
			}
			if unit_get_type(u) == ut {
				append(placeable_units, u)
				taken += 1
			}
		}
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#canWeConsumeUnits(Collection,Territory,CompositeChange)
// Java body translated 1:1. When `change` is nil this is a pure test;
// otherwise the consumed units are removed from `to` via change adds and
// a history event is appended.
abstract_place_delegate_can_we_consume_units :: proc(
	self:   ^Abstract_Place_Delegate,
	units:  [dynamic]^Unit,
	to:     ^Territory,
	change: ^Composite_Change,
) -> bool {
	units_at_start_of_turn_in_to := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start_of_turn_in_to)
	removed_units := make([dynamic]^Unit)
	defer delete(removed_units)

	consume_p, consume_c := matches_unit_consumes_units_on_creation()
	units_which_consume := make([dynamic]^Unit)
	defer delete(units_which_consume)
	for u in units {
		if consume_p(consume_c, u) {
			append(&units_which_consume, u)
		}
	}
	for unit in units_which_consume {
		req_p, req_c := matches_unit_which_consumes_units_has_required_units(units_at_start_of_turn_in_to)
		if !req_p(req_c, unit) {
			return false
		}
		required_units_map := unit_attachment_get_consumes_units(unit_get_unit_attachment(unit))
		owner := unit_get_owner(unit)
		owned_p, owned_c := matches_unit_is_owned_by(owner)
		not_bombed_p, not_bombed_c := matches_unit_has_not_taken_any_bombing_unit_damage()
		not_dmg_p, not_dmg_c := matches_unit_has_not_taken_any_damage()
		not_dis_p, not_dis_c := matches_unit_is_not_disabled()
		for ut, required_number in required_units_map {
			of_type_p, of_type_c := matches_unit_is_of_type(ut)
			units_being_removed := make([dynamic]^Unit)
			taken: i32 = 0
			for candidate in units_at_start_of_turn_in_to {
				if taken >= required_number {
					break
				}
				if owned_p(owned_c, candidate) &&
				   of_type_p(of_type_c, candidate) &&
				   not_bombed_p(not_bombed_c, candidate) &&
				   not_dmg_p(not_dmg_c, candidate) &&
				   not_dis_p(not_dis_c, candidate) {
					append(&units_being_removed, candidate)
					taken += 1
				}
			}
			// removeAll from unitsAtStartOfTurnInTo
			for r in units_being_removed {
				for i := len(units_at_start_of_turn_in_to) - 1; i >= 0; i -= 1 {
					if units_at_start_of_turn_in_to[i] == r {
						ordered_remove(&units_at_start_of_turn_in_to, i)
						break
					}
				}
			}
			if change != nil {
				composite_change_add(change, change_factory_remove_units(cast(^Unit_Holder)to, units_being_removed))
				for r in units_being_removed {
					append(&removed_units, r)
				}
			}
			delete(units_being_removed)
		}
	}
	if change != nil && !composite_change_is_empty(change) {
		message := fmt.aprintf(
			"Units in %s being upgraded or consumed: %s",
			territory_to_string(to),
			my_formatter_units_to_text_no_owner(removed_units, nil),
		)
		bridge := abstract_delegate_get_bridge(&self.abstract_delegate)
		writer := i_delegate_bridge_get_history_writer(bridge)
		dyn_copy := make([dynamic]^Unit)
		for r in removed_units {
			append(&dyn_copy, r)
		}
		i_delegate_history_writer_start_event(writer, message, rawptr(&dyn_copy))
	}
	return true
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#moveAirOntoNewCarriers(Territory,Territory,Collection,GamePlayer,CompositeChange)
// Java body translated 1:1. Returns Maybe(string): the history message
// describing the move when it actually happened, or nil if the rules /
// state did not trigger one.
abstract_place_delegate_move_air_onto_new_carriers :: proc(
	self:         ^Abstract_Place_Delegate,
	at:           ^Territory,
	producer:     ^Territory,
	units:        [dynamic]^Unit,
	player:       ^Game_Player,
	place_change: ^Composite_Change,
) -> Maybe(string) {
	if !territory_is_water(at) {
		return nil
	}
	props := abstract_delegate_get_properties(&self.abstract_delegate)
	if !properties_get_move_existing_fighters_to_new_carriers(props) ||
	   properties_get_lhtr_carrier_production_rules(props) {
		return nil
	}
	carrier_p, carrier_c := matches_unit_is_carrier()
	any_carrier := false
	for u in units {
		if carrier_p(carrier_c, u) {
			any_carrier = true
			break
		}
	}
	if !any_carrier {
		return nil
	}
	capacity := air_movement_validator_carrier_capacity(units[:], at)
	capacity -= air_movement_validator_carrier_cost(units[:])
	if capacity <= 0 {
		return nil
	}
	land_p, land_c := matches_territory_is_land()
	if !land_p(land_c, producer) {
		return nil
	}
	can_produce_p, can_produce_c := matches_unit_can_produce_units()
	any_producer := false
	for u in producer.unit_collection.units {
		if can_produce_p(can_produce_c, u) {
			any_producer = true
			break
		}
	}
	if !any_producer {
		return nil
	}
	can_land_p, can_land_c := matches_unit_can_land_on_carrier()
	owned_p, owned_c := matches_unit_is_owned_by(player)
	any_owned_fighter := false
	for u in producer.unit_collection.units {
		if can_land_p(can_land_c, u) && owned_p(owned_c, u) {
			any_owned_fighter = true
			break
		}
	}
	if !any_owned_fighter {
		return nil
	}
	if abstract_place_delegate_was_conquered(self, producer) {
		return nil
	}
	already_in_producer := abstract_place_delegate_get_already_produced(self, producer)
	defer delete(already_in_producer)
	for u in already_in_producer {
		if can_produce_p(can_produce_c, u) {
			return nil
		}
	}
	fighters := make([dynamic]^Unit)
	defer delete(fighters)
	for u in producer.unit_collection.units {
		if can_land_p(can_land_c, u) && owned_p(owned_c, u) {
			append(&fighters, u)
		}
	}
	bridge := abstract_delegate_get_bridge(&self.abstract_delegate)
	remote := i_delegate_bridge_get_remote_player(bridge)
	moved_fighters := player_get_number_of_fighters_to_move_to_new_carrier(remote, fighters, producer)
	defer delete(moved_fighters)
	if len(moved_fighters) == 0 {
		return nil
	}
	change := change_factory_move_units(producer, at, moved_fighters)
	composite_change_add(place_change, change)
	return fmt.aprintf(
		"%s moved from %s to %s",
		my_formatter_units_to_text_no_owner(moved_fighters, nil),
		territory_to_string(producer),
		territory_to_string(at),
	)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#applyStackingLimitsPerUnitType(Collection,Territory)
// Java filters each unit type separately so a stacking limit on one type does
// not also exclude units of another type that share a combined limit.
abstract_place_delegate_apply_stacking_limits_per_unit_type :: proc(
	self:  ^Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	to:    ^Territory,
) -> [dynamic]^Unit {
	result := make([dynamic]^Unit)
	unit_types := unit_utils_get_unit_types_from_unit_list(units)
	defer delete(unit_types)
	for ut, _ in unit_types {
		of_type_p, of_type_c := matches_unit_is_of_type(ut)
		matched := make([dynamic]^Unit)
		for u in units {
			if of_type_p(of_type_c, u) {
				append(&matched, u)
			}
		}
		snapshot := make([dynamic]^Unit)
		if existing, ok := self.produced[to]; ok {
			for u in existing {
				append(&snapshot, u)
			}
		}
		filtered := unit_stacking_limit_filter_filter_units(
			matched,
			UNIT_STACKING_LIMIT_FILTER_PLACEMENT_LIMIT,
			self.player,
			to,
			snapshot,
		)
		for u in filtered {
			append(&result, u)
		}
		delete(matched)
		delete(snapshot)
		delete(filtered)
	}
	return result
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlacedFrom(Territory,Collection,Territory,GamePlayer)
// Private 4-arg variant: delegates to the 7-arg implementation with
// countSwitchedProductionToNeighbors=false and the two optional arguments
// nil, mirroring Java's `getMaxUnitsToBePlacedFrom(producer, units, to, player, false, null, null)`.
abstract_place_delegate_get_max_units_to_be_placed_from :: proc(
	self:     ^Abstract_Place_Delegate,
	producer: ^Territory,
	units:    [dynamic]^Unit,
	to:       ^Territory,
	player:   ^Game_Player,
) -> i32 {
	return abstract_place_delegate_get_max_units_to_be_placed_from_full(
		self, producer, units, to, player, false, nil, nil,
	)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlacedFrom(Territory,Collection,Territory,GamePlayer,boolean,Collection,Map)
// Full 7-arg implementation. Returns -1 if we can place unlimited units.
// The two trailing pointer parameters are nilable and only consulted when
// `count_switched_production_to_neighbors` is true; that mirrors Java's
// nullable Collection / nullable Map.
abstract_place_delegate_get_max_units_to_be_placed_from_full :: proc(
	self:     ^Abstract_Place_Delegate,
	producer: ^Territory,
	units:    [dynamic]^Unit,
	to:       ^Territory,
	player:   ^Game_Player,
	count_switched_production_to_neighbors:          bool,
	not_usable_as_other_producers:                   ^[dynamic]^Territory,
	current_available_placement_for_other_producers: ^map[^Territory]i32,
) -> i32 {
	properties := abstract_delegate_get_properties(&self.abstract_delegate)
	unit_placement_restrictions := abstract_place_delegate_has_unit_placement_restrictions(self)

	units_can_be_placed_by_this_producer := make([dynamic]^Unit)
	defer delete(units_can_be_placed_by_this_producer)
	if unit_placement_restrictions {
		req_p, req_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, producer, false)
		for u in units {
			if req_p(req_c, u) {
				append(&units_can_be_placed_by_this_producer, u)
			}
		}
	} else {
		for u in units {
			append(&units_can_be_placed_by_this_producer, u)
		}
	}
	if len(units_can_be_placed_by_this_producer) == 0 {
		return 0
	}

	// factoryMatch = unitIsOwnedAndIsFactoryOrCanProduceUnits(player)
	//                .and(unitIsBeingTransported().negate())
	//                .and(producer.isWater() ? unitIsLand().negate() : unitIsSea().negate())
	fact_p, fact_c := matches_unit_is_owned_and_is_factory_or_can_produce_units(player)
	trans_p, trans_c := matches_unit_is_being_transported()
	side_p: proc(rawptr, ^Unit) -> bool
	side_c: rawptr
	if territory_is_water(producer) {
		side_p, side_c = matches_unit_is_not_land()
	} else {
		side_p, side_c = matches_unit_is_not_sea()
	}
	factory_units := make([dynamic]^Unit)
	defer delete(factory_units)
	for u in producer.unit_collection.units {
		if fact_p(fact_c, u) && !trans_p(trans_c, u) && side_p(side_c, u) {
			append(&factory_units, u)
		}
	}

	unit_placement_per_territory_restricted := properties_get_unit_placement_per_territory_restricted(properties)
	original_factory := false
	if ta := territory_attachment_get(producer); ta != nil {
		original_factory = territory_attachment_get_original_factory(ta)
	}
	player_is_original_owner := false
	if len(factory_units) > 0 {
		player_is_original_owner = self.player == abstract_place_delegate_get_original_factory_owner(self, producer)
	}
	ra := game_player_get_rules_attachment(player)
	already_produced_units := abstract_place_delegate_get_already_produced(self, producer)
	defer delete(already_produced_units)
	unit_count_already_produced := i32(len(already_produced_units))

	if original_factory && player_is_original_owner {
		if ra != nil && ra.max_place_per_territory != -1 {
			v := ra.max_place_per_territory - unit_count_already_produced
			if v < 0 {
				return 0
			}
			return v
		}
		return -1
	}

	if unit_placement_per_territory_restricted && ra != nil && ra.placement_per_territory > 0 {
		allowed_placement := ra.placement_per_territory
		owned_p, owned_c := matches_unit_is_owned_by(player)
		owned_units_in_territory: i32 = 0
		for u in to.unit_collection.units {
			if owned_p(owned_c, u) {
				owned_units_in_territory += 1
			}
		}
		if owned_units_in_territory >= allowed_placement {
			return 0
		}
		if ra.max_place_per_territory == -1 {
			return -1
		}
		v := ra.max_place_per_territory - unit_count_already_produced
		if v < 0 {
			return 0
		}
		return v
	}

	constructions_map := abstract_place_delegate_how_many_of_each_construction_can_place(
		self, to, producer, units_can_be_placed_by_this_producer, player,
	)
	defer delete(constructions_map)
	max_constructions: i32 = 0
	for _, v in constructions_map {
		max_constructions += v
	}

	was_factory_there_at_start := abstract_place_delegate_was_owned_unit_that_can_produce_units_or_is_factory_in_territory_at_start_of_step(
		self, producer, player,
	)
	if !was_factory_there_at_start {
		if ra != nil && ra.max_place_per_territory > 0 {
			v := ra.max_place_per_territory - unit_count_already_produced
			if max_constructions < v {
				v = max_constructions
			}
			if v < 0 {
				return 0
			}
			return v
		}
		if max_constructions < 0 {
			return 0
		}
		return max_constructions
	}

	units_at_start := abstract_place_delegate_units_at_start_of_step_in_territory(self, producer)
	defer delete(units_at_start)
	production := unit_utils_get_production_potential_of_territory(units_at_start, producer, player, true, true)
	if max_constructions > 0 {
		production += max_constructions
	}
	if production < 0 {
		return 0
	}
	con_p, con_c := matches_unit_is_construction()
	for u in already_produced_units {
		if con_p(con_c, u) {
			production += 1
		}
	}

	unit_count_have_to_and_have_been_be_produced_here := unit_count_already_produced
	if count_switched_production_to_neighbors && unit_count_already_produced > 0 {
		if not_usable_as_other_producers == nil {
			panic("notUsableAsOtherProducers cannot be null if countSwitchedProductionToNeighbors is true")
		}
		if current_available_placement_for_other_producers == nil {
			panic("currentAvailablePlacementForOtherProducers cannot be null if countSwitchedProductionToNeighbors is true")
		}
		production_can_not_be_moved: i32 = 0
		production_that_can_be_taken_over: i32 = 0
		req_creation_p, req_creation_c := matches_unit_requires_units_on_creation()
		for placement_move in self.placements {
			if placement_move.producer_territory != producer {
				continue
			}
			place_territory := placement_move.place_territory
			units_placed_by_current_placement_move := placement_move.units
			any_requires := false
			if abstract_place_delegate_has_unit_placement_restrictions(self) {
				for u in units_placed_by_current_placement_move {
					if req_creation_p(req_creation_c, u) {
						any_requires = true
						break
					}
				}
			}
			if !territory_is_water(place_territory) || any_requires {
				production_can_not_be_moved += i32(len(units_placed_by_current_placement_move))
			} else {
				max_production_that_can_be_taken_over_from_this_placement := i32(len(units_placed_by_current_placement_move))
				new_potential_other_producers := abstract_place_delegate_get_all_producers_3(
					self, place_territory, player, units_can_be_placed_by_this_producer,
				)
				// removeAll(notUsableAsOtherProducers)
				for i := len(new_potential_other_producers) - 1; i >= 0; i -= 1 {
					t := new_potential_other_producers[i]
					for nu in not_usable_as_other_producers^ {
						if t == nu {
							ordered_remove(&new_potential_other_producers, i)
							break
						}
					}
				}
				// stable insertion sort by best-producer comparator
				cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(
					self, place_territory, units_can_be_placed_by_this_producer, player,
				)
				for i := 1; i < len(new_potential_other_producers); i += 1 {
					j := i
					for j > 0 && cmp_fn(cmp_ctx, new_potential_other_producers[j], new_potential_other_producers[j - 1]) < 0 {
						tmp := new_potential_other_producers[j]
						new_potential_other_producers[j] = new_potential_other_producers[j - 1]
						new_potential_other_producers[j - 1] = tmp
						j -= 1
					}
				}
				free(cmp_ctx)
				production_that_can_be_taken_over_from_this_placement: i32 = 0
				for potential_other_producer in new_potential_other_producers {
					potential, has_potential := current_available_placement_for_other_producers[potential_other_producer]
					if !has_potential {
						units_placed_so_far := abstract_place_delegate_units_placed_in_territory_so_far(self, place_territory)
						potential = abstract_place_delegate_get_max_units_to_be_placed_from(
							self, potential_other_producer, units_placed_so_far, place_territory, player,
						)
						delete(units_placed_so_far)
					}
					if potential == -1 {
						current_available_placement_for_other_producers[potential_other_producer] = -1
						production_that_can_be_taken_over_from_this_placement = max_production_that_can_be_taken_over_from_this_placement
						break
					}
					needed := max_production_that_can_be_taken_over_from_this_placement - production_that_can_be_taken_over_from_this_placement
					surplus := potential - needed
					if surplus > 0 {
						current_available_placement_for_other_producers[potential_other_producer] = surplus
						production_that_can_be_taken_over_from_this_placement += needed
					} else {
						current_available_placement_for_other_producers[potential_other_producer] = 0
						production_that_can_be_taken_over_from_this_placement += potential
						append(not_usable_as_other_producers, potential_other_producer)
					}
					if surplus >= 0 {
						break
					}
				}
				delete(new_potential_other_producers)
				if production_that_can_be_taken_over_from_this_placement > max_production_that_can_be_taken_over_from_this_placement {
					panic("productionThatCanBeTakenOverFromThisPlacement should never be larger than maxProductionThatCanBeTakenOverFromThisPlacement")
				}
				production_that_can_be_taken_over += production_that_can_be_taken_over_from_this_placement
			}
			if production_that_can_be_taken_over >= unit_count_already_produced - production_can_not_be_moved {
				break
			}
		}
		v := unit_count_already_produced - production_that_can_be_taken_over
		if v < 0 {
			v = 0
		}
		unit_count_have_to_and_have_been_be_produced_here = v
	}

	if ra != nil && ra.max_place_per_territory > 0 {
		current_value := unit_count_have_to_and_have_been_be_produced_here
		v1 := production - current_value
		v2 := ra.max_place_per_territory - current_value
		value := v1
		if v2 < value {
			value = v2
		}
		if value < 0 {
			return 0
		}
		return value
	}
	v := production - unit_count_have_to_and_have_been_be_produced_here
	if v < 0 {
		return 0
	}
	return v
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#performPlaceFrom(Territory,Collection,Territory,GamePlayer)
// Private. Builds a CompositeChange consuming/upgrading units, moving any
// fighter overflow onto new carriers, removing the placed units from the
// player's hand, adding them to `at`, and recording an UndoablePlacement.
abstract_place_delegate_perform_place_from :: proc(
	self:            ^Abstract_Place_Delegate,
	producer:        ^Territory,
	placeable_units: [dynamic]^Unit,
	at:              ^Territory,
	player:          ^Game_Player,
) {
	change := composite_change_new()
	did_it := abstract_place_delegate_can_we_consume_units(self, placeable_units, at, change)
	if !did_it {
		panic("Something wrong with consuming/upgrading units")
	}
	infra_p, infra_c := matches_unit_is_infrastructure()
	factory_and_infrastructure := make([dynamic]^Unit)
	defer delete(factory_and_infrastructure)
	for u in placeable_units {
		if infra_p(infra_c, u) {
			append(&factory_and_infrastructure, u)
		}
	}
	if len(factory_and_infrastructure) > 0 {
		composite_change_add(
			change,
			original_owner_tracker_add_original_owner_change_units(factory_and_infrastructure, player),
		)
	}
	moved_air_transcript_text_for_history := abstract_place_delegate_move_air_onto_new_carriers(
		self, at, producer, placeable_units, player, change,
	)
	remove := change_factory_remove_units(cast(^Unit_Holder)player, placeable_units)
	place := change_factory_add_units(cast(^Unit_Holder)at, placeable_units)
	composite_change_add(change, remove)
	composite_change_add(change, place)
	current_placement := undoable_placement_new(change, producer, at, placeable_units)
	append(&self.placements, current_placement)
	abstract_place_delegate_update_undoable_placement_indexes(self)
	transcript_text := fmt.aprintf(
		"%s placed in %s",
		my_formatter_units_to_text_no_owner(placeable_units, nil),
		territory_to_string(at),
	)
	bridge := abstract_delegate_get_bridge(&self.abstract_delegate)
	writer := i_delegate_bridge_get_history_writer(bridge)
	desc := undoable_placement_get_description_object(current_placement)
	i_delegate_history_writer_start_event(writer, transcript_text, rawptr(desc))
	if msg, has := moved_air_transcript_text_for_history.?; has {
		history_writer_add_child_to_event(writer, msg)
	}
	i_delegate_bridge_add_change(bridge, &change.change)
	abstract_place_delegate_update_produced_map(self, producer, placeable_units)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#removeAirThatCantLand()
// LHTR-style cleanup at the end of the place phase. The current player's air is
// removed first; then the same removal runs against every other player to clean
// up after edit-mode side-effects.
abstract_place_delegate_remove_air_that_cant_land :: proc(self: ^Abstract_Place_Delegate) {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	bridge := abstract_delegate_get_bridge(&self.abstract_delegate)
	util := air_that_cant_land_util_new(bridge)
	air_that_cant_land_util_remove_air_that_cant_land(util, self.player, false)
	players := player_list_get_players(game_data_get_player_list(data))
	defer delete(players)
	for player in players {
		if player != self.player {
			air_that_cant_land_util_remove_air_that_cant_land(util, player, false)
		}
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlacedMap(Collection,Territory,GamePlayer)
// Returns an IntegerMap keyed by each producer Territory; -1 anywhere in the
// map means "unlimited" for that producer. Producers are visited in
// best-producer order so the recursive accounting in
// getMaxUnitsToBePlacedFrom_full sees neighbors consistently.
abstract_place_delegate_get_max_units_to_be_placed_map :: proc(
	self:   ^Abstract_Place_Delegate,
	units:  [dynamic]^Unit,
	to:     ^Territory,
	player: ^Game_Player,
) -> ^Integer_Map {
	max_units_to_be_placed_map := integer_map_new()
	producers := abstract_place_delegate_get_all_producers(self, to, player, units, true)
	defer delete(producers)
	if len(producers) == 0 {
		return max_units_to_be_placed_map
	}
	cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(self, to, units, player)
	for i := 1; i < len(producers); i += 1 {
		j := i
		for j > 0 && cmp_fn(cmp_ctx, producers[j], producers[j - 1]) < 0 {
			tmp := producers[j]
			producers[j] = producers[j - 1]
			producers[j - 1] = tmp
			j -= 1
		}
	}
	free(cmp_ctx)
	not_usable_as_other_producers := make([dynamic]^Territory)
	defer delete(not_usable_as_other_producers)
	for p in producers {
		append(&not_usable_as_other_producers, p)
	}
	current_available_placement_for_other_producers := make(map[^Territory]i32)
	defer delete(current_available_placement_for_other_producers)
	for producer_territory in producers {
		prod_t := abstract_place_delegate_get_max_units_to_be_placed_from_full(
			self,
			producer_territory,
			units,
			to,
			player,
			true,
			&not_usable_as_other_producers,
			&current_available_placement_for_other_producers,
		)
		integer_map_put(max_units_to_be_placed_map, rawptr(producer_territory), prod_t)
	}
	return max_units_to_be_placed_map
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#lambda$getBestProducerComparator$4(Territory,Collection,GamePlayer,Territory,Territory)
// Synthetic body of the (t1, t2) -> ... lambda inside getBestProducerComparator.
// The reusable implementation lives in abstract_place_delegate_best_producer_compare,
// which is keyed off a heap-allocated ctx; this proc mirrors javac's flat
// arg list (captured locals followed by lambda params) by stack-allocating
// an equivalent ctx and dispatching to the shared body.
abstract_place_delegate_lambda__get_best_producer_comparator__4 :: proc(
	self: ^Abstract_Place_Delegate,
	at: ^Territory,
	units: [dynamic]^Unit,
	player: ^Game_Player,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	ctx := Abstract_Place_Delegate_Best_Producer_Comparator_Ctx{
		self   = self,
		to     = at,
		units  = units,
		player = player,
	}
	return abstract_place_delegate_best_producer_compare(rawptr(&ctx), t1, t2)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#freePlacementCapacity(Territory,int,Collection,Territory,GamePlayer)
// Frees `freeSize` slots on `producer` by trying to hand off existing sea-zone
// placements (whose units don't have requiresUnits) to other adjacent
// producers. Whole placements migrate intact when possible; otherwise we
// remember (placement, newProducer) splits and, after the first pass, undo
// each split-target placement once and re-perform it as two: one through the
// new producer and one through the original. Recurses (once at most) when the
// requested capacity is still short and unused split candidates remain.
abstract_place_delegate_free_placement_capacity :: proc(
	self:               ^Abstract_Place_Delegate,
	producer:           ^Territory,
	free_size:          i32,
	units_left_to_place: [dynamic]^Unit,
	at:                 ^Territory,
	player:             ^Game_Player,
) {
	redo_placements := make([dynamic]^Undoable_Placement)
	defer delete(redo_placements)
	redo_placements_count := make(map[^Territory]i32)
	defer delete(redo_placements_count)
	req_p, req_c := matches_unit_requires_units_on_creation()
	for placement in self.placements {
		if undoable_placement_get_producer_territory(placement) != producer {
			continue
		}
		place_territory := undoable_placement_get_place_territory(placement)
		if !territory_is_water(place_territory) || place_territory == producer {
			continue
		}
		placement_units := abstract_undoable_move_get_units(&placement.abstract_undoable_move)
		any_requires := false
		if abstract_place_delegate_has_unit_placement_restrictions(self) {
			for u in placement_units {
				if req_p(req_c, u) {
					any_requires = true
					break
				}
			}
		}
		if any_requires {
			continue
		}
		append(&redo_placements, placement)
		add := i32(len(placement_units))
		if existing, ok := redo_placements_count[place_territory]; ok {
			redo_placements_count[place_territory] = existing + add
		} else {
			redo_placements_count[place_territory] = add
		}
	}

	split_placements := make([dynamic]^Tuple(^Undoable_Placement, ^Territory))
	defer {
		for t in split_placements {
			free(t)
		}
		delete(split_placements)
	}
	found_space_total: i32 = 0

	outer_loop: for place_territory, max_production_that_can_be_taken_over_from_this_placement in redo_placements_count {
		potential_new_producers := abstract_place_delegate_get_all_producers_3(
			self, place_territory, player, units_left_to_place,
		)
		// remove `producer` from the candidate list
		for i := len(potential_new_producers) - 1; i >= 0; i -= 1 {
			if potential_new_producers[i] == producer {
				ordered_remove(&potential_new_producers, i)
			}
		}
		// stable insertion sort by best-producer comparator
		cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(
			self, place_territory, units_left_to_place, player,
		)
		for i := 1; i < len(potential_new_producers); i += 1 {
			j := i
			for j > 0 && cmp_fn(cmp_ctx, potential_new_producers[j], potential_new_producers[j - 1]) < 0 {
				tmp := potential_new_producers[j]
				potential_new_producers[j] = potential_new_producers[j - 1]
				potential_new_producers[j - 1] = tmp
				j -= 1
			}
		}
		free(cmp_ctx)

		max_space_to_be_free := max_production_that_can_be_taken_over_from_this_placement
		remaining_to_find := free_size - found_space_total
		if remaining_to_find < max_space_to_be_free {
			max_space_to_be_free = remaining_to_find
		}
		space_already_free: i32 = 0
		producer_loop: for potential_new_producer_territory in potential_new_producers {
			units_placed_so_far := abstract_place_delegate_units_placed_in_territory_so_far(self, place_territory)
			left_to_place := abstract_place_delegate_get_max_units_to_be_placed_from(
				self, potential_new_producer_territory, units_placed_so_far, place_territory, player,
			)
			delete(units_placed_so_far)
			if left_to_place == -1 {
				left_to_place = max_production_that_can_be_taken_over_from_this_placement
			}
			for placement in redo_placements {
				if undoable_placement_get_place_territory(placement) != place_territory {
					continue
				}
				placed_units := abstract_undoable_move_get_units(&placement.abstract_undoable_move)
				placement_size := i32(len(placed_units))
				if placement_size <= left_to_place {
					// potentialNewProducerTerritory can take over the entire production
					undoable_placement_set_producer_territory(placement, potential_new_producer_territory)
					abstract_place_delegate_remove_from_produced_map(self, producer, placed_units)
					abstract_place_delegate_update_produced_map(self, potential_new_producer_territory, placed_units)
					space_already_free += placement_size
				} else {
					// Only part of the production can move; remember it for the split pass
					append(
						&split_placements,
						tuple_new(^Undoable_Placement, ^Territory, placement, potential_new_producer_territory),
					)
				}
				if space_already_free >= max_space_to_be_free {
					break producer_loop
				}
			}
			if space_already_free >= max_space_to_be_free {
				break producer_loop
			}
		}
		delete(potential_new_producers)
		found_space_total += space_already_free
		if found_space_total >= free_size {
			break outer_loop
		}
	}

	// Java guards against splitting the same UndoablePlacement twice (it can only
	// be undone once); track the placements we've already used.
	unused_split_placements := false
	if found_space_total < free_size {
		used_undoable_placements := make(map[^Undoable_Placement]struct{})
		defer delete(used_undoable_placements)
		for tuple in split_placements {
			placement := tuple.first
			if _, already := used_undoable_placements[placement]; already {
				unused_split_placements = true
				continue
			}
			new_producer := tuple.second
			left_to_place := abstract_place_delegate_get_max_units_to_be_placed_from(
				self, new_producer, units_left_to_place, at, player,
			)
			found_space_total += left_to_place
			placement_units := abstract_undoable_move_get_units(&placement.abstract_undoable_move)
			units_for_old_producer := make([dynamic]^Unit)
			for u in placement_units {
				append(&units_for_old_producer, u)
			}
			units_for_new_producer := make([dynamic]^Unit)
			for unit in placement_units {
				if left_to_place == 0 {
					break
				}
				append(&units_for_new_producer, unit)
				left_to_place -= 1
			}
			// removeAll(units_for_new_producer) from units_for_old_producer
			for moved in units_for_new_producer {
				for i := len(units_for_old_producer) - 1; i >= 0; i -= 1 {
					if units_for_old_producer[i] == moved {
						ordered_remove(&units_for_old_producer, i)
					}
				}
			}
			if len(units_for_new_producer) > 0 {
				used_undoable_placements[placement] = struct{}{}
				abstract_place_delegate_undo_move(self, abstract_undoable_move_get_index(&placement.abstract_undoable_move))
				abstract_place_delegate_perform_place_from(
					self, new_producer, units_for_new_producer, undoable_placement_get_place_territory(placement), player,
				)
				abstract_place_delegate_perform_place_from(
					self, producer, units_for_old_producer, undoable_placement_get_place_territory(placement), player,
				)
			} else {
				delete(units_for_new_producer)
				delete(units_for_old_producer)
			}
		}
	}
	if found_space_total < free_size && unused_split_placements {
		abstract_place_delegate_free_placement_capacity(
			self, producer, free_size - found_space_total, units_left_to_place, at, player,
		)
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#doAfterEnd()
// Clears unplaced units (unless property keeps them), resets the produced map
// and the placements list, and removes air that can't land for LHTR-style games.
abstract_place_delegate_do_after_end :: proc(self: ^Abstract_Place_Delegate) {
	player := i_delegate_bridge_get_game_player(self.bridge)
	units := unit_holder_get_units(cast(^Unit_Holder)player)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if !properties_get_unplaced_units_live(game_data_get_properties(data)) && len(units) > 0 {
		event_text := strings.concatenate({
			my_formatter_units_to_text_no_owner_simple(units),
			" were produced but were not placed",
		})
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			event_text,
			rawptr(&units),
		)
		change := change_factory_remove_units(cast(^Unit_Holder)player, units)
		i_delegate_bridge_add_change(self.bridge, change)
	}
	// reset ourselves for next turn
	clear(&self.produced)
	clear(&self.placements)
	if game_step_properties_helper_is_remove_air_that_can_not_land(data) {
		abstract_place_delegate_remove_air_that_cant_land(self)
	}
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlaced(Collection,Territory,GamePlayer)
// Returns -1 if any producer is unlimited; otherwise sums the per-producer caps
// from getMaxUnitsToBePlacedMap.
abstract_place_delegate_get_max_units_to_be_placed :: proc(
	self:   ^Abstract_Place_Delegate,
	units:  [dynamic]^Unit,
	to:     ^Territory,
	player: ^Game_Player,
) -> i32 {
	im := abstract_place_delegate_get_max_units_to_be_placed_map(self, units, to, player)
	defer free(im)
	production: i32 = 0
	for _, prod_t in im.map_values {
		if prod_t == -1 {
			return -1
		}
		production += prod_t
	}
	return production
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getUnitsThatCantBePlacedThatRequireUnits(Collection,Territory)
// Mirrors Java: greedily assigns units to best-ordered producers, respecting
// each producer's `unitWhichRequiresUnitsHasRequiredUnits` predicate, and
// returns whichever units could not be placed anywhere.
abstract_place_delegate_get_units_that_cant_be_placed_that_require_units :: proc(
	self:  ^Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	to:    ^Territory,
) -> [dynamic]^Unit {
	if !abstract_place_delegate_has_unit_placement_restrictions(self) {
		return make([dynamic]^Unit)
	}
	req_p, req_c := matches_unit_requires_units_on_creation()
	any_requires := false
	for u in units {
		if req_p(req_c, u) {
			any_requires = true
			break
		}
	}
	if !any_requires {
		return make([dynamic]^Unit)
	}
	producers_map := abstract_place_delegate_get_max_units_to_be_placed_map(self, units, to, self.player)
	defer free(producers_map)
	producers := abstract_place_delegate_get_all_producers_3(self, to, self.player, units)
	defer delete(producers)
	if len(producers) == 0 {
		// Java returns the original `units` collection here.
		result := make([dynamic]^Unit)
		for u in units {
			append(&result, u)
		}
		return result
	}
	// stable insertion sort by best-producer comparator
	cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(self, to, units, self.player)
	for i := 1; i < len(producers); i += 1 {
		j := i
		for j > 0 && cmp_fn(cmp_ctx, producers[j], producers[j - 1]) < 0 {
			tmp := producers[j]
			producers[j] = producers[j - 1]
			producers[j - 1] = tmp
			j -= 1
		}
	}
	free(cmp_ctx)

	units_left_to_place := make([dynamic]^Unit)
	for u in units {
		append(&units_left_to_place, u)
	}
	hardest_cmp := abstract_place_delegate_get_hardest_to_place_with_requires_units_restrictions()

	for t in producers {
		if len(units_left_to_place) == 0 {
			clear(&units_left_to_place)
			return units_left_to_place
		}
		production_here := integer_map_get_int(producers_map, rawptr(t))
		req_at_p, req_at_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, t, false)
		can_be_placed_here := make([dynamic]^Unit)
		for u in units_left_to_place {
			if req_at_p(req_at_c, u) {
				append(&can_be_placed_here, u)
			}
		}
		free(req_at_c)
		if production_here == -1 || production_here >= i32(len(can_be_placed_here)) {
			// remove every can_be_placed_here element from units_left_to_place
			for moved in can_be_placed_here {
				for i := len(units_left_to_place) - 1; i >= 0; i -= 1 {
					if units_left_to_place[i] == moved {
						ordered_remove(&units_left_to_place, i)
					}
				}
			}
			delete(can_be_placed_here)
			continue
		}
		// stable insertion sort by hardest-to-place comparator
		for i := 1; i < len(can_be_placed_here); i += 1 {
			j := i
			for j > 0 && hardest_cmp(can_be_placed_here[j], can_be_placed_here[j - 1]) < 0 {
				tmp := can_be_placed_here[j]
				can_be_placed_here[j] = can_be_placed_here[j - 1]
				can_be_placed_here[j - 1] = tmp
				j -= 1
			}
		}
		// take first `production_here` matches (predicate is `it -> true`)
		placed_here := make([dynamic]^Unit)
		taken: i32 = 0
		for u in can_be_placed_here {
			if taken >= production_here {
				break
			}
			if abstract_place_delegate_lambda_get_units_that_cant_be_placed_that_require_units_3(u) {
				append(&placed_here, u)
				taken += 1
			}
		}
		for moved in placed_here {
			for i := len(units_left_to_place) - 1; i >= 0; i -= 1 {
				if units_left_to_place[i] == moved {
					ordered_remove(&units_left_to_place, i)
				}
			}
		}
		delete(placed_here)
		delete(can_be_placed_here)
	}
	return units_left_to_place
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getCanAllUnitsWithRequiresUnitsBePlacedCorrectly(java.util.Collection,games.strategy.engine.data.Territory)
// Java: return getUnitsThatCantBePlacedThatRequireUnits(units, to).isEmpty();
abstract_place_delegate_get_can_all_units_with_requires_units_be_placed_correctly :: proc(
	self:  ^Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	to:    ^Territory,
) -> bool {
	cant := abstract_place_delegate_get_units_that_cant_be_placed_that_require_units(self, units, to)
	defer delete(cant)
	return len(cant) == 0
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getUnitsToBePlaced(games.strategy.engine.data.Territory,java.util.Collection,games.strategy.engine.data.GamePlayer)
// Java returns @Nullable Collection<Unit>: returns (_, false) when sea-zone enemy
// presence forbids placement in non-WW2v2 / non-EnemySeas games, otherwise
// (placeable, true). The body mirrors Java line-by-line.
abstract_place_delegate_get_units_to_be_placed :: proc(
	self:      ^Abstract_Place_Delegate,
	to:        ^Territory,
	all_units: [dynamic]^Unit,
	player:    ^Game_Player,
) -> (
	[dynamic]^Unit,
	bool,
) {
	properties := abstract_delegate_get_properties(&self.abstract_delegate)
	water := territory_is_water(to)
	if water &&
	   (!properties_get_ww2_v2(properties) && !properties_get_unit_placement_in_enemy_seas(properties)) {
		enemy_p, enemy_c := matches_enemy_unit(player)
		for u in to.unit_collection.units {
			if enemy_p(enemy_c, u) {
				empty: [dynamic]^Unit
				return empty, false
			}
		}
	}
	// if unit is water, remove land, if unit is land, remove water.
	units := make([dynamic]^Unit)
	defer delete(units)
	if water {
		not_land_p, not_land_c := matches_unit_is_not_land()
		for u in all_units {
			if not_land_p(not_land_c, u) {
				append(&units, u)
			}
		}
	} else {
		not_sea_p, not_sea_c := matches_unit_is_not_sea()
		for u in all_units {
			if not_sea_p(not_sea_c, u) {
				append(&units, u)
			}
		}
	}
	placeable_units := make([dynamic]^Unit)
	defer delete(placeable_units)
	units_at_start_of_turn_in_to := abstract_place_delegate_units_at_start_of_step_in_territory(self, to)
	defer delete(units_at_start_of_turn_in_to)
	all_produced_units := abstract_place_delegate_units_placed_in_territory_so_far(self, to)
	defer delete(all_produced_units)
	is_bid := game_step_properties_helper_is_bid(abstract_delegate_get_data(&self.abstract_delegate))
	was_factory_there_at_start :=
		abstract_place_delegate_was_owned_unit_that_can_produce_units_or_is_factory_in_territory_at_start_of_step(self, to, player)

	// we add factories and constructions later
	if water || was_factory_there_at_start ||
	   abstract_place_delegate_is_player_allowed_to_placement_any_territory_owned_land(self, player) {
		not_construction_p, not_construction_c := matches_unit_is_not_construction()
		side_p: proc(rawptr, ^Unit) -> bool
		side_c: rawptr
		if water {
			side_p, side_c = matches_unit_is_sea()
		} else {
			side_p, side_c = matches_unit_is_land()
		}
		for u in units {
			if side_p(side_c, u) && not_construction_p(not_construction_c, u) {
				append(&placeable_units, u)
			}
		}
		if !water {
			air_p, air_c := matches_unit_is_air()
			for u in units {
				if air_p(air_c, u) && not_construction_p(not_construction_c, u) {
					append(&placeable_units, u)
				}
			}
		} else {
			can_produce_fighters_on_carriers :=
				is_bid ||
				properties_get_produce_fighters_on_carriers(properties) ||
				properties_get_lhtr_carrier_production_rules(properties)
			carrier_p, carrier_c := matches_unit_is_carrier()
			any_produced_carrier := false
			for u in all_produced_units {
				if carrier_p(carrier_c, u) {
					any_produced_carrier = true
					break
				}
			}
			combined_p, combined_c :=
				abstract_place_delegate_unit_is_carrier_owned_by_combined_players(self, player)
			any_combined_carrier_in_to := false
			for u in to.unit_collection.units {
				if combined_p(combined_c, u) {
					any_combined_carrier_in_to = true
					break
				}
			}
			if (can_produce_fighters_on_carriers && any_produced_carrier) ||
			   any_combined_carrier_in_to {
				air_p, air_c := matches_unit_is_air()
				can_land_p, can_land_c := matches_unit_can_land_on_carrier()
				for u in units {
					if air_p(air_c, u) && can_land_p(can_land_c, u) {
						append(&placeable_units, u)
					}
				}
			}
		}
	}
	abstract_place_delegate_add_construction_units(self, units, to, &placeable_units)
	// remove any units that require other units to be consumed on creation,
	// if we don't have enough to consume (veqryn)
	{
		req_p, req_c := matches_unit_which_consumes_units_has_required_units(units_at_start_of_turn_in_to)
		for i := len(placeable_units) - 1; i >= 0; i -= 1 {
			if !req_p(req_c, placeable_units[i]) {
				ordered_remove(&placeable_units, i)
			}
		}
	}

	placeable_units2: [dynamic]^Unit
	if abstract_place_delegate_has_unit_placement_restrictions(self) {
		territory_production: i32 = 0
		if ta := territory_attachment_get(to); ta != nil {
			territory_production = territory_attachment_get_production(ta)
		}
		placeable_units2 = make([dynamic]^Unit)
		req_p, req_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, to, true)
		only_orig_p, only_orig_c := matches_unit_can_only_place_in_original_territories()
		orig_owned_p, orig_owned_c := matches_territory_is_originally_owned_by(player)
		for current_unit in placeable_units {
			ua := unit_get_unit_attachment(current_unit)
			required_production := unit_attachment_get_can_only_be_placed_in_territory_valued_at_x(ua)
			if required_production != -1 && required_production > territory_production {
				continue
			}
			if !req_p(req_c, current_unit) {
				continue
			}
			if only_orig_p(only_orig_c, current_unit) && !orig_owned_p(orig_owned_c, to) {
				continue
			}
			if !unit_attachment_unit_placement_restrictions_contain(ua, to) {
				append(&placeable_units2, current_unit)
			}
		}
	} else {
		placeable_units2 = make([dynamic]^Unit)
		for u in placeable_units {
			append(&placeable_units2, u)
		}
	}

	// Limit count of each unit type to the max that can be placed based on unit requirements.
	unit_types := unit_utils_get_unit_types_from_unit_list(placeable_units)
	defer delete(unit_types)
	for ut, _ in unit_types {
		of_type_p, of_type_c := matches_unit_is_of_type(ut)
		units_of_type := make([dynamic]^Unit)
		for u in placeable_units2 {
			if of_type_p(of_type_c, u) {
				append(&units_of_type, u)
			}
		}
		cant := abstract_place_delegate_get_units_that_cant_be_placed_that_require_units(
			self, units_of_type, to,
		)
		for r in cant {
			for i := len(placeable_units2) - 1; i >= 0; i -= 1 {
				if placeable_units2[i] == r {
					ordered_remove(&placeable_units2, i)
				}
			}
		}
		delete(units_of_type)
		delete(cant)
	}
	// now check stacking limits
	limited := abstract_place_delegate_apply_stacking_limits_per_unit_type(self, placeable_units2, to)
	delete(placeable_units2)
	return limited, true
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#checkProduction(Territory,Collection,GamePlayer)
// Test whether the territory has the factory resources to support the placement.
abstract_place_delegate_check_production :: proc(
	self:   ^Abstract_Place_Delegate,
	to:     ^Territory,
	units:  [dynamic]^Unit,
	player: ^Game_Player,
) -> Maybe(string) {
	producers := abstract_place_delegate_get_all_producers_3(self, to, player, units)
	defer delete(producers)
	if len(producers) == 0 {
		return fmt.aprintf("No factory in or adjacent to %s", territory_to_string(to))
	}
	// if it's an original factory then unlimited production
	cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(self, to, units, player)
	for i := 1; i < len(producers); i += 1 {
		j := i
		for j > 0 && cmp_fn(cmp_ctx, producers[j], producers[j - 1]) < 0 {
			tmp := producers[j]
			producers[j] = producers[j - 1]
			producers[j - 1] = tmp
			j -= 1
		}
	}
	free(cmp_ctx)
	if !abstract_place_delegate_get_can_all_units_with_requires_units_be_placed_correctly(self, units, to) {
		return "Cannot place more units which require units, than production capacity of territories with the required units"
	}
	max_units_to_be_placed := abstract_place_delegate_get_max_units_to_be_placed(self, units, to, player)
	if max_units_to_be_placed != -1 && max_units_to_be_placed < i32(len(units)) {
		return fmt.aprintf("Cannot place %d more units in %s", len(units), territory_to_string(to))
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#canUnitsBePlaced(Territory,Collection,GamePlayer)
// Returns Optional.empty() if the units can be placed in `to`; otherwise an error.
abstract_place_delegate_can_units_be_placed :: proc(
	self:   ^Abstract_Place_Delegate,
	to:     ^Territory,
	units:  [dynamic]^Unit,
	player: ^Game_Player,
) -> Maybe(string) {
	allowed_units, allowed_ok := abstract_place_delegate_get_units_to_be_placed(self, to, units, player)
	defer delete(allowed_units)
	if !allowed_ok {
		return fmt.aprintf("Cannot place these units in %s", territory_to_string(to))
	}
	// allowedUnits.containsAll(units)
	for u in units {
		found := false
		for a in allowed_units {
			if a == u {
				found = true
				break
			}
		}
		if !found {
			return fmt.aprintf("Cannot place these units in %s", territory_to_string(to))
		}
	}
	// Stacking limits over the full collection.
	existing_at_to: [dynamic]^Unit
	if existing, ok := self.produced[to]; ok {
		existing_at_to = make([dynamic]^Unit)
		for u in existing {
			append(&existing_at_to, u)
		}
	} else {
		existing_at_to = make([dynamic]^Unit)
	}
	defer delete(existing_at_to)
	filtered_units := unit_stacking_limit_filter_filter_units(
		units,
		UNIT_STACKING_LIMIT_FILTER_PLACEMENT_LIMIT,
		player,
		to,
		existing_at_to,
	)
	defer delete(filtered_units)
	if len(units) != len(filtered_units) {
		return fmt.aprintf("Cannot place these units in %s", territory_to_string(to))
	}
	construction_map := abstract_place_delegate_how_many_of_each_construction_can_place(self, to, to, units, player)
	defer delete(construction_map)
	for current_unit in units {
		if !matches_pred_unit_is_construction(nil, current_unit) {
			continue
		}
		ua := unit_get_unit_attachment(current_unit)
		ct := unit_attachment_get_construction_type(ua)
		construction_map[ct] = construction_map[ct] - 1
	}
	for _, v in construction_map {
		if v < 0 {
			return fmt.aprintf("Too many constructions in %s", territory_to_string(to))
		}
	}
	data := abstract_delegate_get_data(&self.abstract_delegate)
	capitals_list_owned := territory_attachment_get_all_currently_owned_capitals(player, game_data_get_map(data))
	defer delete(capitals_list_owned)
	to_in_capitals := false
	for c in capitals_list_owned {
		if c == to {
			to_in_capitals = true
			break
		}
	}
	if !to_in_capitals && abstract_place_delegate_is_placement_in_capital_restricted(player) {
		return "Cannot place these units outside of the capital"
	}
	if territory_is_water(to) {
		can_land := abstract_place_delegate_validate_new_air_can_land_on_carriers(to, units)
		if _, has := can_land.?; has {
			return can_land
		}
	} else {
		// make sure we own the territory
		if !territory_is_owned_by(to, player) {
			if game_step_properties_helper_is_bid(data) {
				pa := player_attachment_get(territory_get_owner(to))
				gives_control := false
				if pa != nil {
					for gp in player_attachment_get_give_unit_control(pa) {
						if gp == player {
							gives_control = true
							break
						}
					}
				}
				if !gives_control {
					owned_p, owned_c := matches_unit_is_owned_by(player)
					any_owned := false
					for u in to.unit_collection.units {
						if owned_p(owned_c, u) {
							any_owned = true
							break
						}
					}
					free(owned_c)
					if !any_owned {
						return abstract_place_delegate_get_error_message_you_do_not_own(to)
					}
				}
			} else {
				return abstract_place_delegate_get_error_message_you_do_not_own(to)
			}
		}
		// make sure all units are land
		if len(units) == 0 {
			return "Can't place sea units on land"
		}
		all_not_sea := true
		for u in units {
			if !matches_pred_unit_is_not_sea(nil, u) {
				all_not_sea = false
				break
			}
		}
		if !all_not_sea {
			return "Can't place sea units on land"
		}
	}
	// make sure we can place consuming units
	if !abstract_place_delegate_can_we_consume_units(self, units, to, nil) {
		return "Not Enough Units To Upgrade or Be Consumed"
	}
	// no further restrictions if game disables them
	if !abstract_place_delegate_has_unit_placement_restrictions(self) {
		return nil
	}
	territory_production := territory_attachment_static_get_production(to)
	for current_unit in units {
		ua := unit_get_unit_attachment(current_unit)
		required_production := unit_attachment_get_can_only_be_placed_in_territory_valued_at_x(ua)
		if required_production != -1 && required_production > territory_production {
			return fmt.aprintf(
				"Cannot place these units in %s due to Unit Placement Restrictions on Territory Value",
				territory_to_string(to),
			)
		}
		if unit_attachment_unit_placement_restrictions_contain(ua, to) {
			return fmt.aprintf(
				"Cannot place these units in %s due to Unit Placement Restrictions",
				territory_to_string(to),
			)
		}
		only_orig_p, only_orig_c := matches_unit_can_only_place_in_original_territories()
		if only_orig_p(only_orig_c, current_unit) {
			orig_p, orig_c := matches_territory_is_originally_owned_by(player)
			is_orig := orig_p(orig_c, to)
			free(orig_c)
			if !is_orig {
				return fmt.aprintf(
					"Cannot place these units in %s as territory is not originally owned",
					territory_to_string(to),
				)
			}
		}
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#getPlaceableUnits(Collection,Territory)
// Java:
//   final Optional<String> error = canProduce(to, units, player);
//   if (error.isPresent()) return new PlaceableUnits(error.get());
//   final Collection<Unit> placeableUnits = getUnitsToBePlaced(to, units, player);
//   final int maxUnits = getMaxUnitsToBePlaced(placeableUnits, to, player);
//   return new PlaceableUnits(placeableUnits, maxUnits);
abstract_place_delegate_get_placeable_units :: proc(
	self:  ^Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	to:    ^Territory,
) -> ^Placeable_Units {
	result := new(Placeable_Units)
	error := abstract_place_delegate_can_produce_to(self, to, units, self.player)
	if msg, has := error.?; has {
		placeable_units_init_error(result, msg)
		return result
	}
	placeable_units, _ := abstract_place_delegate_get_units_to_be_placed(self, to, units, self.player)
	max_units := abstract_place_delegate_get_max_units_to_be_placed(self, placeable_units, to, self.player)
	placeable_units_init_units(result, placeable_units, max_units)
	return result
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#isValidPlacement(Collection,Territory,GamePlayer)
// Java body translated 1:1: chains the placement validation predicates and
// returns the first error message encountered, or nil if every check passes.
abstract_place_delegate_is_valid_placement :: proc(
	self:   ^Abstract_Place_Delegate,
	units:  [dynamic]^Unit,
	at:     ^Territory,
	player: ^Game_Player,
) -> Maybe(string) {
	// do we hold enough units
	error := abstract_place_delegate_player_has_enough_units(units, player)
	if _, has := error.?; has {
		return error
	}
	// can we produce that much
	error = abstract_place_delegate_can_produce_to(self, at, units, player)
	if _, has := error.?; has {
		return error
	}
	// can we produce that much
	error = abstract_place_delegate_check_production(self, at, units, player)
	if _, has := error.?; has {
		return error
	}
	// can we place it
	return abstract_place_delegate_can_units_be_placed(self, at, units, player)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#placeUnits(java.util.Collection,games.strategy.engine.data.Territory)
// Greedy placement: validates, sorts producers by best-producer comparator,
// then walks producers consuming units up to each producer's max. Reports
// "Not enough unit production territories available" via the bridge display
// channel when units remain unplaced, and plays the appropriate placement
// sound clip. Returns Optional.empty() on success; any earlier validation
// error short-circuits and is returned as-is.
abstract_place_delegate_place_units :: proc(
	self:  ^Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	at:    ^Territory,
) -> Maybe(string) {
	if len(units) == 0 {
		return nil
	}
	error := abstract_place_delegate_is_valid_placement(self, units, at, self.player)
	if _, has := error.?; has {
		return error
	}
	producers := abstract_place_delegate_get_all_producers(self, at, self.player, units, false)
	cmp_fn, cmp_ctx := abstract_place_delegate_get_best_producer_comparator(self, at, units, self.player)
	for i := 1; i < len(producers); i += 1 {
		j := i
		for j > 0 && cmp_fn(cmp_ctx, producers[j], producers[j - 1]) < 0 {
			tmp := producers[j]
			producers[j] = producers[j - 1]
			producers[j - 1] = tmp
			j -= 1
		}
	}
	free(cmp_ctx)
	max_placeable_map := abstract_place_delegate_get_max_units_to_be_placed_map(self, units, at, self.player)
	defer free(max_placeable_map)

	// sort both producers and units so that the "to/at" territory comes first,
	// and so that all constructions come first (constructions must be produced
	// in the same territory they are going into).
	units_left_to_place := make([dynamic]^Unit)
	for u in units {
		append(&units_left_to_place, u)
	}
	construction_cmp := abstract_place_delegate_get_unit_construction_comparator()
	for i := 1; i < len(units_left_to_place); i += 1 {
		j := i
		for j > 0 && construction_cmp(units_left_to_place[j], units_left_to_place[j - 1]) < 0 {
			tmp := units_left_to_place[j]
			units_left_to_place[j] = units_left_to_place[j - 1]
			units_left_to_place[j - 1] = tmp
			j -= 1
		}
	}

	for len(units_left_to_place) > 0 && len(producers) > 0 {
		// Get next producer territory
		producer := producers[0]
		ordered_remove(&producers, 0)

		max_placeable := integer_map_get_int(max_placeable_map, rawptr(producer))
		if max_placeable == 0 {
			continue
		}

		// units may have special restrictions like RequiresUnits
		units_can_be_placed_by_this_producer := make([dynamic]^Unit)
		if abstract_place_delegate_has_unit_placement_restrictions(self) {
			req_p, req_c := abstract_place_delegate_unit_which_requires_units_has_required_units(self, producer, false)
			for u in units_left_to_place {
				if req_p(req_c, u) {
					append(&units_can_be_placed_by_this_producer, u)
				}
			}
			free(req_c)
		} else {
			for u in units_left_to_place {
				append(&units_can_be_placed_by_this_producer, u)
			}
		}

		hardest_cmp := abstract_place_delegate_get_hardest_to_place_with_requires_units_restrictions()
		for i := 1; i < len(units_can_be_placed_by_this_producer); i += 1 {
			j := i
			for j > 0 && hardest_cmp(units_can_be_placed_by_this_producer[j], units_can_be_placed_by_this_producer[j - 1]) < 0 {
				tmp := units_can_be_placed_by_this_producer[j]
				units_can_be_placed_by_this_producer[j] = units_can_be_placed_by_this_producer[j - 1]
				units_can_be_placed_by_this_producer[j - 1] = tmp
				j -= 1
			}
		}
		max_for_this_producer := abstract_place_delegate_get_max_units_to_be_placed_from(
			self, producer, units_can_be_placed_by_this_producer, at, self.player,
		)
		// don't forget that -1 == infinite
		if max_for_this_producer == -1 || max_for_this_producer >= i32(len(units_can_be_placed_by_this_producer)) {
			abstract_place_delegate_perform_place_from(
				self, producer, units_can_be_placed_by_this_producer, at, self.player,
			)
			for moved in units_can_be_placed_by_this_producer {
				for i := len(units_left_to_place) - 1; i >= 0; i -= 1 {
					if units_left_to_place[i] == moved {
						ordered_remove(&units_left_to_place, i)
					}
				}
			}
			delete(units_can_be_placed_by_this_producer)
			continue
		}
		needed_extra := i32(len(units_can_be_placed_by_this_producer)) - max_for_this_producer
		if max_placeable > max_for_this_producer {
			abstract_place_delegate_free_placement_capacity(
				self, producer, needed_extra, units_can_be_placed_by_this_producer, at, self.player,
			)
			new_max_for_this_producer := abstract_place_delegate_get_max_units_to_be_placed_from(
				self, producer, units_can_be_placed_by_this_producer, at, self.player,
			)
			if new_max_for_this_producer != max_placeable && needed_extra > new_max_for_this_producer {
				panic(fmt.aprintf(
					"getMaxUnitsToBePlaced originally returned: %d, \nWhich is not the same as it is returning after using freePlacementCapacity: %d, \nFor territory: %s, Current Producer: %s",
					max_placeable,
					new_max_for_this_producer,
					default_named_get_name(&at.named_attachable.default_named),
					default_named_get_name(&producer.named_attachable.default_named),
				))
			}
		}
		// CollectionUtils.getNMatches(unitsCanBePlacedByThisProducer, maxPlaceable, it -> true)
		placed_units := make([dynamic]^Unit)
		taken: i32 = 0
		for u in units_can_be_placed_by_this_producer {
			if taken >= max_placeable {
				break
			}
			if abstract_place_delegate_lambda_place_units_1(u) {
				append(&placed_units, u)
				taken += 1
			}
		}
		abstract_place_delegate_perform_place_from(self, producer, placed_units, at, self.player)
		for moved in placed_units {
			for i := len(units_left_to_place) - 1; i >= 0; i -= 1 {
				if units_left_to_place[i] == moved {
					ordered_remove(&units_left_to_place, i)
				}
			}
		}
		delete(placed_units)
		delete(units_can_be_placed_by_this_producer)
	}
	delete(producers)

	bridge := abstract_delegate_get_bridge(&self.abstract_delegate)
	if len(units_left_to_place) > 0 {
		display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
		send_to := make([dynamic]^Game_Player)
		append(&send_to, self.player)
		exclude := make([dynamic]^Game_Player)
		i_display_report_message_to_players(
			display,
			send_to,
			exclude,
			"Not enough unit production territories available",
			"Unit Placement Canceled",
		)
		delete(send_to)
		delete(exclude)
	}
	delete(units_left_to_place)

	// play a sound
	sound := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
	infra_p, infra_c := matches_unit_is_infrastructure()
	has_infra := false
	for u in units {
		if infra_p(infra_c, u) {
			has_infra = true
			break
		}
	}
	if has_infra {
		headless_sound_channel_play_sound_for_all(sound, "placed_infrastructure", self.player)
	} else {
		sea_p, sea_c := matches_unit_is_sea()
		has_sea := false
		for u in units {
			if sea_p(sea_c, u) {
				has_sea = true
				break
			}
		}
		if has_sea {
			headless_sound_channel_play_sound_for_all(sound, "placed_sea", self.player)
		} else {
			air_p, air_c := matches_unit_is_air()
			has_air := false
			for u in units {
				if air_p(air_c, u) {
					has_air = true
					break
				}
			}
			if has_air {
				headless_sound_channel_play_sound_for_all(sound, "placed_air", self.player)
			} else {
				headless_sound_channel_play_sound_for_all(sound, "placed_land", self.player)
			}
		}
	}
	return nil
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#end()
// Java body:
//   super.end();
//   doAfterEnd();
abstract_place_delegate_end :: proc(self: ^Abstract_Place_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	abstract_place_delegate_do_after_end(self)
}

// games.strategy.triplea.delegate.AbstractPlaceDelegate#placeUnits(Collection,Territory,BidMode)
// Java body: the bidMode param is unused; delegates to placeUnits(units, at).
abstract_place_delegate_place_units_with_bid_mode :: proc(
	self:     ^Abstract_Place_Delegate,
	units:    [dynamic]^Unit,
	at:       ^Territory,
	bid_mode: I_Abstract_Place_Delegate_Bid_Mode,
) -> Maybe(string) {
	_ = bid_mode
	return abstract_place_delegate_place_units(self, units, at)
}
