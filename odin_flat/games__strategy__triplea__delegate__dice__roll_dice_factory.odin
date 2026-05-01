package game

Roll_Dice_Factory :: struct {}

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

