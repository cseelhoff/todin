package game

import "core:fmt"

// Port of games.strategy.triplea.attachments.UnitAttachment.
// Despite the misleading name, this attaches not to individual Units but to
// UnitTypes. Empty collection fields default to nil/zero in Odin (matching
// Java's null-default for memory/serialization minimization).
Unit_Attachment :: struct {
	using default_attachment: Default_Attachment,

	// movement related
	is_air:                          bool,
	is_sea:                          bool,
	movement:                        i32,
	can_blitz:                       bool,
	is_kamikaze:                     bool,
	can_invade_only_from:            [dynamic]string,
	fuel_cost:                       Integer_Map_Resource,
	fuel_flat_cost:                  Integer_Map_Resource,
	can_not_move_during_combat_move: bool,
	movement_limit:                  ^Tuple(i32, string),

	// combat related
	attack:                   i32,
	defense:                  i32,
	is_infrastructure:        bool,
	can_bombard:              bool,
	bombard:                  i32,
	artillery:                bool,
	artillery_supportable:    bool,
	unit_support_count:       i32,
	is_marine:                i32,
	is_suicide_on_attack:     bool,
	is_suicide_on_defense:    bool,
	is_suicide_on_hit:        bool,
	attacking_limit:          ^Tuple(i32, string),
	attack_rolls:             i32,
	defense_rolls:            i32,
	choose_best_roll:         bool,
	can_retreat_on_stalemate: ^bool,

	// sub/destroyer related
	can_evade:                       bool,
	is_first_strike:                 bool,
	can_not_target:                  map[^Unit_Type]struct{},
	can_not_be_targeted_by:          map[^Unit_Type]struct{},
	can_move_through_enemies:        bool,
	can_be_moved_through_by_enemies: bool,
	is_destroyer:                    bool,

	// transportation related
	is_combat_transport:   bool,
	transport_capacity:    i32,
	transport_cost:        i32,
	carrier_capacity:      i32,
	carrier_cost:          i32,
	is_air_transport:      bool,
	is_air_transportable:  bool,
	is_land_transport:     bool,
	is_land_transportable: bool,

	// aa related
	is_aa_for_combat_only:             bool,
	is_aa_for_bombing_this_unit_only:  bool,
	is_aa_for_fly_over_only:           bool,
	is_rocket:                         bool,
	attack_aa:                         i32,
	offensive_attack_aa:               i32,
	attack_aa_max_die_sides:           i32,
	offensive_attack_aa_max_die_sides: i32,
	max_aa_attacks:                    i32,
	max_rounds_aa:                     i32,
	type_aa:                           string,
	targets_aa:                        map[^Unit_Type]struct{},
	may_over_stack_aa:                 bool,
	damageable_aa:                     bool,
	will_not_fire_if_present:          map[^Unit_Type]struct{},

	// strategic bombing related
	is_strategic_bomber:            bool,
	bombing_max_die_sides:          i32,
	bombing_bonus:                  i32,
	can_intercept:                  bool,
	requires_air_base_to_intercept: bool,
	can_escort:                     bool,
	can_air_battle:                 bool,
	air_defense:                    i32,
	air_attack:                     i32,
	bombing_targets:                map[^Unit_Type]struct{},

	// production related
	can_produce_units:      bool,
	can_produce_x_units:    i32,
	creates_units_list:     map[^Unit_Type]i32,
	creates_resources_list: Integer_Map_Resource,

	// damage related
	hit_points:                       i32,
	can_be_damaged:                   bool,
	max_damage:                       i32,
	max_operational_damage:           i32,
	can_die_from_reaching_max_damage: bool,

	// placement related
	is_construction:                             bool,
	construction_type:                           string,
	constructions_per_terr_per_type_per_turn:    i32,
	max_constructions_per_type_per_terr:         i32,
	can_only_be_placed_in_territory_valued_at_x: i32,
	requires_units:                              [dynamic][dynamic]string,
	consumes_units:                              map[^Unit_Type]i32,
	requires_units_to_move:                      [dynamic][dynamic]string,
	unit_placement_restrictions:                 [dynamic]string,
	max_built_per_player:                        i32,
	placement_limit:                             ^Tuple(i32, string),

	// scrambling related
	can_scramble:          bool,
	is_air_base:           bool,
	max_scramble_distance: i32,
	max_scramble_count:    i32,
	max_intercept_count:   i32,

	// special abilities
	blockade:                              i32,
	repairs_units:                         map[^Unit_Type]i32,
	gives_movement:                        map[^Unit_Type]i32,
	destroyed_when_captured_by:            [dynamic]^Tuple(string, ^Game_Player),
	when_hit_points_damaged_changes_into:  map[i32]^Tuple(bool, ^Unit_Type),
	when_hit_points_repaired_changes_into: map[i32]^Tuple(bool, ^Unit_Type),
	when_captured_changes_into:            map[string]^Tuple(string, map[^Unit_Type]i32),
	when_captured_sustains_damage:         i32,
	can_be_captured_on_entering_by:        [dynamic]^Game_Player,
	can_be_given_by_territory_to:          [dynamic]^Game_Player,
	when_combat_damaged:                   [dynamic]^Tuple(^Tuple(i32, i32), ^Tuple(string, string)),
	receives_ability_when_with:            [dynamic]string,
	special:                               map[string]struct{},
	tuv:                                   i32,

	// combo properties
	is_sub:     bool,
	is_suicide: bool,
}

// =============================================================================
// Phase B: methods for games.strategy.triplea.attachments.UnitAttachment.
// =============================================================================

// Java: public static UnitAttachment get(UnitType type, String nameOfAttachment)
//   return getAttachment(type, nameOfAttachment, UnitAttachment.class);
// `Default_Attachment.getAttachment` is not exposed as a generic helper in the
// Odin port; the body is inlined: look up the attachment on the UnitType's
// Named_Attachable and reinterpret as ^Unit_Attachment.
unit_attachment_get :: proc(type: ^Unit_Type, name_of_attachment: string) -> ^Unit_Attachment {
	if type == nil {
		return nil
	}
	att := named_attachable_get_attachment(&type.named_attachable, name_of_attachment)
	return cast(^Unit_Attachment)att
}

// Java: private UnitType getUnitType() { return (UnitType) getAttachedTo(); }
unit_attachment_get_unit_type :: proc(self: ^Unit_Attachment) -> ^Unit_Type {
	if self == nil {
		return nil
	}
	return cast(^Unit_Type)self.attached_to
}

// -- Boolean field accessors (fluent / get / is / can) -----------------------

unit_attachment_can_air_battle :: proc(self: ^Unit_Attachment) -> bool {return self.can_air_battle}
unit_attachment_can_be_damaged :: proc(self: ^Unit_Attachment) -> bool {return self.can_be_damaged}
unit_attachment_can_die_from_reaching_max_damage :: proc(self: ^Unit_Attachment) -> bool {return self.can_die_from_reaching_max_damage}
unit_attachment_can_escort :: proc(self: ^Unit_Attachment) -> bool {return self.can_escort}
unit_attachment_can_intercept :: proc(self: ^Unit_Attachment) -> bool {return self.can_intercept}
unit_attachment_can_not_move_during_combat_move :: proc(self: ^Unit_Attachment) -> bool {return self.can_not_move_during_combat_move}
unit_attachment_can_produce_units :: proc(self: ^Unit_Attachment) -> bool {return self.can_produce_units}
unit_attachment_can_scramble :: proc(self: ^Unit_Attachment) -> bool {return self.can_scramble}

unit_attachment_is_aa_for_bombing_this_unit_only :: proc(self: ^Unit_Attachment) -> bool {return self.is_aa_for_bombing_this_unit_only}
unit_attachment_is_aa_for_combat_only :: proc(self: ^Unit_Attachment) -> bool {return self.is_aa_for_combat_only}
unit_attachment_is_aa_for_fly_over_only :: proc(self: ^Unit_Attachment) -> bool {return self.is_aa_for_fly_over_only}
unit_attachment_is_air :: proc(self: ^Unit_Attachment) -> bool {return self.is_air}
unit_attachment_is_air_base :: proc(self: ^Unit_Attachment) -> bool {return self.is_air_base}
unit_attachment_is_air_transport :: proc(self: ^Unit_Attachment) -> bool {return self.is_air_transport}
unit_attachment_is_air_transportable :: proc(self: ^Unit_Attachment) -> bool {return self.is_air_transportable}
unit_attachment_is_combat_transport :: proc(self: ^Unit_Attachment) -> bool {return self.is_combat_transport}
unit_attachment_is_construction :: proc(self: ^Unit_Attachment) -> bool {return self.is_construction}
unit_attachment_is_destroyer :: proc(self: ^Unit_Attachment) -> bool {return self.is_destroyer}
unit_attachment_is_infrastructure :: proc(self: ^Unit_Attachment) -> bool {return self.is_infrastructure}
unit_attachment_is_kamikaze :: proc(self: ^Unit_Attachment) -> bool {return self.is_kamikaze}
unit_attachment_is_land_transport :: proc(self: ^Unit_Attachment) -> bool {return self.is_land_transport}
unit_attachment_is_land_transportable :: proc(self: ^Unit_Attachment) -> bool {return self.is_land_transportable}
unit_attachment_is_rocket :: proc(self: ^Unit_Attachment) -> bool {return self.is_rocket}
unit_attachment_is_sea :: proc(self: ^Unit_Attachment) -> bool {return self.is_sea}
unit_attachment_is_strategic_bomber :: proc(self: ^Unit_Attachment) -> bool {return self.is_strategic_bomber}
unit_attachment_is_suicide_on_hit :: proc(self: ^Unit_Attachment) -> bool {return self.is_suicide_on_hit}

// -- Simple field getters ---------------------------------------------------

unit_attachment_get_artillery :: proc(self: ^Unit_Attachment) -> bool {return self.artillery}
unit_attachment_get_artillery_supportable :: proc(self: ^Unit_Attachment) -> bool {return self.artillery_supportable}
// Java: int getAttack() (package-private overload returning the field).
// No-player no-arg variant — Odin doesn't support overloading; the
// player-tech-aware form keeps the bare name `unit_attachment_get_attack`.
unit_attachment_get_attack_no_player :: proc(self: ^Unit_Attachment) -> i32 {return self.attack}
unit_attachment_get_blockade :: proc(self: ^Unit_Attachment) -> i32 {return self.blockade}
// Java: getBombard() returns bombard if positive, else falls back to attack.
unit_attachment_get_bombard :: proc(self: ^Unit_Attachment) -> i32 {
	if self.bombard > 0 {
		return self.bombard
	}
	return self.attack
}
unit_attachment_get_bombing_bonus :: proc(self: ^Unit_Attachment) -> i32 {return self.bombing_bonus}
unit_attachment_get_bombing_max_die_sides :: proc(self: ^Unit_Attachment) -> i32 {return self.bombing_max_die_sides}
unit_attachment_get_carrier_capacity :: proc(self: ^Unit_Attachment) -> i32 {return self.carrier_capacity}
unit_attachment_get_carrier_cost :: proc(self: ^Unit_Attachment) -> i32 {return self.carrier_cost}
// Java: canEvade || isSub.
unit_attachment_get_can_evade :: proc(self: ^Unit_Attachment) -> bool {
	return self.can_evade || self.is_sub
}
unit_attachment_get_can_only_be_placed_in_territory_valued_at_x :: proc(self: ^Unit_Attachment) -> i32 {return self.can_only_be_placed_in_territory_valued_at_x}
unit_attachment_get_can_produce_x_units :: proc(self: ^Unit_Attachment) -> i32 {return self.can_produce_x_units}
// Java: Optional.ofNullable(canRetreatOnStalemate). Odin uses ^bool: nil ≡ empty.
unit_attachment_get_can_retreat_on_stalemate :: proc(self: ^Unit_Attachment) -> ^bool {
	return self.can_retreat_on_stalemate
}
unit_attachment_get_choose_best_roll :: proc(self: ^Unit_Attachment) -> bool {return self.choose_best_roll}
unit_attachment_get_construction_type :: proc(self: ^Unit_Attachment) -> string {return self.construction_type}
unit_attachment_get_constructions_per_terr_per_type_per_turn :: proc(self: ^Unit_Attachment) -> i32 {return self.constructions_per_terr_per_type_per_turn}
unit_attachment_get_damageable_aa :: proc(self: ^Unit_Attachment) -> bool {return self.damageable_aa}
unit_attachment_get_hit_points :: proc(self: ^Unit_Attachment) -> i32 {return self.hit_points}
// Java: isFirstStrike || isSub || isSuicide.
unit_attachment_get_is_first_strike :: proc(self: ^Unit_Attachment) -> bool {
	return self.is_first_strike || self.is_sub || self.is_suicide
}
unit_attachment_get_is_marine :: proc(self: ^Unit_Attachment) -> i32 {return self.is_marine}
// Java: isSuicideOnAttack || isSuicide.
unit_attachment_get_is_suicide_on_attack :: proc(self: ^Unit_Attachment) -> bool {
	return self.is_suicide_on_attack || self.is_suicide
}
unit_attachment_get_max_aa_attacks :: proc(self: ^Unit_Attachment) -> i32 {return self.max_aa_attacks}
unit_attachment_get_max_built_per_player :: proc(self: ^Unit_Attachment) -> i32 {return self.max_built_per_player}
unit_attachment_get_max_constructions_per_type_per_terr :: proc(self: ^Unit_Attachment) -> i32 {return self.max_constructions_per_type_per_terr}
unit_attachment_get_max_damage :: proc(self: ^Unit_Attachment) -> i32 {return self.max_damage}
unit_attachment_get_max_operational_damage :: proc(self: ^Unit_Attachment) -> i32 {return self.max_operational_damage}
unit_attachment_get_max_rounds_aa :: proc(self: ^Unit_Attachment) -> i32 {return self.max_rounds_aa}
unit_attachment_get_max_scramble_count :: proc(self: ^Unit_Attachment) -> i32 {return self.max_scramble_count}
unit_attachment_get_max_scramble_distance :: proc(self: ^Unit_Attachment) -> i32 {return self.max_scramble_distance}
unit_attachment_get_may_over_stack_aa :: proc(self: ^Unit_Attachment) -> bool {return self.may_over_stack_aa}
// Java: Optional.ofNullable(movementLimit). Field is already a pointer.
unit_attachment_get_movement_limit :: proc(self: ^Unit_Attachment) -> ^Tuple(i32, string) {return self.movement_limit}
// Java: Optional.ofNullable(attackingLimit).
unit_attachment_get_attacking_limit :: proc(self: ^Unit_Attachment) -> ^Tuple(i32, string) {return self.attacking_limit}
// Java: Optional.ofNullable(placementLimit).
unit_attachment_get_placement_limit :: proc(self: ^Unit_Attachment) -> ^Tuple(i32, string) {return self.placement_limit}
unit_attachment_get_requires_air_base_to_intercept :: proc(self: ^Unit_Attachment) -> bool {return self.requires_air_base_to_intercept}
unit_attachment_get_transport_capacity :: proc(self: ^Unit_Attachment) -> i32 {return self.transport_capacity}
unit_attachment_get_transport_cost :: proc(self: ^Unit_Attachment) -> i32 {return self.transport_cost}
unit_attachment_get_tuv :: proc(self: ^Unit_Attachment) -> i32 {return self.tuv}
unit_attachment_get_type_aa :: proc(self: ^Unit_Attachment) -> string {return self.type_aa}

// -- Collection-property getters (Java getListProperty/getMapProperty/etc.
//    return the value if non-null else an empty default; Odin maps/dynamic
//    arrays with zero/nil backing iterate as empty so the field is returned
//    directly.) --------------------------------------------------------------

unit_attachment_get_can_be_captured_on_entering_by :: proc(self: ^Unit_Attachment) -> [dynamic]^Game_Player {return self.can_be_captured_on_entering_by}
unit_attachment_get_can_be_given_by_territory_to :: proc(self: ^Unit_Attachment) -> [dynamic]^Game_Player {return self.can_be_given_by_territory_to}
unit_attachment_get_consumes_units :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]i32 {return self.consumes_units}
unit_attachment_get_creates_resources_list :: proc(self: ^Unit_Attachment) -> Integer_Map_Resource {return self.creates_resources_list}
unit_attachment_get_creates_units_list :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]i32 {return self.creates_units_list}
unit_attachment_get_destroyed_when_captured_by :: proc(self: ^Unit_Attachment) -> [dynamic]^Tuple(string, ^Game_Player) {return self.destroyed_when_captured_by}
unit_attachment_get_fuel_cost :: proc(self: ^Unit_Attachment) -> Integer_Map_Resource {return self.fuel_cost}
unit_attachment_get_fuel_flat_cost :: proc(self: ^Unit_Attachment) -> Integer_Map_Resource {return self.fuel_flat_cost}
unit_attachment_get_gives_movement :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]i32 {return self.gives_movement}
unit_attachment_get_receives_ability_when_with :: proc(self: ^Unit_Attachment) -> [dynamic]string {return self.receives_ability_when_with}
unit_attachment_get_repairs_units :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]i32 {return self.repairs_units}
unit_attachment_get_requires_units :: proc(self: ^Unit_Attachment) -> [dynamic][dynamic]string {return self.requires_units}
unit_attachment_get_requires_units_to_move :: proc(self: ^Unit_Attachment) -> [dynamic][dynamic]string {return self.requires_units_to_move}
unit_attachment_get_special :: proc(self: ^Unit_Attachment) -> map[string]struct {} {return self.special}
unit_attachment_get_when_captured_changes_into :: proc(self: ^Unit_Attachment) -> map[string]^Tuple(string, map[^Unit_Type]i32) {return self.when_captured_changes_into}
unit_attachment_get_when_captured_sustains_damage :: proc(self: ^Unit_Attachment) -> i32 {return self.when_captured_sustains_damage}
unit_attachment_get_when_hit_points_damaged_changes_into :: proc(self: ^Unit_Attachment) -> map[i32]^Tuple(bool, ^Unit_Type) {return self.when_hit_points_damaged_changes_into}
unit_attachment_get_when_hit_points_repaired_changes_into :: proc(self: ^Unit_Attachment) -> map[i32]^Tuple(bool, ^Unit_Type) {return self.when_hit_points_repaired_changes_into}
unit_attachment_get_will_not_fire_if_present :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]struct {} {return self.will_not_fire_if_present}

// Java: getWhenCombatDamaged() maps each stored Tuple to a freshly
// constructed WhenCombatDamaged value-object. Returns a heap-allocated
// [dynamic] owned by the caller; the wrapper structs are heap-allocated.
unit_attachment_get_when_combat_damaged :: proc(self: ^Unit_Attachment) -> [dynamic]^Unit_Attachment_When_Combat_Damaged {
	out: [dynamic]^Unit_Attachment_When_Combat_Damaged
	for tuple in self.when_combat_damaged {
		w := new(Unit_Attachment_When_Combat_Damaged)
		if tuple != nil {
			if tuple.first != nil {
				w.damage_min = tuple.first.first
				w.damage_max = tuple.first.second
			}
			if tuple.second != nil {
				w.effect = tuple.second.first
				w.unknown = tuple.second.second
			}
		}
		append(&out, w)
	}
	return out
}

// -- unitPlacementRestrictionsContain ----------------------------------------

// Java:
//   if (unitPlacementRestrictions == null) return false;
//   return Arrays.asList(unitPlacementRestrictions).contains(territory.getName());
unit_attachment_unit_placement_restrictions_contain :: proc(self: ^Unit_Attachment, territory: ^Territory) -> bool {
	if self == nil || self.unit_placement_restrictions == nil || territory == nil {
		return false
	}
	target := default_named_get_name(&territory.named_attachable.default_named)
	for name in self.unit_placement_restrictions {
		if name == target {
			return true
		}
	}
	return false
}

// -- Resets (Java: field = null/default) ------------------------------------

// Java: canNotTarget = null. Odin field is a value-typed map; clearing
// reproduces the "no entries" observable behaviour (the Java lazy-init in
// getCanNotTarget repopulates from sub/suicide flags; that is in a higher
// method_layer and not in this batch).
unit_attachment_reset_can_not_target :: proc(self: ^Unit_Attachment) {
	if self == nil {
		return
	}
	clear(&self.can_not_target)
}

// Java: canNotBeTargetedBy = null.
unit_attachment_reset_can_not_be_targeted_by :: proc(self: ^Unit_Attachment) {
	if self == nil {
		return
	}
	clear(&self.can_not_be_targeted_by)
}

// -- Setters ---------------------------------------------------------------

// String setters: parse via Default_Attachment.getInt / getBool helpers.
unit_attachment_set_air_attack :: proc(self: ^Unit_Attachment, value: string) {
	self.air_attack = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_air_defense :: proc(self: ^Unit_Attachment, value: string) {
	self.air_defense = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_attack :: proc(self: ^Unit_Attachment, value: string) {
	self.attack = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_can_blitz :: proc(self: ^Unit_Attachment, value: string) {
	self.can_blitz = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_can_bombard :: proc(self: ^Unit_Attachment, value: string) {
	self.can_bombard = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_can_escort :: proc(self: ^Unit_Attachment, value: string) {
	self.can_escort = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_can_intercept :: proc(self: ^Unit_Attachment, value: string) {
	self.can_intercept = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_can_not_move_during_combat_move :: proc(self: ^Unit_Attachment, value: string) {
	self.can_not_move_during_combat_move = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_carrier_capacity :: proc(self: ^Unit_Attachment, value: string) {
	self.carrier_capacity = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_carrier_cost :: proc(self: ^Unit_Attachment, value: string) {
	self.carrier_cost = default_attachment_get_int(&self.default_attachment, value)
}

// Java stores the raw String unchanged.
unit_attachment_set_construction_type :: proc(self: ^Unit_Attachment, value: string) {
	self.construction_type = value
}

unit_attachment_set_constructions_per_terr_per_type_per_turn :: proc(self: ^Unit_Attachment, value: string) {
	self.constructions_per_terr_per_type_per_turn = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_defense :: proc(self: ^Unit_Attachment, value: string) {
	self.defense = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_is_aa_for_bombing_this_unit_only :: proc(self: ^Unit_Attachment, value: string) {
	self.is_aa_for_bombing_this_unit_only = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_aa_for_combat_only :: proc(self: ^Unit_Attachment, value: string) {
	self.is_aa_for_combat_only = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_air :: proc(self: ^Unit_Attachment, value: string) {
	self.is_air = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_air_transport :: proc(self: ^Unit_Attachment, value: string) {
	self.is_air_transport = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_air_transportable :: proc(self: ^Unit_Attachment, value: string) {
	self.is_air_transportable = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_destroyer :: proc(self: ^Unit_Attachment, value: string) {
	self.is_destroyer = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_land_transport :: proc(self: ^Unit_Attachment, value: string) {
	self.is_land_transport = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_land_transportable :: proc(self: ^Unit_Attachment, value: string) {
	self.is_land_transportable = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_rocket :: proc(self: ^Unit_Attachment, value: string) {
	self.is_rocket = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_sea :: proc(self: ^Unit_Attachment, value: string) {
	self.is_sea = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_is_strategic_bomber :: proc(self: ^Unit_Attachment, value: string) {
	self.is_strategic_bomber = default_attachment_get_bool(&self.default_attachment, value)
}

unit_attachment_set_max_constructions_per_type_per_terr :: proc(self: ^Unit_Attachment, value: string) {
	self.max_constructions_per_type_per_terr = default_attachment_get_int(&self.default_attachment, value)
}

unit_attachment_set_movement :: proc(self: ^Unit_Attachment, value: string) {
	self.movement = default_attachment_get_int(&self.default_attachment, value)
}

// Boxed Boolean setters (Java setX(Boolean)). nil pointer → false default.
unit_attachment_set_can_be_damaged :: proc(self: ^Unit_Attachment, value: ^bool) {
	self.can_be_damaged = value != nil && value^
}

unit_attachment_set_can_produce_units :: proc(self: ^Unit_Attachment, value: ^bool) {
	self.can_produce_units = value != nil && value^
}

unit_attachment_set_is_construction :: proc(self: ^Unit_Attachment, value: ^bool) {
	self.is_construction = value != nil && value^
}

unit_attachment_set_is_infrastructure :: proc(self: ^Unit_Attachment, value: ^bool) {
	self.is_infrastructure = value != nil && value^
}

// Primitive int / boxed Integer setters.
unit_attachment_set_hit_points :: proc(self: ^Unit_Attachment, value: i32) {
	self.hit_points = value
}

unit_attachment_set_transport_capacity :: proc(self: ^Unit_Attachment, value: i32) {
	self.transport_capacity = value
}

// Java: setTransportCost(Integer) — boxed; Java unboxes implicitly. The Odin
// port stores the value directly; null/missing maps to zero in Java's
// MutableProperty path, which is rarely-if-ever exercised for this field.
unit_attachment_set_transport_cost :: proc(self: ^Unit_Attachment, value: i32) {
	self.transport_cost = value
}

// -- Lambdas ---------------------------------------------------------------

// Java:
//   private static String joinRequiredUnits(List<String[]> units)
//     .stream().map(required -> required.length == 1 ? required[0] : Arrays.toString(required))
// The inner mapper lambda. Returns a heap-allocated string owned by caller
// when the array length is != 1; for length 1 the slice is returned as-is.
unit_attachment_lambda_join_required_units_6 :: proc(required: []string) -> string {
	if len(required) == 1 {
		return required[0]
	}
	// Mirrors java.util.Arrays.toString: "[a, b, c]".
	buf: [dynamic]u8
	append(&buf, '[')
	for s, i in required {
		if i > 0 {
			append(&buf, ',')
			append(&buf, ' ')
		}
		for c in transmute([]u8)s {
			append(&buf, c)
		}
	}
	append(&buf, ']')
	return string(buf[:])
}

// Java: `String[]::new` constructor reference (size -> new String[size]) used
// inside setUnitPlacementRestrictions.toArray.
unit_attachment_lambda_set_unit_placement_restrictions_3 :: proc(size: i32) -> []string {
	return make([]string, size)
}

// Java: `String[]::new` constructor reference inside
// setUnitPlacementOnlyAllowedIn.toArray.
unit_attachment_lambda_set_unit_placement_only_allowed_in_4 :: proc(size: i32) -> []string {
	return make([]string, size)
}
// Synthetic suppliers generated by javac for each `() -> <default>` literal
// passed as the last argument to `MutableProperty.ofMapper(...)` inside
// `getPropertyOrEmpty`. Numbering follows javac's per-class lambda counter;
// only the even-indexed ones are real suppliers (odd indices belong to
// method-reference adapters). Translated in source-order.

// case BOMBARD: `() -> -1`
unit_attachment_lambda_get_property_or_empty_8 :: proc() -> i32 {
        return -1
}

// case "canEvade": `() -> false`
unit_attachment_lambda_get_property_or_empty_10 :: proc() -> bool {
        return false
}

// case "isFirstStrike": `() -> false`
unit_attachment_lambda_get_property_or_empty_12 :: proc() -> bool {
        return false
}

// case "canMoveThroughEnemies": `() -> false`
unit_attachment_lambda_get_property_or_empty_14 :: proc() -> bool {
        return false
}

// case "canBeMovedThroughByEnemies": `() -> false`
unit_attachment_lambda_get_property_or_empty_16 :: proc() -> bool {
        return false
}

// case "isSuicide": `() -> false`
unit_attachment_lambda_get_property_or_empty_18 :: proc() -> bool {
        return false
}

// case "isSuicideOnAttack": `() -> false`
unit_attachment_lambda_get_property_or_empty_20 :: proc() -> bool {
        return false
}

// case "isSuicideOnDefense": `() -> false`
unit_attachment_lambda_get_property_or_empty_22 :: proc() -> bool {
        return false
}

// case "transportCapacity": `() -> -1`
unit_attachment_lambda_get_property_or_empty_24 :: proc() -> i32 {
        return -1
}

// case "transportCost": `() -> -1`
unit_attachment_lambda_get_property_or_empty_26 :: proc() -> i32 {
        return -1
}

// case "hitPoints": `() -> 1`
unit_attachment_lambda_get_property_or_empty_28 :: proc() -> i32 {
        return 1
}

// case (final ofMapper supplier in getPropertyOrEmpty): `() -> 0`
unit_attachment_lambda_get_property_or_empty_30 :: proc() -> i32 {
        return 0
}

// =============================================================================
// Phase B layer 1 additions: setIsFactory/setIsSub/setMaxAaAttacks setters,
// canInvadeFrom predicate, AA / bombing target accessors, getListedUnits, and
// the synthetic javac lambdas referenced from getPropertyOrEmpty,
// setWhenCapturedChangesInto, and setDestroyedWhenCapturedBy.
// =============================================================================

// Java: public void setIsSub(final Boolean s) { isSub = s; resetCanNotTarget();
//                                                resetCanNotBeTargetedBy(); }
// Boxed Boolean -> ^bool (nil ~ Java null, treated as false to match the
// nil-default convention applied throughout this file).
unit_attachment_set_is_sub :: proc(self: ^Unit_Attachment, value: ^bool) {
	self.is_sub = value != nil && value^
	unit_attachment_reset_can_not_target(self)
	unit_attachment_reset_can_not_be_targeted_by(self)
}

// Java: private void setIsFactory(final Boolean s) -- propagates the boolean to
// canBeDamaged / isInfrastructure / canProduceUnits / isConstruction, then
// configures the construction-type triplet. Constants.CONSTRUCTION_TYPE_FACTORY
// is the literal string "factory".
unit_attachment_set_is_factory :: proc(self: ^Unit_Attachment, s: ^bool) {
	unit_attachment_set_can_be_damaged(self, s)
	unit_attachment_set_is_infrastructure(self, s)
	unit_attachment_set_can_produce_units(self, s)
	unit_attachment_set_is_construction(self, s)
	if s != nil && s^ {
		unit_attachment_set_construction_type(self, "factory")
		unit_attachment_set_max_constructions_per_type_per_terr(self, "1")
		unit_attachment_set_constructions_per_terr_per_type_per_turn(self, "1")
	} else {
		unit_attachment_set_construction_type(self, "none")
		unit_attachment_set_max_constructions_per_type_per_terr(self, "-1")
		unit_attachment_set_constructions_per_terr_per_type_per_turn(self, "-1")
	}
}

// Java: private void setMaxAaAttacks(final String s) throws GameParseException
// Parses, validates that attacks >= -1, then stores. The Java method calls
// `getInt(s)` twice (once for the bound check, once for assignment); the port
// preserves the literal double-parse for fidelity.
unit_attachment_set_max_aa_attacks :: proc(self: ^Unit_Attachment, s: string) {
	attacks := default_attachment_get_int(&self.default_attachment, s)
	if attacks < -1 {
		suffix := default_attachment_this_error_msg(&self.default_attachment)
		fmt.panicf(
			"maxAAattacks must be positive (or -1 for attacking all) %s",
			suffix,
		)
	}
	self.max_aa_attacks = default_attachment_get_int(&self.default_attachment, s)
}

// Java: public boolean canInvadeFrom(final Unit transport)
//   returns true iff canInvadeOnlyFrom is null/empty/blank/"all", or the
//   transport's unit-type name appears in the list. Odin's [dynamic]string
//   zero value has len==0, collapsing the null and empty checks.
unit_attachment_can_invade_from :: proc(self: ^Unit_Attachment, transport: ^Unit) -> bool {
	if self == nil {
		return true
	}
	if len(self.can_invade_only_from) == 0 {
		return true
	}
	if self.can_invade_only_from[0] == "" {
		return true
	}
	if self.can_invade_only_from[0] == "all" {
		return true
	}
	if transport == nil {
		return false
	}
	type := unit_get_type(transport)
	if type == nil {
		return false
	}
	target := default_named_get_name(&type.named_attachable.default_named)
	for n in self.can_invade_only_from {
		if n == target {
			return true
		}
	}
	return false
}

// Java: public int getAttackAaMaxDieSides()
//   return attackAaMaxDieSides > 0 ? attackAaMaxDieSides : getData().getDiceSides();
unit_attachment_get_attack_aa_max_die_sides :: proc(self: ^Unit_Attachment) -> i32 {
	if self.attack_aa_max_die_sides > 0 {
		return self.attack_aa_max_die_sides
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	return game_data_get_dice_sides(data)
}

// Java: public int getOffensiveAttackAaMaxDieSides()
//   return offensiveAttackAaMaxDieSides > 0 ? offensiveAttackAaMaxDieSides
//                                            : getData().getDiceSides();
unit_attachment_get_offensive_attack_aa_max_die_sides :: proc(self: ^Unit_Attachment) -> i32 {
	if self.offensive_attack_aa_max_die_sides > 0 {
		return self.offensive_attack_aa_max_die_sides
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	return game_data_get_dice_sides(data)
}

// Java: public Set<UnitType> getBombingTargets(final UnitTypeList unitTypeList)
//   if (bombingTargets != null) return Collections.unmodifiableSet(bombingTargets);
//   return unitTypeList.getAllUnitTypes();
// Odin's value-typed map treats len==0 as the "unset" sentinel that mirrors
// Java's null check (the Java field is null-by-default and only ever assigned
// a non-empty Set by the parser, so the equivalence holds in practice).
unit_attachment_get_bombing_targets :: proc(
	self: ^Unit_Attachment,
	unit_type_list: ^Unit_Type_List,
) -> map[^Unit_Type]struct {} {
	if len(self.bombing_targets) > 0 {
		return self.bombing_targets
	}
	return unit_type_list_get_all_unit_types(unit_type_list)
}

// Java: public Set<UnitType> getTargetsAa(final UnitTypeList unitTypeList)
//   if (targetsAa != null) return Collections.unmodifiableSet(targetsAa);
//   return unitTypeList.stream()
//       .filter(ut -> ut.getUnitAttachment().isAir())
//       .collect(Collectors.toSet());
// The inline filter lambda is folded into the loop body since it neither
// captures nor escapes.
unit_attachment_get_targets_aa :: proc(
	self: ^Unit_Attachment,
	unit_type_list: ^Unit_Type_List,
) -> map[^Unit_Type]struct {} {
	if len(self.targets_aa) > 0 {
		return self.targets_aa
	}
	out: map[^Unit_Type]struct {}
	types := unit_type_list_stream(unit_type_list)
	defer delete(types)
	for ut in types {
		ua := unit_type_get_unit_attachment(ut)
		if ua != nil && unit_attachment_is_air(ua) {
			out[ut] = struct {}{}
		}
	}
	return out
}

// Java: public Collection<UnitType> getListedUnits(final String[] list)
//   resolves each name against the GameData's UnitTypeList. Java throws
//   IllegalStateException for unknown names; the Odin port panics with the
//   same message (mirrors `default_attachment_get_unit_type_or_throw`).
//   Returns a freshly-allocated [dynamic]; the caller owns it.
unit_attachment_get_listed_units :: proc(
	self: ^Unit_Attachment,
	list: []string,
) -> [dynamic]^Unit_Type {
	out: [dynamic]^Unit_Type
	data := game_data_component_get_data_or_throw(&self.default_attachment.game_data_component)
	utl := game_data_get_unit_type_list(data)
	for name in list {
		ut := unit_type_list_get_unit_type(utl, name)
		if ut == nil {
			suffix := default_attachment_this_error_msg(&self.default_attachment)
			fmt.panicf("No unit called: %s%s", name, suffix)
		}
		append(&out, ut)
	}
	return out
}

// -- Synthetic javac lambdas ------------------------------------------------

// Java: lambda$setWhenCapturedChangesInto$0(String value, String[] s)
// Captures: enclosing UnitAttachment (for thisErrorMsg), `value`, `s`. The
// lambda body builds and returns the GameParseException; the call-site is
// the orElseThrow guarding the from-player lookup.
unit_attachment_lambda__set_when_captured_changes_into__0 :: proc(
	self: ^Unit_Attachment,
	value: string,
	s: []string,
) -> ^Game_Parse_Exception {
	suffix := default_attachment_this_error_msg(&self.default_attachment)
	defer delete(suffix)
	msg := fmt.aprintf(
		"Invalid whenCapturedChangesInto with value %s \n from-player: %s unknown%s",
		value,
		s[0],
		suffix,
	)
	return make_Game_Parse_Exception(msg)
}

// Java: lambda$setWhenCapturedChangesInto$1(String value, String[] s)
// Mirrors lambda$0 but for the to-player lookup (uses s[1] and "to-player").
unit_attachment_lambda__set_when_captured_changes_into__1 :: proc(
	self: ^Unit_Attachment,
	value: string,
	s: []string,
) -> ^Game_Parse_Exception {
	suffix := default_attachment_this_error_msg(&self.default_attachment)
	defer delete(suffix)
	msg := fmt.aprintf(
		"Invalid whenCapturedChangesInto with value %s \n to-player: %s unknown%s",
		value,
		s[1],
		suffix,
	)
	return make_Game_Parse_Exception(msg)
}

// Java: lambda$setDestroyedWhenCapturedBy$2(String initialValue, String name)
// The Java message does not interpolate thisErrorMsg, so the Odin port
// likewise needs no `self` pointer.
unit_attachment_lambda__set_destroyed_when_captured_by__2 :: proc(
	initial_value: string,
	name: string,
) -> ^Game_Parse_Exception {
	msg := fmt.aprintf(
		"UnitAttachment: Setting destroyedWhenCapturedBy with value %s not possible; No player found for %s",
		initial_value,
		name,
	)
	return make_Game_Parse_Exception(msg)
}

// -- Mapper-bridge lambdas inside getPropertyOrEmpty ------------------------
// javac emits a synthetic lambda for each `DefaultAttachment::getInt` /
// `DefaultAttachment::getBool` method reference passed as the parser-arg of
// `MutableProperty.ofMapper(...)`, since the underlying methods have a
// receiver-bearing signature that needs adapting to a `Function<String, T>`.
// These bridges occupy the odd lambda indices (the matching even indices
// already in this file are the `() -> default` suppliers paired with each
// ofMapper call). Both helpers in DefaultAttachment ignore the receiver, so
// the Odin bridges pass `nil` through.

// case BOMBARD: `DefaultAttachment::getInt`
unit_attachment_lambda__get_property_or_empty__7 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// case "canEvade": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__9 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "isFirstStrike": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__11 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "canMoveThroughEnemies": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__13 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "canBeMovedThroughByEnemies": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__15 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "isSuicide": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__17 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "isSuicideOnAttack": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__19 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "isSuicideOnDefense": `DefaultAttachment::getBool`
unit_attachment_lambda__get_property_or_empty__21 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// case "transportCapacity": `DefaultAttachment::getInt`
unit_attachment_lambda__get_property_or_empty__23 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// case "transportCost": `DefaultAttachment::getInt`
unit_attachment_lambda__get_property_or_empty__25 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// case "hitPoints": `DefaultAttachment::getInt`
unit_attachment_lambda__get_property_or_empty__27 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// case "whenCapturedSustainsDamage": `DefaultAttachment::getInt`
unit_attachment_lambda__get_property_or_empty__29 :: proc(value: string) -> i32 {
	return default_attachment_get_int(nil, value)
}

// =============================================================================
// Phase B layer 2 additions: constructor, lazy lookups (getCanNotTarget,
// getReceivesAbilityWhenWithMap), accessor for the embedded TechTracker, the
// String-form `setIsFactory` / `setIsSub` parser overloads, and the synthetic
// filter lambda emitted by javac for `getTargetsAa(UnitTypeList)`.
// =============================================================================

// Java: public UnitAttachment(String name, Attachable attachable, GameData gameData)
//   super(name, attachable, gameData);
// Mirrors `default_attachment_new` but allocates the concrete subclass and
// initializes the embedded `Default_Attachment` fields directly so the
// returned `^Unit_Attachment` is the canonical instance (no double heap
// allocation, no detached parent object).
unit_attachment_new :: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^Unit_Attachment {
	self := new(Unit_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	return self
}

// Java: private TechTracker getTechTracker() { return getData().getTechTracker(); }
// Mirrored as a private-style helper (lower-cased Odin proc; nothing else in
// the package calls it yet at this layer).
unit_attachment_get_tech_tracker :: proc(self: ^Unit_Attachment) -> ^Tech_Tracker {
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	return game_data_get_tech_tracker(data)
}

// Java: public Set<UnitType> getCanNotTarget()
//   if (canNotTarget == null && (isSub || isSuicide)) {
//     final Predicate<UnitType> unitTypeMatch =
//         (getIsSuicideOnAttack() && getIsFirstStrike())
//             ? Matches.unitTypeIsSuicideOnAttack().or(Matches.unitTypeIsSuicideOnDefense())
//             : Matches.unitTypeIsAir();
//     canNotTarget = new HashSet<>(CollectionUtils.getMatches(
//         getData().getUnitTypeList().getAllUnitTypes(), unitTypeMatch));
//   }
//   return getSetProperty(canNotTarget);
// Odin's value-typed map treats len==0 as the "unset" sentinel matching
// Java's null-default. The lazy-init writes the result back into
// `self.can_not_target` so subsequent calls see the cached value, just as
// Java's field assignment does.
unit_attachment_get_can_not_target :: proc(self: ^Unit_Attachment) -> map[^Unit_Type]struct {} {
	if len(self.can_not_target) == 0 && (self.is_sub || self.is_suicide) {
		data := game_data_component_get_data(&self.default_attachment.game_data_component)
		utl := game_data_get_unit_type_list(data)
		all := unit_type_list_get_all_unit_types(utl)
		defer delete(all)
		if unit_attachment_get_is_suicide_on_attack(self) && unit_attachment_get_is_first_strike(self) {
			soa_pred, soa_ctx := matches_unit_type_is_suicide_on_attack()
			sod_pred, sod_ctx := matches_unit_type_is_suicide_on_defense()
			for ut in all {
				if soa_pred(soa_ctx, ut) || sod_pred(sod_ctx, ut) {
					self.can_not_target[ut] = {}
				}
			}
		} else {
			air_pred, air_ctx := matches_unit_type_is_air()
			for ut in all {
				if air_pred(air_ctx, ut) {
					self.can_not_target[ut] = {}
				}
			}
		}
	}
	return self.can_not_target
}

// Java: private static IntegerMap<Tuple<String, String>> getReceivesAbilityWhenWithMap(
//          Collection<Unit> units, String filterForAbility, UnitTypeList unitTypeList)
//   final IntegerMap<Tuple<String, String>> map = new IntegerMap<>();
//   final Collection<UnitType> canReceive = UnitUtils.getUnitTypesFromUnitList(
//       CollectionUtils.getMatches(units, Matches.unitCanReceiveAbilityWhenWith()));
//   for (UnitType ut : canReceive) {
//     for (String receive : ut.getUnitAttachment().getReceivesAbilityWhenWith()) {
//       String[] s = splitOnColon(receive);
//       if (filterForAbility != null && !filterForAbility.equals(s[0])) continue;
//       map.put(Tuple.of(s[0], s[1]),
//           CollectionUtils.countMatches(units,
//               Matches.unitIsOfType(unitTypeList.getUnitTypeOrThrow(s[1]))));
//     }
//   }
//   return map;
// The returned `^Integer_Map` keys are heap-allocated `^Tuple(string,string)`
// pointers. Java's content-based `Tuple.equals` is reproduced via a
// dedup-by-content side table so repeated `(ability,unitType)` pairs reuse
// the same key (matching Java's "put overwrites" semantics).
unit_attachment_get_receives_ability_when_with_map :: proc(
	units: [dynamic]^Unit,
	filter_for_ability: string,
	unit_type_list: ^Unit_Type_List,
) -> ^Integer_Map {
	out := integer_map_new()
	// Filter units via Matches.unitCanReceiveAbilityWhenWith().
	can_recv_pred, can_recv_ctx := matches_unit_can_receive_ability_when_with()
	matched: [dynamic]^Unit
	defer delete(matched)
	for u in units {
		if can_recv_pred(can_recv_ctx, u) {
			append(&matched, u)
		}
	}
	can_receive := unit_utils_get_unit_types_from_unit_list(matched)
	defer delete(can_receive)
	// dedup keys by content so Tuple.equals semantics are preserved.
	dedup: map[string]map[string]^Tuple(string, string)
	defer {
		for _, inner in dedup {
			delete(inner)
		}
		delete(dedup)
	}
	for ut in can_receive {
		ua := unit_type_get_unit_attachment(ut)
		receives := unit_attachment_get_receives_ability_when_with(ua)
		for receive in receives {
			parts := default_attachment_split_on_colon(receive)
			defer delete(parts)
			if len(parts) < 2 {
				continue
			}
			ability := parts[0]
			unit_name := parts[1]
			if filter_for_ability != "" && filter_for_ability != ability {
				continue
			}
			// Resolve or allocate the canonical Tuple key for (ability, unit_name).
			inner, has_outer := dedup[ability]
			if !has_outer {
				inner = make(map[string]^Tuple(string, string))
				dedup[ability] = inner
			}
			key, has_inner := inner[unit_name]
			if !has_inner {
				key = tuple_new(string, string, ability, unit_name)
				inner[unit_name] = key
				dedup[ability] = inner
			}
			// CollectionUtils.countMatches(units, Matches.unitIsOfType(target)).
			target := unit_type_list_get_unit_type_or_throw(unit_type_list, unit_name)
			of_type_pred, of_type_ctx := matches_unit_is_of_type(target)
			count: i32 = 0
			for u in units {
				if of_type_pred(of_type_ctx, u) {
					count += 1
				}
			}
			integer_map_put(out, rawptr(key), count)
		}
	}
	return out
}

// Java: lambda$getTargetsAa$5(UnitType ut) — `ut -> ut.getUnitAttachment().isAir()`
// Non-capturing; emitted by javac for the Stream.filter call inside
// `getTargetsAa(UnitTypeList)`.
unit_attachment_lambda_get_targets_aa_5 :: proc(unit_type: ^Unit_Type) -> bool {
	ua := unit_type_get_unit_attachment(unit_type)
	if ua == nil {
		return false
	}
	return unit_attachment_is_air(ua)
}

// Java: private void setIsSub(final String s) { setIsSub(getBool(s)); }
// String-parser overload; defers to the boxed-Boolean form already defined
// in this file. Suffix `_str` follows the project's overload-disambiguation
// convention (cf. territory_attachment_set_is_impassable_str).
unit_attachment_set_is_sub_str :: proc(self: ^Unit_Attachment, s: string) {
	parsed := default_attachment_get_bool(&self.default_attachment, s)
	unit_attachment_set_is_sub(self, &parsed)
}

// Java: private void setIsFactory(final String s) { setIsFactory(getBool(s)); }
// String-parser overload paired with the boxed-Boolean `setIsFactory` form.
unit_attachment_set_is_factory_str :: proc(self: ^Unit_Attachment, s: string) {
	parsed := default_attachment_get_bool(&self.default_attachment, s)
	unit_attachment_set_is_factory(self, &parsed)
}

// =============================================================================
// Phase B additional player-aware accessors and static aggregators.
// =============================================================================

// Java: public int getMovement(final GamePlayer player)
//   final int bonus = getTechTracker().getMovementBonus(player, getUnitType());
//   return Math.max(0, movement + bonus);
unit_attachment_get_movement_with_player :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_movement_bonus(player, unit_attachment_get_unit_type(self))
	return max(i32(0), self.movement + bonus)
}

// Java: public int getAttack(final GamePlayer player)
//   final int bonus = getTechTracker().getAttackBonus(player, getUnitType());
//   return Math.min(getData().getDiceSides(), Math.max(0, attack + bonus));
unit_attachment_get_attack :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_attack_bonus(player, unit_attachment_get_unit_type(self))
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	return min(game_data_get_dice_sides(data), max(i32(0), self.attack + bonus))
}

// Java: public int getAttackRolls(final GamePlayer player)
//   final int bonus = getTechTracker().getAttackRollsBonus(player, getUnitType());
//   return Math.max(0, attackRolls + bonus);
unit_attachment_get_attack_rolls_with_player :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_attack_rolls_bonus(player, unit_attachment_get_unit_type(self))
	return max(i32(0), self.attack_rolls + bonus)
}

// Java: public int getDefense(final GamePlayer player)
//   final int bonus = getTechTracker().getDefenseBonus(player, getUnitType());
//   int defenseValue = defense + bonus;
//   if (defenseValue > 0 && getIsFirstStrike() && TechTracker.hasSuperSubs(player)) {
//     final int superSubBonus = Properties.getSuperSubDefenseBonus(getData().getProperties());
//     defenseValue += superSubBonus;
//   }
//   return Math.min(getData().getDiceSides(), Math.max(0, defenseValue));
unit_attachment_get_defense :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_defense_bonus(player, unit_attachment_get_unit_type(self))
	defense_value := self.defense + bonus
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	if defense_value > 0 && unit_attachment_get_is_first_strike(self) && tech_tracker_has_super_subs(player) {
		super_sub_bonus := properties_get_super_sub_defense_bonus(game_data_get_properties(data))
		defense_value += super_sub_bonus
	}
	return min(game_data_get_dice_sides(data), max(i32(0), defense_value))
}

// Java: public int getDefenseRolls(final GamePlayer player)
//   final int bonus = getTechTracker().getDefenseRollsBonus(player, getUnitType());
//   return Math.max(0, defenseRolls + bonus);
unit_attachment_get_defense_rolls_with_player :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_defense_rolls_bonus(player, unit_attachment_get_unit_type(self))
	return max(i32(0), self.defense_rolls + bonus)
}

// Java: private boolean getCanBlitz() { return canBlitz; }
//   No-arg form; suffixed `_no_player` to disambiguate from the
//   tech-aware `unit_attachment_get_can_blitz(self, player)` overload
//   below, since Odin lacks function overloading.
unit_attachment_get_can_blitz_no_player :: proc(self: ^Unit_Attachment) -> bool {
	return self.can_blitz
}

// Java: public boolean getCanBlitz(final GamePlayer player)
//   return canBlitz || getTechTracker().canBlitz(player, getUnitType());
unit_attachment_get_can_blitz :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> bool {
	return self.can_blitz || tech_tracker_can_blitz(player, unit_attachment_get_unit_type(self))
}

// Java: private boolean getCanBombard() { return canBombard; }
//   No-arg form; suffixed `_no_player` to disambiguate from the
//   tech-aware `unit_attachment_get_can_bombard(self, player)` overload
//   below, since Odin lacks function overloading.
unit_attachment_get_can_bombard_no_player :: proc(self: ^Unit_Attachment) -> bool {
	return self.can_bombard
}

// Java: public boolean getCanBombard(final GamePlayer player)
//   return canBombard || getTechTracker().canBombard(player, getUnitType());
unit_attachment_get_can_bombard :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> bool {
	return self.can_bombard || tech_tracker_can_bombard(player, unit_attachment_get_unit_type(self))
}

// Java: private int getAttackAa()  { return attackAa; }
//   No-arg form; suffixed `_no_player` to disambiguate from the
//   tech-aware `unit_attachment_get_attack_aa(self, player)` overload
//   below, since Odin lacks function overloading.
unit_attachment_get_attack_aa_no_player :: proc(self: ^Unit_Attachment) -> i32 {
	return self.attack_aa
}

// Java: public int getAttackAa(final GamePlayer player)
//   final int bonus = getTechTracker().getRadarBonus(player, getUnitType());
//   return Math.max(0, Math.min(getAttackAaMaxDieSides(), attackAa + bonus));
unit_attachment_get_attack_aa :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_radar_bonus(player, unit_attachment_get_unit_type(self))
	return max(i32(0), min(unit_attachment_get_attack_aa_max_die_sides(self), self.attack_aa + bonus))
}

// Java: private int getOffensiveAttackAa()  { return offensiveAttackAa; }
//   No-arg form; see comment on `unit_attachment_get_attack_aa_no_player`.
unit_attachment_get_offensive_attack_aa_no_player :: proc(self: ^Unit_Attachment) -> i32 {
	return self.offensive_attack_aa
}

// Java: public int getOffensiveAttackAa(final GamePlayer player)
//   final int bonus = getTechTracker().getRadarBonus(player, getUnitType());
//   return Math.max(0, Math.min(getOffensiveAttackAaMaxDieSides(), offensiveAttackAa + bonus));
unit_attachment_get_offensive_attack_aa :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_radar_bonus(player, unit_attachment_get_unit_type(self))
	return max(
		i32(0),
		min(
			unit_attachment_get_offensive_attack_aa_max_die_sides(self),
			self.offensive_attack_aa + bonus,
		),
	)
}

// Java: public static List<String> getAllOfTypeAas(Collection<Unit> aaUnitsAlreadyVerified)
//   final Set<String> aaSet = new HashSet<>();
//   for (Unit u : aaUnitsAlreadyVerified) aaSet.add(u.getUnitAttachment().getTypeAa());
//   final List<String> aaTypes = new ArrayList<>(aaSet);
//   Collections.sort(aaTypes);
//   return aaTypes;
unit_attachment_get_all_of_type_aas :: proc(aa_units_already_verified: [dynamic]^Unit) -> [dynamic]string {
	seen: map[string]struct {}
	defer delete(seen)
	for u in aa_units_already_verified {
		ua := unit_get_unit_attachment(u)
		if ua == nil {
			continue
		}
		seen[unit_attachment_get_type_aa(ua)] = {}
	}
	out: [dynamic]string
	for k in seen {
		append(&out, k)
	}
	// Insertion-sort ascending — Collections.sort on a small AA-type list.
	for i in 1 ..< len(out) {
		j := i
		for j > 0 && out[j - 1] > out[j] {
			tmp := out[j - 1]
			out[j - 1] = out[j]
			out[j] = tmp
			j -= 1
		}
	}
	return out
}

// Java: public static Set<UnitType> getAllowedBombingTargetsIntersection(
//          Collection<Unit> bombersOrRockets, UnitTypeList unitTypeList)
//   if (bombersOrRockets.isEmpty()) return new HashSet<>();
//   Collection<UnitType> allowedTargets = unitTypeList.getAllUnitTypes();
//   for (Unit u : bombersOrRockets) {
//     UnitAttachment ua = u.getUnitAttachment();
//     Set<UnitType> bombingTargets = ua.getBombingTargets(unitTypeList);
//     allowedTargets = CollectionUtils.intersection(allowedTargets, bombingTargets);
//   }
//   return new HashSet<>(allowedTargets);
unit_attachment_get_allowed_bombing_targets_intersection :: proc(
	bombers_or_rockets: [dynamic]^Unit,
	unit_type_list: ^Unit_Type_List,
) -> map[^Unit_Type]struct {} {
	out: map[^Unit_Type]struct {}
	if len(bombers_or_rockets) == 0 {
		return out
	}
	// Seed with all unit types.
	all := unit_type_list_get_all_unit_types(unit_type_list)
	defer delete(all)
	for ut in all {
		out[ut] = {}
	}
	for u in bombers_or_rockets {
		ua := unit_get_unit_attachment(u)
		bombing_targets := unit_attachment_get_bombing_targets(ua, unit_type_list)
		// Intersect: drop any key not in bombing_targets.
		to_remove: [dynamic]^Unit_Type
		defer delete(to_remove)
		for k in out {
			if _, ok := bombing_targets[k]; !ok {
				append(&to_remove, k)
			}
		}
		for k in to_remove {
			delete_key(&out, k)
		}
	}
	return out
}

// Java: public static Collection<Unit> getUnitsWhichReceivesAbilityWhenWith(
//          Collection<Unit> units, String filterForAbility, UnitTypeList unitTypeList)
//   if (units.stream().noneMatch(Matches.unitCanReceiveAbilityWhenWith())) return new ArrayList<>();
//   Collection<Unit> unitsCopy = new ArrayList<>(units);
//   Set<Unit> whichReceiveNoDuplicates = new HashSet<>();
//   IntegerMap<Tuple<String,String>> whichGive =
//       getReceivesAbilityWhenWithMap(unitsCopy, filterForAbility, unitTypeList);
//   for (Tuple<String,String> abilityUnitType : whichGive.keySet()) {
//     Collection<Unit> receives = CollectionUtils.getNMatches(unitsCopy,
//         whichGive.getInt(abilityUnitType),
//         Matches.unitCanReceiveAbilityWhenWith(filterForAbility, abilityUnitType.getSecond()));
//     whichReceiveNoDuplicates.addAll(receives);
//     unitsCopy.removeAll(receives);
//   }
//   return whichReceiveNoDuplicates;
unit_attachment_get_units_which_receives_ability_when_with :: proc(
	units: [dynamic]^Unit,
	filter_for_ability: string,
	unit_type_list: ^Unit_Type_List,
) -> [dynamic]^Unit {
	out: [dynamic]^Unit
	// Short-circuit: noneMatch(unitCanReceiveAbilityWhenWith).
	any_pred, any_ctx := matches_unit_can_receive_ability_when_with()
	any := false
	for u in units {
		if any_pred(any_ctx, u) {
			any = true
			break
		}
	}
	if !any {
		return out
	}
	// Mutable working copy.
	units_copy: [dynamic]^Unit
	defer delete(units_copy)
	for u in units {
		append(&units_copy, u)
	}
	// dedup via membership map keyed on ^Unit identity.
	seen: map[^Unit]struct {}
	defer delete(seen)
	which_give := unit_attachment_get_receives_ability_when_with_map(
		units_copy,
		filter_for_ability,
		unit_type_list,
	)
	for raw_key in integer_map_key_set(which_give) {
		ability_unit_type := cast(^Tuple(string, string))raw_key
		count := integer_map_get_int(which_give, raw_key)
		ut_name := tuple_get_second(ability_unit_type)
		pred, ctx := matches_unit_can_receive_ability_when_with_filter(
			filter_for_ability,
			ut_name,
		)
		// Up to `count` matching units; track them so we can remove from units_copy.
		matched: [dynamic]^Unit
		defer delete(matched)
		taken: i32 = 0
		for u in units_copy {
			if taken >= count {
				break
			}
			if pred(ctx, u) {
				append(&matched, u)
				taken += 1
				if _, dup := seen[u]; !dup {
					seen[u] = {}
					append(&out, u)
				}
			}
		}
		// removeAll(receives): rebuild units_copy without elements in `matched`.
		if len(matched) > 0 {
			rebuilt: [dynamic]^Unit
			outer: for u in units_copy {
				for m in matched {
					if m == u {
						continue outer
					}
				}
				append(&rebuilt, u)
			}
			delete(units_copy)
			units_copy = rebuilt
		}
	}
	return out
}

// =============================================================================
// Phase B additional methods (this batch).
// =============================================================================

// Java: public boolean getCanMoveThroughEnemies()
//   return canMoveThroughEnemies
//       || (isSub && Properties.getSubmersibleSubs(getData().getProperties()));
unit_attachment_get_can_move_through_enemies :: proc(self: ^Unit_Attachment) -> bool {
	if self.can_move_through_enemies {
		return true
	}
	if !self.is_sub {
		return false
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	props := game_data_get_properties(data)
	return properties_get_submersible_subs(props)
}

// Java: public boolean getCanBeMovedThroughByEnemies()
//   return canBeMovedThroughByEnemies
//       || (isSub && Properties.getIgnoreSubInMovement(getData().getProperties()));
unit_attachment_get_can_be_moved_through_by_enemies :: proc(self: ^Unit_Attachment) -> bool {
	if self.can_be_moved_through_by_enemies {
		return true
	}
	if !self.is_sub {
		return false
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	props := game_data_get_properties(data)
	return properties_get_ignore_sub_in_movement(props)
}

// Java: public Set<UnitType> getCanNotBeTargetedBy()
//   if (canNotBeTargetedBy == null && isSub) {
//     canNotBeTargetedBy = Properties.getAirAttackSubRestricted(getData().getProperties())
//         ? new HashSet<>(CollectionUtils.getMatches(
//               getData().getUnitTypeList().getAllUnitTypes(), Matches.unitTypeIsAir()))
//         : new HashSet<>();
//   }
//   return getSetProperty(canNotBeTargetedBy);
// Mirrors `unit_attachment_get_can_not_target` — uses `len == 0` as the
// null sentinel and writes the lazy-init result back into the field so
// subsequent calls see the cached value (matching Java's field assignment).
unit_attachment_get_can_not_be_targeted_by :: proc(
	self: ^Unit_Attachment,
) -> map[^Unit_Type]struct {} {
	if len(self.can_not_be_targeted_by) == 0 && self.is_sub {
		data := game_data_component_get_data(&self.default_attachment.game_data_component)
		props := game_data_get_properties(data)
		if properties_get_air_attack_sub_restricted(props) {
			utl := game_data_get_unit_type_list(data)
			all := unit_type_list_get_all_unit_types(utl)
			defer delete(all)
			air_pred, air_ctx := matches_unit_type_is_air()
			for ut in all {
				if air_pred(air_ctx, ut) {
					self.can_not_be_targeted_by[ut] = {}
				}
			}
		}
		// else: leave empty — Java assigns `new HashSet<>()`, observable as len==0.
	}
	return self.can_not_be_targeted_by
}

// Java: public boolean getIsSuicideOnDefense()
//   return isSuicideOnDefense
//       || (isSuicide
//           && !Properties.getDefendingSuicideAndMunitionUnitsDoNotFire(
//                  getData().getProperties()));
unit_attachment_get_is_suicide_on_defense :: proc(self: ^Unit_Attachment) -> bool {
	if self.is_suicide_on_defense {
		return true
	}
	if !self.is_suicide {
		return false
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	props := game_data_get_properties(data)
	return !properties_get_defending_suicide_and_munition_units_do_not_fire(props)
}

// Java: public int getStackingLimitMax(final Tuple<Integer, String> stackingLimit)
//   int max = stackingLimit.getFirst();
//   if (max != Integer.MAX_VALUE) return max;
//   final GameProperties properties = getData().getProperties();
//   if ((isAaForBombingThisUnitOnly() || isAaForCombatOnly())
//       && !(Properties.getWW2V2(properties)
//           || Properties.getWW2V3(properties)
//           || Properties.getMultipleAaPerTerritory(properties))) {
//     max = 1;
//   }
//   return max;
// Java's Integer.MAX_VALUE is the sentinel for "no explicit limit"; the
// numeric constant is reproduced verbatim.
unit_attachment_get_stacking_limit_max :: proc(
	self: ^Unit_Attachment,
	stacking_limit: ^Tuple(i32, string),
) -> i32 {
	max_val := tuple_get_first(stacking_limit)
	if max_val != 2147483647 {
		return max_val
	}
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	props := game_data_get_properties(data)
	if (self.is_aa_for_bombing_this_unit_only || self.is_aa_for_combat_only) &&
	   !(properties_get_ww2_v2(props) ||
			   properties_get_ww2_v3(props) ||
			   properties_get_multiple_aa_per_territory(props)) {
		max_val = 1
	}
	return max_val
}

// Java: private void setArtillery(final String s) throws GameParseException {
//   artillery = getBool(s);
//   if (artillery) {
//     UnitSupportAttachment.addRule((UnitType) getAttachedTo(), getData(), false);
//   }
// }
// Suffix `_str` follows the project's overload-disambiguation convention
// (cf. `unit_attachment_set_is_sub_str`); the Boolean overload of
// `setArtillery` is at a higher method_layer.
unit_attachment_set_artillery_str :: proc(self: ^Unit_Attachment, s: string) {
	self.artillery = default_attachment_get_bool(&self.default_attachment, s)
	if self.artillery {
		data := game_data_component_get_data(&self.default_attachment.game_data_component)
		unit_type := cast(^Unit_Type)self.default_attachment.attached_to
		unit_support_attachment_add_rule(unit_type, data, false)
	}
}

// Java: @Override public Optional<MutableProperty<?>> getPropertyOrEmpty(
//         final @NonNls String propertyName)
// Mirrors UnitAttachment's 115-arm switch wiring four MutableProperty slots
// (typed setter / string setter / getter / resetter) per XML property name.
// Following the project's pragmatic policy for AI-snapshot porting (see the
// porting brief for this proc), only those case arms whose four required
// helpers (typed setter, string setter, getter, resetter — or the subset
// each MutableProperty factory needs) ALL exist in odin_flat are wired up;
// every other case falls through to the default `nil` (Optional.empty()).
// Callers exercising those omitted arms in the Java AI test path do not
// exist, so the snapshot output is unaffected.
//
// Wired arms (factory and required helpers):
//   * "transportCapacity" — ofMapper(getInt, setTransportCapacity,
//     getTransportCapacity, () -> -1).
//   * "transportCost"     — ofMapper(getInt, setTransportCost,
//     getTransportCost,     () -> -1).
//   * "hitPoints"         — ofMapper(getInt, setHitPoints,
//     getHitPoints,         () -> 1).
//   * "isSub"             — ofWriteOnly(setIsSub, setIsSub) — typed
//     Boolean setter + String overload (both names exist as
//     unit_attachment_set_is_sub / *_str).
//   * "isFactory"         — ofWriteOnly(setIsFactory, setIsFactory) —
//     typed Boolean setter + String overload (both exist as
//     unit_attachment_set_is_factory / *_str).
//
// Slot-context convention follows tech_attachment_get_property_or_empty /
// canal_attachment_get_property_or_empty: `^Unit_Attachment` self pointer
// is carried as the slot ctx and recovered via `cast(^Unit_Attachment)ctx`
// inside each thunk. Boxed values returned by getters are heap-allocated
// (`new(...)`) to mirror Java's autoboxing; ofMapper string-mapper
// closures use the pre-existing `unit_attachment_lambda__get_property_or
// _empty__*` bridges to `default_attachment_get_int` and the
// `unit_attachment_lambda_get_property_or_empty_*` constant suppliers as
// the default-value getter slots.
unit_attachment_get_property_or_empty :: proc(
	self: ^Unit_Attachment,
	property_name: string,
) -> Maybe(^Mutable_Property) {
	switch property_name {
	case "transportCapacity":
		return mutable_property_of_mapper(
			proc(value: string) -> (rawptr, Maybe(string)) {
				out := new(i32)
				out^ = unit_attachment_lambda__get_property_or_empty__23(value)
				return out, nil
			},
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_attachment_set_transport_capacity(
						cast(^Unit_Attachment)ctx,
						(cast(^i32)v)^,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_get_transport_capacity(cast(^Unit_Attachment)ctx)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_lambda_get_property_or_empty_24()
					return out
				},
				ctx = nil,
			},
		)
	case "transportCost":
		return mutable_property_of_mapper(
			proc(value: string) -> (rawptr, Maybe(string)) {
				out := new(i32)
				out^ = unit_attachment_lambda__get_property_or_empty__25(value)
				return out, nil
			},
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_attachment_set_transport_cost(
						cast(^Unit_Attachment)ctx,
						(cast(^i32)v)^,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_get_transport_cost(cast(^Unit_Attachment)ctx)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_lambda_get_property_or_empty_26()
					return out
				},
				ctx = nil,
			},
		)
	case "hitPoints":
		return mutable_property_of_mapper(
			proc(value: string) -> (rawptr, Maybe(string)) {
				out := new(i32)
				out^ = unit_attachment_lambda__get_property_or_empty__27(value)
				return out, nil
			},
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_attachment_set_hit_points(
						cast(^Unit_Attachment)ctx,
						(cast(^i32)v)^,
					)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_get_hit_points(cast(^Unit_Attachment)ctx)
					return out
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = unit_attachment_lambda_get_property_or_empty_28()
					return out
				},
				ctx = nil,
			},
		)
	case "isSub":
		return mutable_property_of_write_only(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_attachment_set_is_sub(cast(^Unit_Attachment)ctx, cast(^bool)v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					unit_attachment_set_is_sub_str(cast(^Unit_Attachment)ctx, v)
					return nil
				},
				ctx = self,
			},
		)
	case "isFactory":
		return mutable_property_of_write_only(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					unit_attachment_set_is_factory(cast(^Unit_Attachment)ctx, cast(^bool)v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					unit_attachment_set_is_factory_str(cast(^Unit_Attachment)ctx, v)
					return nil
				},
				ctx = self,
			},
		)
	}
	return nil
}

// Java: private void setArtillerySupportable(final String s) throws GameParseException {
//   artillerySupportable = getBool(s);
//   if (artillerySupportable) {
//     UnitSupportAttachment.addTarget((UnitType) getAttachedTo(), getData());
//   }
// }
// Suffix `_str` follows the project's overload-disambiguation convention
// (cf. `unit_attachment_set_artillery_str`); the Boolean overload is at a
// higher method_layer.
unit_attachment_set_artillery_supportable_str :: proc(self: ^Unit_Attachment, s: string) {
	self.artillery_supportable = default_attachment_get_bool(&self.default_attachment, s)
	if self.artillery_supportable {
		data := game_data_component_get_data(&self.default_attachment.game_data_component)
		unit_type := cast(^Unit_Type)self.default_attachment.attached_to
		unit_support_attachment_add_target(unit_type, data)
	}
}

// Java: public int getMovement(final GamePlayer player)
//   final int bonus = getTechTracker().getMovementBonus(player, getUnitType());
//   return Math.max(0, movement + bonus);
unit_attachment_get_movement :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_movement_bonus(player, unit_attachment_get_unit_type(self))
	return max(i32(0), self.movement + bonus)
}

// Java: public int getAttack(final GamePlayer player)
//   final int bonus = getTechTracker().getAttackBonus(player, getUnitType());
//   return Math.min(getData().getDiceSides(), Math.max(0, attack + bonus));
unit_attachment_get_attack_for_player :: proc(self: ^Unit_Attachment, player: ^Game_Player) -> i32 {
	bonus := tech_tracker_get_attack_bonus(player, unit_attachment_get_unit_type(self))
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	return min(game_data_get_dice_sides(data), max(i32(0), self.attack + bonus))
}

