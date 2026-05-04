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
unit_get_transporting_collection :: proc(
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

// games.strategy.engine.data.Unit#getTransporting()
//
// Java: if this unit can transport or is a carrier, find the territory that
// contains it and return getTransporting(territory); otherwise List.of().
// The carrier/transport gate matches Java exactly; the territory loop mirrors
// the existing `unit_is_transporting_any` traversal.
unit_get_transporting_no_args :: proc(self: ^Unit) -> [dynamic]^Unit {
	empty: [dynamic]^Unit
	if !matches_pred_unit_can_transport(nil, self) && !matches_pred_unit_is_carrier(nil, self) {
		return empty
	}
	if self.game_data == nil {
		return empty
	}
	gmap := game_data_get_map(self.game_data)
	if gmap == nil {
		return empty
	}
	for t in gmap.territories {
		if t == nil || t.unit_collection == nil {
			continue
		}
		if unit_collection_contains(t.unit_collection, self) {
			return unit_get_transporting_in_territory(self, t)
		}
	}
	return empty
}

// Proc group covering Java overloads `getTransporting()` and
// `getTransporting(Collection<Unit>)`.
unit_get_transporting :: proc{unit_get_transporting_no_args, unit_get_transporting_collection}

// games.strategy.engine.data.Unit#getUnitAttachment()
//
// `return type.getUnitAttachment()`.
unit_get_unit_attachment :: proc(self: ^Unit) -> ^Unit_Attachment {
	return unit_type_get_unit_attachment(self.type)
}

// games.strategy.engine.data.Unit#hitsUnitCanTakeHitWithoutBeingKilled()
//
// Java: `return getUnitAttachment().getHitPoints() - 1 - hits;`
unit_hits_unit_can_take_hit_without_being_killed :: proc(self: ^Unit) -> i32 {
	return unit_attachment_get_hit_points(unit_get_unit_attachment(self)) - 1 - self.hits
}

// games.strategy.engine.data.Unit#lambda$getPropertyOrEmpty$0(Unit$PropertyName)
//
// Java: the inner `unitPropertyName -> switch (unitPropertyName) { ... }`
// passed to `Optional.map` inside `getPropertyOrEmpty`'s default branch.
// Captures `this`; the Odin port carries it as the explicit `self` parameter.
// Each enum arm builds a `MutableProperty.ofSimple(this::setX, this::getX)`
// over the corresponding Unit field. The setter value-pointer points at the
// typed value (matching the convention used by `tech_attachment_get_property_or_empty`):
// reference fields receive `^^T` (pointer to a pointer); primitives receive
// `^T`. Getters allocate a freshly boxed value so callers may dereference
// uniformly.
unit_lambda_get_property_or_empty_0 :: proc(
	self: ^Unit,
	unit_property_name: Unit_Property_Name,
) -> ^Mutable_Property {
	switch unit_property_name {
	case .Transported_By:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_transported_by(cast(^Unit)ctx, (cast(^^Unit)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Unit)
					out^ = unit_get_transported_by(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Unloaded:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_unloaded(cast(^Unit)ctx, (cast(^[dynamic]^Unit)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new([dynamic]^Unit)
					out^ = unit_get_unloaded(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Loaded_This_Turn:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_loaded_this_turn(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_loaded_this_turn(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Unloaded_To:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_unloaded_to(cast(^Unit)ctx, (cast(^^Territory)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Territory)
					out^ = unit_get_unloaded_to(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Unloaded_In_Combat_Phase:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_unloaded_in_combat_phase(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_unloaded_in_combat_phase(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Already_Moved:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_already_moved(cast(^Unit)ctx, (cast(^f64)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(f64)
					out^ = unit_get_already_moved(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Bonus_Movement:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_bonus_movement(cast(^Unit)ctx, (cast(^i32)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_get_bonus_movement(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Submerged:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_submerged(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_submerged(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Was_In_Combat:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_in_combat(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_in_combat(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Loaded_After_Combat:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_loaded_after_combat(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_loaded_after_combat(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Unloaded_Amphibious:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					_ = unit_set_was_amphibious(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_amphibious(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Originated_From:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_originated_from(cast(^Unit)ctx, (cast(^^Territory)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Territory)
					out^ = unit_get_originated_from(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Was_Scrambled:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_scrambled(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_scrambled(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Max_Scramble_Count:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_max_scramble_count(cast(^Unit)ctx, (cast(^i32)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_get_max_scramble_count(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Was_In_Air_Battle:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_was_in_air_battle(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_was_in_air_battle(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Launched:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_launched(cast(^Unit)ctx, (cast(^i32)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_get_launched(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Airborne:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_airborne(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_airborne(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case .Charged_Flat_Fuel_Cost:
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_charged_flat_fuel_cost(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_charged_flat_fuel_cost(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	}
	return nil
}

// games.strategy.engine.data.Unit#getHowMuchDamageCanThisUnitTakeTotal(Territory)
//
// Java:
//   if (!Matches.unitCanBeDamaged().test(this)) return -1;
//   ua = getType().getUnitAttachment();
//   territoryUnitProduction = TerritoryAttachment.getUnitProduction(t);
//   if (Properties.getDamageFromBombingDoneToUnitsInsteadOfTerritories(getData().getProperties())) {
//     if (ua.getMaxDamage() <= 0)               return territoryUnitProduction * 2;
//     if (Matches.unitCanProduceUnits().test(this))
//       return ua.getCanProduceXUnits() < 0
//                ? territoryUnitProduction * ua.getMaxDamage()
//                : ua.getMaxDamage();
//     return ua.getMaxDamage();
//   }
//   return Integer.MAX_VALUE;
unit_get_how_much_damage_can_this_unit_take_total :: proc(self: ^Unit, t: ^Territory) -> i32 {
	if !matches_pred_unit_can_be_damaged(nil, self) {
		return -1
	}
	ua := unit_type_get_unit_attachment(unit_get_type(self))
	territory_unit_production := territory_attachment_static_get_unit_production(t)
	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(game_data_component_get_data(&self.game_data_component)),
	) {
		if unit_attachment_get_max_damage(ua) <= 0 {
			return territory_unit_production * 2
		}
		if matches_pred_unit_can_produce_units(nil, self) {
			if unit_attachment_get_can_produce_x_units(ua) < 0 {
				return territory_unit_production * unit_attachment_get_max_damage(ua)
			}
			return unit_attachment_get_max_damage(ua)
		}
		return unit_attachment_get_max_damage(ua)
	}
	return max(i32)
}

// games.strategy.engine.data.Unit#getMaxMovementAllowed()
//
// Java: `return Math.max(0, bonusMovement + getType().getUnitAttachment().getMovement(getOwner()));`
unit_get_max_movement_allowed :: proc(self: ^Unit) -> i32 {
	mv := unit_attachment_get_movement_with_player(
		unit_type_get_unit_attachment(unit_get_type(self)),
		unit_get_owner(self),
	)
	return max(i32(0), self.bonus_movement + mv)
}

// games.strategy.engine.data.Unit#getMovementLeft()
//
// Java: `return new BigDecimal(getType().getUnitAttachment().getMovement(getOwner()))
//                  .add(new BigDecimal(bonusMovement))
//                  .subtract(alreadyMoved);`
// BigDecimal → f64 per the Odin port convention.
unit_get_movement_left :: proc(self: ^Unit) -> f64 {
	mv := unit_attachment_get_movement_with_player(
		unit_type_get_unit_attachment(unit_get_type(self)),
		unit_get_owner(self),
	)
	return f64(mv) + f64(self.bonus_movement) - self.already_moved
}

// games.strategy.engine.data.Unit#getPropertyOrEmpty(String)
//
// Java: head switch on a fixed list of names, falling through to a parse of
// the supplied string into a `Unit$PropertyName` and dispatch to
// `lambda$getPropertyOrEmpty$0` (already ported as
// `unit_lambda_get_property_or_empty_0`). The Java return type is
// `Optional<MutableProperty<?>>`; here `nil` represents `Optional.empty()`.
unit_get_property_or_empty :: proc(self: ^Unit, property_name: string) -> ^Mutable_Property {
	switch property_name {
	case "owner":
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_owner(cast(^Unit)ctx, (cast(^^Game_Player)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Game_Player)
					out^ = unit_get_owner(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "uid":
		return mutable_property_of_read_only_simple(
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(Uuid)
					out^ = unit_get_id(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "hits":
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_hits(cast(^Unit)ctx, (cast(^i32)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_get_hits(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "type":
		return mutable_property_of_read_only_simple(
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Unit_Type)
					out^ = unit_get_type(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "unitDamage":
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_unit_damage(cast(^Unit)ctx, (cast(^i32)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_get_unit_damage(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "originalOwner":
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_original_owner(cast(^Unit)ctx, (cast(^^Game_Player)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(^Game_Player)
					out^ = unit_get_original_owner(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	case "disabled":
		return mutable_property_of_simple(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_set_disabled(cast(^Unit)ctx, (cast(^bool)v)^)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = unit_get_disabled(cast(^Unit)ctx)
					return out
				},
				ctx = self,
			},
		)
	}
	prop, ok := unit_property_name_parse_from_string(property_name)
	if !ok {
		return nil
	}
	return unit_lambda_get_property_or_empty_0(self, prop)
}

// games.strategy.engine.data.Unit#getHowMuchMoreDamageCanThisUnitTake(Territory)
//
// Java:
//   if (!Matches.unitCanBeDamaged().test(this)) return 0;
//   return Properties.getDamageFromBombingDoneToUnitsInsteadOfTerritories(getData().getProperties())
//       ? Math.max(0, getHowMuchDamageCanThisUnitTakeTotal(t) - getUnitDamage())
//       : Integer.MAX_VALUE;
unit_get_how_much_more_damage_can_this_unit_take :: proc(self: ^Unit, t: ^Territory) -> i32 {
	if !matches_pred_unit_can_be_damaged(nil, self) {
		return 0
	}
	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(game_data_component_get_data(&self.game_data_component)),
	) {
		return max(
			i32(0),
			unit_get_how_much_damage_can_this_unit_take_total(self, t) - unit_get_unit_damage(self),
		)
	}
	return max(i32)
}
