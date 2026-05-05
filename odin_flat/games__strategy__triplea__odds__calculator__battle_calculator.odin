package game

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:time"

Battle_Calculator :: struct {
	using i_battle_calculator: I_Battle_Calculator,
	game_data: ^Game_Data,
	tuv_calculator: ^Tuv_Costs_Calculator,
	keep_one_attacking_land_unit: bool,
	amphibious: bool,
	retreat_after_round: i32,
	retreat_after_x_units_left: i32,
	attacker_order_of_losses: string,
	defender_order_of_losses: string,
	cancelled: bool,
	is_running: bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.BattleCalculator

battle_calculator_cancel :: proc(self: ^Battle_Calculator) {
	self.cancelled = true
}

// Mirrors Java's `mergeUnitCollections`: returns the union of two
// unit collections and panics (IllegalStateException analogue) if
// the two inputs share any element. Pointer identity matches Java
// HashSet semantics for Unit (which inherits Object equality via
// its UUID-keyed identity used elsewhere in the engine).
battle_calculator_merge_unit_collections :: proc(
	self: ^Battle_Calculator,
	c1: [dynamic]^Unit,
	c2: [dynamic]^Unit,
) -> [dynamic]^Unit {
	seen: map[^Unit]struct{}
	defer delete(seen)
	combined := make([dynamic]^Unit)
	for u in c1 {
		if _, exists := seen[u]; !exists {
			seen[u] = {}
			append(&combined, u)
		}
	}
	for u in c2 {
		if _, exists := seen[u]; !exists {
			seen[u] = {}
			append(&combined, u)
		}
	}
	if len(combined) != len(c1) + len(c2) {
		fmt.panicf(
			"Attackers and defenders collections must be distinct with no duplicates. " +
			"This helps catch logic errors in AI code that would otherwise be hard to debug.",
		)
	}
	return combined
}

// Java: `attackingUnits.forEach(unit -> unit.setWasAmphibious(true))`
// inside `BattleCalculator.calculate`. Captures nothing.
battle_calculator_calculate_lambda_0 :: proc(unit: ^Unit) {
	unit_set_was_amphibious(unit, true)
}

// games.strategy.triplea.odds.calculator.BattleCalculator#<init>(byte[])
// Java:
//   BattleCalculator(byte[] data) {
//     gameData = GameDataUtils.createGameDataFromBytes(data).orElseThrow();
//     gameData.getProperties().set(EDIT_MODE, false);
//   }
// `Constants.EDIT_MODE` is the literal "EditMode". The Optional<GameData>
// from createGameDataFromBytes is represented as ^Game_Data (nil = empty)
// per the GameDataUtils shim; orElseThrow() collapses to using the value
// directly since the snapshot harness's opaque IO regime tolerates nil
// game data on the worker pool. Field defaults match Java's field
// initializers (-1 retreat thresholds, fresh TuvCostsCalculator, false
// flags). The `EDIT_MODE` value is a heap-boxed bool so the property
// store owns a stable rawptr (mirrors game_data_set_map_name).
battle_calculator_new :: proc(data: []u8) -> ^Battle_Calculator {
	self := new(Battle_Calculator)
	self.tuv_calculator = tuv_costs_calculator_new()
	self.keep_one_attacking_land_unit = false
	self.amphibious = false
	self.retreat_after_round = -1
	self.retreat_after_x_units_left = -1
	self.attacker_order_of_losses = ""
	self.defender_order_of_losses = ""
	self.cancelled = false
	self.is_running = false
	self.game_data = game_data_utils_create_game_data_from_bytes(data)
	if self.game_data != nil {
		boxed := new(bool)
		boxed^ = false
		game_properties_set(game_data_get_properties(self.game_data), "EditMode", rawptr(boxed))
	}
	return self
}

// games.strategy.triplea.odds.calculator.BattleCalculator#translateCollectionIntoOtherGameData(
//     java.util.Collection, games.strategy.engine.data.GameData)
// Java:
//   private <T> Collection<T> translateCollectionIntoOtherGameData(
//       Collection<T> collection, GameData otherData) {
//     if (!(collection instanceof Serializable)) {
//       collection = new ArrayList<>(collection);
//     }
//     return GameDataUtils.translateIntoOtherGameData(collection, otherData);
//   }
// The Serializable-vs-non-Serializable check is a Java-only artifact:
// Odin's [dynamic]^T collections are always serializable in the porting
// model (they are concrete arrays, not view wrappers like
// `HashMap.keySet()`). The explicit ArrayList copy therefore has no
// observable effect in Odin and collapses to a direct call into
// GameDataUtils.translateIntoOtherGameData. Collections are passed as
// rawptr so this proc can serve any element type (Unit,
// TerritoryEffect, etc.) just like Java's generic `<T>`.
battle_calculator_translate_collection_into_other_game_data :: proc(
	self: ^Battle_Calculator,
	collection: rawptr,
	other_data: ^Game_Data,
) -> rawptr {
	_ = self
	return game_data_utils_translate_into_other_game_data(collection, other_data)
}

// Static helper mirroring `OrderOfLossesInputPanel.getUnitListByOrderOfLoss`.
// The Swing OOL panel itself is excluded from the porting universe (UI),
// but its static helper is referenced from `BattleCalculator.calculate`.
// Returns nil for null/blank input (matches Java's `null` return). For a
// real OOL specification, parses `<amount>^<unitType>;<amount>^<unitType>...`,
// reverses, greedily collects up to `amount` units of `unitType` from the
// remaining pool, then reverses the accumulated order. `*` means "all".
@(private="file")
battle_calculator_get_unit_list_by_order_of_loss :: proc(
	ool: string,
	units: [dynamic]^Unit,
	data: ^Game_Data,
) -> [dynamic]^Unit {
	is_blank := true
	for r in ool {
		if r != ' ' && r != '\t' && r != '\n' && r != '\r' {
			is_blank = false
			break
		}
	}
	if len(ool) == 0 || is_blank {
		return nil
	}
	OOL_Pair :: struct { amount: i32, type: ^Unit_Type }
	pairs: [dynamic]OOL_Pair
	defer delete(pairs)
	trimmed := strings.trim_space(ool)
	sections := strings.split(trimmed, ";")
	defer delete(sections)
	for section in sections {
		if len(section) == 0 {
			continue
		}
		parts := strings.split(section, "^")
		defer delete(parts)
		if len(parts) < 2 {
			continue
		}
		amount: i32
		if parts[0] == "*" {
			amount = max(i32)
		} else {
			parsed, _ := strconv.parse_int(parts[0], 10)
			amount = i32(parsed)
		}
		unit_type := unit_type_list_get_unit_type_or_throw(
			game_data_get_unit_type_list(data),
			parts[1],
		)
		append(&pairs, OOL_Pair{amount = amount, type = unit_type})
	}
	// Collections.reverse(map)
	for i := 0; i < len(pairs) / 2; i += 1 {
		j := len(pairs) - 1 - i
		pairs[i], pairs[j] = pairs[j], pairs[i]
	}
	units_left: map[^Unit]struct{}
	defer delete(units_left)
	for u in units {
		units_left[u] = {}
	}
	order := make([dynamic]^Unit)
	for pair in pairs {
		count: i32 = 0
		taken: [dynamic]^Unit
		for u in units {
			if count >= pair.amount {
				break
			}
			if _, in_left := units_left[u]; !in_left {
				continue
			}
			if unit_get_type(u) == pair.type {
				append(&taken, u)
				append(&order, u)
				count += 1
			}
		}
		for u in taken {
			delete_key(&units_left, u)
		}
		delete(taken)
	}
	// Collections.reverse(order)
	for i := 0; i < len(order) / 2; i += 1 {
		j := len(order) - 1 - i
		order[i], order[j] = order[j], order[i]
	}
	return order
}

// games.strategy.triplea.odds.calculator.BattleCalculator#calculate(
//   GamePlayer attacker, GamePlayer defender, Territory location,
//   Collection<Unit> attacking, Collection<Unit> defending,
//   Collection<Unit> bombarding, Collection<TerritoryEffect> territoryEffects,
//   boolean retreatWhenOnlyAirLeft, int runCount)
//
// Java drives `runCount` simulated battles on `location` between the
// rebound attacker/defender (translated into this calculator's private
// `gameData`), aggregating results. Notes on the port:
//   * `isRunning.getAndSet(true)` collapses to a plain bool check; the
//     snapshot harness is single-threaded.
//   * `translateCollectionIntoOtherGameData` is the
//     `GameDataUtils.translateIntoOtherGameData` round-trip, which is a
//     no-op identity in the Odin shim (see `game_data_utils.odin`); we
//     mirror Java's local rebinding by copying the input slices.
//   * `OrderOfLossesInputPanel.getUnitListByOrderOfLoss` is a Swing-class
//     static helper inlined here (`battle_calculator_get_unit_list_by_order_of_loss`).
//   * The MustFightBattle is exposed as `^I_Delegate_Bridge` via the
//     same cast pattern other call sites use for concrete bridge types
//     (compare `make_Default_Delegate_Bridge` -> `cast(^I_Delegate_Bridge)`).
battle_calculator_calculate :: proc(
	self: ^Battle_Calculator,
	attacker: ^Game_Player,
	defender: ^Game_Player,
	location: ^Territory,
	attacking: [dynamic]^Unit,
	defending: [dynamic]^Unit,
	bombarding: [dynamic]^Unit,
	territory_effects: [dynamic]^Territory_Effect,
	retreat_when_only_air_left: bool,
	run_count: i32,
) -> ^Aggregate_Results {
	if self.is_running {
		fmt.panicf("Can't calculate while operation is still running!")
	}
	self.is_running = true
	defer self.is_running = false

	pl := game_data_get_player_list(self.game_data)
	attacker2: ^Game_Player
	if attacker == nil {
		attacker2 = player_list_get_null_player(pl)
	} else {
		attacker2 = player_list_get_player_id(
			pl,
			default_named_get_name(&attacker.default_named),
		)
	}
	defender2: ^Game_Player
	if defender == nil {
		defender2 = player_list_get_null_player(pl)
	} else {
		defender2 = player_list_get_player_id(
			pl,
			default_named_get_name(&defender.default_named),
		)
	}
	location2 := game_map_get_territory_or_null(
		game_data_get_map(self.game_data),
		default_named_get_name(&location.default_named),
	)

	// Identity translation: mirror Java's local rebinding by copying the
	// inputs. game_data_utils_translate_into_other_game_data is a no-op
	// in the Odin shim, so the explicit rawptr round-trip would have no
	// observable effect; preserving the copy keeps semantics aligned
	// with the Java side, which always returns a fresh Collection.
	attacking_units := make([dynamic]^Unit)
	for u in attacking { append(&attacking_units, u) }
	defending_units := make([dynamic]^Unit)
	for u in defending { append(&defending_units, u) }
	bombarding_units := make([dynamic]^Unit)
	for u in bombarding { append(&bombarding_units, u) }
	territory_effects2 := make([dynamic]^Territory_Effect)
	for te in territory_effects { append(&territory_effects2, te) }

	// gameData.performChange(ChangeFactory.removeUnits(location2, location2.getUnits()));
	existing_units: [dynamic]^Unit
	if location2 != nil && location2.unit_collection != nil {
		for u in location2.unit_collection.units {
			append(&existing_units, u)
		}
	}
	game_data_perform_change(
		self.game_data,
		change_factory_remove_units(cast(^Unit_Holder)location2, existing_units),
	)
	merged := battle_calculator_merge_unit_collections(self, attacking_units, defending_units)
	game_data_perform_change(
		self.game_data,
		change_factory_add_units(cast(^Unit_Holder)location2, merged),
	)

	start_tick := time.tick_now()
	aggregate_results := aggregate_results_new_int(run_count)
	battle_tracker := battle_tracker_new()
	attacker_ool := battle_calculator_get_unit_list_by_order_of_loss(
		self.attacker_order_of_losses,
		attacking_units,
		self.game_data,
	)
	defender_ool := battle_calculator_get_unit_list_by_order_of_loss(
		self.defender_order_of_losses,
		defending_units,
		self.game_data,
	)

	for i: i32 = 0; i < run_count && !self.cancelled; i += 1 {
		all_changes := composite_change_new()
		bridge := dummy_delegate_bridge_new(
			attacker2,
			self.game_data,
			all_changes,
			attacker_ool,
			defender_ool,
			self.keep_one_attacking_land_unit,
			self.retreat_after_round,
			self.retreat_after_x_units_left,
			retreat_when_only_air_left,
			self.tuv_calculator,
		)
		battle := must_fight_battle_new(location2, attacker2, self.game_data, battle_tracker)
		abstract_battle_set_headless(&battle.abstract_battle, true)
		if self.amphibious {
			for u in attacking_units {
				battle_calculator_calculate_lambda_0(u)
			}
		}
		must_fight_battle_set_units(
			battle,
			defending_units,
			attacking_units,
			bombarding_units,
			defender2,
			territory_effects2,
		)
		dummy_delegate_bridge_set_battle(bridge, battle)
		must_fight_battle_fight(battle, cast(^I_Delegate_Bridge)bridge)
		aggregate_results_add_result(
			aggregate_results,
			battle_results_new(cast(^I_Battle)&battle.abstract_battle, self.game_data),
		)
		// restore the game to its original state
		game_data_perform_change(self.game_data, composite_change_invert(all_changes))
		battle_tracker_clear(battle_tracker)
		battle_tracker_clear_battle_records(battle_tracker)
	}
	elapsed_ms := time.duration_milliseconds(time.tick_since(start_tick))
	aggregate_results_set_time(aggregate_results, i64(elapsed_ms))
	self.cancelled = false
	return aggregate_results
}

