package game

Abstract_Battle :: struct {
	battle_id: Uuid,
	headless: bool,
	battle_site: ^Territory,
	attacker: ^Game_Player,
	defender: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	round: i32,
	is_bombing_run: bool,
	is_amphibious: bool,
	battle_type: I_Battle_Battle_Type,
	is_over: bool,
	dependent_units: map[^Unit][dynamic]^Unit,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	amphibious_land_attackers: [dynamic]^Unit,
	bombarding_units: [dynamic]^Unit,
	territory_effects: [dynamic]^Territory_Effect,
	battle_result_description: Battle_Record_Battle_Result_Description,
	who_won: I_Battle_Who_Won,
	attacker_lost_tuv: i32,
	defender_lost_tuv: i32,
	game_data: ^Game_Data,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.AbstractBattle

// games.strategy.triplea.delegate.battle.AbstractBattle#addBombardingUnit
abstract_battle_add_bombarding_unit :: proc(self: ^Abstract_Battle, unit: ^Unit) {
	append(&self.bombarding_units, unit)
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getAttacker
abstract_battle_get_attacker :: proc(self: ^Abstract_Battle) -> ^Game_Player {
	return self.attacker
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getAttackingUnits
abstract_battle_get_attacking_units :: proc(self: ^Abstract_Battle) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.attacking_units {
		append(&result, u)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getBattleId
abstract_battle_get_battle_id :: proc(self: ^Abstract_Battle) -> Uuid {
	return self.battle_id
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getBattleRound
abstract_battle_get_battle_round :: proc(self: ^Abstract_Battle) -> i32 {
	return self.round
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getBattleType
abstract_battle_get_battle_type :: proc(self: ^Abstract_Battle) -> I_Battle_Battle_Type {
	return self.battle_type
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getBombardingUnits
abstract_battle_get_bombarding_units :: proc(self: ^Abstract_Battle) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.bombarding_units {
		append(&result, u)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getDefender
abstract_battle_get_defender :: proc(self: ^Abstract_Battle) -> ^Game_Player {
	return self.defender
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getDefendingUnits
abstract_battle_get_defending_units :: proc(self: ^Abstract_Battle) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.defending_units {
		append(&result, u)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getDependentUnits
//
//   return units.stream()
//       .map(unit -> unit.getTransporting(battleSite))
//       .flatMap(Collection::stream)
//       .collect(Collectors.toUnmodifiableList());
abstract_battle_get_dependent_units :: proc(self: ^Abstract_Battle, units: [dynamic]^Unit) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for unit in units {
		transported := unit_get_transporting_in_territory(unit, self.battle_site)
		for t in transported {
			append(&result, t)
		}
		delete(transported)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getRemainingAttackingUnits
abstract_battle_get_remaining_attacking_units :: proc(self: ^Abstract_Battle) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.attacking_units {
		append(&result, u)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getRemainingDefendingUnits
abstract_battle_get_remaining_defending_units :: proc(self: ^Abstract_Battle) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for u in self.defending_units {
		append(&result, u)
	}
	return result
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getTerritory
abstract_battle_get_territory :: proc(self: ^Abstract_Battle) -> ^Territory {
	return self.battle_site
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getWhoWon
abstract_battle_get_who_won :: proc(self: ^Abstract_Battle) -> I_Battle_Who_Won {
	return self.who_won
}

// games.strategy.triplea.delegate.battle.AbstractBattle#hashCode
//
//   return Objects.hashCode(battleSite);
//
// Territory's hashCode is inherited from DefaultNamed, which is
// Objects.hashCode(name); mirror that via default_named_hash_code,
// returning 0 when battleSite is null (Objects.hashCode contract).
abstract_battle_hash_code :: proc(self: ^Abstract_Battle) -> i32 {
	if self.battle_site == nil {
		return 0
	}
	return default_named_hash_code(&self.battle_site.named_attachable.default_named)
}

// games.strategy.triplea.delegate.battle.AbstractBattle#isAmphibious
abstract_battle_is_amphibious :: proc(self: ^Abstract_Battle) -> bool {
	return self.is_amphibious
}

// games.strategy.triplea.delegate.battle.AbstractBattle#removeUnitsThatNoLongerExist
abstract_battle_remove_units_that_no_longer_exist :: proc(self: ^Abstract_Battle) {
	if self.headless {
		return
	}
	// defendingUnits.retainAll(battleSite.getUnits())
	kept_def: [dynamic]^Unit
	for u in self.defending_units {
		if unit_collection_contains(self.battle_site.unit_collection, u) {
			append(&kept_def, u)
		}
	}
	delete(self.defending_units)
	self.defending_units = kept_def

	kept_atk: [dynamic]^Unit
	for u in self.attacking_units {
		if unit_collection_contains(self.battle_site.unit_collection, u) {
			append(&kept_atk, u)
		}
	}
	delete(self.attacking_units)
	self.attacking_units = kept_atk
}

// games.strategy.triplea.delegate.battle.AbstractBattle#setHeadless
abstract_battle_set_headless :: proc(self: ^Abstract_Battle, headless: bool) {
	self.headless = headless
}

// games.strategy.triplea.delegate.battle.AbstractBattle#equals(java.lang.Object)
//
//   if (!(o instanceof IBattle)) return false;
//   final IBattle other = (IBattle) o;
//   return other.getTerritory().equals(this.battleSite)
//       && other.getBattleType() == this.getBattleType();
abstract_battle_equals :: proc(self: ^Abstract_Battle, other: ^Abstract_Battle) -> bool {
	if other == nil {
		return false
	}
	if other.battle_site != self.battle_site {
		return false
	}
	return other.battle_type == self.battle_type
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getRemote(IDelegateBridge)
//
//   return bridge.getRemotePlayer();
abstract_battle_get_remote :: proc(bridge: ^I_Delegate_Bridge) -> ^Player {
	return i_delegate_bridge_get_remote_player(bridge)
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getTransportDependents(Collection)
//
//   if (headless) return List.of();
//   if (targets.stream().noneMatch(Matches.unitCanTransport())) return List.of();
//   return targets.stream()
//       .map(TransportTracker::transportingAndUnloaded)
//       .flatMap(Collection::stream)
//       .collect(Collectors.toUnmodifiableList());
abstract_battle_get_transport_dependents :: proc(
	self: ^Abstract_Battle,
	targets: [dynamic]^Unit,
) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	if self.headless {
		return result
	}
	pred, pred_ctx := matches_unit_can_transport()
	any_can := false
	for u in targets {
		if pred(pred_ctx, u) {
			any_can = true
			break
		}
	}
	if !any_can {
		return result
	}
	for u in targets {
		transported := transport_tracker_transporting_and_unloaded(u)
		for t in transported {
			append(&result, t)
		}
		delete(transported)
	}
	return result
}

