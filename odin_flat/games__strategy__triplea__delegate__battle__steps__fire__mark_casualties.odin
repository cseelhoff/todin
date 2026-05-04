package game

import "core:fmt"

Mark_Casualties :: struct {
	using battle_step: Battle_Step,
	battle_state:      ^Battle_State,
	battle_actions:    ^Battle_Actions,
	side:              Battle_State_Side,
	firing_group:      ^Firing_Group,
	fire_round_state:  ^Fire_Round_State,
	return_fire:       Must_Fight_Battle_Return_Fire,
}

mark_casualties_new :: proc(
	battle_state: ^Battle_State,
	battle_actions: ^Battle_Actions,
	side: Battle_State_Side,
	firing_group: ^Firing_Group,
	fire_round_state: ^Fire_Round_State,
	return_fire: Must_Fight_Battle_Return_Fire,
) -> ^Mark_Casualties {
	self := new(Mark_Casualties)
	self.battle_state = battle_state
	self.battle_actions = battle_actions
	self.side = side
	self.firing_group = firing_group
	self.fire_round_state = fire_round_state
	self.return_fire = return_fire
	return self
}

// Java: private String getName()
//   battleState.getPlayer(side.getOpposite()).getName()
//     + NOTIFY_PREFIX
//     + (firingGroup.getDisplayName().equals(UNITS)
//         ? CASUALTIES_WITHOUT_SPACE_SUFFIX
//         : firingGroup.getDisplayName() + CASUALTIES_SUFFIX)
mark_casualties_get_name :: proc(self: ^Mark_Casualties) -> string {
	opp := battle_state_side_get_opposite(self.side)
	player := battle_state_get_player(self.battle_state, opp)
	display_name := firing_group_get_display_name(self.firing_group)
	suffix: string
	if display_name == BATTLE_STEP_UNITS {
		suffix = BATTLE_STEP_CASUALTIES_WITHOUT_SPACE_SUFFIX
	} else {
		suffix = fmt.aprintf("%s%s", display_name, BATTLE_STEP_CASUALTIES_SUFFIX)
	}
	return fmt.aprintf("%s%s%s", player.named.base.name, BATTLE_STEP_NOTIFY_PREFIX, suffix)
}

// Java: static String getPossibleOldNameForNotifyingBattleDisplay(
//   BattleState battleState, FiringGroup firingGroup, BattleState.Side side, String name)
// Searches the cached battle step strings for `name`; if absent, falls back
// to BattleState.findStepNameForFiringUnits, then to legacy step names based
// on whether the firing group contains first-strike or sea units.
mark_casualties_get_possible_old_name_for_notifying_battle_display :: proc(
	battle_state: ^Battle_State,
	firing_group: ^Firing_Group,
	side: Battle_State_Side,
	name: string,
) -> string {
	step_strings := battle_state_get_step_strings(battle_state)
	for s in step_strings {
		if s == name {
			return name
		}
	}

	firing_units := firing_group_get_firing_units(firing_group)
	found, ok := battle_state_find_step_name_for_firing_units(battle_state, firing_units)
	if ok {
		return found
	}

	// firingGroup.getFiringUnits().stream().anyMatch(Matches.unitIsFirstStrike())
	pred_fs, ctx_fs := matches_unit_is_first_strike()
	for u in firing_units {
		if pred_fs(ctx_fs, u) {
			opp_player := battle_state_get_player(
				battle_state,
				battle_state_side_get_opposite(side),
			)
			return fmt.aprintf(
				"%s%s",
				opp_player.named.base.name,
				BATTLE_STEP_SELECT_FIRST_STRIKE_CASUALTIES,
			)
		}
	}

	// firingGroup.getFiringUnits().stream().anyMatch(Matches.unitIsSea())
	//   && !battleState.getBattleSite().isWater()
	pred_sea, ctx_sea := matches_unit_is_sea()
	any_sea := false
	for u in firing_units {
		if pred_sea(ctx_sea, u) {
			any_sea = true
			break
		}
	}
	if any_sea && !territory_is_water(battle_state_get_battle_site(battle_state)) {
		return BATTLE_STEP_SELECT_NAVAL_BOMBARDMENT_CASUALTIES
	}

	opp_player := battle_state_get_player(
		battle_state,
		battle_state_side_get_opposite(side),
	)
	return fmt.aprintf(
		"%s%s",
		opp_player.named.base.name,
		BATTLE_STEP_SELECT_CASUALTIES,
	)
}

// Java: private void removeSuicideOnHitUnits(IDelegateBridge bridge)
//   final List<Unit> suicidedUnits =
//       firingGroup.getFiringUnits().stream()
//           .limit(fireRoundState.getDice().getHits())
//           .collect(Collectors.toList());
//   ... bridge.getDisplayChannelBroadcaster().deadUnitNotification(...)
//   battleActions.removeUnits(suicidedUnits, bridge, battleState.getBattleSite(), side);
mark_casualties_remove_suicide_on_hit_units :: proc(
	self: ^Mark_Casualties,
	bridge: ^I_Delegate_Bridge,
) {
	firing_units := firing_group_get_firing_units(self.firing_group)
	hits := dice_roll_get_hits(fire_round_state_get_dice(self.fire_round_state))
	limit := i32(len(firing_units))
	if hits < limit {
		limit = hits
	}
	suicided := make([dynamic]^Unit)
	for i in 0 ..< limit {
		append(&suicided, firing_units[i])
	}

	dependent_units := make(map[^Unit][dynamic]^Unit)
	for unit in suicided {
		single := make([dynamic]^Unit)
		append(&single, unit)
		dependent_units[unit] = battle_state_get_dependent_units(self.battle_state, single)
	}

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_dead_unit_notification(
		display,
		battle_state_get_battle_id(self.battle_state),
		battle_state_get_player(self.battle_state, self.side),
		suicided,
		dependent_units,
	)

	battle_actions_remove_units(
		self.battle_actions,
		suicided,
		bridge,
		battle_state_get_battle_site(self.battle_state),
		self.side,
	)
}

// Java: MarkCasualties#getAllStepDetails
//   return List.of(new StepDetails(getName(), this));
mark_casualties_get_all_step_details :: proc(
	self: ^Mark_Casualties,
) -> [dynamic]^Battle_Step_Step_Details {
	out := make([dynamic]^Battle_Step_Step_Details)
	append(&out, battle_step_step_details_new(mark_casualties_get_name(self), &self.battle_step))
	return out
}

// Java: lambda$notifyCasualties$0(IDelegateBridge bridge)
//   () -> {
//     try {
//       battleActions.getRemotePlayer(battleState.getPlayer(side), bridge)
//           .confirmEnemyCasualties(
//               battleState.getBattleId(),
//               "Press space to continue",
//               battleState.getPlayer(side.getOpposite()));
//     } catch (final Exception e) { /* ignore */ }
//   }
// Captured: this (Mark_Casualties) and bridge (passed as arg).
mark_casualties_lambda_notify_casualties_0 :: proc(
	self: ^Mark_Casualties,
	bridge: ^I_Delegate_Bridge,
) {
	remote := battle_actions_get_remote_player(
		self.battle_actions,
		battle_state_get_player(self.battle_state, self.side),
		bridge,
	)
	if remote == nil {
		return
	}
	player_confirm_enemy_casualties(
		remote,
		battle_state_get_battle_id(self.battle_state),
		"Press space to continue",
		battle_state_get_player(self.battle_state, battle_state_side_get_opposite(self.side)),
	)
}

// Java: private void notifyCasualties(IDelegateBridge bridge)
//   final Map<Unit, Collection<Unit>> dependentUnits = new HashMap<>();
//   for (final Unit unit : fireRoundState.getCasualties().getKilled()) {
//     dependentUnits.put(unit, battleState.getDependentUnits(List.of(unit)));
//   }
//   for (final Unit unit : fireRoundState.getCasualties().getDamaged()) {
//     dependentUnits.put(unit, battleState.getDependentUnits(List.of(unit)));
//   }
//   bridge.getDisplayChannelBroadcaster().casualtyNotification(
//       battleState.getBattleId(),
//       getPossibleOldNameForNotifyingBattleDisplay(battleState, firingGroup, side, getName()),
//       fireRoundState.getDice(),
//       battleState.getPlayer(side.getOpposite()),
//       new ArrayList<>(fireRoundState.getCasualties().getKilled()),
//       new ArrayList<>(fireRoundState.getCasualties().getDamaged()),
//       dependentUnits);
//   if (autoCalculated || opp.isAi()) {
//     battleActions.getRemotePlayer(opp, bridge)
//         .confirmOwnCasualties(battleState.getBattleId(), "Press space to continue");
//   }
//   final Thread t = new Thread(() -> { ...lambda$0... }, "click to continue waiter");
//   t.start();
//   bridge.leaveDelegateExecution();
//   Interruptibles.join(t);
//   bridge.enterDelegateExecution();
mark_casualties_notify_casualties :: proc(
	self: ^Mark_Casualties,
	bridge: ^I_Delegate_Bridge,
) {
	casualties := fire_round_state_get_casualties(self.fire_round_state)
	killed := casualty_list_get_killed(&casualties.casualty_list)
	damaged := casualty_list_get_damaged(&casualties.casualty_list)

	dependent_units := make(map[^Unit][dynamic]^Unit)
	for unit in killed {
		single := make([dynamic]^Unit)
		append(&single, unit)
		dependent_units[unit] = battle_state_get_dependent_units(self.battle_state, single)
	}
	for unit in damaged {
		single := make([dynamic]^Unit)
		append(&single, unit)
		dependent_units[unit] = battle_state_get_dependent_units(self.battle_state, single)
	}

	killed_copy := make([dynamic]^Unit)
	for u in killed do append(&killed_copy, u)
	damaged_copy := make([dynamic]^Unit)
	for u in damaged do append(&damaged_copy, u)

	step_name := mark_casualties_get_possible_old_name_for_notifying_battle_display(
		self.battle_state,
		self.firing_group,
		self.side,
		mark_casualties_get_name(self),
	)

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_casualty_notification(
		display,
		battle_state_get_battle_id(self.battle_state),
		step_name,
		fire_round_state_get_dice(self.fire_round_state),
		battle_state_get_player(self.battle_state, battle_state_side_get_opposite(self.side)),
		killed_copy,
		damaged_copy,
		dependent_units,
	)

	opp := battle_state_get_player(self.battle_state, battle_state_side_get_opposite(self.side))
	if casualty_details_get_auto_calculated(casualties) || game_player_is_ai(opp) {
		remote_opp := battle_actions_get_remote_player(self.battle_actions, opp, bridge)
		if remote_opp != nil {
			player_confirm_own_casualties(
				remote_opp,
				battle_state_get_battle_id(self.battle_state),
				"Press space to continue",
			)
		}
	}

	// Java spawns a thread running lambda$0, then leaves/joins/enters the
	// delegate execution context. The snapshot harness is single-threaded:
	// thread_start runs the target inline and Interruptibles.join is a
	// no-op (see java__lang__thread.odin / interruptibles.odin), and the
	// I_Delegate_Bridge vtable does not expose leaveDelegateExecution
	// (only enter), so the leave/enter pair collapses to a no-op. We
	// invoke the lambda directly to preserve observable behavior.
	mark_casualties_lambda_notify_casualties_0(self, bridge)
}

// Java: public void execute(ExecutionStack stack, IDelegateBridge bridge)
//   if (!battleState.getStatus().isHeadless()) notifyCasualties(bridge);
//   battleState.markCasualties(killed, side.getOpposite());
//   if (returnFire == ReturnFire.SUBS) {
//     battleActions.removeUnits(
//         CollectionUtils.getMatches(killed, Matches.unitIsFirstStrike().negate()),
//         bridge, battleState.getBattleSite(), side.getOpposite());
//   } else if (returnFire == ReturnFire.NONE) {
//     battleActions.removeUnits(killed, bridge, battleState.getBattleSite(), side.getOpposite());
//   }
//   if (firingGroup.isSuicideOnHit()) removeSuicideOnHitUnits(bridge);
mark_casualties_execute :: proc(
	self: ^Mark_Casualties,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	if !battle_status_is_headless(battle_state_get_status(self.battle_state)) {
		mark_casualties_notify_casualties(self, bridge)
	}

	opposite := battle_state_side_get_opposite(self.side)
	casualties := fire_round_state_get_casualties(self.fire_round_state)
	killed := casualty_list_get_killed(&casualties.casualty_list)
	battle_state_mark_casualties(self.battle_state, killed, opposite)

	battle_site := battle_state_get_battle_site(self.battle_state)
	if self.return_fire == .SUBS {
		// CollectionUtils.getMatches(killed, unitIsFirstStrike().negate())
		fs_pred, fs_ctx := matches_unit_is_first_strike()
		filtered := make([dynamic]^Unit)
		for u in killed {
			if !fs_pred(fs_ctx, u) {
				append(&filtered, u)
			}
		}
		battle_actions_remove_units(
			self.battle_actions,
			filtered,
			bridge,
			battle_site,
			opposite,
		)
	} else if self.return_fire == .NONE {
		killed_copy := make([dynamic]^Unit)
		for u in killed do append(&killed_copy, u)
		battle_actions_remove_units(
			self.battle_actions,
			killed_copy,
			bridge,
			battle_site,
			opposite,
		)
	}

	if firing_group_is_suicide_on_hit(self.firing_group) {
		mark_casualties_remove_suicide_on_hit_units(self, bridge)
	}
}

