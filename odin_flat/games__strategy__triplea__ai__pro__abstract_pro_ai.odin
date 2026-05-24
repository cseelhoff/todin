package game

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

Abstract_Pro_Ai :: struct {
	using abstract_ai: Abstract_Ai,

	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,

	// Phases
	combat_move_ai:     ^Pro_Combat_Move_Ai,
	non_combat_move_ai: ^Pro_Non_Combat_Move_Ai,
	purchase_ai:        ^Pro_Purchase_Ai,
	retreat_ai:         ^Pro_Retreat_Ai,
	scramble_ai:        ^Pro_Scramble_Ai,
	politics_ai:        ^Pro_Politics_Ai,

	// Data shared across phases
	stored_combat_move_map:      map[^Territory]^Pro_Territory,
	stored_factory_move_map:     map[^Territory]^Pro_Territory,
	stored_purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	stored_political_actions:    [dynamic]^Political_Action_Attachment,
	stored_strafing_territories: [dynamic]^Territory,
}

when PUR_TRACE {
	abstract_pro_ai_dump_caucasus :: proc(data_copy: ^Game_Data, player: ^Game_Player, tag: string) {
		pname := default_named_get_name(&player.named_attachable.default_named)
		if pname != "Russians" { return }
		gm := game_data_get_map(data_copy)
		if gm == nil { return }
		for t in gm.territories {
			if t == nil { continue }
			if territory_get_name(t) != "Caucasus" { continue }
			n := 0
			owners := make(map[string]int)
			defer delete(owners)
			for u in unit_collection_get_units(territory_get_unit_collection(t)) {
				n += 1
				o := unit_get_owner(u)
				on := default_named_get_name(&o.named_attachable.default_named)
				utn := unit_type_get_name(unit_get_type(u))
				k := fmt.tprintf("%s:%s", on, utn)
				owners[k] = owners[k] + 1
			}
			fmt.printf("SIM_CAUCASUS tag=%s addr=%p n=%d breakdown=%v\n", tag, t, n, owners)
		}
	}
}

// Java: public AbstractProAi(String name, IBattleCalculator battleCalculator,
//                            ProData proData, String playerLabel)
abstract_pro_ai_new :: proc(
	name: string,
	battle_calculator: ^I_Battle_Calculator,
	pro_data: ^Pro_Data,
	player_label: string,
) -> ^Abstract_Pro_Ai {
	self := new(Abstract_Pro_Ai)
	// super(name, playerLabel)
	self.name = name
	self.player_label = player_label
	self.pro_data = pro_data
	self.calc = pro_odds_calculator_new(battle_calculator)
	self.combat_move_ai = pro_combat_move_ai_new(self)
	self.non_combat_move_ai = pro_non_combat_move_ai_new(self)
	self.purchase_ai = pro_purchase_ai_new(self)
	self.retreat_ai = pro_retreat_ai_new(self)
	self.scramble_ai = pro_scramble_ai_new(self)
	self.politics_ai = pro_politics_ai_new(self)
	self.stored_combat_move_map = nil
	self.stored_factory_move_map = nil
	self.stored_purchase_territories = nil
	self.stored_political_actions = nil
	self.stored_strafing_territories = make([dynamic]^Territory)
	self.purchase = abstract_pro_ai_v_purchase
	self.move = abstract_pro_ai_v_move
	self.place = abstract_pro_ai_v_place
	return self
}

@(private = "file")
abstract_pro_ai_v_place :: proc(
	self:           ^Abstract_Ai,
	place_for_bid:  bool,
	place_delegate: ^I_Abstract_Place_Delegate,
	data:           ^Game_Data,
	player:         ^Game_Player,
) {
	abstract_pro_ai_place(
		cast(^Abstract_Pro_Ai)self,
		place_for_bid,
		place_delegate,
		data,
		player,
	)
}

@(private = "file")
abstract_pro_ai_v_move :: proc(
	self:       ^Abstract_Ai,
	non_combat: bool,
	move_del:   ^I_Move_Delegate,
	data:       ^Game_Data,
	player:     ^Game_Player,
) {
	abstract_pro_ai_move(
		cast(^Abstract_Pro_Ai)self,
		non_combat,
		move_del,
		data,
		player,
	)
}

@(private = "file")
abstract_pro_ai_v_purchase :: proc(
	self:               ^Abstract_Ai,
	purchase_for_bid:   bool,
	pus_to_spend:       i32,
	purchase_delegate:  ^I_Purchase_Delegate,
	data:               ^Game_Data,
	player:             ^Game_Player,
) {
	abstract_pro_ai_purchase(
		cast(^Abstract_Pro_Ai)self,
		purchase_for_bid,
		pus_to_spend,
		purchase_delegate,
		data,
		player,
	)
}

abstract_pro_ai_get_pro_data :: proc(self: ^Abstract_Pro_Ai) -> ^Pro_Data {
	return self.pro_data
}

abstract_pro_ai_get_calc :: proc(self: ^Abstract_Pro_Ai) -> ^Pro_Odds_Calculator {
	return self.calc
}

abstract_pro_ai_set_stored_strafing_territories :: proc(self: ^Abstract_Pro_Ai, strafing_territories: [dynamic]^Territory) {
	self.stored_strafing_territories = strafing_territories
}

abstract_pro_ai_has_non_combat_move :: proc(self: ^Abstract_Pro_Ai, steps: [dynamic]^Game_Step) -> bool {
	for s in steps {
		if abstract_pro_ai_lambda__has_non_combat_move__0(s) {
			return true
		}
	}
	return false
}

// Java: s -> GameStep.isNonCombatMoveStepName(s.getName())
abstract_pro_ai_lambda__has_non_combat_move__0 :: proc(s: ^Game_Step) -> bool {
	return game_step_is_non_combat_move_step_name(s.name)
}

// Java: private static List<GameStep> getGameStepsForPlayer(
//           GameData gameData, GamePlayer gamePlayer, int startStep)
abstract_pro_ai_get_game_steps_for_player :: proc(
	game_data: ^Game_Data,
	game_player: ^Game_Player,
	start_step: i32,
) -> [dynamic]^Game_Step {
	step_index: i32 = 0
	game_steps: [dynamic]^Game_Step
	for game_step in game_sequence_iterator(game_data_get_sequence(game_data)) {
		if step_index >= start_step && game_player == game_step_get_player_id(game_step) {
			append(&game_steps, game_step)
		}
		step_index += 1
	}
	return game_steps
}

// Java: public boolean shouldBomberBomb(final Territory territory) {
//           return combatMoveAi.isBombing(); }
abstract_pro_ai_should_bomber_bomb :: proc(self: ^Abstract_Pro_Ai, territory: ^Territory) -> bool {
	return pro_combat_move_ai_is_bombing(self.combat_move_ai)
}

// Java: private void initializeData() { proData.initialize(this); }
abstract_pro_ai_initialize_data :: proc(self: ^Abstract_Pro_Ai) {
	pro_data_initialize(self.pro_data, self)
}

// Java: private GameData copyData(GameData data) {
//   GameDataManager.Options options = GameDataManager.Options.builder().withDelegates(true).build();
//   GameData dataCopy = GameDataUtils.cloneGameData(data, options).orElse(null);
//   Optional.ofNullable(dataCopy).ifPresent(this::prepareData);
//   return dataCopy;
// }
abstract_pro_ai_copy_data :: proc(self: ^Abstract_Pro_Ai, data: ^Game_Data) -> ^Game_Data {
	options := game_data_manager_options_options_builder_build(
		game_data_manager_options_options_builder_with_delegates(
			game_data_manager_options_builder(),
			true,
		),
	)
	t0 := time.now()
	data_copy := game_data_utils_clone_game_data(data, options)
	dt := time.since(t0)
	if dt > 100 * time.Millisecond {
		fmt.printf("[copy_data] clone took %v\n", dt)
	}
	if data_copy != nil {
		// prepareData is abstract; dispatch to the concrete ProAi override.
		pro_ai_prepare_data(cast(^Pro_Ai)self, data_copy)
	}
	return data_copy
}

// Java: public Optional<Territory> retreatQuery(
//           UUID battleId, boolean submerge, Territory battleTerritory,
//           Collection<Territory> possibleTerritories, String message)
abstract_pro_ai_retreat_query :: proc(
	self: ^Abstract_Pro_Ai,
	battle_id: Uuid,
	submerge: bool,
	battle_territory: ^Territory,
	possible_territories: [dynamic]^Territory,
	message: string,
) -> ^Territory {
	abstract_pro_ai_initialize_data(self)

	// Get battle data
	data := abstract_base_player_get_game_data(&self.abstract_base_player)
	player := abstract_base_player_get_game_player(&self.abstract_base_player)
	delegate := game_data_get_battle_delegate(data)
	battle := battle_tracker_get_pending_battle_by_id(
		battle_delegate_get_battle_tracker(delegate),
		battle_id,
	)

	// If battle is null or amphibious then don't retreat
	if battle == nil || battle_territory == nil || i_battle_is_amphibious(battle) {
		return nil
	}

	// If attacker with more unit strength or strafing and isn't land battle with only air left then
	// don't retreat
	is_attacker := player == i_battle_get_attacker(battle)
	attackers := i_battle_get_attacking_units(battle)
	defenders := i_battle_get_defending_units(battle)
	strength_difference := pro_battle_utils_estimate_strength_difference(
		battle_territory,
		attackers,
		defenders,
	)
	is_strafing :=
		is_attacker && slice.contains(self.stored_strafing_territories[:], battle_territory)
	pro_logger_info(
		fmt.tprintf(
			"%s checking retreat from territory %v, attackers=%d, defenders=%d, submerge=%v, attacker=%v, isStrafing=%v",
			default_named_get_name(&player.named_attachable.default_named),
			battle_territory,
			len(attackers),
			len(defenders),
			submerge,
			is_attacker,
			is_strafing,
		),
	)
	if (is_strafing || (is_attacker && strength_difference > 50)) {
		any_land := false
		if !territory_is_water(battle_territory) {
			land_pred, land_ctx := matches_unit_is_land()
			for u in attackers {
				if land_pred(land_ctx, u) {
					any_land = true
					break
				}
			}
		}
		if territory_is_water(battle_territory) || any_land {
			return nil
		}
	}
	pro_ai_prepare_data(
		cast(^Pro_Ai)self,
		abstract_base_player_get_game_data(&self.abstract_base_player),
	)
	return pro_retreat_ai_retreat_query(
		self.retreat_ai,
		battle_id,
		battle_territory,
		possible_territories,
	)
}

// Java: public CasualtyDetails selectCasualties(
//           Collection<Unit> selectFrom, Map<Unit, Collection<Unit>> dependents,
//           int count, String message, DiceRoll dice, GamePlayer hit,
//           Collection<Unit> friendlyUnits, Collection<Unit> enemyUnits,
//           boolean amphibious, Collection<Unit> amphibiousLandAttackers,
//           CasualtyList defaultCasualties, UUID battleId, Territory battleSite,
//           boolean allowMultipleHitsPerUnit)
abstract_pro_ai_select_casualties :: proc(
	self: ^Abstract_Pro_Ai,
	select_from: [dynamic]^Unit,
	dependents: map[^Unit][dynamic]^Unit,
	count: i32,
	message: string,
	dice: ^Dice_Roll,
	hit: ^Game_Player,
	friendly_units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	amphibious: bool,
	amphibious_land_attackers: [dynamic]^Unit,
	default_casualties: ^Casualty_List,
	battle_id: Uuid,
	battle_site: ^Territory,
	allow_multiple_hits_per_unit: bool,
) -> ^Casualty_Details {
	abstract_pro_ai_initialize_data(self)

	if i32(casualty_list_size(default_casualties)) != count {
		panic(
			fmt.tprintf(
				"Select Casualties showing different numbers for number of hits to take (%d) vs total size of default casualty selections (%d) in %v (hit = %s)",
				count,
				casualty_list_size(default_casualties),
				battle_site,
				default_named_get_name(&hit.named_attachable.default_named),
			),
		)
	}
	if len(casualty_list_get_killed(default_casualties)) == 0 {
		return casualty_details_new_from_list_auto_calculated(default_casualties, false)
	}

	// Consider unit cost
	my_casualties := casualty_details_new_auto_calculated(false)
	default_damaged := casualty_list_get_damaged(default_casualties)
	casualty_list_add_to_damaged_many(&my_casualties.casualty_list, default_damaged[:])

	select_from_sorted := make([dynamic]^Unit, 0, len(select_from))
	for u in select_from {
		append(&select_from_sorted, u)
	}

	if len(enemy_units) == 0 {
		less_fn, less_ctx := pro_purchase_utils_get_cost_comparator(self.pro_data)
		n := len(select_from_sorted)
		for i in 0 ..< n {
			for j in 0 ..< n - 1 - i {
				if less_fn(less_ctx, select_from_sorted[j + 1], select_from_sorted[j]) {
					select_from_sorted[j], select_from_sorted[j + 1] =
						select_from_sorted[j + 1], select_from_sorted[j]
				}
			}
		}
	} else {
		// Get battle data
		data := abstract_base_player_get_game_data(&self.abstract_base_player)
		player := abstract_base_player_get_game_player(&self.abstract_base_player)
		delegate := game_data_get_battle_delegate(data)
		battle := battle_tracker_get_pending_battle_by_id(
			battle_delegate_get_battle_tracker(delegate),
			battle_id,
		)

		// If defender and could lose battle then don't consider unit cost as just trying to survive
		need_to_check := true
		is_attacker := player == i_battle_get_attacker(battle)
		if !is_attacker {
			attackers := i_battle_get_attacking_units(battle)
			defenders_orig := i_battle_get_defending_units(battle)
			killed := casualty_list_get_killed(default_casualties)
			defenders := make([dynamic]^Unit, 0, len(defenders_orig))
			defer delete(defenders)
			for d in defenders_orig {
				if !slice.contains(killed[:], d) {
					append(&defenders, d)
				}
			}
			strength_difference := pro_battle_utils_estimate_strength_difference(
				battle_site,
				attackers,
				defenders,
			)
			min_strength_difference: f64 = 60
			if !properties_get_low_luck(game_data_get_properties(data)) {
				min_strength_difference = 55
			}
			if strength_difference > min_strength_difference {
				need_to_check = false
			}
		}

		// Use bubble sort to save expensive units
		for need_to_check {
			need_to_check = false
			for i in 0 ..< len(select_from_sorted) - 1 {
				unit1 := select_from_sorted[i]
				unit2 := select_from_sorted[i + 1]
				unit_cost1 := pro_purchase_utils_get_cost(self.pro_data, unit1)
				unit_cost2 := pro_purchase_utils_get_cost(self.pro_data, unit2)
				if unit_cost1 > 1.5 * unit_cost2 {
					select_from_sorted[i] = unit2
					select_from_sorted[i + 1] = unit1
					need_to_check = true
				}
			}
		}
	}

	// Interleave carriers and planes
	interleaved_target_list := pro_transport_utils_interleave_units_carriers_and_planes(
		select_from_sorted,
		0,
	)
	default_killed := casualty_list_get_killed(default_casualties)
	for i in 0 ..< len(default_killed) {
		casualty_list_add_to_killed(&my_casualties.casualty_list, interleaved_target_list[i])
	}
	if int(count) != casualty_list_size(&my_casualties.casualty_list) {
		panic("AI chose wrong number of casualties")
	}
	return my_casualties
}

// Java: public boolean selectAttackSubs(final Territory unitTerritory)
abstract_pro_ai_select_attack_subs :: proc(self: ^Abstract_Pro_Ai, unit_territory: ^Territory) -> bool {
	abstract_pro_ai_initialize_data(self)

	// Get battle data
	data := abstract_base_player_get_game_data(&self.abstract_base_player)
	player := abstract_base_player_get_game_player(&self.abstract_base_player)
	delegate := game_data_get_battle_delegate(data)
	battle := battle_tracker_get_pending_battle(
		battle_delegate_get_battle_tracker(delegate),
		unit_territory,
		I_Battle_Battle_Type.NORMAL,
	)

	// If battle is null then don't attack
	if battle == nil {
		return false
	}
	attackers := i_battle_get_attacking_units(battle)
	defenders := i_battle_get_defending_units(battle)
	pro_logger_info(
		fmt.tprintf(
			"%s checking sub attack in %v, attackers=%v, defenders=%v",
			default_named_get_name(&player.named_attachable.default_named),
			unit_territory,
			attackers,
			defenders,
		),
	)
	pro_ai_prepare_data(
		cast(^Pro_Ai)self,
		abstract_base_player_get_game_data(&self.abstract_base_player),
	)

	// Calculate battle results
	bombarding: [dynamic]^Unit
	result := pro_odds_calculator_calculate_battle_results(
		self.calc,
		self.pro_data,
		unit_territory,
		attackers,
		defenders,
		bombarding,
	)
	pro_logger_debug(
		fmt.tprintf(
			"%s sub attack TUVSwing=%v",
			default_named_get_name(&player.named_attachable.default_named),
			pro_battle_result_get_tuv_swing(result),
		),
	)
	return pro_battle_result_get_tuv_swing(result) > 0
}

// Java: protected void place(boolean bid, IAbstractPlaceDelegate placeDelegate,
//                            GameState data, GamePlayer player)
abstract_pro_ai_place :: proc(
	self:           ^Abstract_Pro_Ai,
	bid:            bool,
	place_delegate: ^I_Abstract_Place_Delegate,
	data:           ^Game_State,
	player:         ^Game_Player,
) {
	when #config(PLACE_TRACE, false) {
		fmt.printf("PLACE_ENTER player=%s stored_pt=%d\n",
			default_named_get_name(&player.named_attachable.default_named),
			len(self.stored_purchase_territories))
	}
	fmt.printf("PLACE_ENTER_UNCOND player=%s stored_pt=%d bid=%v\n",
		default_named_get_name(&player.named_attachable.default_named),
		len(self.stored_purchase_territories), bid)
	start := time.tick_now()
	// ProLogUi.notifyStartOfRound is a Swing UI no-op outside the editor;
	// not flagged actually_called_in_ai_test, so the call is elided.
	_ = game_sequence_get_round(game_state_get_sequence(data))
	abstract_pro_ai_initialize_data(self)
	pro_purchase_ai_place(self.purchase_ai, self.stored_purchase_territories, place_delegate)
	self.stored_purchase_territories = nil
	pro_logger_info(
		fmt.tprintf(
			"%s time for place=%d",
			default_named_get_name(&player.named_attachable.default_named),
			i64(time.duration_milliseconds(time.tick_since(start))),
		),
	)
	_ = bid
}

// Java: protected void move(boolean nonCombat, IMoveDelegate moveDel,
//                           GameData data, GamePlayer player)
abstract_pro_ai_move :: proc(
	self:       ^Abstract_Pro_Ai,
	non_combat: bool,
	move_del:   ^I_Move_Delegate,
	data:       ^Game_Data,
	player:     ^Game_Player,
) {
	start := time.tick_now()
	// ProLogUi.notifyStartOfRound is a Swing UI no-op outside the editor;
	// not flagged actually_called_in_ai_test, so the call is elided.
	_ = game_sequence_get_round(game_data_get_sequence(data))
	abstract_pro_ai_initialize_data(self)
	pro_ai_prepare_data(cast(^Pro_Ai)self, data)
	did_combat_move := false
	did_non_combat_move := false
	if non_combat {
		_ = pro_non_combat_move_ai_do_non_combat_move(
			self.non_combat_move_ai,
			self.stored_factory_move_map,
			self.stored_factory_move_map != nil,
			self.stored_purchase_territories,
			self.stored_purchase_territories != nil,
			move_del,
		)
		self.stored_factory_move_map = nil
		did_non_combat_move = true
	} else {
		if self.stored_combat_move_map == nil {
			_ = pro_combat_move_ai_do_combat_move(self.combat_move_ai, move_del)
		} else {
			pro_combat_move_ai_do_move(
				self.combat_move_ai,
				self.stored_combat_move_map,
				move_del,
				data,
				player,
			)
			self.stored_combat_move_map = nil
		}
		did_combat_move = true
		// Some maps only have a single "combat" move phase. For these, do "non-combat" moves too,
		// after combat moves.
		steps := abstract_pro_ai_get_game_steps_for_player(data, player, 0)
		defer delete(steps)
		if !abstract_pro_ai_has_non_combat_move(self, steps) {
			_ = pro_non_combat_move_ai_do_non_combat_move(
				self.non_combat_move_ai,
				self.stored_factory_move_map,
				self.stored_factory_move_map != nil,
				self.stored_purchase_territories,
				self.stored_purchase_territories != nil,
				move_del,
			)
			self.stored_factory_move_map = nil
			did_non_combat_move = true
		}
	}

	pro_logger_info(
		fmt.tprintf(
			"%s move (didCombatMove=%v  didNonCombatMove=%v) time=%d",
			default_named_get_name(&player.named_attachable.default_named),
			did_combat_move,
			did_non_combat_move,
			i64(time.duration_milliseconds(time.tick_since(start))),
		),
	)
}

// I_Delegate_Bridge vtable adapters that forward to a Pro_Dummy_Delegate_Bridge
// stashed in `concrete`. Mirrors the wrapping pattern in
// pro_purchase_validation_utils so AbstractDelegate.setDelegateBridgeAndPlayer
// can dispatch get_data / get_game_player / add_change through the vtable.
@(private="file")
abstract_pro_ai_pdb_get_data :: proc(self: ^I_Delegate_Bridge) -> ^Game_Data {
	return pro_dummy_delegate_bridge_get_data(cast(^Pro_Dummy_Delegate_Bridge)self.concrete)
}
@(private="file")
abstract_pro_ai_pdb_get_game_player :: proc(self: ^I_Delegate_Bridge) -> ^Game_Player {
	return pro_dummy_delegate_bridge_get_game_player(cast(^Pro_Dummy_Delegate_Bridge)self.concrete)
}
@(private="file")
abstract_pro_ai_pdb_add_change :: proc(self: ^I_Delegate_Bridge, change: ^Change) {
	pro_dummy_delegate_bridge_add_change(cast(^Pro_Dummy_Delegate_Bridge)self.concrete, change)
}
@(private="file")
abstract_pro_ai_pdb_get_history_writer :: proc(self: ^I_Delegate_Bridge) -> ^I_Delegate_History_Writer {
	w := pro_dummy_delegate_bridge_get_history_writer(cast(^Pro_Dummy_Delegate_Bridge)self.concrete)
	return cast(^I_Delegate_History_Writer)w
}
@(private="file")
abstract_pro_ai_pdb_get_sound_channel_broadcaster :: proc(self: ^I_Delegate_Bridge) -> ^Headless_Sound_Channel {
	return pro_dummy_delegate_bridge_get_sound_channel_broadcaster(cast(^Pro_Dummy_Delegate_Bridge)self.concrete)
}
@(private="file")
abstract_pro_ai_pdb_get_display_channel_broadcaster :: proc(self: ^I_Delegate_Bridge) -> ^I_Display {
	dd := cast(^Pro_Dummy_Delegate_Bridge)self.concrete
	return cast(^I_Display)dd.display
}
@(private="file")
abstract_pro_ai_pdb_get_remote_player :: proc(self: ^I_Delegate_Bridge, p: ^Game_Player) -> ^Player {
	r := pro_dummy_delegate_bridge_get_remote_player(cast(^Pro_Dummy_Delegate_Bridge)self.concrete, p)
	return cast(^Player)r
}
@(private="file")
abstract_pro_ai_pdb_enter_delegate_execution :: proc(self: ^I_Delegate_Bridge) { /* no-op */ }
@(private="file")
abstract_pro_ai_pdb_get_resource_loader :: proc(self: ^I_Delegate_Bridge) -> ^Resource_Loader { return nil }
@(private="file")
abstract_pro_ai_pdb_send_message :: proc(self: ^I_Delegate_Bridge, msg: ^Web_Socket_Message) { /* no-op */ }
@(private="file")
abstract_pro_ai_pdb_stop_game_sequence :: proc(self: ^I_Delegate_Bridge, status: string, title: string) { /* no-op */ }
@(private="file")
abstract_pro_ai_pdb_get_random :: proc(
	self: ^I_Delegate_Bridge,
	max: i32, count: i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
	annotation: string,
) -> [dynamic]i32 {
	dd := cast(^Pro_Dummy_Delegate_Bridge)self.concrete
	return plain_random_source_get_random_array(&dd.random_source, max, count, annotation)
}

// Java: protected void purchase(boolean purchaseForBid, int pusToSpend,
//                               IPurchaseDelegate purchaseDelegate,
//                               GameData data, GamePlayer player)
abstract_pro_ai_purchase :: proc(
	self:               ^Abstract_Pro_Ai,
	purchase_for_bid:   bool,
	pus_to_spend:       i32,
	purchase_delegate:  ^I_Purchase_Delegate,
	data:               ^Game_Data,
	player:             ^Game_Player,
) {
	when NCM_HANG_PROBE {
		_ph_entry_pn := default_named_get_name(&player.named_attachable.default_named)
		fmt.eprintf("NCM_HANG.purchase_entry player=%s pus=%d bid=%v\n", _ph_entry_pn, pus_to_spend, purchase_for_bid)
		os.flush(os.stderr)
	}
	start := time.tick_now()
	// ProLogUi.notifyStartOfRound is a Swing UI no-op outside the editor;
	// not flagged actually_called_in_ai_test, so the call is elided.
	_ = game_sequence_get_round(game_data_get_sequence(data))
	abstract_pro_ai_initialize_data(self)
	if pus_to_spend <= 0 {
		return
	}
	if purchase_for_bid {
		pro_ai_prepare_data(cast(^Pro_Ai)self, data)
		self.stored_purchase_territories = pro_purchase_ai_bid(
			self.purchase_ai,
			pus_to_spend,
			purchase_delegate,
			&data.game_state,
		)
	} else {
		// Repair factories
		pro_purchase_ai_repair(self.purchase_ai, pus_to_spend, purchase_delegate, data, player)

		// Check if any place territories exist
		purchase_territories := pro_purchase_utils_find_purchase_territories(
			self.pro_data,
			player,
		)
		// CollectionUtils.getMatches with a rawptr-ctx ProMatches predicate is
		// inlined per the codebase convention (collection_utils_get_matches
		// only handles bare proc(rawptr)->bool predicates).
		factory_pred, factory_ctx :=
			pro_matches_territory_has_no_infra_factory_and_is_not_conquered_owned_land(player)
		all_territories := game_map_get_territories(game_data_get_map(data))
		possible_factory_territories: [dynamic]^Territory
		defer delete(possible_factory_territories)
		for t in all_territories {
			if factory_pred(factory_ctx, t) {
				append(&possible_factory_territories, t)
			}
		}
		if len(purchase_territories) == 0 && len(possible_factory_territories) == 0 {
			pro_logger_info("No possible place or factory territories owned so exiting purchase logic")
			return
		}
		pro_logger_info("Starting simulation for purchase phase")

		// Setup data copy and delegates
		when PUR_TRACE {
			abstract_pro_ai_dump_caucasus(data, player, "PRE_COPYDATA_LIVE")
		}
		data_copy := abstract_pro_ai_copy_data(self, data)
		if data_copy == nil {
			return
		}
		when #config(PLAN, false) {
			pname_dbg := default_named_get_name(&player.named_attachable.default_named)
			if pname_dbg == "Japanese" {
				dump_alaska :: proc(d: ^Game_Data, label: string, pname: string) {
					gm := game_data_get_map(d)
					if gm == nil {
						return
					}
					for t in gm.territories {
						if t == nil {
							continue
						}
						if territory_get_name(t) != "Alaska" {
							continue
						}
						uc := territory_get_unit_collection(t)
						units := unit_collection_get_units(uc)
						fmt.printf(
							"ALASKA_DUMP %s player=%s n=%d\n",
							label,
							pname,
							len(units),
						)
						for u in units {
							owner_name := "-"
							if o := unit_get_owner(u); o != nil {
								owner_name = default_named_get_name(&o.named_attachable.default_named)
							}
							fmt.printf(
								"  ALASKA_UNIT %s type=%s owner=%s\n",
								label,
								unit_type_get_name(unit_get_type(u)),
								owner_name,
							)
						}
					}
				}
				dump_alaska(data, "LIVE_PRE_COPY", pname_dbg)
				dump_alaska(data_copy, "COPY_AFTER", pname_dbg)
			}
		}
		player_copy := player_list_get_player_id(
			game_data_get_player_list(data_copy),
			default_named_get_name(&player.named_attachable.default_named),
		)
		move_del := game_data_get_move_delegate(data_copy)
		dummy := pro_dummy_delegate_bridge_new(self, player_copy, data_copy)
		bridge := new(I_Delegate_Bridge)
		bridge.concrete = rawptr(dummy)
		bridge.get_data = abstract_pro_ai_pdb_get_data
		bridge.get_game_player = abstract_pro_ai_pdb_get_game_player
		bridge.add_change = abstract_pro_ai_pdb_add_change
		// Wire the rest of the I_Delegate_Bridge vtable so dispatchers
		// don't fall through to the default cast-to-Default_Delegate_Bridge
		// path, which reads garbage when our bridge.concrete is actually
		// ^Pro_Dummy_Delegate_Bridge (different layout).
		bridge.get_history_writer = abstract_pro_ai_pdb_get_history_writer
		bridge.get_sound_channel_broadcaster = abstract_pro_ai_pdb_get_sound_channel_broadcaster
		bridge.get_display_channel_broadcaster = abstract_pro_ai_pdb_get_display_channel_broadcaster
		bridge.get_remote_player = abstract_pro_ai_pdb_get_remote_player
		bridge.enter_delegate_execution = abstract_pro_ai_pdb_enter_delegate_execution
		bridge.get_resource_loader = abstract_pro_ai_pdb_get_resource_loader
		bridge.send_message = abstract_pro_ai_pdb_send_message
		bridge.stop_game_sequence = abstract_pro_ai_pdb_stop_game_sequence
		bridge.get_random = abstract_pro_ai_pdb_get_random
		// Java's setDelegateBridgeAndPlayer reads bridge.getGamePlayer(); the
		// snapshot dispatcher i_delegate_bridge_get_game_player blindly casts
		// to ^Default_Delegate_Bridge which is wrong for our AI bridge (proc-
		// field-backed). Inline the assignment here using the AI's known
		// player_copy to avoid the bad cast. Mirrors the Java effect:
		// move_del.bridge = bridge; move_del.player = bridge.getGamePlayer().
		// Shallow clone shares the delegates map; save/restore so the
		// outer harness sees move_del unchanged after AI returns.
		saved_move_bridge := move_del.abstract_delegate.bridge
		saved_move_player := move_del.abstract_delegate.player
		defer {
			move_del.abstract_delegate.bridge = saved_move_bridge
			move_del.abstract_delegate.player = saved_move_player
		}
		move_del.abstract_delegate.bridge = bridge
		move_del.abstract_delegate.player = player_copy

		// Simulate the next phases until place/end of turn is reached then use simulated data for
		// purchase
		sequence := game_data_get_sequence(data_copy)
		// Shallow clone shares the sequence pointer with the original
		// data; save/restore the cursor so the harness's outer end_step
		// fires on the original (purchase) step, not whatever phase the
		// AI sim ended on. See serialization-shim-divergence-plan.md
		// (Layer 5).
		saved_index := sequence.current_index
		saved_round := sequence.round
		defer {
			sequence.current_index = saved_index
			sequence.round = saved_round
		}
		next_step_index := game_sequence_get_step_index(sequence) + 1
		game_steps := abstract_pro_ai_get_game_steps_for_player(
			data_copy,
			player_copy,
			next_step_index,
		)
		defer delete(game_steps)
		when PUR_TRACE {
			abstract_pro_ai_dump_caucasus(data_copy, player, "00_after_copyData")
		}
		when #config(AMPHIB_BYPASS, false) {
			pname_byp := default_named_get_name(&player.named_attachable.default_named)
			if pname_byp == "Japanese" {
				fmt.println("AMPHIB_BYPASS: skipping sim walk for Japanese, invoking pro_purchase_ai_purchase directly")
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player)
				self.stored_purchase_territories = pro_purchase_ai_purchase(
					self.purchase_ai,
					purchase_delegate,
					&data.game_state,
				)
				return
			}
		}
		for step in game_steps {
			game_sequence_set_round_and_step(
				sequence,
				game_sequence_get_round(sequence),
				game_step_get_display_name(step),
				game_step_get_player_id(step),
			)
			step_name := step.name
			when NCM_HANG_PROBE {
				_pn_sw_any := default_named_get_name(&player.named_attachable.default_named)
				fmt.eprintf("NCM_HANG.simwalk_any player=%s step=%s START\n", _pn_sw_any, step_name)
				os.flush(os.stderr)
			}
			when NCM_HANG_PROBE {
				_pn_sim := default_named_get_name(&player.named_attachable.default_named)
				if _pn_sim == "Japanese" {
					fmt.eprintf("NCM_HANG.simwalk player=Japanese step=%s START\n", step_name)
				}
			}
			pro_logger_info(fmt.tprintf("Simulating phase: %s", step_name))
			when NCM_TRACE {
				pname_sim := default_named_get_name(&player.named_attachable.default_named)
				if pname_sim == "Russians" {
					// Count Russian fighters/bombers in data_copy and print their locations.
					gm_sim := game_data_get_map(data_copy)
					n_air_total := 0
					air_locations := strings.builder_make()
					defer strings.builder_destroy(&air_locations)
					if gm_sim != nil {
						for t in gm_sim.territories {
							if t == nil { continue }
							n_at := 0
							for u in unit_collection_get_units(territory_get_unit_collection(t)) {
								if u == nil || u.type == nil { continue }
								if u.owner == nil { continue }
								// name-based owner check (clone-safe)
								if u.owner.named_attachable.default_named.name != "Russians" { continue }
								utn := unit_type_get_name(u.type)
								if utn == "fighter" || utn == "bomber" {
									n_at += 1
								}
							}
							if n_at > 0 {
								tn := territory_get_name(t)
								fmt.sbprintf(&air_locations, " %s=%d(amov=%v)", tn, n_at, "?")
								n_air_total += n_at
							}
						}
					}
					fmt.printf("SIM_STEP player=Russians step=%s n_air_total=%d locs=[%s]\n",
						step_name, n_air_total, strings.to_string(air_locations))
				}
			}
			when PUR_TRACE {
				abstract_pro_ai_dump_caucasus(data_copy, player, fmt.tprintf("BEFORE_%s", step_name))
			}
			if game_step_is_non_combat_move_step_name(step_name) {
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player_copy)
				when NCM_HANG_PROBE {
					_pn_ncm := default_named_get_name(&player.named_attachable.default_named)
					if _pn_ncm == "Japanese" {
						fmt.eprintf("NCM_HANG.simwalk Japanese branch=ncm calling simulate_non_combat_move\n")
					}
				}
				when PUR_TRACE {
					abstract_pro_ai_dump_caucasus(data_copy, player, fmt.tprintf("PRE_SIM_%s", step_name))					// Pre-NCM-sim air units owned by player_copy
					gm_pre := game_data_get_map(data_copy)
					if gm_pre != nil {
						for t in gm_pre.territories {
							if t == nil { continue }
							n_air := 0
							for u in unit_collection_get_units(territory_get_unit_collection(t)) {
								if u == nil || u.type == nil { continue }
								if u.owner != player_copy { continue }
								utn := unit_type_get_name(u.type)
								if utn == "fighter" || utn == "bomber" {
									n_air += 1
								}
							}
							if n_air > 0 {
								tn := territory_get_name(t)
								own_name := "-"
								if to := territory_get_owner(t); to != nil {
									own_name = default_named_get_name(&to.named_attachable.default_named)
								}
								fmt.printf("PRE_SIM_AIR step=%s t=%s terr_owner=%s n_player_air=%d\n",
									step_name, tn, own_name, n_air)
							}
						}
					}				}
				factory_move_map := pro_non_combat_move_ai_simulate_non_combat_move(
					self.non_combat_move_ai,
					cast(^I_Move_Delegate)move_del,
				)
				when PUR_TRACE {
					abstract_pro_ai_dump_caucasus(data_copy, player, fmt.tprintf("POST_SIM_%s", step_name))
					// Dump per-territory air-unit counts for ANY territory with units owned by player_copy
					// (NOT just where territory.owner == player_copy — air can be on allied land too).
					gm := game_data_get_map(data_copy)
					if gm != nil {
						for t in gm.territories {
							if t == nil { continue }
							n_air := 0
							for u in unit_collection_get_units(territory_get_unit_collection(t)) {
								if u == nil || u.type == nil { continue }
								if u.owner != player_copy { continue }
								utn := unit_type_get_name(u.type)
								if utn == "fighter" || utn == "bomber" {
									n_air += 1
								}
							}
							if n_air > 0 {
								tn := territory_get_name(t)
								own_name := "-"
								if to := territory_get_owner(t); to != nil {
									own_name = default_named_get_name(&to.named_attachable.default_named)
								}
								fmt.printf("POST_SIM_AIR step=%s t=%s terr_owner=%s n_player_air=%d\n",
									step_name, tn, own_name, n_air)
							}
						}
					}
				}
				if self.stored_factory_move_map == nil {
					self.stored_factory_move_map = pro_simulate_turn_utils_transfer_move_map(
						self.pro_data,
						factory_move_map,
						&data.game_state,
						player,
					)
				}
			} else if game_step_is_combat_move_step_name(step_name) &&
			   !game_step_is_airborne_combat_move_step_name(step_name) {
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player_copy)
				when NCM_HANG_PROBE {
					_pn_cm := default_named_get_name(&player.named_attachable.default_named)
					if _pn_cm == "Japanese" {
						fmt.eprintf("NCM_HANG.simwalk Japanese branch=combat_move calling do_combat_move\n")
					}
				}
				move_map := pro_combat_move_ai_do_combat_move(
					self.combat_move_ai,
					cast(^I_Move_Delegate)move_del,
				)
				when NCM_HANG_PROBE {
					_pn_cm2 := default_named_get_name(&player.named_attachable.default_named)
					if _pn_cm2 == "Japanese" {
						fmt.eprintf("NCM_HANG.simwalk Japanese branch=combat_move DONE\n")
					}
				}
				if self.stored_combat_move_map == nil {
					self.stored_combat_move_map = pro_simulate_turn_utils_transfer_move_map(
						self.pro_data,
						move_map,
						&data.game_state,
						player,
					)
				}
				// Some maps only have a combat move. For these, do both types of moves during this phase.
				if !abstract_pro_ai_has_non_combat_move(self, game_steps) {
					// Copy the data so we can simulate battles on it, in order to choose our "non
					// combat" moves based on that (estimated) board state.
					data_copy2 := abstract_pro_ai_copy_data(self, data)
					if data_copy2 == nil {
						return
					}
					player_copy2 := player_list_get_player_id(
						game_data_get_player_list(data_copy2),
						default_named_get_name(&player.named_attachable.default_named),
					)
					pro_data_initialize_simulation(self.pro_data, self, data_copy2, player_copy2)
					pro_simulate_turn_utils_simulate_battles(
						self.pro_data,
						data_copy2,
						player_copy2,
						bridge,
						self.calc,
					)
					pro_data_initialize_simulation(self.pro_data, self, data_copy2, player_copy2)
					factory_move_map := pro_non_combat_move_ai_simulate_non_combat_move(
						self.non_combat_move_ai,
						cast(^I_Move_Delegate)move_del,
					)
					if self.stored_factory_move_map == nil {
						self.stored_factory_move_map = pro_simulate_turn_utils_transfer_move_map(
							self.pro_data,
							factory_move_map,
							&data.game_state,
							player,
						)
					}
				}
			} else if game_step_is_battle_step_name(step_name) {
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player_copy)
				when NCM_HANG_PROBE {
					_pn_b := default_named_get_name(&player.named_attachable.default_named)
					if _pn_b == "Japanese" {
						fmt.eprintf("NCM_HANG.simwalk Japanese branch=battle calling simulate_battles\n")
					}
				}
				pro_simulate_turn_utils_simulate_battles(
					self.pro_data,
					data_copy,
					player_copy,
					bridge,
					self.calc,
				)
				when NCM_HANG_PROBE {
					_pn_b2 := default_named_get_name(&player.named_attachable.default_named)
					if _pn_b2 == "Japanese" {
						fmt.eprintf("NCM_HANG.simwalk Japanese branch=battle DONE\n")
					}
				}
			} else if game_step_is_place_step_name(step_name) ||
			   game_step_is_end_turn_step_name(step_name) {
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player)
				self.stored_purchase_territories = pro_purchase_ai_purchase(
					self.purchase_ai,
					purchase_delegate,
					&data.game_state,
				)
				break
			} else if game_step_is_politics_step_name(step_name) {
				pro_data_initialize_simulation(self.pro_data, self, data_copy, player)
				// Can only do politics if this player still owns its capital.
				my_capital := pro_data_get_my_capital(self.pro_data)
				if my_capital == nil || territory_is_owned_by(my_capital, player) {
					politics_delegate := game_data_get_politics_delegate(data_copy)
					abstract_delegate_set_delegate_bridge_and_player_no_websocket(
						&politics_delegate.abstract_delegate,
						bridge,
					)
					actions := pro_politics_ai_political_actions(self.politics_ai)
					if self.stored_political_actions == nil {
						self.stored_political_actions = actions
					}
				}
			}
		}
	}
	pro_logger_info(
		fmt.tprintf(
			"%s time for purchase=%d",
			default_named_get_name(&player.named_attachable.default_named),
			i64(time.duration_milliseconds(time.tick_since(start))),
		),
	)
}
