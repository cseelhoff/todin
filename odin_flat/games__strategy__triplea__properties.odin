package game

import "core:strings"

// `Properties` doubles as the Odin shim for java.util.Properties.
// games.strategy.triplea.Properties is a Java static utility class with no
// instance state, so the same struct can also serve as the JDK shim used by
// NotificationMessages, OrderedProperties, UserActionText, PoliticsText, etc.
Properties :: struct {
	values: map[string]string,
}

properties_new :: proc() -> ^Properties {
	p := new(Properties)
	p.values = make(map[string]string)
	return p
}

properties_get_property :: proc(self: ^Properties, key: string) -> string {
	if self == nil {
		return ""
	}
	if v, ok := self.values[key]; ok {
		return v
	}
	return ""
}

properties_get_property_or_default :: proc(self: ^Properties, key: string, default_value: string) -> string {
	if self == nil {
		return default_value
	}
	if v, ok := self.values[key]; ok {
		return v
	}
	return default_value
}

properties_set_property :: proc(self: ^Properties, key: string, value: string) {
	if self == nil {
		return
	}
	self.values[key] = value
}

// JDK shim for java.util.Properties#load(InputStream). Java's loader
// understands `key=value`, `key:value`, comments (`#`/`!`), continuation
// lines, and Latin-1 unicode escapes. The snapshot harness only feeds in
// well-formed UTF-8 property files, so we implement the common subset:
// strip blank/comment lines, split on the first `=` or `:`, trim
// surrounding whitespace, and treat a trailing backslash on the
// preceding line as a continuation.
properties_load :: proc(self: ^Properties, stream: ^Input_Stream) {
	if self == nil || stream == nil {
		return
	}
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	for {
		b := input_stream_read(stream)
		if b < 0 {
			break
		}
		strings.write_byte(&sb, u8(b))
	}
	text := strings.to_string(sb)
	pending := strings.builder_make()
	defer strings.builder_destroy(&pending)
	for raw_line in strings.split_lines_iterator(&text) {
		line := strings.trim_left(raw_line, " \t\f")
		if strings.builder_len(pending) == 0 {
			if len(line) == 0 { continue }
			if line[0] == '#' || line[0] == '!' { continue }
		}
		strings.write_string(&pending, line)
		joined := strings.to_string(pending)
		if len(joined) > 0 && joined[len(joined)-1] == '\\' {
			// Drop the trailing backslash and keep accumulating.
			strings.builder_reset(&pending)
			strings.write_string(&pending, joined[:len(joined)-1])
			continue
		}
		// Find the first key/value separator that isn't escaped.
		sep := -1
		i := 0
		for i < len(joined) {
			c := joined[i]
			if c == '\\' { i += 2; continue }
			if c == '=' || c == ':' { sep = i; break }
			if c == ' ' || c == '\t' || c == '\f' { sep = i; break }
			i += 1
		}
		key:   string
		value: string
		if sep < 0 {
			key = strings.trim_space(joined)
			value = ""
		} else {
			key = strings.trim_space(joined[:sep])
			rest := strings.trim_left(joined[sep:], " \t\f")
			if len(rest) > 0 && (rest[0] == '=' || rest[0] == ':') {
				rest = strings.trim_left(rest[1:], " \t\f")
			}
			value = rest
		}
		if len(key) > 0 {
			self.values[key] = value
		}
		strings.builder_reset(&pending)
	}
}

// Java owners covered by this file:
//   - games.strategy.triplea.Properties (static utility class)
//   - java.util.Properties (JDK shim — see procs above)

properties_get_neutral_charge :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "neutralCharge", 0)
}

properties_get_factories_per_country :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "maxFactoriesPerTerritory", 1)
}

properties_get_two_hit_battleships :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Two hit battleship", false)
}

properties_get_ww2_v2 :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "WW2V2", false)
}

properties_get_ww2_v3 :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "WW2V3", false)
}

properties_get_ww2_v3_tech_model :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "WW2V3 Tech Model", false)
}

properties_get_partial_amphibious_retreat :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Partial Amphibious Retreat", false)
}

properties_get_total_victory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Total Victory", false)
}

properties_get_honorable_surrender :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Honorable Surrender", false)
}

properties_get_projection_of_power :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Projection of Power", false)
}

properties_get_all_rockets_attack :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "All Rockets Attack", false)
}

properties_get_neutrals_impassable :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Neutrals Are Impassable", false)
}

properties_get_neutrals_blitzable :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Neutrals Are Blitzable", false)
}

properties_get_rockets_can_fly_over_impassables :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Rockets Can Fly Over Impassables", false)
}

properties_get_sequentially_targeted_rockets :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Target Rockets Sequentially and After SBR", false)
}

properties_get_pacific_theater :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Pacific Theater", false)
}

properties_get_economic_victory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Economic Victory", false)
}

properties_get_triggered_victory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Triggered Victory", false)
}

properties_get_tech_development :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Tech Development", false)
}

properties_get_transport_unload_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Transport Restricted Unload", false)
}

properties_get_limit_rocket_and_sbr_damage_to_production :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Limit SBR Damage To Factory Production", false)
}

properties_get_limit_sbr_damage_per_turn :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Limit SBR Damage Per Turn", false)
}

properties_get_limit_rocket_damage_per_turn :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Limit Rocket Damage Per Turn", false)
}

properties_get_pu_cap :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Territory Turn Limit", false)
}

properties_get_sbr_victory_points :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "SBR Victory Points", false)
}

properties_get_allied_air_independent :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Allied Air Independent", false)
}

properties_get_defending_subs_sneak_attack :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Defending Subs Sneak Attack", false)
}

properties_get_attacker_retreat_planes :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Attacker Retreat Planes", false)
}

properties_get_surviving_air_move_to_land :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Surviving Air Move To Land", false)
}

properties_get_naval_bombard_casualties_return_fire :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Naval Bombard Casualties Return Fire", false)
}

properties_get_blitz_through_factories_and_aa_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Blitz Through Factories And AA Restricted", false)
}

properties_get_unit_placement_in_enemy_seas :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Unit Placement In Enemy Seas", false)
}

properties_get_sub_control_sea_zone_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Sub Control Sea Zone Restricted", false)
}

properties_get_transport_control_sea_zone :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Transport Control Sea Zone", false)
}

properties_get_place_in_any_territory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Place in Any Territory", false)
}

properties_get_unit_placement_per_territory_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Unit Placement Per Territory Restricted", false)
}

properties_get_movement_by_territory_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Movement By Territory Restricted", false)
}

properties_get_transport_casualties_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Transport Casualties Restricted", false)
}

properties_get_ignore_transport_in_movement :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Ignore Transport In Movement", false)
}

properties_get_ignore_sub_in_movement :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Ignore Sub In Movement", false)
}

properties_get_unplaced_units_live :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Unplaced units live when not placed", false)
}

properties_get_air_attack_sub_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Air Attack Sub Restricted", false)
}

properties_get_paratroopers_can_move_during_non_combat :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Paratroopers Can Move During Non Combat", false)
}

properties_get_sub_retreat_before_battle :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Sub Retreat Before Battle", false)
}

properties_get_shore_bombard_per_ground_unit_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Shore Bombard Per Ground Unit Restricted", false)
}

properties_get_aa_territory_restricted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "AA Territory Restricted", false)
}

properties_get_multiple_aa_per_territory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Multiple AA Per Territory", false)
}

properties_get_national_objectives :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "National Objectives", false)
}

properties_get_triggers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Triggers", false)
}

properties_get_always_on_aa :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Always on AA", false)
}

properties_get_lhtr_carrier_production_rules :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "LHTR Carrier production rules", false)
}

properties_get_produce_fighters_on_carriers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Produce fighters on carriers", false)
}

properties_get_produce_new_fighters_on_old_carriers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Produce new fighters on old carriers", false)
}

properties_get_move_existing_fighters_to_new_carriers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Move existing fighters to new carriers", false)
}

properties_get_land_existing_fighters_on_new_carriers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Land existing fighters on new carriers", false)
}

properties_get_heavy_bomber_dice_rolls :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Heavy Bomber Dice Rolls", 2)
}

properties_get_battleships_repair_at_end_of_round :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units Repair Hits End Turn", false)
}

properties_get_battleships_repair_at_beginning_of_round :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units Repair Hits Start Turn", false)
}

properties_get_two_hit_point_units_require_repair_facilities :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Two HitPoint Units Require Repair Facilities", false)
}

properties_get_choose_aa_casualties :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Choose AA Casualties", false)
}

properties_get_submersible_subs :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Submersible Subs", false)
}

properties_get_use_destroyers_and_artillery :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Destroyers and Artillery", false)
}

properties_get_use_shipyards :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Shipyards", false)
}

properties_get_low_luck :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Low Luck", false)
}

properties_get_low_luck_aa_only :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Low Luck for AntiAircraft", false)
}

properties_get_low_luck_damage_only :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Low Luck for Bombing and Territory Damage", false)
}

properties_get_kamikaze_airplanes :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Kamikaze Airplanes", false)
}

properties_get_lhtr_heavy_bombers :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "LHTR Heavy Bombers", false)
}

properties_get_super_sub_defense_bonus :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Super Sub Defence Bonus", 0)
}

properties_get_scramble_rules_in_effect :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Scramble Rules In Effect", false)
}

properties_get_scrambled_units_return_to_base :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Scrambled Units Return To Base", false)
}

properties_get_scramble_to_sea_only :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Scramble To Sea Only", false)
}

properties_get_scramble_from_island_only :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Scramble From Island Only", false)
}

properties_get_scramble_to_any_amphibious_assault :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Scramble To Any Amphibious Assault", false)
}

properties_get_pu_multiplier :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Multiply PUs", 1)
}

properties_get_unlimited_constructions :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Unlimited Constructions", false)
}

properties_get_more_constructions_without_factory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "More Constructions without Factory", false)
}

properties_get_more_constructions_with_factory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "More Constructions with Factory", false)
}

properties_get_unit_placement_restrictions :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Unit Placement Restrictions", false)
}

properties_get_give_units_by_territory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Give Units By Territory", false)
}

properties_get_units_can_be_destroyed_instead_of_captured :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units Can Be Destroyed Instead Of Captured", false)
}

properties_get_defending_suicide_and_munition_units_do_not_fire :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Defending Suicide and Munition Units Do Not Fire", false)
}

properties_get_naval_units_may_not_non_combat_move_into_controlled_sea_zones :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Naval Units May Not NonCombat Move Into Controlled Sea Zones", false)
}

properties_get_units_may_give_bonus_movement :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units May Give Bonus Movement", false)
}

properties_get_capture_units_on_entering_territory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Capture Units On Entering Territory", false)
}

properties_get_on_entering_units_destroyed_instead_of_captured :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "On Entering Units Destroyed Instead Of Captured", false)
}

properties_get_damage_from_bombing_done_to_units_instead_of_territories :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Damage From Bombing Done To Units Instead Of Territories", game_properties_get_bool_with_default(properties, "Damage From Bombing Done To Units Instead Of Territories", false))
}

properties_get_neutral_flyover_allowed :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Neutral Flyover Allowed", false)
}

properties_get_units_can_be_changed_on_capture :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units Can Be Changed On Capture", false)
}

properties_get_use_politics :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Politics", false)
}

properties_get_income_percentage :: proc(game_player: ^Game_Player, properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, constants_get_property_name_income_percentage_for(game_player), 100)
}

properties_get_pu_income_bonus :: proc(game_player: ^Game_Player, properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, constants_get_property_name_pu_income_bonus_for(game_player), 0)
}

properties_get_alliances_can_chain_together :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Alliances Can Chain Together", false)
}

properties_get_raids_may_be_preceeded_by_air_battles :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Raids May Be Preceeded By Air Battles", false)
}

properties_get_battles_may_be_preceeded_by_air_battles :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Battles May Be Preceeded By Air Battles", false)
}

properties_get_use_kamikaze_suicide_attacks :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Kamikaze Suicide Attacks", false)
}

properties_get_kamikaze_suicide_attacks_done_by_current_territory_owner :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Kamikaze Suicide Attacks Done By Current Territory Owner", false)
}

properties_get_force_aa_attacks_for_last_step_of_fly_over :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Force AA Attacks For Last Step Of Fly Over", false)
}

properties_get_paratroopers_can_attack_deep_into_enemy_territory :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Paratroopers Can Attack Deep Into Enemy Territory", false)
}

properties_get_use_bombing_max_dice_sides_and_bonus :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Bombing Max Dice Sides And Bonus", false)
}

properties_get_convoy_blockades_roll_dice_for_cost :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Convoy Blockades Roll Dice For Cost", false)
}

properties_get_subs_can_end_non_combat_move_with_enemies :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Subs Can End NonCombat Move With Enemies", false)
}

properties_get_kamikaze_suicide_attacks_only_where_battles_are :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Kamikaze Suicide Attacks Only Where Battles Are", false)
}

properties_get_submarines_prevent_unescorted_amphibious_assaults :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Submarines Prevent Unescorted Amphibious Assaults", false)
}

properties_get_submarines_defending_may_submerge_or_retreat :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Submarines Defending May Submerge Or Retreat", false)
}

properties_get_air_battle_rounds :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Air Battle Rounds", 1)
}

properties_get_sea_battle_rounds :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Sea Battle Rounds", -1)
}

properties_get_land_battle_rounds :: proc(properties: ^Game_Properties) -> i32 {
	return game_properties_get_int_with_default(properties, "Land Battle Rounds", -1)
}

properties_get_sea_battles_may_be_ignored :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Sea Battles May Be Ignored", false)
}

properties_get_land_battles_may_be_ignored :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Land Battles May Be Ignored", false)
}

properties_get_can_scramble_into_air_battles :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Can Scramble Into Air Battles", false)
}

properties_get_use_fuel_cost :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Use Fuel Cost", false)
}

properties_get_retreating_units_remain_in_place :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Retreating Units Remain In Place", false)
}

properties_get_contested_territories_produce_no_income :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Contested Territories Produce No Income", false)
}

properties_get_all_units_can_attack_from_contested_territories :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "All Units Can Attack From Contested Territories", false)
}

properties_get_abandoned_territories_may_be_taken_over_immediately :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Abandoned Territories May Be Taken Over Immediately", false)
}

properties_get_disabled_players_assets_deleted :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Disabled Players Assets Deleted", false)
}

properties_get_control_all_canals_between_territories_to_pass :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Control All Canals Between Territories To Pass", false)
}

properties_get_enter_territories_with_higher_movement_costs_then_remaining_movement :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Enter Territories With Higher Movement Costs Then Remaining Moves", false)
}

properties_get_units_can_load_in_hostile_sea_zones :: proc(properties: ^Game_Properties) -> bool {
	return game_properties_get_bool_with_default(properties, "Units Can Load In Hostile Sea Zones", false)
}
