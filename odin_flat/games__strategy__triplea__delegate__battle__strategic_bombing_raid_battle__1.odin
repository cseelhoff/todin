package game

Strategic_Bombing_Raid_Battle_1 :: struct {
	using i_executable: I_Executable,
	outer:        ^Strategic_Bombing_Raid_Battle,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$1

strategic_bombing_raid_battle_1_new :: proc(outer: ^Strategic_Bombing_Raid_Battle) -> ^Strategic_Bombing_Raid_Battle_1 {
	self := new(Strategic_Bombing_Raid_Battle_1)
	self.outer = outer
	return self
}

