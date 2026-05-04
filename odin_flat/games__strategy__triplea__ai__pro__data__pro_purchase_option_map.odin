package game

import "core:fmt"
import "core:strings"

Pro_Purchase_Option_Map :: struct {
	land_fodder_options:    [dynamic]^Pro_Purchase_Option,
	land_attack_options:    [dynamic]^Pro_Purchase_Option,
	land_defense_options:   [dynamic]^Pro_Purchase_Option,
	land_zero_move_options: [dynamic]^Pro_Purchase_Option,
	air_options:            [dynamic]^Pro_Purchase_Option,
	sea_defense_options:    [dynamic]^Pro_Purchase_Option,
	sea_transport_options:  [dynamic]^Pro_Purchase_Option,
	sea_carrier_options:    [dynamic]^Pro_Purchase_Option,
	sea_sub_options:        [dynamic]^Pro_Purchase_Option,
	aa_options:             [dynamic]^Pro_Purchase_Option,
	factory_options:        [dynamic]^Pro_Purchase_Option,
	special_options:        [dynamic]^Pro_Purchase_Option,
}
// Java owners covered by this file:
//   - games.strategy.triplea.ai.pro.data.ProPurchaseOptionMap

pro_purchase_option_map_get_land_fodder_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_fodder_options
}

pro_purchase_option_map_get_land_attack_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_attack_options
}

pro_purchase_option_map_get_land_defense_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_defense_options
}

pro_purchase_option_map_get_land_zero_move_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.land_zero_move_options
}

pro_purchase_option_map_get_air_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.air_options
}

pro_purchase_option_map_get_sea_defense_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.sea_defense_options
}

pro_purchase_option_map_get_sea_transport_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.sea_transport_options
}

pro_purchase_option_map_get_aa_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.aa_options
}

pro_purchase_option_map_get_factory_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	return self.factory_options
}

pro_purchase_option_map_get_land_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	seen: map[^Pro_Purchase_Option]struct{}
	defer delete(seen)
	result: [dynamic]^Pro_Purchase_Option
	for ppo in self.land_fodder_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.land_attack_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.land_defense_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	return result
}

pro_purchase_option_map_get_sea_options :: proc(self: ^Pro_Purchase_Option_Map) -> [dynamic]^Pro_Purchase_Option {
	seen: map[^Pro_Purchase_Option]struct{}
	defer delete(seen)
	result: [dynamic]^Pro_Purchase_Option
	for ppo in self.sea_defense_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_transport_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_carrier_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	for ppo in self.sea_sub_options {
		if _, ok := seen[ppo]; !ok {
			seen[ppo] = {}
			append(&result, ppo)
		}
	}
	return result
}

pro_purchase_option_map_can_unit_type_suicide :: proc(self: ^Pro_Purchase_Option_Map, unit_type: ^Unit_Type, player: ^Game_Player) -> bool {
	ua := unit_type_get_unit_attachment(unit_type)
	return (unit_attachment_get_is_suicide_on_attack(ua) &&
			unit_attachment_get_movement_with_player(ua, player) > 0) ||
		unit_attachment_get_is_suicide_on_defense(ua)
}

pro_purchase_option_map_log_options :: proc(purchase_options: [dynamic]^Pro_Purchase_Option, name: string) {
	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)
	strings.write_string(&sb, name)
	for ppo in purchase_options {
		ut := pro_purchase_option_get_unit_type(ppo)
		strings.write_string(&sb, default_named_get_name(&ut.named_attachable.default_named))
		strings.write_string(&sb, ", ")
	}
	buf := strings.to_string(sb)
	if len(buf) >= 2 {
		buf = buf[:len(buf) - 2]
	}
	pro_logger_debug(buf)
}

// Java: ProPurchaseOptionMap(GamePlayer player, GameData data)
// Mirrors the constructor exactly: classify every UnitType-producing
// ProductionRule from the player's production frontier into the matching
// option list, mirror the Java empty-attack/empty-defense fallback, and
// emit the per-category log lines via pro_purchase_option_map_log_options.
pro_purchase_option_map_new :: proc(player: ^Game_Player, data: ^Game_Data) -> ^Pro_Purchase_Option_Map {
	self := new(Pro_Purchase_Option_Map)

	pro_logger_info("Purchase Options")

	production_frontier := player.production_frontier
	if production_frontier == nil {
		return self
	}
	rules := production_frontier_get_rules(production_frontier)
	if rules == nil {
		return self
	}

	for rule in rules {
		// Java: NamedAttachable resourceOrUnit = rule.getAnyResultKey();
		// rule.results is an Integer_Map keyed by ^Named_Attachable stored
		// as rawptr; pull any one entry. Same pattern as
		// tuv_costs_calculator_compute_base_costs_for_player.
		any_named: ^Named_Attachable = nil
		for k, _ in rule.results.map_values {
			any_named = cast(^Named_Attachable)k
			break
		}
		if any_named == nil || any_named.default_named.named.kind != .Unit_Type {
			continue
		}
		unit_type := cast(^Unit_Type)any_named
		ua := unit_type_get_unit_attachment(unit_type)

		if unit_attachment_is_suicide_on_hit(ua) ||
		   pro_purchase_option_map_can_unit_type_suicide(self, unit_type, player) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			append(&self.special_options, ppo)
			pro_logger_debug(fmt.tprintf("Special: %s", pro_purchase_option_to_string(ppo)))
			continue
		}

		produce_p, produce_c := matches_unit_type_can_produce_units()
		infra_p, infra_c := matches_unit_type_is_infrastructure()
		if produce_p(produce_c, unit_type) && infra_p(infra_c, unit_type) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			append(&self.factory_options, ppo)
			pro_logger_debug(fmt.tprintf("Factory: %s", pro_purchase_option_to_string(ppo)))
			continue
		}

		land_p, land_c := matches_unit_type_is_land()
		if unit_attachment_get_movement_with_player(ua, player) <= 0 && land_p(land_c, unit_type) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			append(&self.land_zero_move_options, ppo)
			pro_logger_debug(fmt.tprintf("Zero Move Land: %s", pro_purchase_option_to_string(ppo)))
			continue
		}

		if land_p(land_c, unit_type) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			if !infra_p(infra_c, unit_type) {
				append(&self.land_fodder_options, ppo)
			}
			if (pro_purchase_option_get_attack(ppo) > 0 || pro_purchase_option_is_attack_support(ppo)) &&
			   (pro_purchase_option_get_attack(ppo) >= pro_purchase_option_get_defense(ppo) ||
				   pro_purchase_option_get_movement(ppo) > 1) {
				append(&self.land_attack_options, ppo)
			}
			if (pro_purchase_option_get_defense(ppo) > 0 || pro_purchase_option_is_defense_support(ppo)) &&
			   (pro_purchase_option_get_defense(ppo) >= pro_purchase_option_get_attack(ppo) ||
				   pro_purchase_option_get_movement(ppo) > 1) {
				append(&self.land_defense_options, ppo)
			}
			aa_p, aa_c := matches_unit_type_is_aa_for_bombing_this_unit_only()
			if aa_p(aa_c, unit_type) {
				append(&self.aa_options, ppo)
			}
			pro_logger_debug(fmt.tprintf("Land: %s", pro_purchase_option_to_string(ppo)))
			continue
		}

		air_p, air_c := matches_unit_type_is_air()
		if air_p(air_c, unit_type) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			append(&self.air_options, ppo)
			pro_logger_debug(fmt.tprintf("Air: %s", pro_purchase_option_to_string(ppo)))
			continue
		}

		sea_p, sea_c := matches_unit_type_is_sea()
		if sea_p(sea_c, unit_type) {
			ppo := pro_purchase_option_new(rule, unit_type, player, data)
			if !pro_purchase_option_is_sub(ppo) {
				append(&self.sea_defense_options, ppo)
			}
			if pro_purchase_option_is_transport(ppo) {
				append(&self.sea_transport_options, ppo)
			}
			if pro_purchase_option_is_carrier(ppo) {
				append(&self.sea_carrier_options, ppo)
			}
			if pro_purchase_option_is_sub(ppo) {
				append(&self.sea_sub_options, ppo)
			}
			pro_logger_debug(fmt.tprintf("Sea: %s", pro_purchase_option_to_string(ppo)))
			continue
		}
	}

	if len(self.land_attack_options) == 0 {
		for ppo in self.land_defense_options {
			append(&self.land_attack_options, ppo)
		}
	}
	if len(self.land_defense_options) == 0 {
		for ppo in self.land_attack_options {
			append(&self.land_defense_options, ppo)
		}
	}

	pro_logger_info("Purchase Categories")
	pro_purchase_option_map_log_options(self.land_fodder_options, "Land Fodder Options: ")
	pro_purchase_option_map_log_options(self.land_attack_options, "Land Attack Options: ")
	pro_purchase_option_map_log_options(self.land_defense_options, "Land Defense Options: ")
	pro_purchase_option_map_log_options(self.land_zero_move_options, "Land Zero Move Options: ")
	pro_purchase_option_map_log_options(self.air_options, "Air Options: ")
	pro_purchase_option_map_log_options(self.sea_defense_options, "Sea Defense Options: ")
	pro_purchase_option_map_log_options(self.sea_transport_options, "Sea Transport Options: ")
	pro_purchase_option_map_log_options(self.sea_carrier_options, "Sea Carrier Options: ")
	pro_purchase_option_map_log_options(self.sea_sub_options, "Sea Sub Options: ")
	pro_purchase_option_map_log_options(self.aa_options, "AA Options: ")
	pro_purchase_option_map_log_options(self.factory_options, "Factory Options: ")
	pro_purchase_option_map_log_options(self.special_options, "Special Options: ")

	return self
}

