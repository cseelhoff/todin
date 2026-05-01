package game

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
