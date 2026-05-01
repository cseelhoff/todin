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

