package game

Dependent_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	attacking_from_map: map[^Territory][dynamic]^Unit,
	attacking_from: map[^Territory]bool,
	amphibious_attack_from: [dynamic]^Territory,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.DependentBattle

// DependentBattle(Territory, GamePlayer, BattleTracker, GameData)
//   super(battleSite, attacker, battleTracker, BattleType.NORMAL, data);
//   attackingFromMap = new HashMap<>();
//   amphibiousAttackFrom = new ArrayList<>();
// attackingFrom is a @RemoveOnNextMajorRelease Set<Territory> left at
// its zero value (Java would default it to null); we leave the map
// uninitialized to mirror that.
dependent_battle_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	data: ^Game_Data,
) -> ^Dependent_Battle {
	base := abstract_battle_new(battle_site, attacker, battle_tracker, .NORMAL, data)
	self := new(Dependent_Battle)
	self.abstract_battle = base^
	free(base)
	self.attacking_from_map = make(map[^Territory][dynamic]^Unit)
	self.amphibious_attack_from = make([dynamic]^Territory)
	return self
}

// Return attacking from Collection.
dependent_battle_get_attacking_from :: proc(self: ^Dependent_Battle) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	for k, _ in self.attacking_from_map {
		append(&result, k)
	}
	return result
}

// Returns territories where there are amphibious attacks.
dependent_battle_get_amphibious_attack_territories :: proc(self: ^Dependent_Battle) -> [dynamic]^Territory {
	return self.amphibious_attack_from
}

