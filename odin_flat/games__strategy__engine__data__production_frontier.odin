package game

import "core:fmt"
import "core:slice"

Production_Frontier :: struct {
	using default_named: Default_Named,
	rules:               [dynamic]^Production_Rule,
	cached_rules:        [dynamic]^Production_Rule,
}

// Mirrors Java ProductionFrontier#addRule(ProductionRule). Throws if the rule
// is already present, otherwise appends and invalidates the cached unmodifiable
// view. cached_rules is cleared (length 0) to signal "rebuild on next get".
production_frontier_add_rule :: proc(self: ^Production_Frontier, rule: ^Production_Rule) {
	if slice.contains(self.rules[:], rule) {
		fmt.panicf("Rule already added: %v", rule)
	}
	append(&self.rules, rule)
	clear(&self.cached_rules)
}

// Java: ProductionFrontier#iterator() — returns getRules().iterator().
// Odin convention (see game_map_iterator): expose the backing list and
// let callers use `for r in production_frontier_iterator(pf)`.
production_frontier_iterator :: proc(self: ^Production_Frontier) -> [dynamic]^Production_Rule {
	return self.rules
}

production_frontier_get_rules :: proc(self: ^Production_Frontier) -> [dynamic]^Production_Rule {
	if self.cached_rules == nil {
		self.cached_rules = self.rules
	}
	return self.cached_rules
}

