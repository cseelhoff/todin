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
