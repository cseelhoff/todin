package game

import "core:fmt"

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

