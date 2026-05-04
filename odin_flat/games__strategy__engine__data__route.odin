package game

import "core:fmt"
import "core:math"
import "core:slice"

Route :: struct {
	start: ^Territory,
	steps: [dynamic]^Territory,
}

// Mirrors Java Route#add(Territory) (private). Appends `territory` to the
// step list, rejecting any input that would form a loop — i.e. matches the
// route's start or is already present in steps. Java throws
// IllegalArgumentException; we panic with the same message.
route_add :: proc(self: ^Route, territory: ^Territory) {
	if territory == self.start || slice.contains(self.steps[:], territory) {
		fmt.panicf("Loops not allowed in steps, route: %v, new territory: %v", self, territory)
	}
	append(&self.steps, territory)
}

// Mirrors Java Route#anyMatch(Predicate<Territory>). Returns true iff any
// step territory satisfies the predicate. The Java implementation streams
// `steps` (excluding `start`); we mirror that exactly.
route_any_match :: proc(self: ^Route, predicate: proc(t: ^Territory) -> bool) -> bool {
	for step in self.steps {
		if predicate(step) {
			return true
		}
	}
	return false
}

// Mirrors Java Route#getEnd(). Returns the last territory in the route, or
// the start when there are no steps.
route_get_end :: proc(self: ^Route) -> ^Territory {
	if len(self.steps) == 0 {
		return self.start
	}
	return self.steps[len(self.steps) - 1]
}

// Mirrors Java Route#getMiddleSteps(): returns all step territories
// except the last one (the end). When there are 0 or 1 steps, returns
// an empty list. Java returns a subList view; we allocate a fresh
// [dynamic] copy.
route_get_middle_steps :: proc(self: ^Route) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	if len(self.steps) > 1 {
		for i in 0 ..< len(self.steps) - 1 {
			append(&result, self.steps[i])
		}
	}
	return result
}

// Mirrors Java Route#getAllTerritories(). Returns a freshly allocated list
// containing the start territory followed by every step, in order.
route_get_all_territories :: proc(self: ^Route) -> [dynamic]^Territory {
	list := make([dynamic]^Territory, 0, len(self.steps) + 1)
	append(&list, self.start)
	for t in self.steps {
		append(&list, t)
	}
	return list
}

// Mirrors Java Route#equals(Object). Two routes are equal when they have
// the same start, the same number of steps, and the same step
// territories in the same order. Java compares getAllTerritories() (start
// plus steps); given equal starts, that reduces to equal step sequences.
// Territory identity is by pointer in the Odin port.
route_equals :: proc(self: ^Route, other: ^Route) -> bool {
	if self == other {
		return true
	}
	if other == nil {
		return false
	}
	if len(self.steps) != len(other.steps) {
		return false
	}
	if self.start != other.start {
		return false
	}
	for t, i in self.steps {
		if t != other.steps[i] {
			return false
		}
	}
	return true
}


// Mirrors Java Route#allMatchMiddleSteps(Predicate<Territory>). Returns true
// iff the middle steps (every step except the last, i.e. excluding both the
// start territory and the end territory) are non-empty and every territory
// satisfies the predicate. When there are fewer than 2 steps the middle is
// empty and Java returns false; we preserve that behaviour.
route_all_match_middle_steps :: proc(self: ^Route, predicate: proc(t: ^Territory) -> bool) -> bool {
	if len(self.steps) <= 1 {
		return false
	}
	for t in self.steps[:len(self.steps) - 1] {
		if !predicate(t) {
			return false
		}
	}
	return true
}

// Mirrors Java Route#hasExactlyOneStep(): true when steps.size() == 1.
route_has_exactly_one_step :: proc(self: ^Route) -> bool {
	return len(self.steps) == 1
}

// Mirrors Java Route#getSteps(). Java returns an unmodifiable view of the
// internal `steps` list; in Odin we return a freshly allocated [dynamic]
// copy of the step territories (excluding the start).
route_get_steps :: proc(self: ^Route) -> [dynamic]^Territory {
	result := make([dynamic]^Territory, 0, len(self.steps))
	for t in self.steps {
		append(&result, t)
	}
	return result
}

// Mirrors Java Route#getTerritoryAtStep(int). Returns the territory at the
// i'th step (0-indexed into the step list).
route_get_territory_at_step :: proc(self: ^Route, i: i32) -> ^Territory {
	return self.steps[i]
}

// Mirrors Java Route#hasMoreThanOneStep(): true when steps.size() > 1.
route_has_more_than_one_step :: proc(self: ^Route) -> bool {
	return len(self.steps) > 1
}

// Mirrors Java Route#getTerritoryBeforeEnd(): returns the start territory
// when the route has 0 or 1 steps, otherwise the second-to-last step.
route_get_territory_before_end :: proc(self: ^Route) -> ^Territory {
	if len(self.steps) <= 1 {
		return self.start
	}
	return self.steps[len(self.steps) - 2]
}

// Mirrors Java Route#getMovementCost(Unit): delegates to the private static
// findMovementCost helper, walking every step territory and summing the
// per-territory movement cost for `unit`. BigDecimal → f64.
route_get_movement_cost :: proc(self: ^Route, unit: ^Unit) -> f64 {
	return route_find_movement_cost(unit, self.steps[:])
}

// Mirrors Java Route#getMovementCostIgnoreEnd(Unit): delegates to the private
// static findMovementCost helper, but excludes the final step territory (the
// route's end). When `steps` is empty, the full (empty) slice is used so the
// result is BigDecimal.ZERO → 0.
route_get_movement_cost_ignore_end :: proc(self: ^Route, unit: ^Unit) -> f64 {
	territories: []^Territory
	if len(self.steps) > 0 {
		territories = self.steps[:len(self.steps) - 1]
	} else {
		territories = self.steps[:]
	}
	return route_find_movement_cost(unit, territories)
}

// Mirrors Java Route#findMovementCost(Unit, Collection<Territory>) (private
// static). Sums TerritoryEffectHelper.getMovementCost(t, unit) over each
// territory in the collection. BigDecimal → f64; BigDecimal.ZERO → 0.
route_find_movement_cost :: proc(unit: ^Unit, territories: []^Territory) -> f64 {
	movement_cost: f64 = 0
	for t in territories {
		movement_cost += territory_effect_helper_get_movement_cost(t, unit)
	}
	return movement_cost
}

// Mirrors Java Route#hasSteps(): true when the route has at least one step
// territory (i.e. `steps` is non-empty).
route_has_steps :: proc(self: ^Route) -> bool {
	return len(self.steps) > 0
}

// Mirrors Java Route#isLoad(): true iff the route has steps, the start
// territory is land, and the end territory is water (loading from land
// into a transport at sea).
route_is_load :: proc(self: ^Route) -> bool {
	return route_has_steps(self) && !self.start.water && route_get_end(self).water
}

// Mirrors Java Route#hasNoSteps(): inverse of hasSteps — true when the
// step list is empty.
route_has_no_steps :: proc(self: ^Route) -> bool {
	return !route_has_steps(self)
}

// Mirrors Java Route#numberOfSteps(): returns the number of step
// territories in this route (does not include the start).
route_number_of_steps :: proc(self: ^Route) -> i32 {
	return i32(len(self.steps))
}

// Mirrors Java Route#isUnload(): true when the route has at least one step
// and the start territory is water while the end territory is not. Used by
// movement validation to detect transport-to-land unload routes.
route_is_unload :: proc(self: ^Route) -> bool {
	return route_has_steps(self) && self.start.water && !route_get_end(self).water
}

// Mirrors Java Route#iterator() (from Iterable<Territory>):
//     return getAllTerritories().iterator();
// Java returns an Iterator over the start-plus-steps list. The Odin port
// follows the same convention as `game_map_iterator` /
// `player_list_iterator` and surfaces the freshly allocated snapshot
// directly — callers iterate with `for t in route_iterator(r)`.
route_iterator :: proc(self: ^Route) -> [dynamic]^Territory {
	return route_get_all_territories(self)
}

// Mirrors Java Route#getStart() (Lombok @Getter on `private final Territory
// start`). Returns the route's start territory.
route_get_start :: proc(self: ^Route) -> ^Territory {
	return self.start
}

// Mirrors Java Route(Territory start, List<Territory> territories): the
// primary constructor. Heap-allocates a new Route, sets `start`, then
// appends each territory via route_add (which rejects loops the same way
// the Java helper does).
route_new :: proc(start: ^Territory, territories: [dynamic]^Territory) -> ^Route {
	r := new(Route)
	r.start = start
	for t in territories {
		route_add(r, t)
	}
	return r
}

// Mirrors Java Route#hasLand(): true iff some territory in the route
// (start + steps) is land. Java implementation:
//     return !getStart().isWater() || !steps.stream().allMatch(Matches.territoryIsWater());
// i.e. the start is land, or at least one step is non-water.
route_has_land :: proc(self: ^Route) -> bool {
	if !territory_is_water(self.start) {
		return true
	}
	for step in self.steps {
		if !territory_is_water(step) {
			return true
		}
	}
	return false
}

// Mirrors Java Route#hasWater(): true iff some territory in the route
// (start + steps) is water. Java implementation:
//     return getStart().isWater() || steps.stream().anyMatch(Matches.territoryIsWater());
route_has_water :: proc(self: ^Route) -> bool {
	if territory_is_water(self.start) {
		return true
	}
	for step in self.steps {
		if territory_is_water(step) {
			return true
		}
	}
	return false
}

// Mirrors Java Route(Territory start, Territory... territories): the
// varargs constructor that delegates to `this(start, List.of(territories))`.
// In Odin we accept a slice of step territories and append each via
// route_add (which rejects loops with the same panic the private add does).
route_new_from_start_and_steps :: proc(start: ^Territory, territories: ..^Territory) -> ^Route {
	r := new(Route)
	r.start = start
	for t in territories {
		route_add(r, t)
	}
	return r
}

// Mirrors Java Route(List<Territory> territories): delegating constructor
// equivalent to `this(territories.get(0), territories.subList(1, size))`.
// First element becomes the start; remaining elements are added as steps.
route_new_from_list :: proc(territories: [dynamic]^Territory) -> ^Route {
	r := new(Route)
	r.start = territories[0]
	for i in 1 ..< len(territories) {
		route_add(r, territories[i])
	}
	return r
}

// Mirrors Java Route#getMatches(Predicate<Territory>):
//     return CollectionUtils.getMatches(steps, match);
// Returns a freshly allocated [dynamic] containing every step territory
// (excluding the start) for which `predicate` returns true, preserving
// order.
route_get_matches :: proc(self: ^Route, predicate: proc(t: ^Territory) -> bool) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	for t in self.steps {
		if predicate(t) {
			append(&result, t)
		}
	}
	return result
}

// Mirrors Java Route#hasNeutralBeforeEnd(): true iff some middle step
// (every step except the last) is non-water and owned by the null player.
// Java:
//     for (Territory current : getMiddleSteps()) {
//       if (!current.isWater() && current.getOwner().isNull()) return true;
//     }
//     return false;
route_has_neutral_before_end :: proc(self: ^Route) -> bool {
	middle := route_get_middle_steps(self)
	defer delete(middle)
	for current in middle {
		if !territory_is_water(current) && game_player_is_null(territory_get_owner(current)) {
			return true
		}
	}
	return false
}

// Mirrors Java Route#getFuelCostsAndIfChargedFlatFuelCost(Unit, GameData,
// boolean) (private). Returns the per-unit fuel resource charge and a
// boolean indicating whether the flat fuel cost was applied. Java:
//   final ResourceCollection resources = new ResourceCollection(data);
//   if (Matches.unitIsBeingTransported().test(unit)) return Tuple.of(resources, false);
//   final UnitAttachment ua = unit.getUnitAttachment();
//   resources.add(ua.getFuelCost());
//   resources.multiply(getMovementCost(unit).setScale(0, CEILING).intValue());
//   boolean chargedFlatFuelCost = false;
//   if (!ignoreFlat && Matches.unitHasNotBeenChargedFlatFuelCost().test(unit)) {
//     resources.add(ua.getFuelFlatCost());
//     chargedFlatFuelCost = true;
//   }
//   return Tuple.of(resources, chargedFlatFuelCost);
// BigDecimal#setScale(0, CEILING).intValue() → i32(math.ceil(f64)).
route_get_fuel_costs_and_if_charged_flat_fuel_cost :: proc(
	self: ^Route,
	unit: ^Unit,
	data: ^Game_Data,
	ignore_flat: bool,
) -> (
	^Resource_Collection,
	bool,
) {
	resources := resource_collection_new(data)
	transported_pred, transported_ctx := matches_unit_is_being_transported()
	if transported_pred(transported_ctx, unit) {
		return resources, false
	}
	ua := unit_get_unit_attachment(unit)
	fuel_cost := unit_attachment_get_fuel_cost(ua)
	resource_collection_add_integer_map(resources, &fuel_cost)
	resource_collection_multiply(resources, i32(math.ceil(route_get_movement_cost(self, unit))))
	charged_flat_fuel_cost := false
	flat_pred, flat_ctx := matches_unit_has_not_been_charged_flat_fuel_cost()
	if !ignore_flat && flat_pred(flat_ctx, unit) {
		fuel_flat_cost := unit_attachment_get_fuel_flat_cost(ua)
		resource_collection_add_integer_map(resources, &fuel_flat_cost)
		charged_flat_fuel_cost = true
	}
	return resources, charged_flat_fuel_cost
}

// Mirrors Java Route#getFuelCostsAndUnitsChargedFlatFuelCost(
//     Collection<Unit>, Route, GamePlayer, GameData, boolean) (private
// static). Returns the aggregate movement-charge ResourceCollection and
// the set of units charged a flat fuel cost. Java:
//   if (!Properties.getUseFuelCost(data.getProperties())) {
//     return Tuple.of(new ResourceCollection(data), new HashSet<>());
//   }
//   final Set<Unit> unitsToChargeFuelCosts = new HashSet<>(units);
//   if (GameStepPropertiesHelper.isNonCombatMove(data, true)) {
//     // allied (not owned) air that can land on carrier first, then owned
//     final List<Unit> canLandOnCarrierUnits = ...;
//     unitsToChargeFuelCosts.removeAll(
//         AirMovementValidator.whatAirCanLandOnTheseCarriers(
//             carriers, canLandOnCarrierUnits, route.getStart()));
//   }
//   unitsToChargeFuelCosts.removeAll(
//       CollectionUtils.getMatches(units,
//           Matches.unitIsBeingTransportedByOrIsDependentOfSomeUnitInThisList(
//               units, player, true)));
//   final ResourceCollection movementCharge = new ResourceCollection(data);
//   final Set<Unit> unitsChargedFlatFuelCost = new HashSet<>();
//   for (final Unit unit : unitsToChargeFuelCosts) {
//     final Tuple<ResourceCollection, Boolean> tuple =
//         route.getFuelCostsAndIfChargedFlatFuelCost(unit, data, ignoreFlat);
//     movementCharge.add(tuple.getFirst());
//     if (tuple.getSecond()) unitsChargedFlatFuelCost.add(unit);
//   }
//   return Tuple.of(movementCharge, unitsChargedFlatFuelCost);
route_get_fuel_costs_and_units_charged_flat_fuel_cost :: proc(
	units: []^Unit,
	route: ^Route,
	player: ^Game_Player,
	data: ^Game_Data,
	ignore_flat: bool,
) -> (
	^Resource_Collection,
	[dynamic]^Unit,
) {
	if !properties_get_use_fuel_cost(game_data_get_properties(data)) {
		empty: [dynamic]^Unit
		return resource_collection_new(data), empty
	}

	units_to_charge: [dynamic]^Unit
	for u in units {
		append(&units_to_charge, u)
	}

	// If non-combat then remove air units moving with a carrier.
	if game_step_properties_helper_is_non_combat_move(data, true) {
		owned_pred, owned_ctx := matches_unit_is_owned_by(player)
		allied_pred, allied_ctx := matches_is_unit_allied(player)
		can_land_pred, can_land_ctx := matches_unit_can_land_on_carrier()
		is_carrier_pred, is_carrier_ctx := matches_unit_is_carrier()

		// Add allied air first so carriers consider them before owned air.
		can_land_on_carrier_units: [dynamic]^Unit
		for u in units {
			if !owned_pred(owned_ctx, u) &&
			   allied_pred(allied_ctx, u) &&
			   can_land_pred(can_land_ctx, u) {
				append(&can_land_on_carrier_units, u)
			}
		}
		for u in units {
			if owned_pred(owned_ctx, u) && can_land_pred(can_land_ctx, u) {
				append(&can_land_on_carrier_units, u)
			}
		}

		carriers: [dynamic]^Unit
		for u in units {
			if is_carrier_pred(is_carrier_ctx, u) {
				append(&carriers, u)
			}
		}

		air_landing := air_movement_validator_what_air_can_land_on_these_carriers(
			carriers[:],
			can_land_on_carrier_units[:],
			route_get_start(route),
		)
		filtered: [dynamic]^Unit
		for u in units_to_charge {
			if !slice.contains(air_landing[:], u) {
				append(&filtered, u)
			}
		}
		units_to_charge = filtered
	}

	// Remove dependent units.
	units_dyn: [dynamic]^Unit
	for u in units {
		append(&units_dyn, u)
	}
	dep_pred, dep_ctx :=
		matches_unit_is_being_transported_by_or_is_dependent_of_some_unit_in_this_list(
			units_dyn,
			player,
			true,
		)
	dependents: [dynamic]^Unit
	for u in units {
		if dep_pred(dep_ctx, u) {
			append(&dependents, u)
		}
	}
	if len(dependents) > 0 {
		filtered: [dynamic]^Unit
		for u in units_to_charge {
			if !slice.contains(dependents[:], u) {
				append(&filtered, u)
			}
		}
		units_to_charge = filtered
	}

	// Sum per-unit fuel cost and collect units charged the flat cost.
	movement_charge := resource_collection_new(data)
	units_charged_flat_fuel_cost: [dynamic]^Unit
	for u in units_to_charge {
		per_unit, charged_flat := route_get_fuel_costs_and_if_charged_flat_fuel_cost(
			route,
			u,
			data,
			ignore_flat,
		)
		resource_collection_add(movement_charge, per_unit)
		if charged_flat {
			append(&units_charged_flat_fuel_cost, u)
		}
	}
	return movement_charge, units_charged_flat_fuel_cost
}
