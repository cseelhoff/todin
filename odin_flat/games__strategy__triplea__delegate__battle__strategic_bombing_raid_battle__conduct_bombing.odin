package game

import "core:fmt"

Strategic_Bombing_Raid_Battle_Conduct_Bombing :: struct {
	using i_executable: I_Executable,
	dice:               [dynamic]i32,
	outer:              ^Strategic_Bombing_Raid_Battle,
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#<init>(StrategicBombingRaidBattle)
//
// Java: `new ConductBombing()` from the enclosing StrategicBombingRaidBattle
// captures the implicit outer-class reference. Java declares only the
// `int[] dice` instance field (default-null) and `serialVersionUID`.
strategic_bombing_raid_battle_conduct_bombing_new :: proc(
	outer: ^Strategic_Bombing_Raid_Battle,
) -> ^Strategic_Bombing_Raid_Battle_Conduct_Bombing {
	self := new(Strategic_Bombing_Raid_Battle_Conduct_Bombing)
	self.outer = outer
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#lambda$addToTargetDiceMap$0(Unit)
//
// Java: `targetToDiceMap.computeIfAbsent(target, unit -> new ArrayList<>())`.
// The lambda body is `new ArrayList<>()` — a fresh empty list keyed by `unit`.
strategic_bombing_raid_battle_conduct_bombing_lambda_add_to_target_dice_map_0 :: proc(
	unit: ^Unit,
) -> [dynamic]^Die {
	_ = unit
	return [dynamic]^Die{}
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#execute(ExecutionStack, IDelegateBridge)
//
// Java pushes two anonymous IExecutable instances (rollDice, findCost) onto
// the enclosing StrategicBombingRaidBattle.this.stack in reverse order of
// execution so rollDice runs first.
strategic_bombing_raid_battle_conduct_bombing_execute :: proc(
	self: ^I_Executable,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	_ = bridge
	cb := cast(^Strategic_Bombing_Raid_Battle_Conduct_Bombing)self

	roll_dice := conduct_bombing_1_new(cb)
	roll_dice.execute = conduct_bombing_1_execute

	find_cost := conduct_bombing_2_new(cb)
	find_cost.execute = conduct_bombing_2_execute

	// push in reverse order of execution
	execution_stack_push_one(cb.outer.stack, &find_cost.i_executable)
	execution_stack_push_one(cb.outer.stack, &roll_dice.i_executable)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#rollDie(IDelegateBridge,String,int,int,int,int)
//
// Java mirrors a single die roll for one attacker. Note Java assigns to
// `dice[dieIndex]` inside the loop over diceRolls, overwriting on each
// iteration; we faithfully reproduce that behavior.
strategic_bombing_raid_battle_conduct_bombing_roll_die :: proc(
	self: ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
	bridge: ^I_Delegate_Bridge,
	annotation: string,
	max_dice: i32,
	rolls: i32,
	die_index: i32,
	bonus: i32,
) {
	if max_dice > 0 {
		dice_rolls := i_delegate_bridge_get_random(
			bridge,
			max_dice,
			rolls,
			self.outer.attacker,
			I_Random_Stats_Dice_Type.BOMBING,
			annotation,
		)
		for die in dice_rolls {
			self.dice[die_index] = max(i32(-1), die + bonus)
		}
	} else {
		for i in 0 ..< rolls {
			_ = i
			self.dice[die_index] = max(i32(-1), bonus)
		}
	}
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#addToTargetDiceMap(Unit, Die, Map<Unit,List<Die>>)
//
// Java: targetToDiceMap.computeIfAbsent(target, unit -> new ArrayList<>()).add(roll);
strategic_bombing_raid_battle_conduct_bombing_add_to_target_dice_map :: proc(
	self: ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
	attacker_unit: ^Unit,
	roll: ^Die,
	target_to_dice_map: map[^Unit][dynamic]^Die,
) {
	if len(self.outer.targets) == 0 {
		return
	}
	target := strategic_bombing_raid_battle_get_target(self.outer, attacker_unit)
	m := target_to_dice_map
	if _, ok := m[target]; !ok {
		m[target] = strategic_bombing_raid_battle_conduct_bombing_lambda_add_to_target_dice_map_0(target)
	}
	list := m[target]
	append(&list, roll)
	m[target] = list
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#rollDiceComplex(IDelegateBridge,boolean,boolean,String)
//
// Java: per-attacker dice roll path used when low-luck or bombing-bonus is
// active. Walks attacking_units, computes maxDice/bonus per unit (subject
// to lowLuck reduction), and delegates to rollDie which writes into
// `dice[nextDieIndex]`.
strategic_bombing_raid_battle_conduct_bombing_roll_dice_complex :: proc(
	self:              ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
	bridge:            ^I_Delegate_Bridge,
	use_bombing_bonus: bool,
	low_luck:          bool,
	annotation:        string,
) {
	next_die_index: i32 = 0
	for u in self.outer.attacking_units {
		rolls := strategic_bombing_raid_battle_get_sbr_rolls_unit(u, self.outer.attacker)
		if rolls < 1 {
			continue
		}

		ua := unit_get_unit_attachment(u)
		max_dice := unit_attachment_get_bombing_max_die_sides(ua)
		// both could be -1, meaning they were not set. if they were not set, then we use
		// default dice sides for the map, and zero for the bonus.
		if max_dice < 0 || !use_bombing_bonus {
			max_dice = self.outer.game_data.dice_sides
		}
		bonus: i32 = 0
		if use_bombing_bonus {
			bonus = unit_attachment_get_bombing_bonus(ua)
		}

		// now, regardless of whether they were set or not, we have to apply "low luck" to them,
		// meaning in this case that we reduce the luck by 2/3.
		if low_luck && max_dice >= 5 {
			bonus += (max_dice + 1) / 3
			max_dice = (max_dice + 1) / 3
		}

		// now we roll, or don't if there is nothing to roll.
		strategic_bombing_raid_battle_conduct_bombing_roll_die(
			self,
			bridge,
			annotation,
			max_dice,
			rolls,
			next_die_index,
			bonus,
		)
		next_die_index += 1
	}
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#rollDice(IDelegateBridge)
//
// Java: roll dice for the bombing raid; if no rolls, set dice = null and
// return. Edit-mode uses Player.selectFixedDice. Otherwise, the simple
// case (no low-luck, no bombing-bonus) calls bridge.getRandom directly,
// while the complex case delegates to rollDiceComplex.
strategic_bombing_raid_battle_conduct_bombing_roll_dice :: proc(
	self:   ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
	bridge: ^I_Delegate_Bridge,
) {
	outer := self.outer
	roll_count := strategic_bombing_raid_battle_get_sbr_rolls(outer.attacking_units[:], outer.attacker)
	if roll_count == 0 {
		self.dice = nil
		return
	}
	self.dice = make([dynamic]i32, roll_count)

	is_edit_mode := edit_delegate_get_edit_mode(game_data_get_properties(outer.game_data))
	if is_edit_mode {
		annotation := fmt.aprintf(
			"%s fixing dice to allocate cost of strategic bombing raid against %s in %s",
			outer.attacker.name,
			outer.defender.name,
			outer.battle_site.name,
		)
		attacker_player := i_delegate_bridge_get_remote_player(bridge, outer.attacker)
		// does not take into account bombers with dice sides higher than getDiceSides
		fixed := player_select_fixed_dice(
			attacker_player,
			roll_count,
			0,
			annotation,
			outer.game_data.dice_sides,
		)
		delete(self.dice)
		self.dice = fixed
		return
	}

	annotation := fmt.aprintf(
		"%s rolling to allocate cost of strategic bombing raid against %s in %s",
		outer.attacker.name,
		outer.defender.name,
		outer.battle_site.name,
	)
	low_luck := properties_get_low_luck_damage_only(game_data_get_properties(outer.game_data))
	use_bombing_bonus := properties_get_use_bombing_max_dice_sides_and_bonus(
		game_data_get_properties(outer.game_data),
	)
	if !low_luck && !use_bombing_bonus {
		// no low luck, and no bonus, so just roll based on the map's dice sides
		dice_sides := outer.game_data.dice_sides
		rolled := i_delegate_bridge_get_random(
			bridge,
			dice_sides,
			roll_count,
			outer.attacker,
			I_Random_Stats_Dice_Type.BOMBING,
			annotation,
		)
		delete(self.dice)
		self.dice = rolled
		return
	}

	strategic_bombing_raid_battle_conduct_bombing_roll_dice_complex(
		self,
		bridge,
		use_bombing_bonus,
		low_luck,
		annotation,
	)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing#findCost(IDelegateBridge)
//
// Java: aggregate per-attacker damage, applying LHTR best-roll selection,
// tech bonuses, optional damage caps (WW2v2 / limit-to-production / PU cap /
// limit-sbr-per-turn), and either damage-units or PU-cost reporting paths.
strategic_bombing_raid_battle_conduct_bombing_find_cost :: proc(
	self:   ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
	bridge: ^I_Delegate_Bridge,
) {
	outer := self.outer
	// if no planes left after aa fires, this is possible
	if len(outer.attacking_units) == 0 {
		return
	}
	// TerritoryAttachment.getProduction(battleSite)
	damage_limit: i32 = 0
	if ta := territory_attachment_get(outer.battle_site); ta != nil {
		damage_limit = territory_attachment_get_production(ta)
	}
	cost: i32 = 0
	lhtr_bombers := properties_get_lhtr_heavy_bombers(game_data_get_properties(outer.game_data))
	index: i32 = 0
	limit_damage :=
		properties_get_ww2_v2(game_data_get_properties(outer.game_data)) ||
		properties_get_limit_rocket_and_sbr_damage_to_production(
			game_data_get_properties(outer.game_data),
		)
	bombing_dice: [dynamic]^Die
	target_to_dice_map := make(map[^Unit][dynamic]^Die)

	// Lazy-allocate the rawptr-keyed bombing_raid_damage map so subsequent
	// integer_map_add / integer_map_put calls have a backing store to write to.
	if outer.bombing_raid_damage.map_values == nil {
		outer.bombing_raid_damage.map_values = make(map[rawptr]i32)
	}

	// limit to maxDamage
	for attacker_unit in outer.attacking_units {
		ua := unit_get_unit_attachment(attacker_unit)
		rolls := strategic_bombing_raid_battle_get_sbr_rolls_unit(attacker_unit, outer.attacker)
		cost_this_unit: i32 = 0
		if rolls > 1 && (lhtr_bombers || unit_attachment_get_choose_best_roll(ua)) {
			// LHTR means we select the best Dice roll for the unit
			max_val: i32 = 0
			max_index := index
			start_index := index
			for i: i32 = 0; i < rolls; i += 1 {
				// +1 since 0 based
				if self.dice[index] + 1 > max_val {
					max_val = self.dice[index] + 1
					max_index = index
				}
				index += 1
			}
			cost_this_unit = max_val
			// for show
			best := new(Die)
			best^ = die_new_from_value(self.dice[max_index])
			append(&bombing_dice, best)
			strategic_bombing_raid_battle_conduct_bombing_add_to_target_dice_map(
				self,
				attacker_unit,
				best,
				target_to_dice_map,
			)
			for i: i32 = 0; i < rolls; i += 1 {
				if start_index != max_index {
					not_best := new(Die)
					not_best^ = die_new(self.dice[start_index], -1, .IGNORED)
					append(&bombing_dice, not_best)
					strategic_bombing_raid_battle_conduct_bombing_add_to_target_dice_map(
						self,
						attacker_unit,
						not_best,
						target_to_dice_map,
					)
				}
				start_index += 1
			}
		} else {
			for i: i32 = 0; i < rolls; i += 1 {
				cost_this_unit += self.dice[index] + 1
				d := new(Die)
				d^ = die_new_from_value(self.dice[index])
				append(&bombing_dice, d)
				strategic_bombing_raid_battle_conduct_bombing_add_to_target_dice_map(
					self,
					attacker_unit,
					d,
					target_to_dice_map,
				)
				index += 1
			}
		}

		bonus := tech_tracker_get_bombing_bonus(
			unit_get_owner(attacker_unit),
			unit_get_type(attacker_unit),
		)
		cost_this_unit = max(i32(0), cost_this_unit + bonus)
		if limit_damage {
			cost_this_unit = min(cost_this_unit, damage_limit)
		}
		cost += cost_this_unit
		if len(outer.targets) != 0 {
			integer_map_add(
				&outer.bombing_raid_damage,
				rawptr(strategic_bombing_raid_battle_get_target(outer, attacker_unit)),
				cost_this_unit,
			)
		}
	}

	// Limit PUs lost if we would like to cap PUs lost at territory value
	if properties_get_pu_cap(game_data_get_properties(outer.game_data)) ||
	   properties_get_limit_sbr_damage_per_turn(game_data_get_properties(outer.game_data)) {
		already_lost := move_delegate_pus_already_lost(
			game_data_get_move_delegate(outer.game_data),
			outer.battle_site,
		)
		limit := max(i32(0), damage_limit - already_lost)
		cost = min(cost, limit)
		if len(outer.targets) != 0 {
			keys := integer_map_key_set(&outer.bombing_raid_damage)
			defer delete(keys)
			for k in keys {
				if integer_map_get_int(&outer.bombing_raid_damage, k) > limit {
					integer_map_put(&outer.bombing_raid_damage, k, limit)
				}
			}
		}
	}

	// If we damage units instead of territories
	if properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(outer.game_data),
	) {
		// at this point, bombingRaidDamage should contain all units that targets contains
		damaged_keys := integer_map_key_set(&outer.bombing_raid_damage)
		defer delete(damaged_keys)
		for k in damaged_keys {
			u := cast(^Unit)k
			if _, ok := outer.targets[u]; !ok {
				panic("targets should contain all damaged units")
			}
		}
		for k in damaged_keys {
			current := cast(^Unit)k
			current_unit_cost := integer_map_get_int(&outer.bombing_raid_damage, k)
			// determine the max allowed damage
			damage_limit = unit_get_how_much_more_damage_can_this_unit_take(
				current,
				outer.battle_site,
			)
			if integer_map_get_int(&outer.bombing_raid_damage, k) > damage_limit {
				integer_map_put(&outer.bombing_raid_damage, k, damage_limit)
				cost = (cost - current_unit_cost) + damage_limit
				current_unit_cost = integer_map_get_int(&outer.bombing_raid_damage, k)
			}
			total_damage := unit_get_unit_damage(current) + current_unit_cost
			// display the results
			if client_setting_use_websocket_network() {
				msg := i_display_bombing_results_message_new(
					outer.battle_id,
					bombing_dice,
					current_unit_cost,
				)
				i_delegate_bridge_send_message(bridge, cast(^Web_Socket_Message)msg)
			} else {
				display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
				i_display_bombing_results(
					display,
					outer.battle_id,
					bombing_dice,
					int(current_unit_cost),
				)
			}

			if current_unit_cost > 0 {
				channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
				headless_sound_channel_play_sound_for_all(
					channel,
					"bombing_strategic",
					outer.attacker,
				)
			}
			// Record production lost
			move_delegate_pus_lost(
				game_data_get_move_delegate(outer.game_data),
				outer.battle_site,
				current_unit_cost,
			)
			// apply the hits to the targets
			damage_map := new(Integer_Map_Unit)
			damage_map.entries = make(map[^Unit]i32)
			damage_map.entries[current] = total_damage
			territories: [dynamic]^Territory
			append(&territories, outer.battle_site)
			i_delegate_bridge_add_change(
				bridge,
				change_factory_bombing_unit_damage(damage_map, territories),
			)
			history_msg := fmt.aprintf(
				"Bombing raid in %s rolls: %s and causes: %d damage to unit: %s",
				outer.battle_site.name,
				my_formatter_as_dice_list(target_to_dice_map[current]),
				current_unit_cost,
				unit_get_type(current).named.base.name,
			)
			history_writer := i_delegate_bridge_get_history_writer(bridge)
			i_delegate_history_writer_add_child_to_event(history_writer, history_msg)
			report_long := fmt.aprintf(
				"Bombing raid in %s rolls: %s and causes: %d damage to unit: %s",
				outer.battle_site.name,
				my_formatter_as_dice_list(target_to_dice_map[current]),
				current_unit_cost,
				unit_get_type(current).named.base.name,
			)
			report_short := fmt.aprintf(
				"Bombing raid causes %d damage to %s",
				current_unit_cost,
				unit_get_type(current).named.base.name,
			)
			i_remote_player_report_message(
				abstract_battle_get_remote_bridge(bridge),
				report_long,
				report_short,
			)
		}
	} else {
		// Record PUs lost
		move_delegate_pus_lost(
			game_data_get_move_delegate(outer.game_data),
			outer.battle_site,
			cost,
		)
		cost *= properties_get_pu_multiplier(game_data_get_properties(outer.game_data))
		if client_setting_use_websocket_network() {
			msg := i_display_bombing_results_message_new(outer.battle_id, bombing_dice, cost)
			i_delegate_bridge_send_message(bridge, cast(^Web_Socket_Message)msg)
		} else {
			display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
			i_display_bombing_results(display, outer.battle_id, bombing_dice, int(cost))
		}
		if cost > 0 {
			channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
			headless_sound_channel_play_sound_for_all(
				channel,
				"bombing_strategic",
				outer.attacker,
			)
		}
		// get resources
		pus := resource_list_get_resource_or_throw(
			game_data_get_resource_list(outer.game_data),
			"PUs",
		)
		have := resource_collection_get_quantity(
			game_player_get_resources(outer.defender),
			pus,
		)
		to_remove := min(cost, have)
		change := change_factory_change_resources_change(outer.defender, pus, -to_remove)
		i_delegate_bridge_add_change(bridge, change)
		history_msg := fmt.aprintf(
			"Bombing raid in %s rolls: %s and costs: %d %s.",
			outer.battle_site.name,
			my_formatter_as_dice_ints(self.dice[:]),
			cost,
			my_formatter_pluralize_quantity("PU", cost),
		)
		history_writer := i_delegate_bridge_get_history_writer(bridge)
		i_delegate_history_writer_add_child_to_event(history_writer, history_msg)
	}
	outer.bombing_raid_total = cost
}
