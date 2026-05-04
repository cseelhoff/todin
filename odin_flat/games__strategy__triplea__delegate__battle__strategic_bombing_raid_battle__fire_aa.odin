package game

// Fire_Aa — IExecutable inner class of StrategicBombingRaidBattle.
// Mirrors Java fields:
//   DiceRoll dice;
//   CasualtyDetails casualties;
//   final Collection<Unit> casualtiesSoFar = new ArrayList<>();
//   Collection<Unit> validAttackingUnitsForThisRoll;
//   final boolean determineAttackers;
Fire_Aa :: struct {
	using i_executable:                  I_Executable,
	this_0:                              ^Strategic_Bombing_Raid_Battle,
	dice:                                ^Dice_Roll,
	casualties:                          ^Casualty_Details,
	casualties_so_far:                   [dynamic]^Unit,
	valid_attacking_units_for_this_roll: [dynamic]^Unit,
	determine_attackers:                 bool,
}

// FireAa(final Collection<Unit> attackers)
fire_aa_new_with_attackers :: proc(
	this_0: ^Strategic_Bombing_Raid_Battle,
	attackers: [dynamic]^Unit,
) -> ^Fire_Aa {
	self := new(Fire_Aa)
	self.this_0 = this_0
	self.casualties_so_far = make([dynamic]^Unit)
	self.valid_attacking_units_for_this_roll = attackers
	self.determine_attackers = false
	return self
}

// FireAa()
fire_aa_new :: proc(this_0: ^Strategic_Bombing_Raid_Battle) -> ^Fire_Aa {
	self := new(Fire_Aa)
	self.this_0 = this_0
	self.casualties_so_far = make([dynamic]^Unit)
	self.valid_attacking_units_for_this_roll = make([dynamic]^Unit)
	self.determine_attackers = true
	return self
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa#prepareValidAttackingUnitsForThisRoll
//
// Java body:
//   final Set<UnitType> targetUnitTypesForThisTypeAa =
//       CollectionUtils.getAny(currentPossibleAa)
//           .getUnitAttachment()
//           .getTargetsAa(gameData.getUnitTypeList());
//   final Set<UnitType> airborneTypesTargetedToo =
//       TechAbilityAttachment.getAirborneTargettedByAa(
//               TechTracker.getCurrentTechAdvances(attacker, gameData.getTechnologyFrontier()))
//           .get(currentTypeAa);
//   if (determineAttackers) {
//     validAttackingUnitsForThisRoll =
//         CollectionUtils.getMatches(
//             attackingUnits,
//             Matches.unitIsOfTypes(targetUnitTypesForThisTypeAa)
//                 .or(Matches.unitIsAirborne()
//                     .and(Matches.unitIsOfTypes(airborneTypesTargetedToo))));
//   }
// The Predicate composition is inlined into the filter loop, mirroring the
// pattern used by strategic_bombing_raid_battle_update_defending_units.
strategic_bombing_raid_battle_fire_aa_prepare_valid_attacking_units_for_this_roll :: proc(
	self: ^Fire_Aa,
	current_type_aa: string,
	current_possible_aa: [dynamic]^Unit,
) {
	outer := self.this_0
	first_aa := current_possible_aa[0]
	target_unit_types_for_this_type_aa := unit_attachment_get_targets_aa(
		unit_get_unit_attachment(first_aa),
		game_data_get_unit_type_list(outer.game_data),
	)

	tech_advances := tech_tracker_get_current_tech_advances(
		outer.attacker,
		game_data_get_technology_frontier(outer.game_data),
	)
	defer delete(tech_advances)
	all_airborne_targeted :=
		tech_ability_attachment_get_airborne_targetted_by_aa_with_techs(tech_advances)
	airborne_types_targeted_too := all_airborne_targeted[current_type_aa]

	if self.determine_attackers {
		of_types_p, of_types_c := matches_unit_is_of_types(target_unit_types_for_this_type_aa)
		airborne_p, airborne_c := matches_unit_is_airborne()
		airborne_of_types_p, airborne_of_types_c := matches_unit_is_of_types(
			airborne_types_targeted_too,
		)
		new_units: [dynamic]^Unit
		for u in outer.attacking_units {
			if of_types_p(of_types_c, u) ||
			   (airborne_p(airborne_c, u) &&
					   airborne_of_types_p(airborne_of_types_c, u)) {
				append(&new_units, u)
			}
		}
		delete(self.valid_attacking_units_for_this_roll)
		self.valid_attacking_units_for_this_roll = new_units
	}
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle$FireAa#execute(ExecutionStack, IDelegateBridge)
//
// Java body iterates aaTypes; for each currentTypeAa it filters defendingAa
// by matches.unitIsAaOfTypeAa(currentTypeAa) into currentPossibleAa, calls
// prepareValidAttackingUnitsForThisRoll, then constructs four anonymous
// IExecutable instances (roll, calculateCasualties, notifyCasualties,
// removeHits) and pushes them in reverse order. The roll step is skipped
// when isEditMode is true.
strategic_bombing_raid_battle_fire_aa_execute :: proc(
	self_base: ^I_Executable,
	stack: ^Execution_Stack,
	bridge: ^I_Delegate_Bridge,
) {
	_ = stack
	self := cast(^Fire_Aa)self_base
	outer := self.this_0
	is_edit_mode := edit_delegate_get_edit_mode(
		game_data_get_properties(i_delegate_bridge_get_data(bridge)),
	)
	for current_type_aa in outer.aa_types {
		of_type_aa_p, of_type_aa_c := matches_unit_is_aa_of_type_aa(current_type_aa)
		current_possible_aa: [dynamic]^Unit
		for u in outer.defending_aa {
			if of_type_aa_p(of_type_aa_c, u) {
				append(&current_possible_aa, u)
			}
		}
		strategic_bombing_raid_battle_fire_aa_prepare_valid_attacking_units_for_this_roll(
			self,
			current_type_aa,
			current_possible_aa,
		)

		roll := fire_aa_1_new(self, current_possible_aa, current_type_aa)
		calculate_casualties := fire_aa_2_new(self, current_possible_aa, current_type_aa)
		notify_casualties := fire_aa_3_new(self, current_type_aa)
		remove_hits := fire_aa_4_new(self, current_type_aa)

		// push in reverse order of execution
		execution_stack_push_one(outer.stack, &remove_hits.i_executable)
		execution_stack_push_one(outer.stack, &notify_casualties.i_executable)
		execution_stack_push_one(outer.stack, &calculate_casualties.i_executable)
		if !is_edit_mode {
			execution_stack_push_one(outer.stack, &roll.i_executable)
		}
	}
}
