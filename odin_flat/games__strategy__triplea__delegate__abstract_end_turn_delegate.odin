package game

import "core:fmt"

Abstract_End_Turn_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
	has_posted_turn_summary: bool,
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#delegateCurrentlyRequiresUserInput()
// Java body: "return true;" — comment notes the call is needed regardless,
// because it resets player sounds for the turn.
abstract_end_turn_delegate_delegate_currently_requires_user_input :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> bool {
	return true
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getName()
// Mirrors AbstractDelegate.getName(): returns the internal name stored
// on the embedded I_Delegate.
abstract_end_turn_delegate_get_name :: proc(self: ^Abstract_End_Turn_Delegate) -> string {
	return self.name
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getDisplayName()
abstract_end_turn_delegate_get_display_name :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> string {
	return self.display_name
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getRemoteType()
// Java: "return IAbstractForumPosterDelegate.class;". Odin mirrors
// Class<? extends IRemote> with typeid.
abstract_end_turn_delegate_get_remote_type :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> typeid {
	return typeid_of(I_Abstract_Forum_Poster_Delegate)
}

// Captured-closure record for the Java method
//   getSingleBlockadeThenHighestToLowestBlockadeDamage(Map<Territory, Tuple<Integer, List<Territory>>>)
// which returns a Comparator<Territory> that closes over the supplied
// damage-per-zone map. The comparator's logic lives in the matching
// `_compare` proc below; the static factory simply packages the
// captured map into this struct value.
Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator :: struct {
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getSingleBlockadeThenHighestToLowestBlockadeDamage(java.util.Map)
// Static factory returning a Comparator<Territory>. The Java source
// wraps it in `Comparator.nullsLast`, so nil sorts after non-nil.
abstract_end_turn_delegate_get_single_blockade_then_highest_to_lowest_blockade_damage :: proc(
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
) -> Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator {
	return Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator{
		damage_per_blockade_zone = damage_per_blockade_zone,
	}
}

// Comparator body for
//   getSingleBlockadeThenHighestToLowestBlockadeDamage. Returns the
// Java Comparator<Territory> contract: negative if t1 < t2, zero if
// equal, positive if t1 > t2. Mirrors `Comparator.nullsLast` for the
// nil cases, then prefers a territory whose tuple's neighbor list has
// exactly one entry, then orders by descending damage value.
abstract_end_turn_delegate_single_blockade_then_highest_to_lowest_blockade_damage_compare :: proc(
	cmp: ^Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	// Comparator.nullsLast: nil sorts after any non-nil value.
	if t1 == nil && t2 == nil {
		return 0
	}
	if t1 == nil {
		return 1
	}
	if t2 == nil {
		return -1
	}
	if t1 == t2 {
		return 0
	}
	tuple1 := cmp.damage_per_blockade_zone[t1]
	tuple2 := cmp.damage_per_blockade_zone[t2]
	// Java's Tuple values are non-null in this map; defend against nil
	// just in case so the comparator stays a total order.
	if tuple1 == nil && tuple2 == nil {
		return 0
	}
	if tuple1 == nil {
		return 1
	}
	if tuple2 == nil {
		return -1
	}
	num1 := i32(len(tuple1.second))
	num2 := i32(len(tuple2.second))
	if num1 == 1 && num2 != 1 {
		return -1
	}
	if num2 == 1 && num1 != 1 {
		return 1
	}
	d1 := tuple1.first
	d2 := tuple2.first
	// Java: Integer.compare(d2, d1) — descending by damage.
	if d2 < d1 {
		return -1
	}
	if d2 > d1 {
		return 1
	}
	return 0
}

// Captured-closure record for
//   getSingleNeighborBlockadesThenHighestToLowestProduction(Collection<Territory>, GameMap)
// holding the blockade-zone collection and the game map needed to
// look up neighbors. The matching `_compare` proc implements the
// comparator body.
Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator :: struct {
	blockade_zones: [dynamic]^Territory,
	game_map:       ^Game_Map,
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getSingleNeighborBlockadesThenHighestToLowestProduction(java.util.Collection, games.strategy.engine.data.GameMap)
abstract_end_turn_delegate_get_single_neighbor_blockades_then_highest_to_lowest_production :: proc(
	blockade_zones: [dynamic]^Territory,
	game_map: ^Game_Map,
) -> Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator {
	return Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator{
		blockade_zones = blockade_zones,
		game_map       = game_map,
	}
}

// Comparator body for getSingleNeighborBlockadesThenHighestToLowestProduction.
// Mirrors Java semantics: nullsLast for nil; if a territory touches only
// one blockade zone, prefer it; otherwise fall back to the natural
// ordering of TerritoryAttachment.getProduction (ascending), exactly as
// the Java `Comparator.comparingInt(...)` chain does.
abstract_end_turn_delegate_single_neighbor_blockades_then_highest_to_lowest_production_compare :: proc(
	cmp: ^Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	// Comparator.nullsLast.
	if t1 == nil && t2 == nil {
		return 0
	}
	if t1 == nil {
		return 1
	}
	if t2 == nil {
		return -1
	}
	if t1 == t2 {
		return 0
	}
	// Count how many of t1/t2's neighbors are in the blockade zone set.
	// Java uses ArrayList(map.getNeighbors(t)).retainAll(blockadeZones);
	// the size after retainAll is what we count.
	count_blockade_neighbors := proc(
		t: ^Territory,
		game_map: ^Game_Map,
		blockade_zones: [dynamic]^Territory,
	) -> i32 {
		neighbors := game_map_get_neighbors(game_map, t)
		count: i32 = 0
		for n in neighbors {
			for b in blockade_zones {
				if n == b {
					count += 1
					break
				}
			}
		}
		return count
	}
	n1 := count_blockade_neighbors(t1, cmp.game_map, cmp.blockade_zones)
	n2 := count_blockade_neighbors(t2, cmp.game_map, cmp.blockade_zones)
	if n1 == 1 && n2 != 1 {
		return -1
	}
	if n2 == 1 && n1 != 1 {
		return 1
	}
	// Java: Comparator.comparingInt(t -> TerritoryAttachment.getProduction((Territory) t))
	// which is ascending production. The static getProduction returns
	// 0 when the territory has no attachment.
	prod_of := proc(t: ^Territory) -> i32 {
		if t == nil || t.territory_attachment == nil {
			return 0
		}
		return territory_attachment_get_production(t.territory_attachment)
	}
	p1 := prod_of(t1)
	p2 := prod_of(t2)
	if p1 < p2 {
		return -1
	}
	if p1 > p2 {
		return 1
	}
	return 0
}

// Synthetic Java lambda body emitted by javac for the inner
// Comparator<Territory> of getSingleBlockadeThenHighestToLowestBlockadeDamage.
// The captured `damage_per_blockade_zone` map is passed explicitly here
// so this proc reproduces the lambda signature exactly. Wraps the
// already-implemented comparator body via a stack-allocated record.
abstract_end_turn_delegate_lambda__get_single_blockade_then_highest_to_lowest_blockade_damage__2 :: proc(
	damage_per_blockade_zone: map[^Territory]^Tuple(i32, [dynamic]^Territory),
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	cmp := Single_Blockade_Then_Highest_To_Lowest_Blockade_Damage_Comparator{
		damage_per_blockade_zone = damage_per_blockade_zone,
	}
	return abstract_end_turn_delegate_single_blockade_then_highest_to_lowest_blockade_damage_compare(
		&cmp,
		t1,
		t2,
	)
}

// Synthetic Java lambda body emitted by javac for the inner
// Comparator<Territory> of getSingleNeighborBlockadesThenHighestToLowestProduction.
// Mirrors the captured-arg signature (map, blockade_zones, t1, t2)
// and delegates to the implemented comparator body.
abstract_end_turn_delegate_lambda__get_single_neighbor_blockades_then_highest_to_lowest_production__1 :: proc(
	game_map: ^Game_Map,
	blockade_zones: [dynamic]^Territory,
	t1: ^Territory,
	t2: ^Territory,
) -> i32 {
	cmp := Single_Neighbor_Blockades_Then_Highest_To_Lowest_Production_Comparator{
		blockade_zones = blockade_zones,
		game_map       = game_map,
	}
	return abstract_end_turn_delegate_single_neighbor_blockades_then_highest_to_lowest_production_compare(
		&cmp,
		t1,
		t2,
	)
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#loadState(java.io.Serializable)
// Restores delegate state from an EndTurnExtendedDelegateState. Mirrors
// the Java cast-and-assign, then forwards `superState` to the parent
// delegate's loadState (BaseTripleADelegate has no override, so this
// resolves to AbstractDelegate's via Base_Triple_A_Delegate.load_state).
abstract_end_turn_delegate_load_state :: proc(
	self: ^Abstract_End_Turn_Delegate,
	state: ^End_Turn_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
	self.has_posted_turn_summary = state.has_posted_turn_summary
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#<init>()
// Java has no explicit constructor; the implicit one applies the field
// initializers `needToInitialize = true` and `hasPostedTurnSummary = false`.
abstract_end_turn_delegate_new :: proc() -> ^Abstract_End_Turn_Delegate {
	self := new(Abstract_End_Turn_Delegate)
	self.need_to_initialize = true
	self.has_posted_turn_summary = false
	return self
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#saveState()
// Builds an EndTurnExtendedDelegateState, fills in superState from the
// parent BaseTripleADelegate.saveState(), and copies the two delegate
// flags. Java returns Serializable; the Odin port returns the concrete
// state pointer (callers downcast in loadState).
abstract_end_turn_delegate_save_state :: proc(
	self: ^Abstract_End_Turn_Delegate,
) -> ^End_Turn_Extended_Delegate_State {
	state := end_turn_extended_delegate_state_new()
	state.super_state = base_triple_a_delegate_save_state(&self.base_triple_a_delegate)
	state.need_to_initialize = self.need_to_initialize
	state.has_posted_turn_summary = self.has_posted_turn_summary
	return state
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#showEndTurnReport(java.lang.String)
// Java body posts a Swing report message via the remote player. The
// AI-snapshot harness never exercises Swing UI, so this port is a
// deliberate no-op (mirrors the JaCoCo-filtered "UI is not in scope"
// rule from llm-instructions.md).
abstract_end_turn_delegate_show_end_turn_report :: proc(
	self: ^Abstract_End_Turn_Delegate,
	end_turn_report: string,
) {
	// no-op: Swing UI not in scope for the snapshot harness
	_ = self
	_ = end_turn_report
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#writeHistoryEventForChangeUnitOwnership(games.strategy.engine.delegate.IDelegateBridge,java.util.Collection)
// Mirrors Java: a single-territory change emits one startEvent with the
// units as rendering data; multiple territories emit a top-level
// "Units Change Ownership" event followed by one addChildToEvent per
// territory.
abstract_end_turn_delegate_write_history_event_for_change_unit_ownership :: proc(
	bridge: ^I_Delegate_Bridge,
	change_list: [dynamic]^Tuple(^Territory, [dynamic]^Unit),
) {
	writer := i_delegate_bridge_get_history_writer(bridge)
	if len(change_list) == 1 {
		tuple := change_list[0]
		text := fmt.aprintf(
			"Some Units in %s change ownership: %s",
			tuple.first.named.base.name,
			my_formatter_units_to_text_no_owner(tuple.second, nil),
		)
		i_delegate_history_writer_start_event(writer, text, rawptr(&tuple.second))
	} else {
		i_delegate_history_writer_start_event(writer, "Units Change Ownership")
		for tuple in change_list {
			text := fmt.aprintf(
				"Some Units in %s change ownership: %s",
				tuple.first.named.base.name,
				my_formatter_units_to_text_no_owner(tuple.second, nil),
			)
			history_writer_add_child_to_event(writer, text, tuple.second)
		}
	}
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#changeUnitOwnershipInTerritory(games.strategy.engine.delegate.IDelegateBridge,games.strategy.engine.data.Territory,boolean,java.util.Collection,games.strategy.engine.data.GamePlayer,games.strategy.engine.data.CompositeChange,java.util.Collection)
// For each new owner candidate that's both eligible per the territory's
// changeUnitOwners list (or all players when inAllTerritories) AND in
// possibleNewOwners, transfer player's units that the owner is allowed
// to receive (Matches.unitIsOwnedBy(player) AND
// Matches.unitCanBeGivenByTerritoryTo(newOwner)).
abstract_end_turn_delegate_change_unit_ownership_in_territory :: proc(
	bridge: ^I_Delegate_Bridge,
	curr_territory: ^Territory,
	in_all_territories: bool,
	possible_new_owners: [dynamic]^Game_Player,
	player: ^Game_Player,
	change: ^Composite_Change,
	change_list: ^[dynamic]^Tuple(^Territory, [dynamic]^Unit),
) {
	// TerritoryAttachment.get(currTerritory).map(getChangeUnitOwners).orElse(List.of())
	curr_terr_change_unit_owners: [dynamic]^Game_Player
	{
		ta := territory_attachment_get(curr_territory)
		if ta != nil {
			curr_terr_change_unit_owners = ta.change_unit_owners
		}
	}

	if !(in_all_territories || len(curr_terr_change_unit_owners) > 0) {
		return
	}

	// candidateOwners = (currTerrChangeUnitOwners.isEmpty() ? data.getPlayerList().getPlayers()
	//                                                       : currTerrChangeUnitOwners)
	//                   .retainAll(possibleNewOwners)
	candidate_source: [dynamic]^Game_Player
	if len(curr_terr_change_unit_owners) == 0 {
		candidate_source = player_list_get_players(
			game_data_get_player_list(i_delegate_bridge_get_data(bridge)),
		)
	} else {
		candidate_source = curr_terr_change_unit_owners
	}

	candidate_owners: [dynamic]^Game_Player
	defer delete(candidate_owners)
	for cand in candidate_source {
		for p in possible_new_owners {
			if cand == p {
				append(&candidate_owners, cand)
				break
			}
		}
	}

	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	for new_owner in candidate_owners {
		given_pred, given_ctx := matches_unit_can_be_given_by_territory_to(new_owner)
		// territory.getMatches(unitIsOwnedBy(player).and(unitCanBeGivenByTerritoryTo(newOwner)))
		transferable_units: [dynamic]^Unit
		uc := territory_get_unit_collection(curr_territory)
		if uc != nil {
			for u in unit_collection_get_units(uc) {
				if owned_pred(owned_ctx, u) && given_pred(given_ctx, u) {
					append(&transferable_units, u)
				}
			}
		}
		if len(transferable_units) > 0 {
			composite_change_add(
				change,
				change_factory_change_owner_3(transferable_units, new_owner, curr_territory),
			)
			append(change_list, tuple_new(^Territory, [dynamic]^Unit, curr_territory, transferable_units))
		} else {
			delete(transferable_units)
		}
	}
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#changeUnitOwnership(games.strategy.engine.delegate.IDelegateBridge)
// Static helper: walks every territory on the map, collecting unit
// ownership transfers driven by the current player's PlayerAttachment
// (giveUnitControl / giveUnitControlInAllTerritories). When at least
// one transfer was queued, write a history event and apply the
// CompositeChange via the bridge.
abstract_end_turn_delegate_change_unit_ownership :: proc(bridge: ^I_Delegate_Bridge) {
	player := i_delegate_bridge_get_game_player(bridge)
	pa := player_attachment_get(player)
	possible_new_owners := player_attachment_get_give_unit_control(pa)
	in_all_territories := player_attachment_get_give_unit_control_in_all_territories(pa)
	change := composite_change_new()
	change_list: [dynamic]^Tuple(^Territory, [dynamic]^Unit)
	for curr_territory in game_map_get_territories(game_data_get_map(i_delegate_bridge_get_data(bridge))) {
		abstract_end_turn_delegate_change_unit_ownership_in_territory(
			bridge,
			curr_territory,
			in_all_territories,
			possible_new_owners,
			player,
			change,
			&change_list,
		)
	}
	if !composite_change_is_empty(change) && len(change_list) > 0 {
		abstract_end_turn_delegate_write_history_event_for_change_unit_ownership(bridge, change_list)
		i_delegate_bridge_add_change(bridge, cast(^Change)change)
	}
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#lambda$getSingleNeighborBlockadesThenHighestToLowestProduction$0(java.lang.Object)
// Synthetic lambda body for
//   Comparator.comparingInt(t -> TerritoryAttachment.getProduction((Territory) t))
// inside getSingleNeighborBlockadesThenHighestToLowestProduction. Java
// erases the parameter to Object then casts; the Odin port keeps the
// resolved Territory type. Returns 0 when the territory has no
// attachment, mirroring TerritoryAttachment.getProduction's
// null-attachment behavior.
abstract_end_turn_delegate_lambda__get_single_neighbor_blockades_then_highest_to_lowest_production__0 :: proc(
	t: ^Territory,
) -> i32 {
	if t == nil || t.territory_attachment == nil {
		return 0
	}
	return territory_attachment_get_production(t.territory_attachment)
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#canPlayerCollectIncome(GamePlayer, GameMap)
// Java:
//   private static boolean canPlayerCollectIncome(final GamePlayer player, final GameMap gameMap) {
//     return TerritoryAttachment.doWeHaveEnoughCapitalsToProduce(player, gameMap);
//   }
abstract_end_turn_delegate_can_player_collect_income :: proc(
	player: ^Game_Player,
	game_map: ^Game_Map,
) -> bool {
	return territory_attachment_do_we_have_enough_capitals_to_produce(player, game_map)
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getProduction(Collection<Territory>, GameState)
// Java:
//   public static int getProduction(final Collection<Territory> territories, final GameState data) {
//     int value = 0;
//     for (final Territory current : territories) {
//       if (Matches.territoryCanCollectIncomeFrom(current.getOwner()).test(current)) {
//         value += TerritoryAttachment.get(current).map(TerritoryAttachment::getProduction).orElse(0);
//       }
//     }
//     return value;
//   }
// `data` is unused in the Java body (the predicate pulls properties via
// the player's GameData reference), so it is accepted for signature
// fidelity and ignored.
abstract_end_turn_delegate_get_production :: proc(
	territories: [dynamic]^Territory,
	data: ^Game_State,
) -> i32 {
	_ = data
	value: i32 = 0
	for current in territories {
		pred, ctx := matches_territory_can_collect_income_from(territory_get_owner(current))
		defer free(ctx)
		if pred(ctx, current) {
			value += territory_attachment_static_get_production(current)
		}
	}
	return value
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#getProduction(Collection<Territory>)
// Java:
//   protected int getProduction(final Collection<Territory> territories) {
//     return getProduction(territories, getData());
//   }
abstract_end_turn_delegate_get_production_instance :: proc(
	self: ^Abstract_End_Turn_Delegate,
	territories: [dynamic]^Territory,
) -> i32 {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	return abstract_end_turn_delegate_get_production(territories, cast(^Game_State)data)
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#rollWarBonds(IDelegateBridge, GamePlayer, TechnologyFrontier)
// Mirrors the Java private method: roll N S-sided dice for the player's
// War Bonds tech and return the summed proceeds (each die contributes
// face_value + 1, matching Java's `getDie(i).getValue() + 1`). Returns 0
// when either count or sides is non-positive (player has no War Bonds
// tech).
abstract_end_turn_delegate_roll_war_bonds :: proc(
	self: ^Abstract_End_Turn_Delegate,
	delegate_bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
	technology_frontier: ^Technology_Frontier,
) -> i32 {
	_ = self
	techs := tech_tracker_get_current_tech_advances(player, technology_frontier)
	count := tech_ability_attachment_get_war_bond_dice_number_with_techs(techs)
	sides := tech_ability_attachment_get_war_bond_dice_sides_with_techs(techs)
	if sides <= 0 || count <= 0 {
		return 0
	}
	player_name := default_named_get_name(&player.named_attachable.default_named)
	annotation := fmt.aprintf("%s rolling to resolve War Bonds: ", player_name)
	dice := roll_dice_factory_roll_n_sided_dice_x_times(
		delegate_bridge,
		count,
		sides,
		player,
		I_Random_Stats_Dice_Type.NONCOMBAT,
		annotation,
	)
	total: i32 = 0
	n := dice_roll_size(dice)
	for i: i32 = 0; i < n; i += 1 {
		total += die_get_value(dice_roll_get_die(dice, i)) + 1
	}
	remote := i_delegate_bridge_get_remote_player(delegate_bridge, player)
	msg := fmt.aprintf("%s%s", annotation, my_formatter_as_dice(dice))
	i_remote_player_report_message(remote, msg, msg)
	return total
}

// games.strategy.triplea.delegate.AbstractEndTurnDelegate#rollWarBondsForFriends(IDelegateBridge, GamePlayer, TechnologyFrontier, GameMap, ResourceList)
// Java private method: when the player shares War Bonds technology with
// an ally that itself has no War Bonds tech (Global 1940 mechanic), roll
// the player's War Bonds and credit the proceeds to the first eligible
// ally. Returns the transcript text (with a trailing "<br />") or "" if
// no roll happens.
abstract_end_turn_delegate_roll_war_bonds_for_friends :: proc(
	self: ^Abstract_End_Turn_Delegate,
	delegate_bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
	technology_frontier: ^Technology_Frontier,
	game_map: ^Game_Map,
	resource_list: ^Resource_List,
) -> string {
	_ = self
	techs := tech_tracker_get_current_tech_advances(player, technology_frontier)
	count := tech_ability_attachment_get_war_bond_dice_number_with_techs(techs)
	sides := tech_ability_attachment_get_war_bond_dice_sides_with_techs(techs)
	if sides <= 0 || count <= 0 {
		return ""
	}
	playerattachment := player_attachment_get(player)
	if playerattachment == nil {
		return ""
	}
	share_with := player_attachment_get_share_technology(playerattachment)
	if share_with == nil || len(share_with) == 0 {
		return ""
	}
	give_war_bonds_to: ^Game_Player = nil
	for p in share_with {
		p_techs := tech_tracker_get_current_tech_advances(p, technology_frontier)
		dice_count := tech_ability_attachment_get_war_bond_dice_number_with_techs(p_techs)
		dice_sides := tech_ability_attachment_get_war_bond_dice_sides_with_techs(p_techs)
		if dice_sides <= 0 &&
		   dice_count <= 0 &&
		   abstract_end_turn_delegate_can_player_collect_income(p, game_map) {
			give_war_bonds_to = p
			break
		}
	}
	if give_war_bonds_to == nil {
		return ""
	}
	player_name := default_named_get_name(&player.named_attachable.default_named)
	target_name := default_named_get_name(
		&give_war_bonds_to.named_attachable.default_named,
	)
	annotation := fmt.aprintf(
		"%s rolling to resolve War Bonds, and giving results to %s: ",
		player_name,
		target_name,
	)
	dice := roll_dice_factory_roll_n_sided_dice_x_times(
		delegate_bridge,
		count,
		sides,
		player,
		I_Random_Stats_Dice_Type.NONCOMBAT,
		annotation,
	)
	total_war_bonds: i32 = 0
	n := dice_roll_size(dice)
	for i: i32 = 0; i < n; i += 1 {
		total_war_bonds += die_get_value(dice_roll_get_die(dice, i)) + 1
	}
	pus := resource_list_get_resource_or_throw(resource_list, "PUs")
	current_pus := resource_collection_get_quantity(
		game_player_get_resources(give_war_bonds_to),
		pus,
	)
	transcript_text := fmt.aprintf(
		"%s rolls %d%s from War Bonds, giving the total to %s, who ends with %d%s total",
		player_name,
		total_war_bonds,
		my_formatter_pluralize_quantity(" PU", total_war_bonds),
		target_name,
		current_pus + total_war_bonds,
		my_formatter_pluralize_quantity(" PU", current_pus + total_war_bonds),
	)
	history_writer := i_delegate_bridge_get_history_writer(delegate_bridge)
	i_delegate_history_writer_start_event(history_writer, transcript_text)
	change := change_factory_change_resources_change(give_war_bonds_to, pus, total_war_bonds)
	i_delegate_bridge_add_change(delegate_bridge, change)
	remote := i_delegate_bridge_get_remote_player(delegate_bridge, player)
	msg := fmt.aprintf("%s%s", annotation, my_formatter_as_dice(dice))
	i_remote_player_report_message(remote, msg, msg)
	return fmt.aprintf("%s<br />", transcript_text)
}
