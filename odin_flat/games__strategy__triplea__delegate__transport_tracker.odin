package game

Transport_Tracker :: struct {}

Allied_Air_Transport_Change :: struct {
	change:     ^Composite_Change,
	allied_air: [dynamic]^Unit,
}

transport_tracker_get_territory_transport_has_unloaded_to :: proc(transport: ^Unit) -> ^Territory {
	unloaded := unit_get_unloaded(transport)
	if len(unloaded) == 0 {
		return nil
	}
	return unit_get_unloaded_to(unloaded[0])
}

transport_tracker_transporting_with_fn :: proc(
	units: [dynamic]^Unit,
	get_units_transported_by_transport: proc(transport: ^Unit) -> [dynamic]^Unit,
) -> map[^Unit][dynamic]^Unit {
	return_val: map[^Unit][dynamic]^Unit
	for transported in units {
		transport := unit_get_transported_by(transported)
		if transport != nil {
			transporting := get_units_transported_by_transport(transport)
			return_val[transport] = transporting
		}
	}
	return return_val
}

// games.strategy.triplea.delegate.TransportTracker#transporting(java.util.Collection)
//
// Java:
//   public static Map<Unit, Collection<Unit>> transporting(Collection<Unit> units) {
//     return transporting(units, Unit::getTransporting);
//   }
// The Java private helper inserts (transport -> transport.getTransporting())
// for each transported unit whose `transportedBy` is non-null. We mirror that
// loop directly here. `Unit#getTransporting()` (the no-arg form) locates the
// territory currently containing the transport in its `GameData` and returns
// `unit_get_transporting_in_territory(transport, t)` for that territory; we
// inline that lookup since the no-arg method is not yet ported.
transport_tracker_transporting :: proc(
	units: [dynamic]^Unit,
) -> map[^Unit][dynamic]^Unit {
	return_val: map[^Unit][dynamic]^Unit
	for transported in units {
		if transported == nil {
			continue
		}
		transport := unit_get_transported_by(transported)
		if transport == nil {
			continue
		}
		if transport.game_data == nil {
			continue
		}
		gmap := game_data_get_map(transport.game_data)
		if gmap == nil {
			continue
		}
		for t in gmap.territories {
			if t == nil || t.unit_collection == nil {
				continue
			}
			contains := false
			for u in t.unit_collection.units {
				if u == transport {
					contains = true
					break
				}
			}
			if contains {
				return_val[transport] = unit_get_transporting_in_territory(transport, t)
				break
			}
		}
	}
	return return_val
}

// games.strategy.triplea.delegate.TransportTracker#transportingInTerritory(
//     java.util.Collection, games.strategy.engine.data.Territory)
//
// Java: identical to `transporting(Collection)` except the lambda
// `transport -> transport.getTransporting(territory)` is passed in, so the
// transported set is restricted to units in `territory`.
transport_tracker_transporting_in_territory :: proc(
	units: [dynamic]^Unit,
	territory: ^Territory,
) -> map[^Unit][dynamic]^Unit {
	return_val: map[^Unit][dynamic]^Unit
	for transported in units {
		if transported == nil {
			continue
		}
		transport := unit_get_transported_by(transported)
		if transport == nil {
			continue
		}
		return_val[transport] = unit_get_transporting_in_territory(transport, territory)
	}
	return return_val
}

// games.strategy.triplea.delegate.TransportTracker#transportingWithAllPossibleUnits(
//     java.util.Collection)
//
// Java: identical to `transporting(Collection)` except the lambda
// `transport -> transport.getTransporting(units)` restricts the transported
// candidates to the input collection.
transport_tracker_transporting_with_all_possible_units :: proc(
	units: [dynamic]^Unit,
) -> map[^Unit][dynamic]^Unit {
	return_val: map[^Unit][dynamic]^Unit
	for transported in units {
		if transported == nil {
			continue
		}
		transport := unit_get_transported_by(transported)
		if transport == nil {
			continue
		}
		return_val[transport] = unit_get_transporting(transport, units)
	}
	return return_val
}

// games.strategy.triplea.delegate.TransportTracker#getUnitsLoadedOnAlliedTransportsThisTurn(
//     java.util.Collection)
//
// Java: returns units that were loaded this turn onto a transport owned by a
// different (allied) player.
transport_tracker_get_units_loaded_on_allied_transports_this_turn :: proc(
	units: [dynamic]^Unit,
) -> [dynamic]^Unit {
	loaded_units: [dynamic]^Unit
	for unit in units {
		if unit == nil {
			continue
		}
		transport := unit_get_transported_by(unit)
		if unit.was_loaded_this_turn &&
		   transport != nil &&
		   !unit_is_owned_by(transport, unit_get_owner(unit)) {
			append(&loaded_units, unit)
		}
	}
	return loaded_units
}

// games.strategy.triplea.delegate.TransportTracker#assertTransport(Unit)
//
// Java:
//   private static void assertTransport(final Unit u) {
//     if (u.getUnitAttachment().getTransportCapacity() == -1) {
//       throw new IllegalStateException("Not a transport: " + u);
//     }
//   }
transport_tracker_assert_transport :: proc(u: ^Unit) {
	ua := unit_get_unit_attachment(u)
	if unit_attachment_get_transport_capacity(ua) == -1 {
		panic("Not a transport")
	}
}

// games.strategy.triplea.delegate.TransportTracker#lambda$transportingWithAllPossibleUnits$0(
//     java.util.Collection, games.strategy.engine.data.Unit)
//
// Java: `transport -> transport.getTransporting(units)` — captures the input
// `units` collection and passes it to `Unit#getTransporting(Collection)`.
transport_tracker_lambda_transporting_with_all_possible_units_0 :: proc(
	units: [dynamic]^Unit,
	transport: ^Unit,
) -> [dynamic]^Unit {
	return unit_get_transporting(transport, units)
}

// games.strategy.triplea.delegate.TransportTracker#lambda$markTransportedByForAlliedAirOnCarrier$3(
//     CompositeChange, java.util.Collection, Unit, java.util.Collection)
//
// Java: BiConsumer body for `MoveValidator.carrierMustMoveWith(...).forEach(
//   (carrier, dependencies) -> { ... })`. Captures `change` and `alliedAir`.
//   For each carrier, if its carrier capacity is -1, skip; otherwise iterate
//   the dependencies, retain only air units, and for each air unit append a
//   `TRANSPORTED_BY = carrier` change and add it to `alliedAir`.
transport_tracker_lambda_mark_transported_by_for_allied_air_on_carrier_3 :: proc(
	change: ^Composite_Change,
	allied_air: ^[dynamic]^Unit,
	carrier: ^Unit,
	dependencies: [dynamic]^Unit,
) {
	ua := unit_get_unit_attachment(carrier)
	if unit_attachment_get_carrier_capacity(ua) == -1 {
		return
	}
	air_pred, air_ctx := matches_unit_is_air()
	prop := Unit_Property_Name.Transported_By
	for air_unit in dependencies {
		if air_unit == nil {
			continue
		}
		if !air_pred(air_ctx, air_unit) {
			continue
		}
		composite_change_add(
			change,
			change_factory_unit_property_change(
				air_unit,
				rawptr(carrier),
				unit_property_name_to_string(&prop),
			),
		)
		append(allied_air, air_unit)
	}
}

// games.strategy.triplea.delegate.TransportTracker#hasTransportUnloadedInPreviousPhase(Unit)
//
// Java:
//   return GameStepPropertiesHelper.isNonCombatMove(transport.getData(), true)
//          && transport.getUnloaded().stream().anyMatch(Unit::getWasUnloadedInCombatPhase);
transport_tracker_has_transport_unloaded_in_previous_phase :: proc(transport: ^Unit) -> bool {
	if !game_step_properties_helper_is_non_combat_move(transport.game_data, true) {
		return false
	}
	for u in unit_get_unloaded(transport) {
		if u != nil && unit_get_was_unloaded_in_combat_phase(u) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.TransportTracker#isTransportLoadRestrictedAfterCombat(Unit)
//
// Java:
//   final GameData data = transport.getData();
//   return (Properties.getWW2V3(data.getProperties())
//           || Properties.getLhtrCarrierProductionRules(data.getProperties()))
//        && GameStepPropertiesHelper.isNonCombatMove(data, true)
//        && transport.getWasInCombat();
transport_tracker_is_transport_load_restricted_after_combat :: proc(transport: ^Unit) -> bool {
	data := transport.game_data
	props := game_data_get_properties(data)
	return (properties_get_ww2_v3(props) ||
		properties_get_lhtr_carrier_production_rules(props)) &&
		game_step_properties_helper_is_non_combat_move(data, true) &&
		unit_get_was_in_combat(transport)
}

// games.strategy.triplea.delegate.TransportTracker#isTransportUnloadRestrictedInNonCombat(Unit)
//
// Java:
//   return GameStepPropertiesHelper.isNonCombatMove(transport.getData(), true)
//          && transport.getWasInCombat()
//          && transport.getWasLoadedAfterCombat();
transport_tracker_is_transport_unload_restricted_in_non_combat :: proc(transport: ^Unit) -> bool {
	return game_step_properties_helper_is_non_combat_move(transport.game_data, true) &&
		unit_get_was_in_combat(transport) &&
		unit_get_was_loaded_after_combat(transport)
}

// games.strategy.triplea.delegate.TransportTracker#isTransportUnloadRestrictedToAnotherTerritory(
//     Unit, Territory)
//
// Java: returns true if any already-unloaded unit went to a territory other
// than `territory`. Under WW2V2 / TransportUnloadRestricted rules the check
// applies in any phase; otherwise only in the combat phase.
transport_tracker_is_transport_unload_restricted_to_another_territory :: proc(
	transport: ^Unit,
	territory: ^Territory,
) -> bool {
	unloaded := unit_get_unloaded(transport)
	if len(unloaded) == 0 {
		return false
	}
	data := cast(^Game_State)transport.game_data
	props := game_state_get_properties(data)
	for unit in unloaded {
		if unit == nil {
			continue
		}
		if properties_get_ww2_v2(props) ||
		   properties_get_transport_unload_restricted(props) {
			if unit_get_unloaded_to(unit) != territory {
				return true
			}
		} else {
			if !game_step_properties_helper_is_non_combat_move(transport.game_data, true) &&
			   unit_get_unloaded_to(unit) != territory {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.TransportTracker#unloadAirTransportChange(
//     Unit, Territory, boolean)
//
// Java: builds a CompositeChange that records a UNLOADED_TO change for the
// air-transported unit; in combat phase also flags both unit and transport
// as unloaded-in-combat-phase; if not part of a dependent battle, clears
// the unit's TRANSPORTED_BY. Unlike the surface variant, the Java code
// deliberately does NOT update the transport's UNLOADED list.
transport_tracker_unload_air_transport_change :: proc(
	unit: ^Unit,
	territory: ^Territory,
	dependent_battle: bool,
) -> ^Change {
	change := composite_change_new()
	transport := unit_get_transported_by(unit)
	if transport == nil {
		return &change.change
	}
	transport_tracker_assert_transport(transport)
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			unit,
			rawptr(territory),
			.Unloaded_To,
		),
	)
	if !game_step_properties_helper_is_non_combat_move(unit.game_data, true) {
		boxed_unit := new(bool)
		boxed_unit^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				rawptr(boxed_unit),
				.Unloaded_In_Combat_Phase,
			),
		)
		boxed_transport := new(bool)
		boxed_transport^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				transport,
				rawptr(boxed_transport),
				.Unloaded_In_Combat_Phase,
			),
		)
	}
	if !dependent_battle {
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				nil,
				.Transported_By,
			),
		)
	}
	return &change.change
}

// games.strategy.triplea.delegate.TransportTracker#clearTransportedByForAlliedAirOnCarrier(
//     Collection<Unit>, Territory, GamePlayer, GameState)
//
// Java: when allied-air-independent is OFF and there are carriers among the
// attacking units, find every allied (non-owned-by-attacker) air unit that
// can land on a carrier — drawn from both the attackingUnits set and the
// battleSite's own unit collection — and clear `TRANSPORTED_BY` on those
// fighters whose transporting carrier does NOT have the
// UNITS_MAY_NOT_LEAVE_ALLIED_CARRIER combat-damaged effect.
transport_tracker_clear_transported_by_for_allied_air_on_carrier :: proc(
	attacking_units: [dynamic]^Unit,
	battle_site: ^Territory,
	attacker: ^Game_Player,
	data: ^Game_State,
) -> ^Composite_Change {
	change := composite_change_new()
	carrier_pred, carrier_ctx := matches_unit_is_carrier()
	carriers: [dynamic]^Unit
	for u in attacking_units {
		if u != nil && carrier_pred(carrier_ctx, u) {
			append(&carriers, u)
		}
	}
	if len(carriers) == 0 {
		return change
	}
	if properties_get_allied_air_independent(game_state_get_properties(data)) {
		return change
	}
	allied_pred, allied_ctx := matches_is_unit_allied(attacker)
	owned_pred, owned_ctx := matches_unit_is_owned_by(attacker)
	air_pred, air_ctx := matches_unit_is_air()
	land_pred, land_ctx := matches_unit_can_land_on_carrier()
	leave_filter_pred, leave_filter_ctx := matches_unit_has_when_combat_damaged_effect_filter(
		"unitsMayNotLeaveAlliedCarrier",
	)
	is_allied_fighter :: proc(
		unit: ^Unit,
		allied_pred: proc(rawptr, ^Unit) -> bool,
		allied_ctx: rawptr,
		owned_pred: proc(rawptr, ^Unit) -> bool,
		owned_ctx: rawptr,
		air_pred: proc(rawptr, ^Unit) -> bool,
		air_ctx: rawptr,
		land_pred: proc(rawptr, ^Unit) -> bool,
		land_ctx: rawptr,
	) -> bool {
		return allied_pred(allied_ctx, unit) &&
			!owned_pred(owned_ctx, unit) &&
			air_pred(air_ctx, unit) &&
			land_pred(land_ctx, unit)
	}
	// Build the union (Sets.union(attackingUnits, battleSite.getUnitCollection())).
	seen: map[^Unit]struct{}
	candidates: [dynamic]^Unit
	for u in attacking_units {
		if u == nil {
			continue
		}
		if _, exists := seen[u]; exists {
			continue
		}
		seen[u] = {}
		append(&candidates, u)
	}
	uc := territory_get_unit_collection(battle_site)
	if uc != nil {
		for u in unit_collection_get_units(uc) {
			if u == nil {
				continue
			}
			if _, exists := seen[u]; exists {
				continue
			}
			seen[u] = {}
			append(&candidates, u)
		}
	}
	for fighter in candidates {
		if !is_allied_fighter(
			fighter,
			allied_pred, allied_ctx,
			owned_pred, owned_ctx,
			air_pred, air_ctx,
			land_pred, land_ctx,
		) {
			continue
		}
		carrier_transporting := unit_get_transported_by(fighter)
		if carrier_transporting == nil {
			continue
		}
		if !leave_filter_pred(leave_filter_ctx, carrier_transporting) {
			composite_change_add(
				change,
				change_factory_unit_property_change_property_name(
					fighter,
					nil,
					.Transported_By,
				),
			)
		}
	}
	return change
}

// games.strategy.triplea.delegate.TransportTracker#lambda$transportingInTerritory$1(
//     Territory, Unit)
//
// Java lambda body: `transport -> transport.getTransporting(territory)`.
transport_tracker_lambda_transporting_in_territory_1 :: proc(
	territory: ^Territory,
	transport: ^Unit,
) -> [dynamic]^Unit {
	return unit_get_transporting_in_territory(transport, territory)
}

// games.strategy.triplea.delegate.TransportTracker#lambda$markTransportedByForAlliedAirOnCarrier$2(
//     CompositeChange, Unit, Collection, Unit)
//
// Java: the inner `airUnit -> { ... }` Consumer in the carrier-must-move-with
// forEach. Captures the outer `change` (CompositeChange), the carrier, and
// the `alliedAir` collection; for each filtered air dependency it appends a
// `TRANSPORTED_BY = carrier` change and adds the unit to alliedAir.
transport_tracker_lambda_mark_transported_by_for_allied_air_on_carrier_2 :: proc(
	change: ^Composite_Change,
	carrier: ^Unit,
	allied_air: ^[dynamic]^Unit,
	air_unit: ^Unit,
) {
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			air_unit,
			rawptr(carrier),
			.Transported_By,
		),
	)
	append(allied_air, air_unit)
}

