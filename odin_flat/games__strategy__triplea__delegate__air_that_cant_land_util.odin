package game

import "core:fmt"

Air_That_Cant_Land_Util :: struct {
	bridge: ^I_Delegate_Bridge,
}

air_that_cant_land_util_new :: proc(bridge: ^I_Delegate_Bridge) -> ^Air_That_Cant_Land_Util {
	self := new(Air_That_Cant_Land_Util)
	self.bridge = bridge
	return self
}

// Java: Collection<Territory> getTerritoriesWhereAirCantLand(GamePlayer player)
air_that_cant_land_util_get_territories_where_air_cant_land :: proc(
	self: ^Air_That_Cant_Land_Util,
	player: ^Game_Player,
) -> [dynamic]^Territory {
	data := i_delegate_bridge_get_data(self.bridge)
	cant_land := make([dynamic]^Territory)
	air_pred, air_ctx := matches_unit_is_air()
	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	territories := game_map_get_territories(game_data_get_map(data))
	for current in territories {
		all_units := unit_holder_get_units(cast(^Unit_Holder)current)
		air := make([dynamic]^Unit, 0, len(all_units))
		for u in all_units {
			if air_pred(air_ctx, u) && owned_pred(owned_ctx, u) {
				append(&air, u)
			}
		}
		delete(all_units)
		if len(air) != 0 &&
		   !air_movement_validator_can_land(air[:], current, player, data) {
			append(&cant_land, current)
		}
		delete(air)
	}
	return cant_land
}

// Java: private void removeAirThatCantLand(
//         final GamePlayer player, final Territory territory, final Collection<Unit> airUnits)
// The private 3-arg overload of removeAirThatCantLand. Distinguished
// here from the public 2-arg `removeAirThatCantLand(player, bool)` by
// the `_in_territory` suffix since Odin does not support overloading.
air_that_cant_land_util_remove_air_that_cant_land_in_territory :: proc(
	self: ^Air_That_Cant_Land_Util,
	player: ^Game_Player,
	territory: ^Territory,
	air_units: [dynamic]^Unit,
) {
	to_remove := make([dynamic]^Unit, 0, len(air_units))
	if !territory_is_water(territory) {
		// if we cant land on land then none can
		for u in air_units {
			append(&to_remove, u)
		}
	} else {
		// on water we may just no have enough carriers — find the carrier capacity
		allied_pred, allied_ctx := matches_allied_unit(player)
		all_units := unit_holder_get_units(cast(^Unit_Holder)territory)
		defer delete(all_units)
		carriers := make([dynamic]^Unit, 0, len(all_units))
		defer delete(carriers)
		for u in all_units {
			if allied_pred(allied_ctx, u) {
				append(&carriers, u)
			}
		}
		capacity := air_movement_validator_carrier_capacity(carriers[:], territory)
		for unit in air_units {
			ua := unit_get_unit_attachment(unit)
			cost := unit_attachment_get_carrier_cost(ua)
			if cost == -1 || cost > capacity {
				append(&to_remove, unit)
			} else {
				capacity -= cost
			}
		}
	}
	remove := change_factory_remove_units(cast(^Unit_Holder)territory, to_remove)
	were_or_was := "was"
	if len(to_remove) > 1 {
		were_or_was = "were"
	}
	transcript_text := fmt.aprintf(
		"%s could not land in %s and %s removed",
		my_formatter_units_to_text_no_owner(to_remove, nil),
		default_named_get_name(&territory.named_attachable.default_named),
		were_or_was,
	)
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		transcript_text,
	)
	i_delegate_bridge_add_change(self.bridge, remove)
}

// Java: void removeAirThatCantLand(
//         final GamePlayer player, final boolean spareAirInSeaZonesBesideFactories)
air_that_cant_land_util_remove_air_that_cant_land :: proc(
	self: ^Air_That_Cant_Land_Util,
	player: ^Game_Player,
	spare_air_in_sea_zones_beside_factories: bool,
) {
	data := i_delegate_bridge_get_data(self.bridge)
	gm := game_data_get_map(data)
	has_neighboring_friendly_factory_match_pred,
		has_neighboring_friendly_factory_match_ctx :=
		matches_territory_has_allied_is_factory_or_can_produce_units(player)
	cant_land := air_that_cant_land_util_get_territories_where_air_cant_land(self, player)
	defer delete(cant_land)
	for current in cant_land {
		air_pred, air_ctx := matches_unit_is_air()
		allied_pred, allied_ctx := matches_allied_unit(player)
		all_units := unit_holder_get_units(cast(^Unit_Holder)current)
		air := make([dynamic]^Unit, 0, len(all_units))
		for u in all_units {
			if air_pred(air_ctx, u) && allied_pred(allied_ctx, u) {
				append(&air, u)
			}
		}
		delete(all_units)
		neighbors := game_map_get_neighbors_predicate(
			gm,
			current,
			has_neighboring_friendly_factory_match_pred,
			has_neighboring_friendly_factory_match_ctx,
		)
		has_neighboring_friendly_factory := len(neighbors) != 0
		delete(neighbors)
		skip :=
			spare_air_in_sea_zones_beside_factories &&
			territory_is_water(current) &&
			has_neighboring_friendly_factory
		if !skip {
			air_that_cant_land_util_remove_air_that_cant_land_in_territory(
				self,
				player,
				current,
				air,
			)
		}
		delete(air)
	}
}

