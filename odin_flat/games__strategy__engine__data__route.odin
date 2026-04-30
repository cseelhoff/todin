package game

import "core:fmt"
import "core:slice"

Route :: struct {
	start: ^Territory,
	steps: [dynamic]^Territory,
}

// Mirrors Java Route#add(Territory) (private). Appends `territory` to the
// step list, rejecting any input that would form a loop — i.e. matches the
// route's start or is already present in steps. Java throws
// IllegalArgumentException; we panic with the same message.
route_add :: proc(self: ^Route, territory: ^Territory) {
	if territory == self.start || slice.contains(self.steps[:], territory) {
		fmt.panicf("Loops not allowed in steps, route: %v, new territory: %v", self, territory)
	}
	append(&self.steps, territory)
}

// Mirrors Java Route#anyMatch(Predicate<Territory>). Returns true iff any
// step territory satisfies the predicate. The Java implementation streams
// `steps` (excluding `start`); we mirror that exactly.
route_any_match :: proc(self: ^Route, predicate: proc(t: ^Territory) -> bool) -> bool {
	for step in self.steps {
		if predicate(step) {
			return true
		}
	}
	return false
}

// Mirrors Java Route#getEnd(). Returns the last territory in the route, or
// the start when there are no steps.
route_get_end :: proc(self: ^Route) -> ^Territory {
	if len(self.steps) == 0 {
		return self.start
	}
	return self.steps[len(self.steps) - 1]
}

// Mirrors Java Route#getMiddleSteps(): returns all step territories
// except the last one (the end). When there are 0 or 1 steps, returns
// an empty list. Java returns a subList view; we allocate a fresh
// [dynamic] copy.
route_get_middle_steps :: proc(self: ^Route) -> [dynamic]^Territory {
	result: [dynamic]^Territory
	if len(self.steps) > 1 {
		for i in 0 ..< len(self.steps) - 1 {
			append(&result, self.steps[i])
		}
	}
	return result
}

// Mirrors Java Route#getAllTerritories(). Returns a freshly allocated list
// containing the start territory followed by every step, in order.
route_get_all_territories :: proc(self: ^Route) -> [dynamic]^Territory {
	list := make([dynamic]^Territory, 0, len(self.steps) + 1)
	append(&list, self.start)
	for t in self.steps {
		append(&list, t)
	}
	return list
}

// Mirrors Java Route#equals(Object). Two routes are equal when they have
// the same start, the same number of steps, and the same step
// territories in the same order. Java compares getAllTerritories() (start
// plus steps); given equal starts, that reduces to equal step sequences.
// Territory identity is by pointer in the Odin port.
route_equals :: proc(self: ^Route, other: ^Route) -> bool {
	if self == other {
		return true
	}
	if other == nil {
		return false
	}
	if len(self.steps) != len(other.steps) {
		return false
	}
	if self.start != other.start {
		return false
	}
	for t, i in self.steps {
		if t != other.steps[i] {
			return false
		}
	}
	return true
}


// Mirrors Java Route#allMatchMiddleSteps(Predicate<Territory>). Returns true
// iff the middle steps (every step except the last, i.e. excluding both the
// start territory and the end territory) are non-empty and every territory
// satisfies the predicate. When there are fewer than 2 steps the middle is
// empty and Java returns false; we preserve that behaviour.
route_all_match_middle_steps :: proc(self: ^Route, predicate: proc(t: ^Territory) -> bool) -> bool {
	if len(self.steps) <= 1 {
		return false
	}
	for t in self.steps[:len(self.steps) - 1] {
		if !predicate(t) {
			return false
		}
	}
	return true
}

// Mirrors Java Route#hasExactlyOneStep(): true when steps.size() == 1.
route_has_exactly_one_step :: proc(self: ^Route) -> bool {
	return len(self.steps) == 1
}

// Mirrors Java Route#getSteps(). Java returns an unmodifiable view of the
// internal `steps` list; in Odin we return a freshly allocated [dynamic]
// copy of the step territories (excluding the start).
route_get_steps :: proc(self: ^Route) -> [dynamic]^Territory {
	result := make([dynamic]^Territory, 0, len(self.steps))
	for t in self.steps {
		append(&result, t)
	}
	return result
}

// Mirrors Java Route#getTerritoryAtStep(int). Returns the territory at the
// i'th step (0-indexed into the step list).
route_get_territory_at_step :: proc(self: ^Route, i: i32) -> ^Territory {
	return self.steps[i]
}

// Mirrors Java Route#hasMoreThanOneStep(): true when steps.size() > 1.
route_has_more_than_one_step :: proc(self: ^Route) -> bool {
	return len(self.steps) > 1
}

// Mirrors Java Route#getTerritoryBeforeEnd(): returns the start territory
// when the route has 0 or 1 steps, otherwise the second-to-last step.
route_get_territory_before_end :: proc(self: ^Route) -> ^Territory {
	if len(self.steps) <= 1 {
		return self.start
	}
	return self.steps[len(self.steps) - 2]
}

// Mirrors Java Route#getMovementCost(Unit): delegates to the private static
// findMovementCost helper, walking every step territory and summing the
// per-territory movement cost for `unit`. BigDecimal → f64.
route_get_movement_cost :: proc(self: ^Route, unit: ^Unit) -> f64 {
	return route_find_movement_cost(unit, self.steps[:])
}

// Mirrors Java Route#hasSteps(): true when the route has at least one step
// territory (i.e. `steps` is non-empty).
route_has_steps :: proc(self: ^Route) -> bool {
	return len(self.steps) > 0
}

// Mirrors Java Route#isLoad(): true iff the route has steps, the start
// territory is land, and the end territory is water (loading from land
// into a transport at sea).
route_is_load :: proc(self: ^Route) -> bool {
	return route_has_steps(self) && !self.start.water && route_get_end(self).water
}

// Mirrors Java Route#hasNoSteps(): inverse of hasSteps — true when the
// step list is empty.
route_has_no_steps :: proc(self: ^Route) -> bool {
	return !route_has_steps(self)
}

// Mirrors Java Route#numberOfSteps(): returns the number of step
// territories in this route (does not include the start).
route_number_of_steps :: proc(self: ^Route) -> i32 {
	return i32(len(self.steps))
}

// Mirrors Java Route#isUnload(): true when the route has at least one step
// and the start territory is water while the end territory is not. Used by
// movement validation to detect transport-to-land unload routes.
route_is_unload :: proc(self: ^Route) -> bool {
	return route_has_steps(self) && self.start.water && !route_get_end(self).water
}

// Mirrors Java Route#iterator() (from Iterable<Territory>):
//     return getAllTerritories().iterator();
// Java returns an Iterator over the start-plus-steps list. The Odin port
// follows the same convention as `game_map_iterator` /
// `player_list_iterator` and surfaces the freshly allocated snapshot
// directly — callers iterate with `for t in route_iterator(r)`.
route_iterator :: proc(self: ^Route) -> [dynamic]^Territory {
	return route_get_all_territories(self)
}
