package game

import "core:fmt"

Rockets_Fire_Helper :: struct {
	attacking_from_territories:  map[^Territory]struct{},
	attacked_territories:        map[^Territory]^Territory,
	attacked_units:              map[^Territory]^Unit,
	need_to_find_rocket_targets: bool,
}

rockets_fire_helper_new :: proc() -> ^Rockets_Fire_Helper {
	helper := new(Rockets_Fire_Helper)
	helper.attacking_from_territories = make(map[^Territory]struct{})
	helper.attacked_territories = make(map[^Territory]^Territory)
	helper.attacked_units = make(map[^Territory]^Unit)
	helper.need_to_find_rocket_targets = false
	return helper
}

// games.strategy.triplea.delegate.RocketsFireHelper#getRemote(IDelegateBridge)
//
//   private static Player getRemote(final IDelegateBridge bridge) {
//     return bridge.getRemotePlayer();
//   }
rockets_fire_helper_get_remote :: proc(bridge: ^I_Delegate_Bridge) -> ^Player {
	return i_delegate_bridge_get_remote_player(bridge)
}

// games.strategy.triplea.delegate.RocketsFireHelper#getTarget(Collection,IDelegateBridge,Territory)
//
//   private static Territory getTarget(
//       final Collection<Territory> targets,
//       final IDelegateBridge bridge,
//       final Territory from) {
//     return bridge.getRemotePlayer().whereShouldRocketsAttack(targets, from);
//   }
rockets_fire_helper_get_target :: proc(
	targets: [dynamic]^Territory,
	bridge:  ^I_Delegate_Bridge,
	from:    ^Territory,
) -> ^Territory {
	remote := i_delegate_bridge_get_remote_player(bridge)
	return player_where_should_rockets_attack(remote, targets, from)
}

// games.strategy.triplea.delegate.RocketsFireHelper#rocketMatch(GamePlayer)
//
//   private static Predicate<Unit> rocketMatch(final GamePlayer player) {
//     return Matches.unitIsRocket()
//         .and(Matches.unitIsOwnedBy(player))
//         .and(Matches.unitIsNotDisabled())
//         .and(Matches.unitIsBeingTransported().negate())
//         .and(Matches.unitIsSubmerged().negate())
//         .and(Matches.unitHasNotMoved());
//   }
Rockets_Fire_Helper_Ctx_rocket_match :: struct {
	player: ^Game_Player,
}

rockets_fire_helper_pred_rocket_match :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Rockets_Fire_Helper_Ctx_rocket_match)ctx_ptr
	rp, rc := matches_unit_is_rocket()
	if !rp(rc, u) {
		return false
	}
	op, oc := matches_unit_is_owned_by(c.player)
	if !op(oc, u) {
		return false
	}
	np, nc := matches_unit_is_not_disabled()
	if !np(nc, u) {
		return false
	}
	bp, bc := matches_unit_is_being_transported()
	if bp(bc, u) {
		return false
	}
	sp, sc := matches_unit_is_submerged()
	if sp(sc, u) {
		return false
	}
	mp, mc := matches_unit_has_not_moved()
	return mp(mc, u)
}

rockets_fire_helper_rocket_match :: proc(
	player: ^Game_Player,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Rockets_Fire_Helper_Ctx_rocket_match)
	ctx.player = player
	return rockets_fire_helper_pred_rocket_match, rawptr(ctx)
}

// games.strategy.triplea.delegate.RocketsFireHelper#getTerritoriesWithRockets(GameData,GamePlayer)
//
//   static Set<Territory> getTerritoriesWithRockets(final GameData data, final GamePlayer player) {
//     final Set<Territory> territories = new HashSet<>();
//     final Predicate<Unit> ownedRockets = rocketMatch(player);
//     final BattleTracker tracker = AbstractMoveDelegate.getBattleTracker(data);
//     for (final Territory current : data.getMap()) {
//       if (tracker.wasConquered(current)) {
//         continue;
//       }
//       if (current.anyUnitsMatch(ownedRockets)) {
//         territories.add(current);
//       }
//     }
//     return territories;
//   }
rockets_fire_helper_get_territories_with_rockets :: proc(
	data:   ^Game_Data,
	player: ^Game_Player,
) -> map[^Territory]struct{} {
	territories := make(map[^Territory]struct{})
	owned_rockets_fn, owned_rockets_ctx := rockets_fire_helper_rocket_match(player)
	tracker := abstract_move_delegate_get_battle_tracker(data)
	for current in game_map_get_territories(game_data_get_map(data)) {
		if battle_tracker_was_conquered(tracker, current) {
			continue
		}
		if territory_any_units_match(current, owned_rockets_fn, owned_rockets_ctx) {
			territories[current] = {}
		}
	}
	return territories
}

// games.strategy.triplea.delegate.RocketsFireHelper#getTargetsWithinRange(Territory,GameState,GamePlayer)
//
//   private static Set<Territory> getTargetsWithinRange(
//       final Territory territory, final GameState data, final GamePlayer player) {
//     final int maxDistance = data.getTechTracker().getRocketDistance(player);
//     final Set<Territory> hasFactory = new HashSet<>();
//     final Predicate<Territory> allowed =
//         PredicateBuilder.of(Matches.territoryAllowsRocketsCanFlyOver(player))
//             .andIf(
//                 !Properties.getRocketsCanFlyOverImpassables(data.getProperties()),
//                 Matches.territoryIsNotImpassable())
//             .build();
//     final Collection<Territory> possible =
//         data.getMap().getNeighbors(territory, maxDistance, allowed);
//     final Predicate<Unit> attackableUnits =
//         Matches.enemyUnit(player).and(Matches.unitIsBeingTransported().negate());
//     for (final Territory current : possible) {
//       final Optional<Route> optionalRoute = data.getMap().getRoute(territory, current, allowed);
//       if (optionalRoute.isPresent()
//           && optionalRoute.get().numberOfSteps() <= maxDistance
//           && current.anyUnitsMatch(
//               attackableUnits.and(Matches.unitIsAtMaxDamageOrNotCanBeDamaged(current).negate()))) {
//         hasFactory.add(current);
//       }
//     }
//     return hasFactory;
//   }
//
// `allowed` captures both `player` and the
// `!getRocketsCanFlyOverImpassables` flag, so it is rendered as a
// rawptr-ctx predicate. `game_map_get_neighbors_distance_predicate`
// already accepts the rawptr form. `game_map_get_route` only takes a
// non-capturing `proc(^Territory) -> bool`, so the route lookup is
// inlined via `route_finder_new_map_condition` /
// `route_finder_find_route_by_distance` which do accept rawptr ctx.
Rockets_Fire_Helper_Ctx_allowed :: struct {
	player:                          ^Game_Player,
	rockets_cannot_fly_over_impassables: bool,
}

rockets_fire_helper_pred_allowed :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Rockets_Fire_Helper_Ctx_allowed)ctx_ptr
	p1, x1 := matches_territory_allows_rockets_can_fly_over(c.player)
	if !p1(x1, t) {
		return false
	}
	if c.rockets_cannot_fly_over_impassables {
		p2, x2 := matches_territory_is_not_impassable()
		if !p2(x2, t) {
			return false
		}
	}
	return true
}

Rockets_Fire_Helper_Ctx_attackable :: struct {
	player:  ^Game_Player,
	current: ^Territory,
}

rockets_fire_helper_pred_attackable :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Rockets_Fire_Helper_Ctx_attackable)ctx_ptr
	ep, ec := matches_enemy_unit(c.player)
	if !ep(ec, u) {
		return false
	}
	bp, bc := matches_unit_is_being_transported()
	if bp(bc, u) {
		return false
	}
	mp, mc := matches_unit_is_at_max_damage_or_not_can_be_damaged(c.current)
	if mp(mc, u) {
		return false
	}
	return true
}

rockets_fire_helper_get_targets_within_range :: proc(
	territory: ^Territory,
	data:      ^Game_State,
	player:    ^Game_Player,
) -> map[^Territory]struct{} {
	max_distance := tech_tracker_get_rocket_distance(player)
	has_factory := make(map[^Territory]struct{})

	allowed_ctx := new(Rockets_Fire_Helper_Ctx_allowed)
	allowed_ctx.player = player
	allowed_ctx.rockets_cannot_fly_over_impassables =
		!properties_get_rockets_can_fly_over_impassables(game_state_get_properties(data))

	game_map := game_state_get_map(data)

	possible := game_map_get_neighbors_distance_predicate(
		game_map,
		territory,
		max_distance,
		rockets_fire_helper_pred_allowed,
		rawptr(allowed_ctx),
	)

	for current, _ in possible {
		rf := route_finder_new_map_condition(
			game_map,
			rockets_fire_helper_pred_allowed,
			rawptr(allowed_ctx),
		)
		route := route_finder_find_route_by_distance(rf, territory, current)
		if route == nil {
			continue
		}
		if route_number_of_steps(route) > max_distance {
			continue
		}
		atk_ctx := new(Rockets_Fire_Helper_Ctx_attackable)
		atk_ctx.player = player
		atk_ctx.current = current
		if territory_any_units_match(
			current,
			rockets_fire_helper_pred_attackable,
			rawptr(atk_ctx),
		) {
			has_factory[current] = {}
		}
	}
	return has_factory
}

// games.strategy.triplea.delegate.RocketsFireHelper#fireRocket(IDelegateBridge,GameData,Territory,Territory)
//
//   private void fireRocket(
//       final IDelegateBridge bridge,
//       final GameData data,
//       final Territory attackFrom,
//       final Territory attackedTerritory) {
//     ... (see Java source)
//   }
//
// Rolls dice for one rocket attack and applies the resulting damage —
// either as unit damage (when DamageFromBombingDoneToUnits is on and we
// have a real attackFrom) or as a PU loss to the territory owner
// (capped per the WW2V2/limit-per-turn rules). Then writes the history
// transcript, fires the SoundPath.CLIP_BOMBING_ROCKET cue, and removes
// any units that have now reached max damage and are
// unitCanDieFromReachingMaxDamage.
rockets_fire_helper_fire_rocket :: proc(
	self:               ^Rockets_Fire_Helper,
	bridge:             ^I_Delegate_Bridge,
	data:               ^Game_Data,
	attack_from:        ^Territory,
	attacked_territory: ^Territory,
) {
	player := i_delegate_bridge_get_game_player(bridge)
	attacked := territory_get_owner(attacked_territory)
	pus := resource_list_get_resource_or_throw(
		game_data_get_resource_list(data),
		"PUs",
	)
	damage_from_bombing_done_to_units :=
		properties_get_damage_from_bombing_done_to_units_instead_of_territories(
			game_data_get_properties(data),
		)

	// unit damage vs territory damage:
	// final Collection<Unit> enemyUnits =
	//     attackedTerritory.getMatches(
	//         Matches.enemyUnit(player).and(Matches.unitIsBeingTransported().negate()));
	enemy_pred_ctx := new(Rockets_Fire_Helper_Ctx_enemy_not_transported)
	enemy_pred_ctx.player = player
	enemy_units := territory_get_matches(
		attacked_territory,
		rockets_fire_helper_pred_enemy_not_transported,
		rawptr(enemy_pred_ctx),
	)

	// final Collection<Unit> enemyTargetsTotal =
	//     CollectionUtils.getMatches(
	//         enemyUnits, Matches.unitIsAtMaxDamageOrNotCanBeDamaged(attackedTerritory).negate());
	enemy_targets_total: [dynamic]^Unit
	{
		mp, mc := matches_unit_is_at_max_damage_or_not_can_be_damaged(attacked_territory)
		for u in enemy_units {
			if !mp(mc, u) {
				append(&enemy_targets_total, u)
			}
		}
	}

	rockets: [dynamic]^Unit
	number_of_attacks: i32
	// attackFrom could be null if WW2V1
	if attack_from == nil {
		number_of_attacks = 1
	} else {
		rocket_match_fn, rocket_match_ctx := rockets_fire_helper_rocket_match(player)
		for u in territory_get_units(attack_from) {
			if rocket_match_fn(rocket_match_ctx, u) {
				append(&rockets, u)
			}
		}
		rocket_dice_number: i32 = 0
		for u in rockets {
			rocket_dice_number += tech_tracker_get_rocket_dice_number(
				unit_get_owner(u),
				unit_get_type(u),
			)
		}
		per_terr := tech_tracker_get_rocket_number_per_territory(player)
		number_of_attacks = min(rocket_dice_number, per_terr)
	}
	if number_of_attacks <= 0 {
		return
	}

	transcript: string
	do_not_use_bombing_bonus :=
		!properties_get_use_bombing_max_dice_sides_and_bonus(game_data_get_properties(data)) ||
		attack_from == nil
	cost: i32 = 0
	annotation := fmt.aprintf(
		"Rocket fired by %s at %s",
		player.named.base.name,
		attacked.named.base.name,
	)

	if !properties_get_low_luck_damage_only(game_data_get_properties(data)) {
		if do_not_use_bombing_bonus {
			// no low luck, and no bonus, so just roll based on the map's dice sides
			rolls := i_delegate_bridge_get_random(
				bridge,
				data.dice_sides,
				number_of_attacks,
				player,
				I_Random_Stats_Dice_Type.BOMBING,
				annotation,
			)
			for r in rolls {
				cost += r + 1
			}
			if attack_from == nil {
				transcript = fmt.aprintf(
					"Rockets  roll: %s",
					my_formatter_as_dice_ints(rolls[:]),
				)
			} else {
				transcript = fmt.aprintf(
					"Rockets in %s roll: %s",
					attack_from.named.base.name,
					my_formatter_as_dice_ints(rolls[:]),
				)
			}
		} else {
			// we must use bombing bonus
			highest_max_dice: i32 = 0
			highest_bonus: i32 = 0
			dice_sides := data.dice_sides
			for u in rockets {
				ua := unit_get_unit_attachment(u)
				max_dice := unit_attachment_get_bombing_max_die_sides(ua)
				bonus := unit_attachment_get_bombing_bonus(ua)
				if max_dice < 0 {
					max_dice = dice_sides
				}
				if (bonus + ((max_dice + 1) / 2)) >
					(highest_bonus + ((highest_max_dice + 1) / 2)) {
					highest_max_dice = max_dice
					highest_bonus = bonus
				}
			}
			if highest_max_dice > 0 {
				rolls := i_delegate_bridge_get_random(
					bridge,
					highest_max_dice,
					number_of_attacks,
					player,
					I_Random_Stats_Dice_Type.BOMBING,
					annotation,
				)
				for i in 0 ..< len(rolls) {
					r := max(i32(-1), rolls[i] + highest_bonus)
					rolls[i] = r
					cost += r + 1
				}
				transcript = fmt.aprintf(
					"Rockets in %s roll: %s",
					attack_from.named.base.name,
					my_formatter_as_dice_ints(rolls[:]),
				)
			} else {
				cost = highest_bonus * number_of_attacks
				transcript = fmt.aprintf(
					"Rockets in %s do %d damage for each rocket",
					attack_from.named.base.name,
					highest_bonus,
				)
			}
		}
	} else {
		// Low luck
		if do_not_use_bombing_bonus {
			max_dice_ll := (data.dice_sides + 1) / 3
			bonus_ll := (data.dice_sides + 1) / 3
			rolls := i_delegate_bridge_get_random(
				bridge,
				max_dice_ll,
				number_of_attacks,
				player,
				I_Random_Stats_Dice_Type.BOMBING,
				annotation,
			)
			for i in 0 ..< len(rolls) {
				r := rolls[i] + bonus_ll
				rolls[i] = r
				cost += r + 1
			}
			if attack_from == nil {
				transcript = fmt.aprintf(
					"Rockets  roll: %s",
					my_formatter_as_dice_ints(rolls[:]),
				)
			} else {
				transcript = fmt.aprintf(
					"Rockets in %s roll: %s",
					attack_from.named.base.name,
					my_formatter_as_dice_ints(rolls[:]),
				)
			}
		} else {
			highest_max_dice: i32 = 0
			highest_bonus: i32 = 0
			dice_sides := data.dice_sides
			for rocket in rockets {
				ua := unit_get_unit_attachment(rocket)
				max_dice := unit_attachment_get_bombing_max_die_sides(ua)
				bonus := unit_attachment_get_bombing_bonus(ua)
				if max_dice < 0 {
					max_dice = dice_sides
				}
				// "low luck" reduces the luck by 2/3
				if max_dice >= 5 {
					bonus += (max_dice + 1) / 3
					max_dice = (max_dice + 1) / 3
				}
				if (bonus + ((max_dice + 1) / 2)) >
					(highest_bonus + ((highest_max_dice + 1) / 2)) {
					highest_max_dice = max_dice
					highest_bonus = bonus
				}
			}
			if highest_max_dice > 0 {
				rolls := i_delegate_bridge_get_random(
					bridge,
					highest_max_dice,
					number_of_attacks,
					player,
					I_Random_Stats_Dice_Type.BOMBING,
					annotation,
				)
				for i in 0 ..< len(rolls) {
					r := max(i32(-1), rolls[i] + highest_bonus)
					rolls[i] = r
					cost += r + 1
				}
				transcript = fmt.aprintf(
					"Rockets in %s roll: %s",
					attack_from.named.base.name,
					my_formatter_as_dice_ints(rolls[:]),
				)
			} else {
				cost = highest_bonus * number_of_attacks
				transcript = fmt.aprintf(
					"Rockets in %s do %d damage for each rocket",
					attack_from.named.base.name,
					highest_bonus,
				)
			}
		}
	}

	territory_production := territory_attachment_static_get_production(attacked_territory)
	unit: ^Unit
	if attack_from != nil {
		unit = self.attacked_units[attack_from]
	}

	if damage_from_bombing_done_to_units && attack_from != nil {
		damage_limit := unit_get_how_much_more_damage_can_this_unit_take(
			unit,
			attacked_territory,
		)
		cost = max(i32(0), min(cost, damage_limit))
		total_damage := unit_get_unit_damage(unit) + cost
		// apply the hits to the targets
		damage_map := new(Integer_Map_Unit)
		damage_map.entries = make(map[^Unit]i32)
		damage_map.entries[unit] = total_damage
		territories: [dynamic]^Territory
		append(&territories, attacked_territory)
		i_delegate_bridge_add_change(
			bridge,
			change_factory_bombing_unit_damage(damage_map, territories),
		)
	} else if properties_get_ww2_v2(game_data_get_properties(data)) ||
		properties_get_limit_rocket_and_sbr_damage_to_production(game_data_get_properties(data)) {
		// If we are limiting total PUs lost then take that into account
		if properties_get_pu_cap(game_data_get_properties(data)) ||
			properties_get_limit_rocket_damage_per_turn(game_data_get_properties(data)) {
			already_lost := move_delegate_pus_already_lost(
				game_data_get_move_delegate(data),
				attacked_territory,
			)
			territory_production -= already_lost
			territory_production = max(i32(0), territory_production)
		}
		if cost > territory_production {
			cost = territory_production
		}
	}

	// Record the PUs lost
	move_delegate_pus_lost(
		game_data_get_move_delegate(data),
		attacked_territory,
		cost,
	)

	if damage_from_bombing_done_to_units && unit != nil {
		msg := fmt.aprintf(
			"Rocket attack in %s does %d damage to %v",
			attacked_territory.named.base.name,
			cost,
			unit,
		)
		i_remote_player_report_message(
			rockets_fire_helper_get_remote(bridge),
			msg,
			msg,
		)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			msg,
		)
	} else {
		cost *= properties_get_pu_multiplier(game_data_get_properties(data))
		report := fmt.aprintf(
			"Rocket attack in %s costs: %d",
			attacked_territory.named.base.name,
			cost,
		)
		i_remote_player_report_message(
			rockets_fire_helper_get_remote(bridge),
			report,
			report,
		)
		// Trying to remove more PUs than the victim has is A Bad Thing[tm]
		avail_for_removal := resource_collection_get_quantity(
			game_player_get_resources(attacked),
			pus,
		)
		if cost > avail_for_removal {
			cost = avail_for_removal
		}
		transcript_text := fmt.aprintf(
			"%s lost %d PUs to rocket attack by %s",
			attacked.named.base.name,
			cost,
			player.named.base.name,
		)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			transcript_text,
		)
		rocket_charge := change_factory_change_resources_change(attacked, pus, -cost)
		i_delegate_bridge_add_change(bridge, rocket_charge)
	}

	// addChildToEvent(transcript, attackFrom == null ? null : new ArrayList<>(rockets))
	// — the I_Delegate_History_Writer interface in this port surfaces only
	// startEvent; the transcript is reported via the same channel as the
	// other history events here.
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(bridge),
		transcript,
	)

	// this is null in WW2V1
	if attack_from != nil {
		if len(rockets) != 0 {
			change := change_factory_mark_no_movement_change(rockets[0])
			i_delegate_bridge_add_change(bridge, change)
		} else {
			fmt.panicf("No rockets?%v", territory_get_units(attack_from))
		}
	}

	// kill any units that can die if they have reached max damage (veqryn)
	target_unit_col: [dynamic]^Unit
	if unit == nil {
		for u in enemy_targets_total {
			append(&target_unit_col, u)
		}
	} else {
		append(&target_unit_col, unit)
	}
	{
		can_die_fn, can_die_ctx := matches_unit_can_die_from_reaching_max_damage()
		any_can_die := false
		for u in target_unit_col {
			if can_die_fn(can_die_ctx, u) {
				any_can_die = true
				break
			}
		}
		if any_can_die {
			max_dmg_fn, max_dmg_ctx := matches_unit_is_at_max_damage_or_not_can_be_damaged(
				attacked_territory,
			)
			units_can_die: [dynamic]^Unit
			for u in target_unit_col {
				if can_die_fn(can_die_ctx, u) && max_dmg_fn(max_dmg_ctx, u) {
					append(&units_can_die, u)
				}
			}
			if len(units_can_die) != 0 {
				remove_dead := change_factory_remove_units(
					cast(^Unit_Holder)attacked_territory,
					units_can_die,
				)
				transcript_text2 := fmt.aprintf(
					"%s lost in %s",
					my_formatter_units_to_text(units_can_die),
					attacked_territory.named.base.name,
				)
				i_delegate_history_writer_start_event(
					i_delegate_bridge_get_history_writer(bridge),
					transcript_text2,
				)
				i_delegate_bridge_add_change(bridge, remove_dead)
			}
		}
	}

	// play a sound
	if cost > 0 {
		channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
		headless_sound_channel_play_sound_for_all(channel, "bombing_rocket", player)
	}
}

// Helper predicate context for `Matches.enemyUnit(player).and(
// Matches.unitIsBeingTransported().negate())` used by fireRocket.
Rockets_Fire_Helper_Ctx_enemy_not_transported :: struct {
	player: ^Game_Player,
}

rockets_fire_helper_pred_enemy_not_transported :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Rockets_Fire_Helper_Ctx_enemy_not_transported)ctx_ptr
	ep, ec := matches_enemy_unit(c.player)
	if !ep(ec, u) {
		return false
	}
	bp, bc := matches_unit_is_being_transported()
	if bp(bc, u) {
		return false
	}
	return true
}
