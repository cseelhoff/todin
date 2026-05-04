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
