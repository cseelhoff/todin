package game

import "core:fmt"
import "core:math"

Pro_Purchase_Option :: struct {
	production_rule:            ^Production_Rule,
	unit_type:                  ^Unit_Type,
	player:                     ^Game_Player,
	cost:                       i32,
	costs:                      ^Integer_Map_Resource,
	is_construction:            bool,
	construction_type:          string,
	construction_type_per_turn: i32,
	max_construction_type:      i32,
	movement:                   i32,
	quantity:                   i32,
	hit_points:                 i32,
	attack:                     f64,
	amphib_attack:              f64,
	defense:                    f64,
	transport_cost:             i32,
	carrier_cost:               i32,
	is_air:                     bool,
	is_sub:                     bool,
	is_destroyer:               bool,
	is_transport:               bool,
	is_land_transport:          bool,
	is_carrier:                 bool,
	carrier_capacity:           i32,
	transport_efficiency:       f64,
	cost_per_hit_point:         f64,
	hit_point_efficiency:       f64,
	attack_efficiency:          f64,
	defense_efficiency:         f64,
	max_built_per_player:       i32,
	unit_support_attachments:   map[^Unit_Support_Attachment]struct{},
	is_attack_support:          bool,
	is_defense_support:         bool,
	consumes_units:             bool,
}

pro_purchase_option_get_production_rule :: proc(self: ^Pro_Purchase_Option) -> ^Production_Rule {
	return self.production_rule
}

pro_purchase_option_get_unit_type :: proc(self: ^Pro_Purchase_Option) -> ^Unit_Type {
	return self.unit_type
}

pro_purchase_option_get_cost :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.cost
}

pro_purchase_option_get_costs :: proc(self: ^Pro_Purchase_Option) -> ^Integer_Map_Resource {
	return self.costs
}

pro_purchase_option_is_construction :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_construction
}

pro_purchase_option_get_construction_type :: proc(self: ^Pro_Purchase_Option) -> string {
	return self.construction_type
}

pro_purchase_option_get_construction_type_per_turn :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.construction_type_per_turn
}

pro_purchase_option_get_max_construction_type :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.max_construction_type
}

pro_purchase_option_get_movement :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.movement
}

pro_purchase_option_get_quantity :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.quantity
}

pro_purchase_option_get_attack :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.attack
}

pro_purchase_option_get_defense :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.defense
}

pro_purchase_option_get_transport_cost :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.transport_cost
}

pro_purchase_option_get_carrier_cost :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.carrier_cost
}

pro_purchase_option_is_air :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_air
}

pro_purchase_option_is_sub :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_sub
}

pro_purchase_option_is_destroyer :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_destroyer
}

pro_purchase_option_is_transport :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_transport
}

pro_purchase_option_is_carrier :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_carrier
}

pro_purchase_option_get_transport_efficiency :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.transport_efficiency
}

pro_purchase_option_get_cost_per_hit_point :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.cost_per_hit_point
}

pro_purchase_option_get_attack_efficiency :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.attack_efficiency
}

pro_purchase_option_get_defense_efficiency :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return self.defense_efficiency
}

pro_purchase_option_get_max_built_per_player :: proc(self: ^Pro_Purchase_Option) -> i32 {
	return self.max_built_per_player
}

pro_purchase_option_is_attack_support :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_attack_support
}

pro_purchase_option_is_defense_support :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.is_defense_support
}

pro_purchase_option_is_consumes_units :: proc(self: ^Pro_Purchase_Option) -> bool {
	return self.consumes_units
}

pro_purchase_option_get_transport_efficiency_ratio :: proc(self: ^Pro_Purchase_Option) -> f64 {
	return math.pow(self.transport_efficiency, 30) / f64(self.quantity)
}

pro_purchase_option_calculate_land_distance_factor :: proc(self: ^Pro_Purchase_Option, enemy_distance: i32) -> f64 {
	if self.movement <= 0 {
		// Set 0 move units to an order of magnitude less than 1 move units
		return 0.1
	}
	distance := max(0.0, f64(enemy_distance) - 1.5)
	move_value: i32 = self.movement + 1 if self.is_land_transport else self.movement
	// 1, 2, 2.5, 2.75, etc
	pow_term := math.pow(f64(2), f64(move_value) - 1.0)
	move_factor := 1.0 + 2.0 * (pow_term - 1.0) / pow_term
	return math.pow(move_factor, distance / 5.0)
}

pro_purchase_option_to_string :: proc(self: ^Pro_Purchase_Option, allocator := context.allocator) -> string {
	return fmt.aprintf(
		"%v | cost=%d | moves=%d | quantity=%d | hitPointEfficiency=%.3f | attackEfficiency=%.3f | defenseEfficiency=%.3f | isSub=%v | isTransport=%v | isCarrier=%v",
		self.production_rule,
		self.cost,
		self.movement,
		self.quantity,
		self.hit_point_efficiency,
		self.attack_efficiency,
		self.defense_efficiency,
		self.is_sub,
		self.is_transport,
		self.is_carrier,
		allocator = allocator,
	)
}

pro_purchase_option_calculate_efficiency :: proc(
	self: ^Pro_Purchase_Option,
	attack_factor: f64,
	defense_factor: f64,
	support_attack_factor: f64,
	support_defense_factor: f64,
	distance_factor: f64,
	sea_factor: f64,
	data: ^Game_Data,
) -> f64 {
	hit_point_per_unit_factor := 3.0 + f64(self.hit_points) / f64(self.quantity)
	attack_value :=
		attack_factor *
		(self.attack + support_attack_factor * f64(self.quantity)) *
		6.0 /
		f64(data.dice_sides)
	defense_value :=
		defense_factor *
		(self.defense + support_defense_factor * f64(self.quantity)) *
		6.0 /
		f64(data.dice_sides)
	return math.pow(
		((2.0 * f64(self.hit_points)) + attack_value + defense_value) *
		hit_point_per_unit_factor *
		distance_factor *
		sea_factor /
		f64(self.cost),
		30,
	) / f64(self.quantity)
}

// Java's 6-arg overload: calculateEfficiency(attackFactor, defenseFactor,
//   supportAttackFactor, supportDefenseFactor, distanceFactor, data)
// — delegates to the 7-arg form with seaFactor = 1.
pro_purchase_option_calculate_efficiency_no_sea :: proc(
	self: ^Pro_Purchase_Option,
	attack_factor: f64,
	defense_factor: f64,
	support_attack_factor: f64,
	support_defense_factor: f64,
	distance_factor: f64,
	data: ^Game_Data,
) -> f64 {
	return pro_purchase_option_calculate_efficiency(
		self,
		attack_factor,
		defense_factor,
		support_attack_factor,
		support_defense_factor,
		distance_factor,
		1.0,
		data,
	)
}

pro_purchase_option_create_temp_units :: proc(self: ^Pro_Purchase_Option) -> [dynamic]^Unit {
	return unit_type_create_temp(self.unit_type, self.quantity, self.player)
}

// Java constructor:
//   ProPurchaseOption(ProductionRule, UnitType, GamePlayer, GameData)
// Constants.PUS == "PUs".
pro_purchase_option_new :: proc(
	production_rule: ^Production_Rule,
	unit_type: ^Unit_Type,
	player: ^Game_Player,
	data: ^Game_Data,
) -> ^Pro_Purchase_Option {
	self := new(Pro_Purchase_Option)
	self.production_rule = production_rule
	self.unit_type = unit_type
	self.player = player
	unit_attachment := unit_type_get_unit_attachment(unit_type)
	resource_list := game_data_get_resource_list(data)
	pus := resource_list_get_resource_or_throw(resource_list, "PUs")
	costs_im := production_rule_get_costs(production_rule)
	self.cost = integer_map_get_int(&costs_im, rawptr(pus))

	// Java: costs = productionRule.getCosts(); — IntegerMap<Resource>.
	// Mirror as the typed Integer_Map_Resource alias.
	costs_typed := new(Integer_Map_Resource)
	costs_typed^ = make(Integer_Map_Resource)
	for k, v in costs_im.map_values {
		(costs_typed^)[cast(^Resource)k] = v
	}
	self.costs = costs_typed

	self.is_construction = unit_attachment_is_construction(unit_attachment)
	self.construction_type = unit_attachment_get_construction_type(unit_attachment)
	self.construction_type_per_turn = unit_attachment_get_constructions_per_terr_per_type_per_turn(unit_attachment)
	self.max_construction_type = unit_attachment_get_max_constructions_per_type_per_terr(unit_attachment)
	self.movement = unit_attachment_get_movement_with_player(unit_attachment, player)
	results_im := production_rule_get_results(production_rule)
	self.quantity = integer_map_total_values(&results_im)
	is_infra := unit_attachment_is_infrastructure(unit_attachment)
	self.hit_points = unit_attachment_get_hit_points(unit_attachment) * self.quantity
	if is_infra {
		self.hit_points = 0
	}
	self.attack = f64(unit_attachment_get_attack_with_player(unit_attachment, player)) * f64(self.quantity)
	self.amphib_attack = self.attack + 0.5 * f64(unit_attachment_get_is_marine(unit_attachment)) * f64(self.quantity)
	self.defense = f64(unit_attachment_get_defense(unit_attachment, player)) * f64(self.quantity)
	self.transport_cost = unit_attachment_get_transport_cost(unit_attachment) * self.quantity
	self.carrier_cost = unit_attachment_get_carrier_cost(unit_attachment) * self.quantity
	self.is_air = unit_attachment_is_air(unit_attachment)
	self.is_sub = unit_attachment_get_can_evade(unit_attachment)
	self.is_destroyer = unit_attachment_is_destroyer(unit_attachment)
	self.is_transport = unit_attachment_get_transport_capacity(unit_attachment) > 0
	self.is_land_transport = unit_attachment_is_land_transport(unit_attachment)
	self.is_carrier = unit_attachment_get_carrier_capacity(unit_attachment) > 0
	self.carrier_capacity = unit_attachment_get_carrier_capacity(unit_attachment) * self.quantity
	self.transport_efficiency = f64(unit_attachment_get_transport_capacity(unit_attachment)) / f64(self.cost)
	if self.hit_points == 0 {
		self.cost_per_hit_point = math.INF_F64
	} else {
		self.cost_per_hit_point = f64(self.cost) / f64(self.hit_points)
	}
	dice_sides := f64(data.dice_sides)
	cost_f := f64(self.cost)
	hp_f := f64(self.hit_points)
	self.hit_point_efficiency =
		(hp_f + 0.2 * self.attack * 6.0 / dice_sides + 0.2 * self.defense * 6.0 / dice_sides) /
		cost_f
	self.attack_efficiency =
		(1.0 + hp_f) *
		(hp_f + self.attack * 6.0 / dice_sides + 0.5 * self.defense * 6.0 / dice_sides) /
		cost_f
	self.defense_efficiency =
		(1.0 + hp_f) *
		(hp_f + 0.5 * self.attack * 6.0 / dice_sides + self.defense * 6.0 / dice_sides) /
		cost_f
	self.max_built_per_player = unit_attachment_get_max_built_per_player(unit_attachment)

	// Support fields.
	self.unit_support_attachments = unit_support_attachment_get(unit_type)
	self.is_attack_support = false
	self.is_defense_support = false
	for usa, _ in self.unit_support_attachments {
		if unit_support_attachment_get_offence(usa) {
			self.is_attack_support = true
		}
		if unit_support_attachment_get_defence(usa) {
			self.is_defense_support = true
		}
	}
	self.consumes_units = len(unit_attachment_get_consumes_units(unit_attachment)) > 0
	return self
}

// TODO (Java): doesn't consider enemy support
pro_purchase_option_calculate_support_factor :: proc(
	self: ^Pro_Purchase_Option,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
	data: ^Game_Data,
	defense: bool,
) -> f64 {
	if (!self.is_attack_support && !defense) || (!self.is_defense_support && defense) {
		return 0
	}

	units: [dynamic]^Unit
	for u in units_to_place {
		append(&units, u)
	}
	temp := unit_type_create_temp(self.unit_type, 1, self.player)
	for u in temp {
		append(&units, u)
	}
	delete(temp)

	// Omit units that will be consumed by placing units here.
	to_consume := pro_purchase_utils_get_units_to_consume(self.player, owned_local_units, units)
	defer delete(to_consume)
	for u in owned_local_units {
		consumed := false
		for c in to_consume {
			if c == u {
				consumed = true
				break
			}
		}
		if !consumed {
			append(&units, u)
		}
	}

	utl := game_data_get_unit_type_list(data)
	support_rules_set := unit_type_list_get_support_rules(utl)
	rules_dyn: [dynamic]^Unit_Support_Attachment
	defer delete(rules_dyn)
	for r, _ in support_rules_set {
		append(&rules_dyn, r)
	}
	side: Battle_State_Side = .OFFENSE
	if defense {
		side = .DEFENSE
	}
	available_supports := support_calculator_new(units, rules_dyn, side, true)
	bonus_types := support_calculator_get_unit_support_attachments(available_supports)
	defer delete(bonus_types)

	total_support_factor: f64 = 0
	for usa, _ in self.unit_support_attachments {
		for bonus_type in bonus_types {
			contains := false
			for x in bonus_type {
				if x == usa {
					contains = true
					break
				}
			}
			if !contains {
				continue
			}

			// Find number of support provided and supportable units.
			num_added_support := unit_support_attachment_get_number(usa)
			if unit_support_attachment_get_imp_art_tech(usa) &&
			   tech_tracker_has_improved_artillery_support(self.player) {
				num_added_support *= 2
			}
			num_support_provided: i32 = -num_added_support
			supportable_units := make(map[^Unit]struct {})
			for usa2 in bonus_type {
				num_support_provided += support_calculator_get_support(available_supports, usa2)
				types := unit_support_attachment_get_unit_type(usa2)
				for u in units {
					if _, ok := types[unit_get_type(u)]; ok {
						supportable_units[u] = struct {}{}
					}
				}
			}
			num_supportable_units := i32(len(supportable_units))
			delete(supportable_units)

			// Find ratio of supportable to support units (optimal 2 to 1).
			num_extra_supportable_units := max(i32(0), num_supportable_units - num_support_provided)

			// Ranges from 0 to 1.
			ratio := min(
				1.0,
				2.0 * f64(num_extra_supportable_units) /
				f64(num_supportable_units + num_added_support),
			)

			// Find approximate strength bonus provided.
			bonus: f64 = 0
			if unit_support_attachment_get_strength(usa) {
				bonus += f64(unit_support_attachment_get_bonus(usa))
			}
			if unit_support_attachment_get_roll(usa) {
				bonus += f64(unit_support_attachment_get_bonus(usa)) * f64(data.dice_sides) * 0.75
			}

			// Find support factor value.
			support_factor := math.pow(f64(num_added_support) * 0.9, 0.9) * bonus * ratio
			total_support_factor += support_factor
			pro_logger_trace(
				fmt.tprintf(
					"%s, bonusType=%v, supportFactor=%v, numSupportProvided=%d, numSupportableUnits=%d, numAddedSupport=%d, ratio=%v, bonus=%v",
					default_named_get_name(&self.unit_type.named_attachable.default_named),
					unit_support_attachment_get_bonus_type(usa),
					support_factor,
					num_support_provided,
					num_supportable_units,
					num_added_support,
					ratio,
					bonus,
				),
			)
		}
	}
	pro_logger_debug(
		fmt.tprintf(
			"%s, defense=%v, totalSupportFactor=%v",
			default_named_get_name(&self.unit_type.named_attachable.default_named),
			defense,
			total_support_factor,
		),
	)
	return total_support_factor
}

pro_purchase_option_get_fodder_efficiency :: proc(
	self: ^Pro_Purchase_Option,
	enemy_distance: i32,
	data: ^Game_Data,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
) -> f64 {
	support_attack_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, false,
	)
	support_defense_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, true,
	)
	distance_factor := math.sqrt(
		pro_purchase_option_calculate_land_distance_factor(self, enemy_distance),
	)
	return pro_purchase_option_calculate_efficiency_no_sea(
		self, 0.25, 0.25, support_attack_factor, support_defense_factor, distance_factor, data,
	)
}

pro_purchase_option_get_attack_efficiency_with_args :: proc(
	self: ^Pro_Purchase_Option,
	enemy_distance: i32,
	data: ^Game_Data,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
) -> f64 {
	support_attack_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, false,
	)
	support_defense_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, true,
	)
	distance_factor := pro_purchase_option_calculate_land_distance_factor(self, enemy_distance)
	return pro_purchase_option_calculate_efficiency_no_sea(
		self, 1.25, 0.75, support_attack_factor, support_defense_factor, distance_factor, data,
	)
}

pro_purchase_option_get_defense_efficiency_with_args :: proc(
	self: ^Pro_Purchase_Option,
	enemy_distance: i32,
	data: ^Game_Data,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
) -> f64 {
	support_attack_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, false,
	)
	support_defense_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, true,
	)
	distance_factor := pro_purchase_option_calculate_land_distance_factor(self, enemy_distance)
	return pro_purchase_option_calculate_efficiency_no_sea(
		self, 0.75, 1.25, support_attack_factor, support_defense_factor, distance_factor, data,
	)
}

// Returns the sea defense efficiency for the specified units if this purchase option is selected.
pro_purchase_option_get_sea_defense_efficiency :: proc(
	self: ^Pro_Purchase_Option,
	data: ^Game_Data,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
	need_destroyer: bool,
	unused_carrier_capacity: i32,
	unused_local_carrier_capacity: i32,
) -> f64 {
	if self.is_air &&
	   (self.carrier_cost <= 0 ||
		   self.carrier_cost > unused_carrier_capacity ||
		   !properties_get_produce_fighters_on_carriers(game_data_get_properties(data))) {
		return 0
	}
	support_attack_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, false,
	)
	support_defense_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, true,
	)
	sea_factor: f64 = 1
	if need_destroyer && self.is_destroyer {
		sea_factor = 8
	}
	if self.is_air || (self.carrier_capacity > 0 && unused_local_carrier_capacity <= 0) {
		sea_factor = 4
	}
	return pro_purchase_option_calculate_efficiency(
		self,
		0.75,
		1,
		support_attack_factor,
		support_defense_factor,
		f64(self.movement),
		sea_factor,
		data,
	)
}

// Calculates amphibious assault efficiency coefficient.
pro_purchase_option_get_amphib_efficiency :: proc(
	self: ^Pro_Purchase_Option,
	data: ^Game_Data,
	owned_local_units: [dynamic]^Unit,
	units_to_place: [dynamic]^Unit,
) -> f64 {
	support_attack_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, false,
	)
	support_defense_factor := pro_purchase_option_calculate_support_factor(
		self, owned_local_units, units_to_place, data, true,
	)
	hit_point_per_unit_factor := 3.0 + f64(self.hit_points) / f64(self.quantity)
	transport_cost_factor := math.pow(1.0 / f64(self.transport_cost), 0.2)
	dice_sides := f64(data.dice_sides)
	attack_value :=
		(self.amphib_attack + support_attack_factor * f64(self.quantity)) * 6.0 / dice_sides
	defense_value :=
		(self.defense + support_defense_factor * f64(self.quantity)) * 6.0 / dice_sides
	return math.pow(
		((2.0 * f64(self.hit_points)) + attack_value + defense_value) *
		hit_point_per_unit_factor *
		transport_cost_factor /
		f64(self.cost),
		30,
	) / f64(self.quantity)
}
