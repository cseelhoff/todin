package game

import "core:fmt"
import "core:math"

Pro_Territory :: struct {
	pro_data:                ^Pro_Data,
	territory:               ^Territory,
	max_units:               map[^Unit]struct{},
	units:                   [dynamic]^Unit,
	bombers:                 [dynamic]^Unit,
	max_battle_result:       ^Pro_Battle_Result,
	value:                   f64,
	sea_value:               f64,
	can_hold:                bool,
	can_attack:              bool,
	strength_estimate:       f64,

	// Amphib variables
	max_amphib_units:        [dynamic]^Unit,
	amphib_attack_map:       map[^Unit][dynamic]^Unit,
	transport_territory_map: map[^Unit]^Territory,
	need_amphib_units:       bool,
	strafing:                bool,
	is_transporting_map:     map[^Unit]bool,
	max_bombard_units:       map[^Unit]struct{},
	bombard_options_map:     map[^Unit]map[^Territory]struct{},
	bombard_territory_map:   map[^Unit]^Territory,

	// Determine territory to attack variables
	currently_wins:          bool,
	battle_result:           ^Pro_Battle_Result,

	// Non-combat move variables
	cant_move_units:         map[^Unit]struct{},
	max_enemy_units:         [dynamic]^Unit,
	max_enemy_bombard_units: map[^Unit]struct{},
	min_battle_result:       ^Pro_Battle_Result,
	temp_units:              [dynamic]^Unit,
	temp_amphib_attack_map:  map[^Unit][dynamic]^Unit,
	load_value:              f64,

	// Scramble variables
	max_scramble_units:      [dynamic]^Unit,
}

// ---- Phase B procs (layer 0) ----

pro_territory_get_territory :: proc(self: ^Pro_Territory) -> ^Territory {
	return self.territory
}

pro_territory_get_max_units :: proc(self: ^Pro_Territory) -> map[^Unit]struct{} {
	return self.max_units
}

pro_territory_get_units :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.units
}

pro_territory_get_bombers :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.bombers
}

pro_territory_get_max_battle_result :: proc(self: ^Pro_Territory) -> ^Pro_Battle_Result {
	return self.max_battle_result
}

pro_territory_get_value :: proc(self: ^Pro_Territory) -> f64 {
	return self.value
}

pro_territory_get_sea_value :: proc(self: ^Pro_Territory) -> f64 {
	return self.sea_value
}

pro_territory_is_can_hold :: proc(self: ^Pro_Territory) -> bool {
	return self.can_hold
}

pro_territory_is_can_attack :: proc(self: ^Pro_Territory) -> bool {
	return self.can_attack
}

pro_territory_get_strength_estimate :: proc(self: ^Pro_Territory) -> f64 {
	return self.strength_estimate
}

pro_territory_get_max_amphib_units :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.max_amphib_units
}

pro_territory_get_amphib_attack_map :: proc(self: ^Pro_Territory) -> map[^Unit][dynamic]^Unit {
	return self.amphib_attack_map
}

pro_territory_get_transport_territory_map :: proc(self: ^Pro_Territory) -> map[^Unit]^Territory {
	return self.transport_territory_map
}

pro_territory_is_need_amphib_units :: proc(self: ^Pro_Territory) -> bool {
	return self.need_amphib_units
}

pro_territory_is_strafing :: proc(self: ^Pro_Territory) -> bool {
	return self.strafing
}

pro_territory_get_is_transporting_map :: proc(self: ^Pro_Territory) -> map[^Unit]bool {
	return self.is_transporting_map
}

pro_territory_get_max_bombard_units :: proc(self: ^Pro_Territory) -> map[^Unit]struct{} {
	return self.max_bombard_units
}

pro_territory_get_bombard_options_map :: proc(self: ^Pro_Territory) -> map[^Unit]map[^Territory]struct{} {
	return self.bombard_options_map
}

pro_territory_get_bombard_territory_map :: proc(self: ^Pro_Territory) -> map[^Unit]^Territory {
	return self.bombard_territory_map
}

pro_territory_is_currently_wins :: proc(self: ^Pro_Territory) -> bool {
	return self.currently_wins
}

pro_territory_get_battle_result :: proc(self: ^Pro_Territory) -> ^Pro_Battle_Result {
	return self.battle_result
}

pro_territory_get_max_enemy_units :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.max_enemy_units
}

pro_territory_get_max_enemy_bombard_units :: proc(self: ^Pro_Territory) -> map[^Unit]struct{} {
	return self.max_enemy_bombard_units
}

pro_territory_get_min_battle_result :: proc(self: ^Pro_Territory) -> ^Pro_Battle_Result {
	return self.min_battle_result
}

pro_territory_get_temp_units :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.temp_units
}

pro_territory_get_temp_amphib_attack_map :: proc(self: ^Pro_Territory) -> map[^Unit][dynamic]^Unit {
	return self.temp_amphib_attack_map
}

pro_territory_get_load_value :: proc(self: ^Pro_Territory) -> f64 {
	return self.load_value
}

pro_territory_get_max_scramble_units :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	return self.max_scramble_units
}

pro_territory_get_all_defenders :: proc(self: ^Pro_Territory) -> map[^Unit]struct{} {
	defenders := make(map[^Unit]struct{})
	for u in self.units {
		defenders[u] = {}
	}
	for u in self.cant_move_units {
		defenders[u] = {}
	}
	for u in self.temp_units {
		defenders[u] = {}
	}
	return defenders
}

pro_territory_get_max_defenders :: proc(self: ^Pro_Territory) -> [dynamic]^Unit {
	defenders: [dynamic]^Unit
	for u in self.max_units {
		append(&defenders, u)
	}
	for u in self.cant_move_units {
		append(&defenders, u)
	}
	return defenders
}

pro_territory_get_cant_move_units :: proc(self: ^Pro_Territory) -> map[^Unit]struct{} {
	return self.cant_move_units
}

pro_territory_add_unit :: proc(self: ^Pro_Territory, unit: ^Unit) {
	append(&self.units, unit)
}

pro_territory_add_units :: proc(self: ^Pro_Territory, units: [dynamic]^Unit) {
	for u in units {
		append(&self.units, u)
	}
}

pro_territory_add_max_amphib_units :: proc(self: ^Pro_Territory, amphib_units: [dynamic]^Unit) {
	for u in amphib_units {
		append(&self.max_amphib_units, u)
	}
}

pro_territory_add_max_unit :: proc(self: ^Pro_Territory, unit: ^Unit) {
	self.max_units[unit] = {}
}

pro_territory_add_max_units :: proc(self: ^Pro_Territory, units: [dynamic]^Unit) {
	for u in units {
		self.max_units[u] = {}
	}
}

pro_territory_set_value :: proc(self: ^Pro_Territory, value: f64) {
	self.value = value
}

pro_territory_set_can_hold :: proc(self: ^Pro_Territory, can_hold: bool) {
	self.can_hold = can_hold
}

pro_territory_set_need_amphib_units :: proc(self: ^Pro_Territory, need_amphib_units: bool) {
	self.need_amphib_units = need_amphib_units
}

pro_territory_set_strafing :: proc(self: ^Pro_Territory, strafing: bool) {
	self.strafing = strafing
}

pro_territory_set_can_attack :: proc(self: ^Pro_Territory, can_attack: bool) {
	self.can_attack = can_attack
}

pro_territory_set_strength_estimate :: proc(self: ^Pro_Territory, strength_estimate: f64) {
	self.strength_estimate = strength_estimate
}

pro_territory_add_cant_move_unit :: proc(self: ^Pro_Territory, unit: ^Unit) {
	self.cant_move_units[unit] = {}
}

pro_territory_add_cant_move_units :: proc(self: ^Pro_Territory, units: [dynamic]^Unit) {
	for u in units {
		self.cant_move_units[u] = {}
	}
}

pro_territory_set_max_enemy_units :: proc(self: ^Pro_Territory, max_enemy_units: [dynamic]^Unit) {
	new_list: [dynamic]^Unit
	for u in max_enemy_units {
		append(&new_list, u)
	}
	self.max_enemy_units = new_list
}

pro_territory_set_min_battle_result :: proc(self: ^Pro_Territory, min_battle_result: ^Pro_Battle_Result) {
	self.min_battle_result = min_battle_result
}

pro_territory_add_temp_unit :: proc(self: ^Pro_Territory, unit: ^Unit) {
	append(&self.temp_units, unit)
}

pro_territory_add_temp_units :: proc(self: ^Pro_Territory, units: [dynamic]^Unit) {
	for u in units {
		append(&self.temp_units, u)
	}
}

pro_territory_put_temp_amphib_attack_map :: proc(self: ^Pro_Territory, transport: ^Unit, amphib_units: [dynamic]^Unit) {
	self.temp_amphib_attack_map[transport] = amphib_units
}

pro_territory_set_load_value :: proc(self: ^Pro_Territory, load_value: f64) {
	self.load_value = load_value
}

pro_territory_set_sea_value :: proc(self: ^Pro_Territory, sea_value: f64) {
	self.sea_value = sea_value
}

pro_territory_add_max_bombard_unit :: proc(self: ^Pro_Territory, unit: ^Unit) {
	self.max_bombard_units[unit] = {}
}

pro_territory_add_bombard_options_map :: proc(self: ^Pro_Territory, unit: ^Unit, t: ^Territory) {
	inner, ok := self.bombard_options_map[unit]
	if !ok {
		inner = make(map[^Territory]struct{})
	}
	inner[t] = {}
	self.bombard_options_map[unit] = inner
}

pro_territory_set_max_enemy_bombard_units :: proc(self: ^Pro_Territory, max_enemy_bombard_units: map[^Unit]struct{}) {
	self.max_enemy_bombard_units = max_enemy_bombard_units
}

pro_territory_set_max_battle_result :: proc(self: ^Pro_Territory, max_battle_result: ^Pro_Battle_Result) {
	self.max_battle_result = max_battle_result
}


pro_territory_put_all_amphib_attack_map :: proc(self: ^Pro_Territory, amphib_attack_map: map[^Unit][dynamic]^Unit) {
	for transport, units in amphib_attack_map {
		pro_territory_put_amphib_attack_map(self, transport, units)
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritory#<init>(ProTerritory, ProData)
// Java copy constructor: ProTerritory(final ProTerritory patd, final ProData proData).
pro_territory_new_from_other :: proc(patd: ^Pro_Territory, pro_data: ^Pro_Data) -> ^Pro_Territory {
	self := new(Pro_Territory)
	self.territory = patd.territory
	self.pro_data = pro_data

	self.max_units = make(map[^Unit]struct{})
	for u in patd.max_units {
		self.max_units[u] = {}
	}
	self.units = make([dynamic]^Unit)
	for u in patd.units {
		append(&self.units, u)
	}
	self.bombers = make([dynamic]^Unit)
	for u in patd.bombers {
		append(&self.bombers, u)
	}
	self.max_battle_result = patd.max_battle_result
	self.value = patd.value
	self.sea_value = patd.sea_value
	self.can_hold = patd.can_hold
	self.can_attack = patd.can_attack
	self.strength_estimate = patd.strength_estimate

	self.max_amphib_units = make([dynamic]^Unit)
	for u in patd.max_amphib_units {
		append(&self.max_amphib_units, u)
	}
	self.amphib_attack_map = make(map[^Unit][dynamic]^Unit)
	for k, v in patd.amphib_attack_map {
		self.amphib_attack_map[k] = v
	}
	self.transport_territory_map = make(map[^Unit]^Territory)
	for k, v in patd.transport_territory_map {
		self.transport_territory_map[k] = v
	}
	self.need_amphib_units = patd.need_amphib_units
	self.strafing = patd.strafing
	self.is_transporting_map = make(map[^Unit]bool)
	for k, v in patd.is_transporting_map {
		self.is_transporting_map[k] = v
	}
	self.max_bombard_units = make(map[^Unit]struct{})
	for u in patd.max_bombard_units {
		self.max_bombard_units[u] = {}
	}
	self.bombard_options_map = make(map[^Unit]map[^Territory]struct{})
	for k, v in patd.bombard_options_map {
		self.bombard_options_map[k] = v
	}
	self.bombard_territory_map = make(map[^Unit]^Territory)
	for k, v in patd.bombard_territory_map {
		self.bombard_territory_map[k] = v
	}

	self.currently_wins = patd.currently_wins
	self.battle_result = patd.battle_result

	self.cant_move_units = make(map[^Unit]struct{})
	for u in patd.cant_move_units {
		self.cant_move_units[u] = {}
	}
	self.max_enemy_units = make([dynamic]^Unit)
	for u in patd.max_enemy_units {
		append(&self.max_enemy_units, u)
	}
	self.max_enemy_bombard_units = make(map[^Unit]struct{})
	for u in patd.max_enemy_bombard_units {
		self.max_enemy_bombard_units[u] = {}
	}
	self.min_battle_result = patd.min_battle_result
	self.temp_units = make([dynamic]^Unit)
	for u in patd.temp_units {
		append(&self.temp_units, u)
	}
	self.temp_amphib_attack_map = make(map[^Unit][dynamic]^Unit)
	for k, v in patd.temp_amphib_attack_map {
		self.temp_amphib_attack_map[k] = v
	}
	self.load_value = patd.load_value

	self.max_scramble_units = make([dynamic]^Unit)
	for u in patd.max_scramble_units {
		append(&self.max_scramble_units, u)
	}
	return self
}

// games.strategy.triplea.ai.pro.data.ProTerritory#getMaxEnemyDefenders(GamePlayer)
// Java:
//   final List<Unit> defenders = territory.getMatches(Matches.enemyUnit(player));
//   defenders.addAll(maxScrambleUnits);
//   return defenders;
pro_territory_get_max_enemy_defenders :: proc(self: ^Pro_Territory, player: ^Game_Player) -> [dynamic]^Unit {
	defenders: [dynamic]^Unit
	pred, ctx := matches_enemy_unit(player)
	uc := territory_get_unit_collection(self.territory)
	for u in unit_collection_get_units(uc) {
		if pred(ctx, u) {
			append(&defenders, u)
		}
	}
	for u in self.max_scramble_units {
		append(&defenders, u)
	}
	return defenders
}

// games.strategy.triplea.ai.pro.data.ProTerritory#getResultString()
pro_territory_get_result_string :: proc(self: ^Pro_Territory) -> string {
	name := default_named_get_name(&self.territory.named_attachable.default_named)
	if self.battle_result != nil {
		return fmt.aprintf(
			"territory=%s, win%%=%v, TUVSwing=%v, hasRemainingLandUnit=%v",
			name,
			self.battle_result.win_percentage,
			self.battle_result.tuv_swing,
			self.battle_result.has_land_unit_remaining,
		)
	}
	return fmt.aprintf("territory=%s", name)
}

// games.strategy.triplea.ai.pro.data.ProTerritory#setBattleResult(ProBattleResult)
pro_territory_set_battle_result :: proc(self: ^Pro_Territory, battle_result: ^Pro_Battle_Result) {
	self.battle_result = battle_result
	if battle_result == nil {
		self.currently_wins = false
	} else if battle_result.win_percentage >= pro_data_get_win_percentage(self.pro_data) &&
	   battle_result.has_land_unit_remaining {
		self.currently_wins = true
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritory#setBattleResultIfNull(java.util.function.Supplier)
pro_territory_set_battle_result_if_null :: proc(
	self: ^Pro_Territory,
	supplier: proc() -> ^Pro_Battle_Result,
) {
	if self.battle_result == nil {
		pro_territory_set_battle_result(self, supplier())
	}
}

// games.strategy.triplea.ai.pro.data.ProTerritory#<init>(Territory, ProData)
pro_territory_new :: proc(territory: ^Territory, pro_data: ^Pro_Data) -> ^Pro_Territory {
	self := new(Pro_Territory)
	self.territory = territory
	self.pro_data = pro_data
	self.max_units = make(map[^Unit]struct{})
	self.units = make([dynamic]^Unit)
	self.bombers = make([dynamic]^Unit)
	self.max_battle_result = pro_battle_result_new_empty()
	self.value = 0
	self.sea_value = 0
	self.can_hold = true
	self.can_attack = false
	self.strength_estimate = math.INF_F64

	self.max_amphib_units = make([dynamic]^Unit)
	self.amphib_attack_map = make(map[^Unit][dynamic]^Unit)
	self.transport_territory_map = make(map[^Unit]^Territory)
	self.need_amphib_units = false
	self.strafing = false
	self.is_transporting_map = make(map[^Unit]bool)
	self.max_bombard_units = make(map[^Unit]struct{})
	self.bombard_options_map = make(map[^Unit]map[^Territory]struct{})
	self.bombard_territory_map = make(map[^Unit]^Territory)

	self.currently_wins = false
	self.battle_result = nil

	self.cant_move_units = make(map[^Unit]struct{})
	self.max_enemy_units = make([dynamic]^Unit)
	self.max_enemy_bombard_units = make(map[^Unit]struct{})
	self.min_battle_result = pro_battle_result_new_empty()
	self.temp_units = make([dynamic]^Unit)
	self.temp_amphib_attack_map = make(map[^Unit][dynamic]^Unit)
	self.load_value = 0

	self.max_scramble_units = make([dynamic]^Unit)
	return self
}

// Mirrors Java ProTerritory#getEligibleDefenders(GamePlayer):
//   Collection<Unit> defendingUnits = getAllDefenders();
//   if (getTerritory().isWater()) return defendingUnits;
//   return CollectionUtils.getMatches(
//       defendingUnits, ProMatches.unitIsAlliedNotOwnedAir(player).negate());
pro_territory_get_eligible_defenders :: proc(
	self: ^Pro_Territory,
	player: ^Game_Player,
) -> [dynamic]^Unit {
	defending_units := pro_territory_get_all_defenders(self)
	defer delete(defending_units)
	result: [dynamic]^Unit
	if territory_is_water(pro_territory_get_territory(self)) {
		for u in defending_units {
			append(&result, u)
		}
		return result
	}
	pred, ctx := pro_matches_unit_is_allied_not_owned_air(player)
	for u in defending_units {
		if !pred(ctx, u) {
			append(&result, u)
		}
	}
	free(ctx)
	return result
}

// Mirrors Java ProTerritory#getNeighbors(Predicate<Territory>):
//   return proData.getData().getMap().getNeighbors(territory, predicate);
// Closure capture follows the rawptr-ctx convention.
pro_territory_get_neighbors :: proc(
	self: ^Pro_Territory,
	predicate: proc(rawptr, ^Territory) -> bool,
	predicate_ctx: rawptr,
) -> map[^Territory]struct{} {
	return game_map_get_neighbors_predicate(
		game_data_get_map(pro_data_get_data(self.pro_data)),
		self.territory,
		predicate,
		predicate_ctx,
	)
}

// Mirrors Java ProTerritory#getAllDefendersForCarrierCalcs(GameState, GamePlayer):
//   if (Properties.getProduceNewFightersOnOldCarriers(data.getProperties())) {
//     return getAllDefenders();
//   }
//   final Set<Unit> defenders = new HashSet<>(
//       CollectionUtils.getMatches(
//           cantMoveUnits, ProMatches.unitIsOwnedCarrier(player).negate()));
//   defenders.addAll(units);
//   defenders.addAll(tempUnits);
//   return defenders;
pro_territory_get_all_defenders_for_carrier_calcs :: proc(
	self: ^Pro_Territory,
	data: ^Game_State,
	player: ^Game_Player,
) -> map[^Unit]struct{} {
	if properties_get_produce_new_fighters_on_old_carriers(game_state_get_properties(data)) {
		return pro_territory_get_all_defenders(self)
	}
	defenders := make(map[^Unit]struct{})
	pred, ctx := pro_matches_unit_is_owned_carrier(player)
	for u in self.cant_move_units {
		if !pred(ctx, u) {
			defenders[u] = {}
		}
	}
	free(ctx)
	for u in self.units {
		defenders[u] = {}
	}
	for u in self.temp_units {
		defenders[u] = {}
	}
	return defenders
}


pro_territory_put_amphib_attack_map :: proc(self: ^Pro_Territory, transport: ^Unit, amphib_units: [dynamic]^Unit) {
	self.amphib_attack_map[transport] = amphib_units
}

// games.strategy.triplea.ai.pro.data.ProTerritory#estimateBattleResult(ProOddsCalculator, GamePlayer)
pro_territory_estimate_battle_result :: proc(
	self: ^Pro_Territory,
	calc: ^Pro_Odds_Calculator,
	player: ^Game_Player,
) {
	bombarding_units := make([dynamic]^Unit)
	for u, _ in self.bombard_territory_map {
		append(&bombarding_units, u)
	}
	pro_territory_set_battle_result(
		self,
		pro_odds_calculator_estimate_attack_battle_results(
			calc,
			self.pro_data,
			self.territory,
			pro_territory_get_units(self),
			pro_territory_get_max_enemy_defenders(self, player),
			bombarding_units,
		),
	)
}
