package game

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
unit_attachment_get_attack :: proc(self: ^Unit_Attachment) -> i32 {return self.attack}
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