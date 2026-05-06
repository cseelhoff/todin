package game

Select_Main_Battle_Casualties :: struct {
	select_function: ^Select_Main_Battle_Casualties_Select,
}

// Java: lambda$limitTransportsToSelect$0(GamePlayer)
// Source: alliedHitPlayer.computeIfAbsent(unit.getOwner(), (owner) -> new ArrayList<>())
select_main_battle_casualties_lambda_limit_transports_to_select_0 :: proc(owner: ^Game_Player) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: SelectMainBattleCasualties() (no-args constructor, @NoArgsConstructor)
select_main_battle_casualties_new :: proc() -> ^Select_Main_Battle_Casualties {
	self := new(Select_Main_Battle_Casualties)
	self.select_function = select_main_battle_casualties_select_new()
	return self
}

// Java: List<Unit> limitTransportsToSelect(Collection<Unit>, int)
// Limit the number of transports to hitsLeftForTransports per ally.
select_main_battle_casualties_limit_transports_to_select :: proc(
	restricted_transports: [dynamic]^Unit,
	hits_left_for_transports: i32,
) -> [dynamic]^Unit {
	allied_hit_player := make(map[^Game_Player][dynamic]^Unit)
	defer {
		for _, list in allied_hit_player {
			delete(list)
		}
		delete(allied_hit_player)
	}
	for unit in restricted_transports {
		owner := unit_get_owner(unit)
		if _, ok := allied_hit_player[owner]; !ok {
			allied_hit_player[owner] = make([dynamic]^Unit)
		}
		bucket := &allied_hit_player[owner]
		append(bucket, unit)
	}
	transports_to_select := make([dynamic]^Unit)
	for _, units in allied_hit_player {
		count: i32 = 0
		for u in units {
			if count >= hits_left_for_transports {
				break
			}
			append(&transports_to_select, u)
			count += 1
		}
	}
	return transports_to_select
}

// Java: int getMaxHits(Collection<Unit> units)
// The maximum number of hits this collection of units can sustain,
// taking into account units with two hits and existing damage.
select_main_battle_casualties_get_max_hits :: proc(units: [dynamic]^Unit) -> i32 {
	count: i32 = 0
	for unit in units {
		count += unit_attachment_get_hit_points(unit_get_unit_attachment(unit))
		count -= unit_get_hits(unit)
	}
	return count
}

// Java: TargetUnits getTargetUnits(SelectCasualties step)
// Splits the firing group's target units into combat units and
// (if transport casualties are restricted) sea transports that may
// only be hit after the combat units are exhausted.
select_main_battle_casualties_get_target_units :: proc(
	step: ^Select_Casualties,
) -> ^Select_Main_Battle_Casualties_Target_Units {
	firing_group := select_casualties_get_firing_group(step)
	target_list := firing_group_get_target_units(firing_group)
	props := game_data_get_properties(battle_state_get_game_data(select_casualties_get_battle_state(step)))
	if properties_get_transport_casualties_restricted(props) {
		nst_p, nst_c := matches_unit_is_not_sea_transport_but_could_be_combat_sea_transport()
		ns_p, ns_c := matches_unit_is_not_sea()
		st_p, st_c := matches_unit_is_sea_transport_but_not_combat_sea_transport()
		s_p, s_c := matches_unit_is_sea()
		combat_units := make([dynamic]^Unit)
		restricted_transports := make([dynamic]^Unit)
		for u in target_list {
			if nst_p(nst_c, u) || ns_p(ns_c, u) {
				append(&combat_units, u)
			}
			if st_p(st_c, u) && s_p(s_c, u) {
				append(&restricted_transports, u)
			}
		}
		return select_main_battle_casualties_target_units_of(combat_units, restricted_transports)
	}
	combat_units := make([dynamic]^Unit, 0, len(target_list))
	for u in target_list {
		append(&combat_units, u)
	}
	return select_main_battle_casualties_target_units_of(combat_units, make([dynamic]^Unit))
}

// Java: CasualtyDetails apply(IDelegateBridge bridge, SelectCasualties step)
// Picks main-battle casualties for a firing group, deferring the actual
// player decision to the inner Select dispatcher when needed.
select_main_battle_casualties_apply :: proc(
	self: ^Select_Main_Battle_Casualties,
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
) -> ^Casualty_Details {
	target_units := select_main_battle_casualties_get_target_units(step)
	total_hit_points_available := select_main_battle_casualties_get_max_hits(target_units.combat_units)
	fire_round_state := select_casualties_get_fire_round_state(step)
	dice := fire_round_state_get_dice(fire_round_state)
	hit_count := dice_roll_get_hits(dice)
	hits_left_for_restricted_transports := hit_count - total_hit_points_available

	bs := select_casualties_get_battle_state(step)
	game_data := battle_state_get_game_data(bs)
	props := game_data_get_properties(game_data)

	casualty_details: ^Casualty_Details

	if edit_delegate_get_edit_mode(props) {
		firing_group := select_casualties_get_firing_group(step)
		message := select_main_battle_casualties_select_apply(
			self.select_function,
			bridge,
			step,
			firing_group_get_target_units(firing_group),
			0,
		)
		casualty_details = casualty_details_new_from_list_auto_calculated(&message.casualty_list, true)

	} else if total_hit_points_available > hit_count {
		// not all units were hit so the player needs to pick which ones are killed
		casualty_details = select_main_battle_casualties_select_apply(
			self.select_function,
			bridge,
			step,
			target_units.combat_units,
			hit_count,
		)

	} else if total_hit_points_available == hit_count || len(target_units.restricted_transports) == 0 {
		// all of the combat units were hit so kill them without asking the player
		casualty_details = casualty_details_new_from_collections(
			target_units.combat_units[:],
			[]^Unit{},
			true,
		)

	} else if hits_left_for_restricted_transports >= i32(len(target_units.restricted_transports)) {
		// in addition to the combat units, all of the restricted transports were hit
		// so kill them all without asking the player
		for u in target_units.restricted_transports {
			append(&target_units.combat_units, u)
		}
		casualty_details = casualty_details_new_from_collections(
			target_units.combat_units[:],
			[]^Unit{},
			true,
		)

	} else {
		// not all restricted transports were hit so the player needs to pick which ones are killed
		limited := select_main_battle_casualties_limit_transports_to_select(
			target_units.restricted_transports,
			hits_left_for_restricted_transports,
		)
		message := select_main_battle_casualties_select_apply(
			self.select_function,
			bridge,
			step,
			limited,
			hits_left_for_restricted_transports,
		)
		for u in message.killed {
			append(&target_units.combat_units, u)
		}
		casualty_details = casualty_details_new_from_collections(
			target_units.combat_units[:],
			[]^Unit{},
			true,
		)
	}
	return casualty_details
}


// Stateless wrapper matching the fire_round_steps_factory_builder
// casualty_selector proc-value signature. Creates a fresh
// Select_Main_Battle_Casualties on each call (mirrors Java where each
// FirstStrike / General step constructs `new SelectMainBattleCasualties()`).
select_main_battle_casualties_apply_stateless :: proc(
	bridge: ^I_Delegate_Bridge,
	step: ^Select_Casualties,
) -> ^Casualty_Details {
	return select_main_battle_casualties_apply(select_main_battle_casualties_new(), bridge, step)
}
