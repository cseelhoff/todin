package game

Firing_Group_Splitter_Bombard :: struct {
}

firing_group_splitter_bombard_new :: proc() -> ^Firing_Group_Splitter_Bombard {
	self := new(Firing_Group_Splitter_Bombard)
	return self
}

// Lombok @Value(staticConstructor = "of") on a class with no instance fields:
// generates a no-arg static factory that returns a new instance.
firing_group_splitter_bombard_of :: proc() -> ^Firing_Group_Splitter_Bombard {
	return firing_group_splitter_bombard_new()
}

// games.strategy.triplea.delegate.battle.steps.fire.FiringGroupSplitterBombard#apply(BattleState)
//
// Java:
//   final Collection<Unit> enemyUnits =
//       CollectionUtils.getMatches(
//           battleState.filterUnits(ALIVE, OFFENSE.getOpposite()),
//           Matches.unitIsNotInfrastructureAndNotCapturedOnEntering(
//               battleState.getPlayer(OFFENSE), battleState.getBattleSite()));
//   return FiringGroup.groupBySuicideOnHit(
//       NAVAL_BOMBARD, battleState.getBombardingUnits(), enemyUnits);
firing_group_splitter_bombard_apply :: proc(
	self: ^Firing_Group_Splitter_Bombard,
	battle_state: ^Battle_State,
) -> [dynamic]^Firing_Group {
	alive_filter := battle_state_unit_battle_filter_new(.Alive)
	defenders := battle_state_filter_units(
		battle_state,
		alive_filter,
		battle_state_side_get_opposite(.OFFENSE),
	)

	pred, pred_ctx := matches_unit_is_not_infrastructure_and_not_captured_on_entering(
		battle_state_get_player(battle_state, .OFFENSE),
		battle_state_get_battle_site(battle_state),
	)
	enemy_units: [dynamic]^Unit
	for u in defenders {
		if pred(pred_ctx, u) {
			append(&enemy_units, u)
		}
	}

	return firing_group_group_by_suicide_on_hit(
		BATTLE_STEP_NAVAL_BOMBARD,
		battle_state_get_bombarding_units(battle_state),
		enemy_units,
	)
}
