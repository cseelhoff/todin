package game

Conduct_Bombing_1 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
}

conduct_bombing_1_new :: proc(outer: ^Strategic_Bombing_Raid_Battle_Conduct_Bombing) -> ^Conduct_Bombing_1 {
	self := new(Conduct_Bombing_1)
	self.this_0 = outer
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing$1#execute(ExecutionStack, IDelegateBridge)
//
// Anonymous IExecutable #1 inside ConductBombing.execute (the `rollDice`
// step). Its sole Java body is `rollDice(bridge);`, which delegates to the
// enclosing ConductBombing instance's rollDice(IDelegateBridge) method.
conduct_bombing_1_execute :: proc(
	self:   ^I_Executable,
	stack:  ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	this := cast(^Conduct_Bombing_1)self
	strategic_bombing_raid_battle_conduct_bombing_roll_dice(this.this_0, bridge)
}
