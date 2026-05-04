package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.NonFightingBattle

Non_Fighting_Battle :: struct {
	using dependent_battle: Dependent_Battle,
}

// NonFightingBattle(Territory, GamePlayer, BattleTracker, GameData)
//   super(battleSite, attacker, battleTracker, data);
non_fighting_battle_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	data: ^Game_Data,
) -> ^Non_Fighting_Battle {
	base := dependent_battle_new(battle_site, attacker, battle_tracker, data)
	self := new(Non_Fighting_Battle)
	self.dependent_battle = base^
	free(base)
	return self
}
