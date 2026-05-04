package game

import "core:fmt"
import "core:slice"

Repair_Frontier :: struct {
	using default_named: Default_Named,
	rules:        [dynamic]^Repair_Rule,
	cached_rules: [dynamic]^Repair_Rule,
}

// Mirrors Java `RepairFrontier(String name, GameData data)` which delegates to
// the (name, data, List.of()) constructor with an empty rules list.
repair_frontier_new :: proc(name: string, data: ^Game_Data) -> ^Repair_Frontier {
	return repair_frontier_new_with_rules(name, data, make([dynamic]^Repair_Rule, 0, 0))
}

// Mirrors Java `RepairFrontier(String name, GameData data, List<RepairRule> rules)`.
// Initializes the embedded DefaultNamed and copies `rules` into a fresh backing
// list (Java uses `new ArrayList<>(rules)`); `cachedRules` stays nil.
repair_frontier_new_with_rules :: proc(name: string, data: ^Game_Data, rules: [dynamic]^Repair_Rule) -> ^Repair_Frontier {
	self := new(Repair_Frontier)
	base := default_named_new(name, data)
	self.default_named = base^
	free(base)
	self.rules = make([dynamic]^Repair_Rule, 0, len(rules))
	for r in rules {
		append(&self.rules, r)
	}
	return self
}

// Mirrors Java RepairFrontier#addRule(RepairRule). Throws if the rule is
// already present, otherwise appends and invalidates the cached unmodifiable
// view. cached_rules is cleared (length 0) to signal "rebuild on next get".
repair_frontier_add_rule :: proc(self: ^Repair_Frontier, rule: ^Repair_Rule) {
	if slice.contains(self.rules[:], rule) {
		fmt.panicf("Rule already added: %v", rule)
	}
	append(&self.rules, rule)
	clear(&self.cached_rules)
}

repair_frontier_get_rules :: proc(self: ^Repair_Frontier) -> [dynamic]^Repair_Rule {
	if self.cached_rules == nil {
		self.cached_rules = self.rules
	}
	return self.cached_rules
}
