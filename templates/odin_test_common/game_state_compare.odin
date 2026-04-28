package test_common

import "core:fmt"
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

	// Units
	// Two-pass match: (1) UUID-aligned units compared field-by-field; (2) leftover
	// units on either side compared by shape-tally (type, owner, scalar flags).
	// Java generates UUIDs via UUID.randomUUID() on unit creation — purchases and
	// battle casualties produce UUIDs we can't reproduce deterministically, so a
	// pure UUID-keyed comparison over-constrains. Shape-tally reconciliation lets
	// Odin match Java behaviour as long as the SET of units (by observable shape)
	// agrees.
	if actual.units_list != nil && expected.units_list != nil {
		if len(actual.units_list.units) != len(expected.units_list.units) {
			return fmt.tprintf("units: count %d != %d",
				len(actual.units_list.units), len(expected.units_list.units))
		}
		act_leftover := make(map[string]int)
		defer delete(act_leftover)
		exp_leftover := make(map[string]int)
		defer delete(exp_leftover)
		for uuid, exp_unit in expected.units_list.units {
			act_unit, found := actual.units_list.units[uuid]
			if !found {
				exp_leftover[unit_shape_signature(exp_unit)] += 1
				continue
			}
			if diff := compare_unit(act_unit, exp_unit); diff != "" {
				return fmt.tprintf("units[%v].%s", uuid, diff)
			}
		}
		for uuid, act_unit in actual.units_list.units {
			if _, found := expected.units_list.units[uuid]; !found {
				act_leftover[unit_shape_signature(act_unit)] += 1
			}
		}
		for sig, exp_count in exp_leftover {
			act_count := act_leftover[sig]
			if act_count != exp_count {
				return fmt.tprintf("units(shape='%s'): count %d != %d", sig, act_count, exp_count)
			}
		}
		for sig, act_count in act_leftover {
			if _, seen := exp_leftover[sig]; !seen && act_count > 0 {
				return fmt.tprintf("units(shape='%s'): count %d != 0 (unexpected)", sig, act_count)
			}
		}
	}

	return ""
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
	return ""
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
