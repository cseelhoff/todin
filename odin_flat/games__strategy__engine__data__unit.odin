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
}

unit_to_string_no_owner :: proc(self: ^Unit) -> string {
	return self.type.name
}

unit_get_already_moved :: proc(self: ^Unit) -> f64 {
	return self.already_moved
}

// games.strategy.engine.data.Unit#canEqual(java.lang.Object)
//
// Lombok @EqualsAndHashCode-generated `return other instanceof Unit`. Odin's
// rawptr carries no runtime type tag, so the faithful translation is the
// pointer-validity check the Java instanceof collapses to once the caller has
// already typed `other` as a Unit reference.
unit_can_equal :: proc(self: ^Unit, other: rawptr) -> bool {
	return other != nil
}

unit_get_bonus_movement :: proc(self: ^Unit) -> i32 {
	return self.bonus_movement
}

unit_get_disabled :: proc(self: ^Unit) -> bool {
	return self.disabled
}

unit_get_hits :: proc(self: ^Unit) -> i32 {
	return self.hits
}

unit_get_id :: proc(self: ^Unit) -> Uuid {
	return self.id
}

unit_get_launched :: proc(self: ^Unit) -> i32 {
	return self.launched
}

unit_get_max_scramble_count :: proc(self: ^Unit) -> i32 {
	return self.max_scramble_count
}

unit_get_original_owner :: proc(self: ^Unit) -> ^Game_Player {
	return self.original_owner
}

unit_get_originated_from :: proc(self: ^Unit) -> ^Territory {
	return self.originated_from
}

unit_get_owner :: proc(self: ^Unit) -> ^Game_Player {
	return self.owner
}

unit_get_transported_by :: proc(self: ^Unit) -> ^Unit {
	return self.transported_by
}

unit_get_type :: proc(self: ^Unit) -> ^Unit_Type {
	return self.type
}

unit_get_unit_damage :: proc(self: ^Unit) -> i32 {
	return self.unit_damage
}

unit_get_unloaded :: proc(self: ^Unit) -> [dynamic]^Unit {
	return self.unloaded
}

unit_get_unloaded_to :: proc(self: ^Unit) -> ^Territory {
	return self.unloaded_to
}

unit_get_was_loaded_after_combat :: proc(self: ^Unit) -> bool {
	return self.was_loaded_after_combat
}

unit_get_was_scrambled :: proc(self: ^Unit) -> bool {
	return self.was_scrambled
}

unit_set_airborne :: proc(self: ^Unit, value: bool) {
	self.airborne = value
}

unit_set_bonus_movement :: proc(self: ^Unit, v: i32) {
	self.bonus_movement = v
}

unit_set_charged_flat_fuel_cost :: proc(self: ^Unit, v: bool) {
	self.charged_flat_fuel_cost = v
}

unit_set_disabled :: proc(self: ^Unit, v: bool) {
	self.disabled = v
}

unit_set_hits :: proc(self: ^Unit, v: i32) {
	self.hits = v
}

unit_set_launched :: proc(self: ^Unit, v: i32) {
	self.launched = v
}

unit_set_max_scramble_count :: proc(self: ^Unit, v: i32) {
	self.max_scramble_count = v
}

unit_set_originated_from :: proc(self: ^Unit, t: ^Territory) {
	self.originated_from = t
}

unit_set_submerged :: proc(self: ^Unit, v: bool) {
	self.submerged = v
}

unit_set_was_in_air_battle :: proc(self: ^Unit, v: bool) {
	self.was_in_air_battle = v
}

unit_set_was_loaded_after_combat :: proc(self: ^Unit, v: bool) {
	self.was_loaded_after_combat = v
}

unit_set_was_scrambled :: proc(self: ^Unit, v: bool) {
	self.was_scrambled = v
}

// games.strategy.engine.data.Unit#equals(java.lang.Object)
//
// Lombok @EqualsAndHashCode(of = "id", callSuper = false): two Units are equal
// iff their UUID `id` fields are equal. The Java code accepts an arbitrary
// Object, returning false on any non-Unit. Odin's rawptr carries no runtime
// type tag; the orchestrator instructions specify casting `other` to `^Unit`
// and comparing UUIDs.
unit_equals :: proc(self: ^Unit, other: rawptr) -> bool {
	if self == nil {
		return other == nil
	}
	if other == nil {
		return false
	}
	if rawptr(self) == other {
		return true
	}
	o := cast(^Unit)other
	return self.id == o.id
}

// games.strategy.engine.data.Unit#hashCode()
//
// Lombok @EqualsAndHashCode(of = "id"): hash derives only from the UUID. Java's
// UUID.hashCode folds the 128-bit value into 32 bits via XOR of the high/low
// 64-bit halves and then high32 ^ low32. Reproduced here over the 16-byte
// representation so equal UUIDs hash equal.
unit_hash_code :: proc(self: ^Unit) -> i32 {
	if self == nil {
		return 0
	}
	hi: u64 = 0
	for i in 0 ..< 8 {
		hi = (hi << 8) | u64(self.id[i])
	}
	lo: u64 = 0
	for i in 8 ..< 16 {
		lo = (lo << 8) | u64(self.id[i])
	}
	folded := hi ~ lo
	return i32(u32(folded ~ (folded >> 32)))
}

// games.strategy.engine.data.Unit#isEquivalent(games.strategy.engine.data.Unit)
//
// Two units are "equivalent" (interchangeable for stacking) when they share
// type, owner, and current hit count. Mirrors the Java predicate exactly.
unit_is_equivalent :: proc(self: ^Unit, unit: ^Unit) -> bool {
	if self == nil || unit == nil {
		return false
	}
	return self.type != nil &&
		self.type == unit.type &&
		self.owner != nil &&
		self.owner == unit.owner &&
		self.hits == unit.hits
}

// games.strategy.engine.data.Unit#setOwner(games.strategy.engine.data.GamePlayer)
//
// Java: owner = Optional.ofNullable(player).orElse(getData().getPlayerList().getNullPlayer()).
// A null argument resolves to the GameData's PlayerList null-player sentinel.
unit_set_owner :: proc(self: ^Unit, player: ^Game_Player) {
	if player != nil {
		self.owner = player
		return
	}
	data := game_data_component_get_data(&self.game_data_component)
	if data == nil || data.player_list == nil {
		self.owner = nil
		return
	}
	self.owner = player_list_get_null_player(data.player_list)
}

// games.strategy.engine.data.Unit#<init>(UUID, UnitType, GamePlayer, GameData)
//
// games.strategy.engine.data.Unit#<init>(UnitType, GamePlayer, GameData)
//
// Java: `this.type = checkNotNull(type); this.id = UUID.randomUUID(); setOwner(owner);`
// Generates a fresh UUID and delegates to the explicit-UUID constructor.
unit_new :: proc(unit_type: ^Unit_Type, owner: ^Game_Player, data: ^Game_Data) -> ^Unit {
	return unit_new_with_uuid(uuid_random_uuid(), unit_type, owner, data)
}

// Explicit-UUID constructor. Mirrors the Java field initializers:
// `unloaded = List.of()`, `alreadyMoved = BigDecimal.ZERO`, `maxScrambleCount = -1`,
// all other primitives default-zero/false. Calls `setOwner` so a nil owner falls
// back to the PlayerList null-player sentinel.
unit_new_with_uuid :: proc(
	uuid: Uuid,
	unit_type: ^Unit_Type,
	owner: ^Game_Player,
	data: ^Game_Data,
) -> ^Unit {
	assert(unit_type != nil)
	self := new(Unit)
	self.game_data_component = make_Game_Data_Component(data)
	self.id = uuid
	self.type = unit_type
	self.max_scramble_count = -1
	unit_set_owner(self, owner)
	return self
}

// games.strategy.engine.data.Unit#getTransporting(java.util.Collection)
//
// Returns the subset of the given collection whose `transportedBy` points at
// this unit. Java: `CollectionUtils.getMatches(transportedUnitsPossible,
// o -> equals(o.getTransportedBy()))`. Unit equality is by UUID; since each
// Unit has a unique UUID and is heap-allocated, pointer identity matches the
// Java semantics (consistent with the existing `unit_get_transporting_in_territory`).
unit_get_transporting :: proc(
	self: ^Unit,
	transported_units_possible: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in transported_units_possible {
		if u != nil && u.transported_by == self {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.engine.data.Unit#getUnitAttachment()
//
// `return type.getUnitAttachment()`.
unit_get_unit_attachment :: proc(self: ^Unit) -> ^Unit_Attachment {
	return unit_type_get_unit_attachment(self.type)
}
