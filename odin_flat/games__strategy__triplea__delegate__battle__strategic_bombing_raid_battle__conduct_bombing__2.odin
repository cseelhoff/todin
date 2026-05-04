package game

Conduct_Bombing_2 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
}

conduct_bombing_2_new :: proc(outer: ^Strategic_Bombing_Raid_Battle_Conduct_Bombing) -> ^Conduct_Bombing_2 {
	self := new(Conduct_Bombing_2)
	self.this_0 = outer
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$ConductBombing$2#execute(ExecutionStack, IDelegateBridge)
//
// Anonymous IExecutable #2 inside ConductBombing.execute (the `findCost`
// step). Its sole Java body is `findCost(bridge);`, which delegates to the
// enclosing ConductBombing instance's findCost(IDelegateBridge) method.
conduct_bombing_2_execute :: proc(
	self:   ^I_Executable,
	stack:  ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	this := cast(^Conduct_Bombing_2)self
	strategic_bombing_raid_battle_conduct_bombing_find_cost(this.this_0, bridge)
}
