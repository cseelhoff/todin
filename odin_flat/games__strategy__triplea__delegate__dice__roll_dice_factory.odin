package game

import "core:fmt"

Roll_Dice_Factory :: struct {}

// Module-level binding used by `roll_dice_factory_roll_battle_dice` to wire
// the `IDelegateBridge::getRandom` method reference into the
// `Random_Dice_Generator` vtable, which carries no capture context.
@(private="file")
roll_dice_factory_battle_bridge_: ^I_Delegate_Bridge

@(private="file")
roll_dice_factory_battle_random_apply_ :: proc(
	max: i32,
	count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	return i_delegate_bridge_get_random(
		roll_dice_factory_battle_bridge_,
		max,
		count,
		player,
		dice_type,
		annotation,
	)
}

// Module-level binding used to adapt a `Power_Strength_And_Rolls` (the
// concrete builder result) into the `Total_Power_And_Total_Rolls`
// interface vtable consumed by `low_luck_dice_calculate` and
// `rolled_dice_calculate`. The vtable signature passes only
// `^Total_Power_And_Total_Rolls`, which carries no concrete pointer, so
// the link to the underlying value is held in a file-private global.
@(private="file")
roll_dice_factory_battle_psr_: ^Power_Strength_And_Rolls

@(private="file")
roll_dice_factory_battle_total_power_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return power_strength_and_rolls_calculate_total_power(roll_dice_factory_battle_psr_)
}

@(private="file")
roll_dice_factory_battle_total_rolls_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return power_strength_and_rolls_calculate_total_rolls(roll_dice_factory_battle_psr_)
}

@(private="file")
roll_dice_factory_battle_dice_sides_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return roll_dice_factory_battle_psr_.dice_sides
}

@(private="file")
roll_dice_factory_battle_active_units_ :: proc(
	self: ^Total_Power_And_Total_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return power_strength_and_rolls_get_active_units(roll_dice_factory_battle_psr_)
}

// games.strategy.triplea.delegate.dice.RollDiceFactory#rollBattleDice(java.util.Collection,GamePlayer,IDelegateBridge,String,CombatValue)
roll_dice_factory_roll_battle_dice :: proc(
	units: [dynamic]^Unit,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
	annotation: string,
	combat_value_calculator: ^Combat_Value,
) -> ^Dice_Roll {
	unit_power_and_rolls_map := power_strength_and_rolls_build(units, combat_value_calculator)

	roll_dice_factory_battle_bridge_ = bridge
	dice_generator := new(Random_Dice_Generator)
	dice_generator.apply = roll_dice_factory_battle_random_apply_

	roll_dice_factory_battle_psr_ = unit_power_and_rolls_map
	tptr := new(Total_Power_And_Total_Rolls)
	tptr.calculate_total_power = roll_dice_factory_battle_total_power_
	tptr.calculate_total_rolls = roll_dice_factory_battle_total_rolls_
	tptr.get_dice_sides = roll_dice_factory_battle_dice_sides_
	tptr.get_active_units = roll_dice_factory_battle_active_units_

	when ARMOUR_TRACE {
		// Iter 20 probe: dump active_units post-sort for UkrSSR battles
		// so we can compare the dice consumption order against Java.
		if len(annotation) >= 14 {
			has_ukr := false
			for i := 0; i + 14 <= len(annotation); i += 1 {
				if annotation[i:i+14] == "Ukraine S.S.R." {
					has_ukr = true
					break
				}
			}
			if has_ukr {
				au := tptr.get_active_units(tptr)
				fmt.printf("ARMOUR_TRACE rbd_in player=%s ann=%q n_units=%d total_rolls=%d total_power=%d sides=%d\n",
					default_named_get_name(&player.named_attachable.default_named),
					annotation, len(au),
					tptr.calculate_total_rolls(tptr),
					tptr.calculate_total_power(tptr),
					tptr.get_dice_sides(tptr))
				for upsr, i in au {
					on := upsr.unit.owner == nil ? "?" : default_named_get_name(&upsr.unit.owner.named_attachable.default_named)
					ut := upsr.unit.type == nil ? "?" : default_named_get_name(&upsr.unit.type.named_attachable.default_named)
					fmt.printf("ARMOUR_TRACE rbd_unit i=%d owner=%s type=%s str=%d rolls=%d sides=%d cbr=%v\n",
						i, on, ut,
						upsr.strength_and_rolls.strength,
						upsr.strength_and_rolls.rolls,
						upsr.dice_sides,
						upsr.choose_best_roll)
				}
			}
		}
	}

	dice_roll: ^Dice_Roll
	if properties_get_low_luck(game_data_get_properties(i_delegate_bridge_get_data(bridge))) {
		dice_roll = low_luck_dice_calculate(tptr, player, dice_generator, annotation)
	} else {
		dice_roll = rolled_dice_calculate(tptr, player, dice_generator, annotation)
	}

	when ARMOUR_TRACE {
		if len(annotation) >= 14 {
			has_ukr := false
			for i := 0; i + 14 <= len(annotation); i += 1 {
				if annotation[i:i+14] == "Ukraine S.S.R." {
					has_ukr = true
					break
				}
			}
			if has_ukr {
				fmt.printf("ARMOUR_TRACE rbd_out ann=%q hits=%d expected=%.3f size=%d\n",
					annotation,
					dice_roll_get_hits(dice_roll),
					dice_roll_get_expected_hits(dice_roll),
					dice_roll_size(dice_roll))
				for i: i32 = 0; i < dice_roll_size(dice_roll); i += 1 {
					d := dice_roll_get_die(dice_roll, i)
					fmt.printf("ARMOUR_TRACE rbd_die i=%d val=%d hit=%v\n",
						i, die_get_value(d), die_get_type(d) == .HIT)
				}
			}
		}
	}

	history_writer := i_delegate_bridge_get_history_writer(bridge)
	history_msg := fmt.aprintf("%s : %s", annotation, my_formatter_as_dice(dice_roll))
	i_delegate_history_writer_add_child_to_event(history_writer, history_msg, dice_roll)
	return dice_roll
}

// games.strategy.triplea.delegate.dice.RollDiceFactory#rollNSidedDiceXTimes(IDelegateBridge,int,int,GamePlayer,IRandomStats$DiceType,String)
roll_dice_factory_roll_n_sided_dice_x_times :: proc(
	bridge: ^I_Delegate_Bridge,
	roll_count: i32,
	dice_sides: i32,
	player_rolling: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> ^Dice_Roll {
	player_name := default_named_get_name(&player_rolling.named_attachable.default_named)
	if roll_count == 0 {
		empty := make([dynamic]^Die, 0)
		return dice_roll_new(empty, 0, 0, player_name)
	}
	random := i_delegate_bridge_get_random(
		bridge,
		dice_sides,
		roll_count,
		player_rolling,
		dice_type,
		annotation,
	)
	dice := make([dynamic]^Die, 0, roll_count)
	for i in 0 ..< int(roll_count) {
		d := new(Die)
		d^ = die_new(random[i], 1, .IGNORED)
		append(&dice, d)
	}
	return dice_roll_new(dice, roll_count, f64(roll_count), player_name)
}

// AA-side wiring for `roll_dice_factory_roll_aa_dice`. Mirrors the battle-side
// file-private bindings above but holds an `^Aa_Power_Strength_And_Rolls`
// since the vtable signatures take only `^Total_Power_And_Total_Rolls`.
@(private="file")
roll_dice_factory_aa_bridge_: ^I_Delegate_Bridge

@(private="file")
roll_dice_factory_aa_random_apply_ :: proc(
	max: i32,
	count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	return i_delegate_bridge_get_random(
		roll_dice_factory_aa_bridge_,
		max,
		count,
		player,
		dice_type,
		annotation,
	)
}

@(private="file")
roll_dice_factory_aa_psr_: ^Aa_Power_Strength_And_Rolls

@(private="file")
roll_dice_factory_aa_total_power_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return aa_power_strength_and_rolls_calculate_total_power(roll_dice_factory_aa_psr_)
}

@(private="file")
roll_dice_factory_aa_total_rolls_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return aa_power_strength_and_rolls_calculate_total_rolls(roll_dice_factory_aa_psr_)
}

@(private="file")
roll_dice_factory_aa_dice_sides_ :: proc(self: ^Total_Power_And_Total_Rolls) -> i32 {
	return aa_power_strength_and_rolls_get_dice_sides(roll_dice_factory_aa_psr_)
}

@(private="file")
roll_dice_factory_aa_active_units_ :: proc(
	self: ^Total_Power_And_Total_Rolls,
) -> [dynamic]Unit_Power_Strength_And_Rolls {
	return aa_power_strength_and_rolls_get_active_units(roll_dice_factory_aa_psr_)
}

// games.strategy.triplea.delegate.dice.RollDiceFactory#rollAaDice(java.util.Collection,java.util.Collection,games.strategy.engine.delegate.IDelegateBridge,games.strategy.engine.data.Territory,games.strategy.triplea.delegate.power.calculator.CombatValue)
roll_dice_factory_roll_aa_dice :: proc(
	valid_targets: [dynamic]^Unit,
	aa_units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	battle_site: ^Territory,
	combat_value_calculator: ^Combat_Value,
) -> ^Dice_Roll {
	// CollectionUtils.getAny(aaUnits) — first element (Java's Collection.iterator().next()).
	any_unit := aa_units[0]
	type_aa := unit_attachment_get_type_aa(unit_get_unit_attachment(any_unit))
	player := unit_get_owner(any_unit)
	player_name := default_named_get_name(&player.named_attachable.default_named)
	territory_name := default_named_get_name(&battle_site.named_attachable.default_named)
	annotation := fmt.aprintf("%s roll %s dice in %s", player_name, type_aa, territory_name)

	unit_power_and_rolls_map := aa_power_strength_and_rolls_build(
		aa_units,
		i32(len(valid_targets)),
		combat_value_calculator,
	)

	roll_dice_factory_aa_bridge_ = bridge
	dice_generator := new(Random_Dice_Generator)
	dice_generator.apply = roll_dice_factory_aa_random_apply_

	roll_dice_factory_aa_psr_ = unit_power_and_rolls_map
	tptr := new(Total_Power_And_Total_Rolls)
	tptr.calculate_total_power = roll_dice_factory_aa_total_power_
	tptr.calculate_total_rolls = roll_dice_factory_aa_total_rolls_
	tptr.get_dice_sides = roll_dice_factory_aa_dice_sides_
	tptr.get_active_units = roll_dice_factory_aa_active_units_

	properties := game_data_get_properties(i_delegate_bridge_get_data(bridge))
	dice_roll: ^Dice_Roll
	if properties_get_low_luck(properties) || properties_get_low_luck_aa_only(properties) {
		dice_roll = low_luck_dice_calculate(tptr, player, dice_generator, annotation)
	} else {
		dice_roll = rolled_dice_calculate(tptr, player, dice_generator, annotation)
	}

	history_writer := i_delegate_bridge_get_history_writer(bridge)
	history_msg := fmt.aprintf("%s : %s", annotation, my_formatter_as_dice(dice_roll))
	i_delegate_history_writer_add_child_to_event(history_writer, history_msg, dice_roll)
	return dice_roll
}

