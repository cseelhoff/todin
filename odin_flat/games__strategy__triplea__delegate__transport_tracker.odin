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

// games.strategy.triplea.delegate.TransportTracker#getAvailableCapacity(
//     games.strategy.engine.data.Unit)
//
// Java:
//   final UnitAttachment ua = unit.getUnitAttachment();
//   if (ua.getTransportCapacity() == -1
//       || (Properties.getPacificTheater(unit.getData().getProperties())
//           && ua.isDestroyer()
//           && !unit.getOwner().getName().equals(Constants.PLAYER_NAME_JAPANESE))) {
//     return 0;
//   }
//   final int capacity = ua.getTransportCapacity();
//   final int used = TransportUtils.getTransportCost(unit.getTransporting());
//   final int unloaded = TransportUtils.getTransportCost(unit.getUnloaded());
//   return capacity - used - unloaded;
transport_tracker_get_available_capacity :: proc(unit: ^Unit) -> i32 {
	ua := unit_get_unit_attachment(unit)
	if unit_attachment_get_transport_capacity(ua) == -1 ||
	   (properties_get_pacific_theater(game_data_get_properties(unit.game_data)) &&
			   unit_attachment_is_destroyer(ua) &&
			   unit_get_owner(unit).named.base.name != "Japanese") {
		return 0
	}
	capacity := unit_attachment_get_transport_capacity(ua)
	used := transport_utils_get_transport_cost(unit_get_transporting_no_args(unit))
	unloaded := transport_utils_get_transport_cost(unit_get_unloaded(unit))
	return capacity - used - unloaded
}

// games.strategy.triplea.delegate.TransportTracker#loadTransportChange(
//     games.strategy.engine.data.Unit, games.strategy.engine.data.Unit)
//
// Java: see TransportTracker.java. Builds a CompositeChange that records
// TRANSPORTED_BY = transport for the unit, throws if the transport already
// carries the unit, then sets LOADED_THIS_TURN on both unit and transport,
// and LOADED_AFTER_COMBAT on the transport when it was previously in combat.
transport_tracker_load_transport_change :: proc(transport: ^Unit, unit: ^Unit) -> ^Change {
	transport_tracker_assert_transport(transport)
	change := composite_change_new()
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			unit,
			rawptr(transport),
			.Transported_By,
		),
	)
	for u in unit_get_transporting_no_args(transport) {
		if u == unit {
			panic("Already carrying")
		}
	}
	b_unit_loaded := new(bool)
	b_unit_loaded^ = true
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			unit,
			rawptr(b_unit_loaded),
			.Loaded_This_Turn,
		),
	)
	b_transport_loaded := new(bool)
	b_transport_loaded^ = true
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			transport,
			rawptr(b_transport_loaded),
			.Loaded_This_Turn,
		),
	)
	if unit_get_was_in_combat(transport) {
		b_loaded_after_combat := new(bool)
		b_loaded_after_combat^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				transport,
				rawptr(b_loaded_after_combat),
				.Loaded_After_Combat,
			),
		)
	}
	return &change.change
}

// games.strategy.triplea.delegate.TransportTracker#markTransportedByForAlliedAirOnCarrier(
//     java.util.Collection, games.strategy.engine.data.GamePlayer)
//
// Java: iterate `MoveValidator.carrierMustMoveWith(units, units, player)` and
// for every (carrier, dependencies) entry append TRANSPORTED_BY = carrier
// changes for every air dependency, gathering those air units into
// `alliedAir`. The body is shared with the existing inner-loop helper
// `transport_tracker_lambda_mark_transported_by_for_allied_air_on_carrier_3`.
transport_tracker_mark_transported_by_for_allied_air_on_carrier :: proc(
	units: [dynamic]^Unit,
	player: ^Game_Player,
) -> ^Allied_Air_Transport_Change {
	change := composite_change_new()
	allied_air: [dynamic]^Unit
	mapping := move_validator_carrier_must_move_with(units, units, player)
	for carrier, dependencies in mapping {
		transport_tracker_lambda_mark_transported_by_for_allied_air_on_carrier_3(
			change,
			&allied_air,
			carrier,
			dependencies,
		)
	}
	result := new(Allied_Air_Transport_Change)
	result.change = change
	result.allied_air = allied_air
	return result
}

// games.strategy.triplea.delegate.TransportTracker#transportingAndUnloaded(
//     games.strategy.engine.data.Unit)
//
// Java:
//   final Collection<Unit> units = new ArrayList<>(transport.getTransporting());
//   units.addAll(transport.getUnloaded());
//   return units;
transport_tracker_transporting_and_unloaded :: proc(transport: ^Unit) -> [dynamic]^Unit {
	units: [dynamic]^Unit
	for u in unit_get_transporting_no_args(transport) {
		append(&units, u)
	}
	for u in unit_get_unloaded(transport) {
		append(&units, u)
	}
	return units
}

// games.strategy.triplea.delegate.TransportTracker#unloadTransportChange(
//     games.strategy.engine.data.Unit, games.strategy.engine.data.Territory, boolean)
//
// Java: see TransportTracker.java. Builds the surface-transport unload
// CompositeChange: UNLOADED_TO, in combat phase also flags
// UNLOADED_IN_COMBAT_PHASE / UNLOADED_AMPHIBIOUS on both unit and transport,
// clears TRANSPORTED_BY when not part of a dependent battle, and updates the
// transport's UNLOADED list with the newly unloaded unit.
transport_tracker_unload_transport_change :: proc(
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
	carrying := unit_get_transporting_no_args(transport)
	contains := false
	for u in carrying {
		if u == unit {
			contains = true
			break
		}
	}
	if !contains {
		panic("Not being carried")
	}
	new_unloaded: [dynamic]^Unit
	for u in unit_get_unloaded(transport) {
		append(&new_unloaded, u)
	}
	append(&new_unloaded, unit)
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			unit,
			rawptr(territory),
			.Unloaded_To,
		),
	)
	if !game_step_properties_helper_is_non_combat_move(unit.game_data, true) {
		b_unit_combat := new(bool)
		b_unit_combat^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				rawptr(b_unit_combat),
				.Unloaded_In_Combat_Phase,
			),
		)
		b_unit_amph := new(bool)
		b_unit_amph^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				rawptr(b_unit_amph),
				.Unloaded_Amphibious,
			),
		)
		b_transport_combat := new(bool)
		b_transport_combat^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				transport,
				rawptr(b_transport_combat),
				.Unloaded_In_Combat_Phase,
			),
		)
		b_transport_amph := new(bool)
		b_transport_amph^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				transport,
				rawptr(b_transport_amph),
				.Unloaded_Amphibious,
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
	box_unloaded := new([dynamic]^Unit)
	box_unloaded^ = new_unloaded
	composite_change_add(
		change,
		change_factory_unit_property_change_property_name(
			transport,
			rawptr(box_unloaded),
			.Unloaded,
		),
	)
	return &change.change
}

// games.strategy.triplea.delegate.TransportTracker#reloadTransports(
//     java.util.Collection, games.strategy.engine.data.CompositeChange)
//
// Java:
//   Collection<Unit> transports =
//       CollectionUtils.getMatches(units, Matches.unitCanTransport());
//   for (Unit transport : transports) {
//     for (Unit load : transport.getUnloaded()) {
//       Change loadChange = TransportTracker.loadTransportChange(transport, load);
//       change.add(loadChange);
//     }
//   }
// `Matches.unitCanTransport()` is a closure-style predicate (proc + ctx),
// so we filter inline rather than via `collection_utils_get_matches`
// (which only accepts plain `proc(rawptr) -> bool`).
transport_tracker_reload_transports :: proc(
	units: [dynamic]^Unit,
	change: ^Composite_Change,
) {
	can_transport_p, can_transport_c := matches_unit_can_transport()
	for transport in units {
		if transport == nil {
			continue
		}
		if !can_transport_p(can_transport_c, transport) {
			continue
		}
		for load in unit_get_unloaded(transport) {
			load_change := transport_tracker_load_transport_change(transport, load)
			composite_change_add(change, load_change)
		}
	}
}

