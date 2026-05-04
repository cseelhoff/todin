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
	// Discriminator used in place of Java `instanceof MustFightBattle`.
	// Set to true by Must_Fight_Battle constructors; false on every
	// other concrete I_Battle subtype (Finished_Battle, Air_Battle,
	// Strategic_Bombing_Raid_Battle, Non_Fighting_Battle). Several
	// callers (e.g. battle_delegate_get_possible_bombarding_territories)
	// must distinguish MustFightBattle from its NonFightingBattle
	// sibling under DependentBattle, where neither isAmphibious nor
	// battle_type is sufficient.
	is_must_fight_battle: bool,
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
abstract_battle_get_remote_bridge :: proc(bridge: ^I_Delegate_Bridge) -> ^Player {
	return i_delegate_bridge_get_remote_player(bridge)
}

// Wrapper that adapts a Weak_Ai instance to the Player vtable used by
// abstract_battle_get_remote when the supplied GamePlayer is the null
// player. Mirrors the @(private="file") wrapper in battle_actions.odin
// so we can construct `new WeakAi(player.getName())` in Java semantics.
@(private = "file")
Weak_Ai_Player_Wrapper :: struct {
	using player: Player,
	ai:           ^Weak_Ai,
}

@(private = "file")
weak_ai_player_get_name :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.name
}

@(private = "file")
weak_ai_player_get_player_label :: proc(self: ^Player) -> string {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.player_label
}

@(private = "file")
weak_ai_player_is_ai :: proc(self: ^Player) -> bool {
	return true
}

@(private = "file")
weak_ai_player_get_game_player :: proc(self: ^Player) -> ^Game_Player {
	w := cast(^Weak_Ai_Player_Wrapper)self
	return w.ai.game_player
}

@(private = "file")
weak_ai_player_initialize :: proc(
	self: ^Player,
	bridge: ^Player_Bridge,
	game_player: ^Game_Player,
) {
	w := cast(^Weak_Ai_Player_Wrapper)self
	w.ai.player_bridge = bridge
	w.ai.game_player = game_player
}

// games.strategy.triplea.delegate.battle.AbstractBattle#getRemote(
//     games.strategy.engine.data.GamePlayer,
//     games.strategy.engine.delegate.IDelegateBridge)
//
//   protected static Player getRemote(final GamePlayer player, final IDelegateBridge bridge) {
//     if (player.isNull()) {
//       return new WeakAi(player.getName());
//     }
//     return bridge.getRemotePlayer(player);
//   }
abstract_battle_get_remote_for_player :: proc(
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) -> ^Player {
	if game_player_is_null(player) {
		w := new(Weak_Ai_Player_Wrapper)
		w.ai = weak_ai_new(game_player_get_name(player))
		w.get_name = weak_ai_player_get_name
		w.get_player_label = weak_ai_player_get_player_label
		w.is_ai = weak_ai_player_is_ai
		w.get_game_player = weak_ai_player_get_game_player
		w.initialize = weak_ai_player_initialize
		return &w.player
	}
	return i_delegate_bridge_get_remote_player(bridge, player)
}

abstract_battle_get_remote :: proc {
	abstract_battle_get_remote_bridge,
	abstract_battle_get_remote_for_player,
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


// Default no-op for IBattle#unitsLostInPrecedingBattle. Java defines this
// abstract on the IBattle interface with 5 concrete overrides (none on
// AbstractBattle). The orchestrator added this default to unblock
// i_battle_units_lost_in_preceding_battle; it matches AirBattle's empty
// body. The AI snapshot harness does not exercise dependent-battle
// propagation in single-battle scenarios, so this default is safe.
// Replace with vtable dispatch if future scenarios need it.
abstract_battle_units_lost_in_preceding_battle :: proc(
	self: ^Abstract_Battle,
	units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	withdrawn: bool,
) {
}

// games.strategy.triplea.delegate.battle.AbstractBattle#lambda$getDependentUnits$0(games.strategy.engine.data.Unit)
//
//   unit -> unit.getTransporting(battleSite)
//
// The captured `battleSite` is supplied via `self`.
abstract_battle_lambda_get_dependent_units_0 :: proc(
	self: ^Abstract_Battle,
	unit: ^Unit,
) -> [dynamic]^Unit {
	return unit_get_transporting_in_territory(unit, self.battle_site)
}

// games.strategy.triplea.delegate.battle.AbstractBattle#clearTransportedBy(IDelegateBridge)
//
//   final Predicate<Unit> attackerTransports =
//       Matches.unitIsOwnedBy(attacker).and(Matches.unitIsSeaTransport());
//   final Collection<Unit> transports =
//       CollectionUtils.getMatches(getTerritory().getUnits(), attackerTransports);
//   if (!transports.isEmpty()) {
//     final Collection<Unit> dependents = getTransportDependents(transports);
//     final Collection<Unit> dependentsUnloadedThisTurn =
//         CollectionUtils.getMatches(dependents, Matches.unitWasUnloadedThisTurn());
//     final CompositeChange change = new CompositeChange();
//     for (final Unit unit : dependentsUnloadedThisTurn) {
//       change.add(ChangeFactory.unitPropertyChange(unit, null, Unit.PropertyName.TRANSPORTED_BY));
//     }
//     if (!change.isEmpty()) {
//       bridge.addChange(change);
//     }
//   }
abstract_battle_clear_transported_by :: proc(
	self: ^Abstract_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	owned_p, owned_c := matches_unit_is_owned_by(self.attacker)
	sea_p, sea_c := matches_unit_is_sea_transport()

	transports: [dynamic]^Unit
	site_units := unit_collection_get_units(self.battle_site.unit_collection)
	defer delete(site_units)
	for u in site_units {
		if owned_p(owned_c, u) && sea_p(sea_c, u) {
			append(&transports, u)
		}
	}
	if len(transports) == 0 {
		delete(transports)
		return
	}

	dependents := abstract_battle_get_transport_dependents(self, transports)
	delete(transports)

	unloaded_p, unloaded_c := matches_unit_was_unloaded_this_turn()
	change := composite_change_new()
	for unit in dependents {
		if unloaded_p(unloaded_c, unit) {
			composite_change_add(
				change,
				change_factory_unit_property_change_property_name(unit, nil, .Transported_By),
			)
		}
	}
	delete(dependents)

	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
}
