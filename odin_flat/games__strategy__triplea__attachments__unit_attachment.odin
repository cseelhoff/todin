package game

// Port of games.strategy.triplea.attachments.UnitAttachment.
// Despite the misleading name, this attaches not to individual Units but to
// UnitTypes. Empty collection fields default to nil/zero in Odin (matching
// Java's null-default for memory/serialization minimization).
Unit_Attachment :: struct {
	using parent: Default_Attachment,

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
