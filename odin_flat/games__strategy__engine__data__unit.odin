package game

import "core:fmt"

// games.strategy.engine.data.Unit
//
// One battlefield unit. Field set mirrors GameStateJsonSerializer.serializeUnit.

Unit :: struct {
	using game_data_component:    Game_Data_Component,
	id:                           Uuid,
	type:                         ^Unit_Type,
	owner:                        ^Game_Player,
	hits:                         i32,
	transported_by:               ^Unit,
	unloaded:                     [dynamic]^Unit,
	was_loaded_this_turn:         bool,
	unloaded_to:                  ^Territory,
	was_unloaded_in_combat_phase: bool,
	already_moved:                f64,
	bonus_movement:               i32,
	unit_damage:                  i32,
	submerged:                    bool,
	original_owner:               ^Game_Player,
	was_in_combat:                bool,
	was_loaded_after_combat:      bool,
	was_amphibious:               bool,
	originated_from:              ^Territory,
	was_scrambled:                bool,
	max_scramble_count:           i32,
	was_in_air_battle:            bool,
	disabled:                     bool,
	launched:                     i32,
	airborne:                     bool,
	charged_flat_fuel_cost:       bool,
}

Unit_Deserialization_Error_Lazy_Message :: struct {
	shown_error: bool,
}

unit_get_airborne :: proc(self: ^Unit) -> bool {
	return self.airborne
}

unit_get_was_amphibious :: proc(self: ^Unit) -> bool {
	return self.was_amphibious
}

unit_get_was_in_combat :: proc(self: ^Unit) -> bool {
	return self.was_in_combat
}

unit_get_submerged :: proc(self: ^Unit) -> bool {
	return self.submerged
}

unit_get_charged_flat_fuel_cost :: proc(self: ^Unit) -> bool {
	return self.charged_flat_fuel_cost
}

unit_get_was_in_air_battle :: proc(self: ^Unit) -> bool {
	return self.was_in_air_battle
}

unit_get_was_unloaded_in_combat_phase :: proc(self: ^Unit) -> bool {
	return self.was_unloaded_in_combat_phase
}

unit_get_was_loaded_this_turn :: proc(self: ^Unit) -> bool {
        return self.was_loaded_this_turn
}

unit_has_moved :: proc(self: ^Unit) -> bool {
	return self.already_moved > 0
}

unit_is_owned_by :: proc(self: ^Unit, player: ^Game_Player) -> bool {
	return self.owner == player
}

unit_has_movement_left :: proc(self: ^Unit) -> bool {
	return unit_get_movement_left(self) > 0
}

unit_get_transporting_in_territory :: proc(self: ^Unit, territory: ^Territory) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	if territory == nil || territory.unit_collection == nil {
		return result
	}
	for u in territory.unit_collection.units {
		if u != nil && u.transported_by == self {
			append(&result, u)
		}
	}
	return result
}

unit_lambda_get_transporting_1 :: proc(self: ^Unit, u: ^Unit) -> bool {
	if u == nil {
		return false
	}
	return u.transported_by == self
}

unit_set_already_moved :: proc(self: ^Unit, already_moved: f64) {
	self.already_moved = already_moved
}

unit_set_original_owner :: proc(self: ^Unit, original_owner: ^Game_Player) {
	self.original_owner = original_owner
}

unit_set_transported_by :: proc(self: ^Unit, transported_by: ^Unit) {
	self.transported_by = transported_by
}

unit_is_transporting_in_territory_arg :: proc(self: ^Unit, t: ^Territory) -> bool {
	transporting := unit_get_transporting_in_territory(self, t)
	defer delete(transporting)
	return len(transporting) > 0
}

unit_is_transporting_any :: proc(self: ^Unit) -> bool {
	if self == nil || self.type == nil || self.type.unit_attachment == nil {
		return false
	}
	ua := self.type.unit_attachment
	if ua.transport_capacity <= 0 && ua.carrier_capacity <= 0 {
		return false
	}
	if self.game_data == nil {
		return false
	}
	gmap := game_data_get_map(self.game_data)
	if gmap == nil {
		return false
	}
	for t in gmap.territories {
		if t == nil || t.unit_collection == nil {
			continue
		}
		contains_self := false
		for u in t.unit_collection.units {
			if u == self {
				contains_self = true
				break
			}
		}
		if contains_self {
			transported := unit_get_transporting_in_territory(self, t)
			result := len(transported) > 0
			delete(transported)
			return result
		}
	}
	return false
}

unit_set_was_in_combat :: proc(self: ^Unit, value: bool) {
	self.was_in_combat = value
}

unit_set_unit_damage :: proc(self: ^Unit, unit_damage: i32) {
	self.unit_damage = unit_damage
}

unit_set_was_loaded_this_turn :: proc(self: ^Unit, x: bool) {
	self.was_loaded_this_turn = x
}

unit_set_was_unloaded_in_combat_phase :: proc(self: ^Unit, x: bool) {
	self.was_unloaded_in_combat_phase = x
}

unit_set_unloaded_to :: proc(self: ^Unit, unloaded_to: ^Territory) {
	self.unloaded_to = unloaded_to
}

unit_set_unloaded :: proc(self: ^Unit, unloaded: [dynamic]^Unit) {
	delete(self.unloaded)
	if len(unloaded) == 0 {
		self.unloaded = make([dynamic]^Unit)
	} else {
		copied := make([dynamic]^Unit, 0, len(unloaded))
		for u in unloaded {
			append(&copied, u)
		}
		self.unloaded = copied
	}
}

unit_set_was_amphibious :: proc(self: ^Unit, value: bool) -> ^Unit {
	self.was_amphibious = value
	return self
}

u

unit_to_string :: proc(self: ^Unit) -> string {
	// TODO: none of these should happen,... except that they did a couple times.
	if self.type == nil || self.owner == nil || self.game_data == nil {
		type_name := "Unit of UNKNOWN TYPE"
		if self.type != nil {
			type_name = default_named_get_name(&self.type.named_attachable.default_named)
		}
		owner_name := "UNKNOWN OWNER"
		if self.owner != nil {
			owner_name = default_named_get_name(&self.owner.named_attachable.default_named)
		}
		id := self.id
		id_str := fmt.aprintf(
			"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
			id[0], id[1], id[2], id[3],
			id[4], id[5],
			id[6], id[7],
			id[8], id[9],
			id[10], id[11], id[12], id[13], id[14], id[15],
		)
		text := fmt.aprintf(
			"Unit.toString() -> Possible java de-serialization error: %s owned by %s with id: %s",
			type_name,
			owner_name,
			id_str,
		)
		unit_deserialization_error_lazy_message_print_error(text)
		return text
	}
	return fmt.aprintf(
		"%s owned by %s",
		default_named_get_name(&self.type.named_attachable.default_named),
		default_named_get_name(&self.owner.named_attachable.default_named),
	)
}nit_to_string_no_owner :: proc(self: ^Unit) -> string {
	return self.type.name
}
