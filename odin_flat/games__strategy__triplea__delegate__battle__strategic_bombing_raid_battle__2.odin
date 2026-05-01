package game

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$2
// Anonymous IExecutable returned by StrategicBombingRaidBattle.end().
// Java declares only `static final long serialVersionUID` (no instance fields);
// outer-class references are implicit captures of the enclosing
// StrategicBombingRaidBattle instance.
Strategic_Bombing_Raid_Battle_2 :: struct {
	using i_executable: I_Executable,
	outer:              ^Strategic_Bombing_Raid_Battle,
}

strategic_bombing_raid_battle_2_new :: proc(outer: ^Strategic_Bombing_Raid_Battle) -> ^Strategic_Bombing_Raid_Battle_2 {
	self := new(Strategic_Bombing_Raid_Battle_2)
	self.outer = outer
	return self
}
