package game

import "base:runtime"

// Java: games.strategy.triplea.odds.calculator.precache.CachedAggregateResults
//
// Aggregate_Results populated from a Stored_Scenario cache hit. Synthesises
// live Unit objects from the cached Unit_Composition entries against the
// supplied Game_Data so downstream callers (e.g. Aggregate_Results
// average TUV swing) receive units with valid Unit_Type and Game_Player
// references and produce results numerically equivalent to a fresh
// simulation.

// Java: fromStored(StoredScenario, GameData) -> Optional<AggregateResults>
//   Returns nil/false when any referenced unit type or player no longer
//   exists in the supplied game data — caller treats as a cache miss.
cached_aggregate_results_from_stored :: proc(
	stored: ^Stored_Scenario, current_data: ^Game_Data,
	allocator := context.allocator,
) -> (^Aggregate_Results, bool) {
	if current_data == nil || stored == nil || len(stored.results) == 0 {
		return nil, false
	}

	type_cache  := make(map[string]^Unit_Type,    allocator = context.temp_allocator)
	defer delete(type_cache)
	player_cache := make(map[string]^Game_Player, allocator = context.temp_allocator)
	defer delete(player_cache)

	rebuilt := make([dynamic]^Battle_Results, allocator)
	for sr in stored.results {
		atk_units, atk_ok := cached_aggregate_results_materialise(
			sr.remaining_attackers, current_data, &type_cache, &player_cache, allocator)
		if !atk_ok { return nil, false }
		def_units, def_ok := cached_aggregate_results_materialise(
			sr.remaining_defenders, current_data, &type_cache, &player_cache, allocator)
		if !def_ok { return nil, false }
		append(&rebuilt, cached_aggregate_results_synthesise_battle_result(
			sr.battle_rounds_fought,
			atk_units,
			def_units,
			cached_aggregate_results_to_live_who_won(sr.who_won),
			current_data,
			allocator,
		))
	}
	return aggregate_results_new_list(rebuilt), true
}

@(private = "file")
cached_aggregate_results_materialise :: proc(
	composition: ^Unit_Composition,
	data: ^Game_Data,
	type_cache: ^map[string]^Unit_Type,
	player_cache: ^map[string]^Game_Player,
	allocator: runtime.Allocator,
) -> ([dynamic]^Unit, bool) {
	out := make([dynamic]^Unit, allocator)
	if composition == nil || len(composition.entries) == 0 {
		return out, true
	}
	for entry in composition.entries {
		ut := cached_aggregate_results_resolve_unit_type(
			entry.unit_type_name, data, type_cache)
		owner := cached_aggregate_results_resolve_player(
			entry.owner_name, data, player_cache)
		if ut == nil || owner == nil {
			delete(out)
			return nil, false
		}
		// Java: type.create(count, owner, /*isTemp=*/true, hits, 0)
		created := unit_type_create_5(ut, entry.count, owner, true, entry.hits, 0)
		for u in created {
			append(&out, u)
		}
	}
	return out, true
}

@(private = "file")
cached_aggregate_results_resolve_unit_type :: proc(
	name: string, data: ^Game_Data, cache: ^map[string]^Unit_Type,
) -> ^Unit_Type {
	if cached, present := cache[name]; present {
		return cached
	}
	type_list := game_data_get_unit_type_list(data)
	ut: ^Unit_Type
	if type_list != nil {
		ut = unit_type_list_get_unit_type(type_list, name)
	}
	cache[name] = ut
	return ut
}

@(private = "file")
cached_aggregate_results_resolve_player :: proc(
	name: string, data: ^Game_Data, cache: ^map[string]^Game_Player,
) -> ^Game_Player {
	if cached, present := cache[name]; present {
		return cached
	}
	player_list := game_data_get_player_list(data)
	player: ^Game_Player
	if player_list != nil {
		if name == "<null>" {
			player = player_list_get_null_player(player_list)
		} else {
			player = player_list_get_player_id(player_list, name)
		}
	}
	cache[name] = player
	return player
}

@(private = "file")
cached_aggregate_results_to_live_who_won :: proc(w: Stored_Scenario_Who_Won) -> I_Battle_Who_Won {
	switch w {
	case .ATTACKER:    return .ATTACKER
	case .DEFENDER:    return .DEFENDER
	case .DRAW:        return .DRAW
	case .NOT_FINISHED: return .NOT_FINISHED
	}
	return .NOT_FINISHED
}

// Java: SyntheticBattleResults — the constructor that takes the direct
// values rather than an IBattle. Odin's Battle_Results already exposes
// the per-field shape, so we just populate one directly.
@(private = "file")
cached_aggregate_results_synthesise_battle_result :: proc(
	rounds: i32,
	attackers: [dynamic]^Unit,
	defenders: [dynamic]^Unit,
	who_won:   I_Battle_Who_Won,
	data:      ^Game_Data,
	allocator: runtime.Allocator,
) -> ^Battle_Results {
	br := new(Battle_Results, allocator)
	br.game_data_component         = make_Game_Data_Component(data)
	br.battle_rounds_fought        = rounds
	br.remaining_attacking_units   = attackers
	br.remaining_defending_units   = defenders
	br.who_won                     = who_won
	return br
}

// Java: toStoredResults(AggregateResults) — invert of fromStored, used
// when persisting a freshly-computed AggregateResults.
cached_aggregate_results_to_stored_results :: proc(
	results: ^Aggregate_Results, allocator := context.allocator,
) -> [dynamic]Stored_Scenario_Result {
	out := make([dynamic]Stored_Scenario_Result, allocator)
	for br in results.results {
		append(&out, Stored_Scenario_Result{
			battle_rounds_fought = br.battle_rounds_fought,
			who_won              = cached_aggregate_results_store_who_won(br),
			remaining_attackers  = unit_composition_from_units(
				battle_results_get_remaining_attacking_units(br), allocator),
			remaining_defenders  = unit_composition_from_units(
				battle_results_get_remaining_defending_units(br), allocator),
		})
	}
	return out
}

@(private = "file")
cached_aggregate_results_store_who_won :: proc(br: ^Battle_Results) -> Stored_Scenario_Who_Won {
	if battle_results_attacker_won(br) { return .ATTACKER }
	if battle_results_defender_won(br) { return .DEFENDER }
	if battle_results_draw(br)         { return .DRAW }
	return .NOT_FINISHED
}
