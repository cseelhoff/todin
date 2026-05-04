package game

// Java owners covered by this file:
//   - games.strategy.triplea.UnitUtils

Unit_Utils :: struct {}

unit_utils_get_unit_types_from_unit_list :: proc(units: [dynamic]^Unit) -> map[^Unit_Type]struct{} {
	result: map[^Unit_Type]struct{}
	for unit in units {
		result[unit_get_type(unit)] = struct{}{}
	}
	return result
}

// public static @Nullable GamePlayer findPlayerWithMostUnits(final Iterable<Unit> units)
unit_utils_find_player_with_most_units :: proc(units: [dynamic]^Unit) -> ^Game_Player {
	player_unit_count := integer_map_new()
	for unit in units {
		integer_map_add(player_unit_count, rawptr(unit_get_owner(unit)), 1)
	}
	max: i32 = -1
	player: ^Game_Player = nil
	for current in integer_map_key_set(player_unit_count) {
		count := integer_map_get_int(player_unit_count, current)
		if count > max {
			max = count
			player = (^Game_Player)(current)
		}
	}
	return player
}

// Helper: deprecated no-arg `Unit#getTransporting()` — locates the
// territory containing this unit and returns the units in it that
// reference this unit as their transporter. Inlined here because the
// no-arg overload is not exposed as its own proc in odin_flat/.
unit_utils_get_transporting_all :: proc(transport: ^Unit) -> [dynamic]^Unit {
	can_transport_p, can_transport_c := matches_unit_can_transport()
	is_carrier_p, is_carrier_c := matches_unit_is_carrier()
	if !can_transport_p(can_transport_c, transport) && !is_carrier_p(is_carrier_c, transport) {
		empty: [dynamic]^Unit
		return empty
	}
	data := game_data_component_get_data(&transport.game_data_component)
	gm := game_data_get_map(data)
	for t in game_map_get_territories(gm) {
		uc := territory_get_unit_collection(t)
		if unit_collection_contains(uc, transport) {
			return unit_get_transporting(transport, uc.units)
		}
	}
	empty: [dynamic]^Unit
	return empty
}

// Helper: Java `translateDependentUnitsToOtherUnit(unitGiving, receivingUnit)` — private.
unit_utils_translate_dependent_units_to_other_unit :: proc(
	unit_giving_attributes: ^Unit,
	receiving_unit: ^Unit,
) -> ^Composite_Change {
	unit_change := composite_change_new()
	unloaded := unit_get_unloaded(unit_giving_attributes)
	if len(unloaded) > 0 {
		// Box the list so it can be passed through the rawptr-typed
		// new_value parameter (mirrors Java's Object reference).
		boxed := new([dynamic]^Unit)
		boxed^ = unloaded
		prop_unloaded := Unit_Property_Name.Unloaded
		composite_change_add(
			unit_change,
			change_factory_unit_property_change(
				receiving_unit,
				rawptr(boxed),
				unit_property_name_to_string(&prop_unloaded),
			),
		)
	}

	transporting := unit_utils_get_transporting_all(unit_giving_attributes)
	acc := unit_change
	for transported in transporting {
		prop_transported_by := Unit_Property_Name.Transported_By
		inner := composite_change_new_from_varargs(
			change_factory_unit_property_change(
				transported,
				rawptr(receiving_unit),
				unit_property_name_to_string(&prop_transported_by),
			),
		)
		acc = composite_change_new_from_varargs(&acc.change, &inner.change)
	}
	return acc
}

// Helper: Java `translateHitPointsAndDamageToOtherUnit(unitGiving, territory, receivingUnit)` — private.
unit_utils_translate_hit_points_and_damage_to_other_unit :: proc(
	unit_giving_attributes: ^Unit,
	territory: ^Territory,
	receiving_unit: ^Unit,
) -> ^Composite_Change {
	unit_change := composite_change_new()

	receiving_hp := unit_attachment_get_hit_points(unit_get_unit_attachment(receiving_unit))
	transfer_hits := unit_get_hits(unit_giving_attributes)
	if receiving_hp - 1 < transfer_hits {
		transfer_hits = receiving_hp - 1
	}
	if transfer_hits > 0 {
		hits := new(Integer_Map_Unit)
		hits.entries = make(map[^Unit]i32)
		hits.entries[receiving_unit] = transfer_hits
		territories := make([dynamic]^Territory)
		append(&territories, territory)
		composite_change_add(unit_change, change_factory_units_hit(hits, territories))
	}

	receiving_damage_max := unit_how_much_damage_can_this_unit_take_total(receiving_unit, territory)
	transfer_damage := unit_get_unit_damage(unit_giving_attributes)
	if receiving_damage_max < transfer_damage {
		transfer_damage = receiving_damage_max
	}
	if transfer_damage > 0 {
		damage := new(Integer_Map_Unit)
		damage.entries = make(map[^Unit]i32)
		damage.entries[receiving_unit] = transfer_damage
		territories := make([dynamic]^Territory)
		append(&territories, territory)
		composite_change_add(unit_change, change_factory_bombing_unit_damage(damage, territories))
	}
	return unit_change
}

// games.strategy.triplea.UnitUtils#translateAttributesToOtherUnits(
//   Unit unitGivingAttributes, Collection<Unit> unitsThatWillGetAttributes,
//   Territory territory) -> Change
//
// Translates Hits, Damage, Unloaded units, and Transported units from one
// unit (about to disappear via transformation) to a collection of units
// taking its place. Hits are clamped so each receiving unit retains at
// least 1 hp; damage is clamped to each receiver's territory-sensitive
// damage cap. Unloaded units and transported-by reassignment go to the
// first receiving unit only (`stream().findFirst()` in Java).
unit_utils_translate_attributes_to_other_units :: proc(
	unit_giving_attributes: ^Unit,
	units_that_will_get_attributes: [dynamic]^Unit,
	territory: ^Territory,
) -> ^Change {
	// First, attributes that can only go to one receiving unit
	// (`stream().findFirst()` → first element if any, else empty composite).
	changes: ^Composite_Change
	if len(units_that_will_get_attributes) > 0 {
		changes = unit_utils_translate_dependent_units_to_other_unit(
			unit_giving_attributes,
			units_that_will_get_attributes[0],
		)
	} else {
		changes = composite_change_new()
	}

	// Next, attributes that can go to all of the receiving units. Mirrors
	// Java's `stream().map(...).reduce(changes, CompositeChange::new)`:
	// the binary combiner is the 2-arg varargs constructor, which wraps
	// (acc, next) into a fresh CompositeChange (filtering empty children).
	acc := changes
	for receiving_unit in units_that_will_get_attributes {
		next_change := unit_utils_translate_hit_points_and_damage_to_other_unit(
			unit_giving_attributes,
			territory,
			receiving_unit,
		)
		acc = composite_change_new_from_varargs(&acc.change, &next_change.change)
	}
	return &acc.change
}

// Synthetic Java lambda: BiFunction<Change,Change,Change> used as the
// reduce combiner inside `translateAttributesToOtherUnits` — the
// Java method reference `CompositeChange::new` (2-arg constructor).
unit_utils_lambda_translate_attributes_to_other_units_2 :: proc(
	a: ^Change,
	b: ^Change,
) -> ^Change {
	return &composite_change_new_from_varargs(a, b).change
}

// Synthetic Java lambda: BiFunction<CompositeChange,CompositeChange,CompositeChange>
// used as the reduce combiner inside `translateDependentUnitsToOtherUnit` —
// the Java method reference `CompositeChange::new` (2-arg constructor).
unit_utils_lambda_translate_dependent_units_to_other_unit_4 :: proc(
	a: ^Change,
	b: ^Change,
) -> ^Change {
	return &composite_change_new_from_varargs(a, b).change
}

// Synthetic Java lambda inside `translateDependentUnitsToOtherUnit`:
//   transported -> new CompositeChange(
//       ChangeFactory.unitPropertyChange(
//           transported, receivingUnit, Unit.PropertyName.TRANSPORTED_BY))
// The mapping step of `transporting.stream().map(...).reduce(...)`. The
// lambda captures `receivingUnit`; we pass it explicitly here.
unit_utils_lambda_translate_dependent_units_to_other_unit_3 :: proc(
	transported: ^Unit,
	receiving_unit: ^Unit,
) -> ^Composite_Change {
	prop_transported_by := Unit_Property_Name.Transported_By
	return composite_change_new_from_varargs(
		change_factory_unit_property_change(
			transported,
			rawptr(receiving_unit),
			unit_property_name_to_string(&prop_transported_by),
		),
	)
}

// games.strategy.triplea.UnitUtils#getHowMuchCanUnitProduce(
//   Unit unit, Territory producer, boolean accountForDamage, boolean mathMaxZero)
//
// Returns the production capacity for `unit` in territory `producer`.
// Mirrors Java semantics: a null unit or a non-producer returns 0;
// otherwise the capacity depends on whether damage is accounted for,
// the bombing-targets-units game property, the unit's CanProduceXUnits
// value, and the territory's production / unit-production. Industrial
// tech bonuses are added when territory production meets the player's
// minimum-territory-value threshold; `mathMaxZero` clamps the result to
// be non-negative.
unit_utils_get_how_much_can_unit_produce :: proc(
	unit: ^Unit,
	producer: ^Territory,
	account_for_damage: bool,
	math_max_zero: bool,
) -> i32 {
	if unit == nil {
		return 0
	}
	can_produce_p, can_produce_c := matches_unit_can_produce_units()
	if !can_produce_p(can_produce_c, unit) {
		return 0
	}
	ua := unit_get_unit_attachment(unit)
	territory_production: i32 = 0
	territory_unit_production: i32 = 0
	optional_ta := territory_attachment_get(producer)
	if optional_ta != nil {
		territory_production = territory_attachment_get_production(optional_ta)
		territory_unit_production = territory_attachment_get_unit_production(optional_ta)
	}
	production_capacity: i32
	data := game_data_component_get_data(&producer.named_attachable.default_named.game_data_component)
	properties := game_data_get_properties(data)
	if account_for_damage {
		if properties_get_damage_from_bombing_done_to_units_instead_of_territories(properties) {
			if unit_attachment_get_can_produce_x_units(ua) < 0 {
				// could use territoryUnitProduction OR territoryProduction
				// (Java comment); damage tracking must follow whichever is chosen.
				production_capacity = territory_unit_production - unit_get_unit_damage(unit)
			} else {
				production_capacity = unit_attachment_get_can_produce_x_units(ua) - unit_get_unit_damage(unit)
			}
		} else {
			production_capacity = territory_production
			if production_capacity < 1 {
				if properties_get_ww2_v2(properties) || properties_get_ww2_v3(properties) {
					production_capacity = 0
				} else {
					production_capacity = 1
				}
			}
		}
	} else {
		damage_to_units := properties_get_damage_from_bombing_done_to_units_instead_of_territories(properties)
		if unit_attachment_get_can_produce_x_units(ua) < 0 && !damage_to_units {
			production_capacity = territory_production
		} else if unit_attachment_get_can_produce_x_units(ua) < 0 && damage_to_units {
			production_capacity = territory_unit_production
		} else {
			production_capacity = unit_attachment_get_can_produce_x_units(ua)
		}
		if production_capacity < 1 && !damage_to_units {
			if properties_get_ww2_v2(properties) || properties_get_ww2_v3(properties) {
				production_capacity = 0
			} else {
				production_capacity = 1
			}
		}
	}
	// Java: producer.getData().getTechTracker() is bound but only used for
	// instance-method calls that the Odin port models as package-level
	// procs over the player; reading the field is therefore a no-op here.
	_ = game_data_get_tech_tracker(data)
	// Increase production if we have industrial technology
	if territory_production >=
	   tech_tracker_get_minimum_territory_value_for_production_bonus(unit_get_owner(unit)) {
		production_capacity += tech_tracker_get_production_bonus(
			unit_get_owner(unit),
			unit_get_type(unit),
		)
	}
	if math_max_zero && production_capacity < 0 {
		return 0
	}
	return production_capacity
}

// games.strategy.triplea.UnitUtils#getBiggestProducer(Collection<Unit>, Territory, GamePlayer, boolean)
// Returns the unit from `units` with the largest production capacity in
// `producer`, or nil if no factory-or-producing unit owned by `player`
// (and not being transported, and matching the territory's land/sea
// side) is present. Mirrors Java semantics: ties keep the first
// strictly-greater unit; the seed is the first matching factory.
unit_utils_get_biggest_producer :: proc(
	units: [dynamic]^Unit,
	producer: ^Territory,
	player: ^Game_Player,
	account_for_damage: bool,
) -> ^Unit {
	fact_p, fact_c := matches_unit_is_owned_and_is_factory_or_can_produce_units(player)
	trans_p, trans_c := matches_unit_is_being_transported()
	side_p: proc(rawptr, ^Unit) -> bool
	side_c: rawptr
	if territory_is_water(producer) {
		side_p, side_c = matches_unit_is_not_land()
	} else {
		side_p, side_c = matches_unit_is_not_sea()
	}
	factories: [dynamic]^Unit
	for u in units {
		if fact_p(fact_c, u) && !trans_p(trans_c, u) && side_p(side_c, u) {
			append(&factories, u)
		}
	}
	if len(factories) == 0 {
		return nil
	}
	highest_unit := factories[0]
	highest_capacity: i32 = min(i32)
	for u in factories {
		capacity := unit_utils_get_how_much_can_unit_produce(u, producer, account_for_damage, false)
		if capacity > highest_capacity {
			highest_capacity = capacity
			highest_unit = u
		}
	}
	return highest_unit
}

