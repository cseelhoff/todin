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

