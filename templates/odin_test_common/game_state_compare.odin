package test_common

import "core:fmt"
import "core:slice"
import "core:strings"
import game "../../odin_flat"

// Compares two Game_Data structs and returns a string describing the first difference found.
// Returns "" if the states are equal.
compare_game_states :: proc(actual: ^game.Game_Data, expected: ^game.Game_Data) -> string {
	if actual == nil && expected == nil { return "" }
	if actual == nil { return "actual is nil" }
	if expected == nil { return "expected is nil" }

	if actual.game_name != expected.game_name {
		return fmt.tprintf("gameName: '%s' != '%s'", actual.game_name, expected.game_name)
	}
	if actual.dice_sides != expected.dice_sides {
		return fmt.tprintf("diceSides: %d != %d", actual.dice_sides, expected.dice_sides)
	}

	// Sequence
	if diff := compare_sequence(actual.sequence, expected.sequence); diff != "" {
		return fmt.tprintf("sequence.%s", diff)
	}

	// Players
	if actual.player_list != nil && expected.player_list != nil {
		for name, exp_player in expected.player_list.players {
			act_player, found := actual.player_list.players[name]
			if !found {
				return fmt.tprintf("players: missing player '%s'", name)
			}
			if diff := compare_player(act_player, exp_player); diff != "" {
				return fmt.tprintf("players.%s.%s", name, diff)
			}
		}
	}

	// Territories
	if actual.game_map != nil && expected.game_map != nil {
		for name, exp_terr in expected.game_map.territory_lookup {
			act_terr, found := actual.game_map.territory_lookup[name]
			if !found {
				return fmt.tprintf("territories: missing '%s'", name)
			}
			if diff := compare_territory(act_terr, exp_terr); diff != "" {
				return fmt.tprintf("territories.%s.%s", name, diff)
			}
		}
	}

	// Purchase pool — units in `units_list` that are not yet placed in any
	// territory's `unit_collection` (e.g. freshly purchased units between
	// the purchase and placement phases). Treated as a synthetic territory
	// so we get the same per-key tally we use for real territories.
	if actual.units_list != nil && expected.units_list != nil {
		act_tally := pool_tally(actual);  defer delete(act_tally)
		exp_tally := pool_tally(expected); defer delete(exp_tally)
		diffs: [dynamic]string; defer delete(diffs)
		for key, ec in exp_tally {
			ac := act_tally[key]
			if ac != ec {
				append(&diffs, fmt.tprintf("[%s]: %d!=%d", territory_unit_key_format(key), ac, ec))
			}
		}
		for key, ac in act_tally {
			if _, ok := exp_tally[key]; !ok && ac > 0 {
				append(&diffs, fmt.tprintf("[%s]: %d!=0", territory_unit_key_format(key), ac))
			}
		}
		if len(diffs) > 0 {
			slice.sort(diffs[:])
			a_total := 0; for _, c in act_tally { a_total += c }
			e_total := 0; for _, c in exp_tally { e_total += c }
			return fmt.tprintf("territories.<purchase_pool>.units: count %d != %d (diffs: %s)",
				a_total, e_total, strings.join(diffs[:], "; "))
		}
	}

	return ""
}

// Tally of units that live in `units_list` but are not in any territory's
// `unit_collection`. Mirrors a real territory's tally so the same
// `Territory_Unit_Key` keys and formatter can be reused.
pool_tally :: proc(gd: ^game.Game_Data) -> map[Territory_Unit_Key]int {
	out := make(map[Territory_Unit_Key]int)
	if gd == nil || gd.units_list == nil { return out }
	placed := make(map[^game.Unit]struct{}); defer delete(placed)
	if gd.game_map != nil {
		for _, t in gd.game_map.territory_lookup {
			if t == nil || t.unit_collection == nil { continue }
			for u in t.unit_collection.units {
				placed[u] = {}
			}
		}
	}
	for _, u in gd.units_list.units {
		if _, in_terr := placed[u]; in_terr { continue }
		out[territory_unit_key(u)] += 1
	}
	return out
}

// Returns a stable string signature of a unit's observable shape — the fields
// compared by compare_unit, plus type/owner. Used for UUID-independent tallying.
unit_shape_signature :: proc(u: ^game.Unit) -> string {
	if u == nil { return "<nil>" }
	t := u.type != nil ? u.type.named.base.name : ""
	o := u.owner != nil ? u.owner.named.base.name : ""
	return fmt.tprintf(
		"type=%s|owner=%s|hits=%d|alreadyMoved=%f|unitDamage=%d|submerged=%v|wasInCombat=%v|wasAmphibious=%v|disabled=%v|bonusMovement=%d|launched=%d|airborne=%v|chargedFlatFuelCost=%v",
		t, o, u.hits, u.already_moved, u.unit_damage, u.submerged,
		u.was_in_combat, u.was_amphibious, u.disabled, u.bonus_movement,
		u.launched, u.airborne, u.charged_flat_fuel_cost,
	)
}

compare_sequence :: proc(a, e: ^game.Game_Sequence) -> string {
	if a == nil && e == nil { return "" }
	if a == nil { return "actual nil" }
	if e == nil { return "expected nil" }
	if a.round != e.round {
		return fmt.tprintf("round: %d != %d", a.round, e.round)
	}
	if a.current_index != e.current_index {
		return fmt.tprintf("currentIndex: %d != %d", a.current_index, e.current_index)
	}
	return ""
}

compare_player :: proc(a, e: ^game.Game_Player) -> string {
	if a.who_am_i != e.who_am_i {
		return fmt.tprintf("whoAmI: '%s' != '%s'", a.who_am_i, e.who_am_i)
	}
	if a.is_disabled != e.is_disabled {
		return fmt.tprintf("isDisabled: %v != %v", a.is_disabled, e.is_disabled)
	}
	// Compare resources by name
	if a.resources != nil && e.resources != nil {
		a_by_name := make(map[string]i32)
		defer delete(a_by_name)
		e_by_name := make(map[string]i32)
		defer delete(e_by_name)
		for res, amt in a.resources.resources {
			if res != nil { a_by_name[res.named.base.name] = amt }
		}
		for res, amt in e.resources.resources {
			if res != nil { e_by_name[res.named.base.name] = amt }
		}
		for name, exp_amt in e_by_name {
			act_amt, found := a_by_name[name]
			if !found {
				return fmt.tprintf("resources[%s]: missing", name)
			}
			if act_amt != exp_amt {
				return fmt.tprintf("resources[%s]: %d != %d", name, act_amt, exp_amt)
			}
		}
	}
	return ""
}

compare_territory :: proc(a, e: ^game.Territory) -> string {
	if a.water != e.water {
		return fmt.tprintf("water: %v != %v", a.water, e.water)
	}
	a_owner := a.owner != nil ? a.owner.named.base.name : ""
	e_owner := e.owner != nil ? e.owner.named.base.name : ""
	if a_owner != e_owner {
		return fmt.tprintf("owner: '%s' != '%s'", a_owner, e_owner)
	}

	// Per-territory unit tally by (type, owner, alreadyMoved, unitDamage).
	// Detects local divergences (e.g. wrong placement territory, wrong
	// number of damaged battleships) that the game-wide shape tally hides.
	a_tally := make(map[Territory_Unit_Key]int); defer delete(a_tally)
	e_tally := make(map[Territory_Unit_Key]int); defer delete(e_tally)
	if a.unit_collection != nil {
		for u in a.unit_collection.units {
			a_tally[territory_unit_key(u)] += 1
		}
	}
	if e.unit_collection != nil {
		for u in e.unit_collection.units {
			e_tally[territory_unit_key(u)] += 1
		}
	}
	t_diffs: [dynamic]string; defer delete(t_diffs)
	for key, ec in e_tally {
		ac := a_tally[key]
		if ac != ec {
			append(&t_diffs, fmt.tprintf("[%s]: %d!=%d", territory_unit_key_format(key), ac, ec))
		}
	}
	for key, ac in a_tally {
		if _, ok := e_tally[key]; !ok && ac > 0 {
			append(&t_diffs, fmt.tprintf("[%s]: %d!=0", territory_unit_key_format(key), ac))
		}
	}
	if len(t_diffs) > 0 {
		slice.sort(t_diffs[:])
		a_count := a.unit_collection != nil ? len(a.unit_collection.units) : 0
		e_count := e.unit_collection != nil ? len(e.unit_collection.units) : 0
		return fmt.tprintf("units: count %d != %d (diffs: %s)",
			a_count, e_count, strings.join(t_diffs[:], "; "))
	}
	return ""
}

// Per-territory unit grouping key: type, owner, alreadyMoved, unitDamage.
// Pointer-equality is sufficient for type/owner since both live in the
// shared GameData and are interned.
Territory_Unit_Key :: struct {
	type:          ^game.Unit_Type,
	owner:         ^game.Game_Player,
	already_moved: f64,
	unit_damage:   i32,
}

territory_unit_key :: proc(u: ^game.Unit) -> Territory_Unit_Key {
	if u == nil { return {} }
	return {u.type, u.owner, u.already_moved, u.unit_damage}
}

territory_unit_key_format :: proc(k: Territory_Unit_Key) -> string {
	t := k.type != nil ? k.type.named.base.name : ""
	o := k.owner != nil ? k.owner.named.base.name : ""
	return fmt.tprintf("type=%s|owner=%s|alreadyMoved=%f|unitDamage=%d",
		t, o, k.already_moved, k.unit_damage)
}

compare_unit :: proc(a, e: ^game.Unit) -> string {
	a_type := a.type != nil ? a.type.named.base.name : ""
	e_type := e.type != nil ? e.type.named.base.name : ""
	if a_type != e_type {
		return fmt.tprintf("type: '%s' != '%s'", a_type, e_type)
	}
	a_owner := a.owner != nil ? a.owner.named.base.name : ""
	e_owner := e.owner != nil ? e.owner.named.base.name : ""
	if a_owner != e_owner {
		return fmt.tprintf("owner: '%s' != '%s'", a_owner, e_owner)
	}
	if a.hits != e.hits {
		return fmt.tprintf("hits: %d != %d", a.hits, e.hits)
	}
	if a.already_moved != e.already_moved {
		return fmt.tprintf("alreadyMoved: %f != %f", a.already_moved, e.already_moved)
	}
	if a.unit_damage != e.unit_damage {
		return fmt.tprintf("unitDamage: %d != %d", a.unit_damage, e.unit_damage)
	}
	if a.submerged != e.submerged {
		return fmt.tprintf("submerged: %v != %v", a.submerged, e.submerged)
	}
	if a.was_in_combat != e.was_in_combat {
		return fmt.tprintf("wasInCombat: %v != %v", a.was_in_combat, e.was_in_combat)
	}
	if a.was_amphibious != e.was_amphibious {
		return fmt.tprintf("wasAmphibious: %v != %v", a.was_amphibious, e.was_amphibious)
	}
	if a.disabled != e.disabled {
		return fmt.tprintf("disabled: %v != %v", a.disabled, e.disabled)
	}
	if a.bonus_movement != e.bonus_movement {
		return fmt.tprintf("bonusMovement: %d != %d", a.bonus_movement, e.bonus_movement)
	}
	if a.launched != e.launched {
		return fmt.tprintf("launched: %d != %d", a.launched, e.launched)
	}
	if a.airborne != e.airborne {
		return fmt.tprintf("airborne: %v != %v", a.airborne, e.airborne)
	}
	if a.charged_flat_fuel_cost != e.charged_flat_fuel_cost {
		return fmt.tprintf("chargedFlatFuelCost: %v != %v", a.charged_flat_fuel_cost, e.charged_flat_fuel_cost)
	}
	return ""
}
