package game

// Port of games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle.
// Implements interface BattleStepStrings (constants only; not modeled).

Strategic_Bombing_Raid_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	targets: map[^Unit]map[^Unit]struct{},
	stack: ^Execution_Stack,
	steps: [dynamic]string,
	defending_aa: [dynamic]^Unit,
	aa_types: [dynamic]string,
	bombing_raid_total: i32,
	bombing_raid_damage: Integer_Map,
}
