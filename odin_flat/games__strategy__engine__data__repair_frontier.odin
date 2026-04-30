package game

import "core:fmt"
import "core:slice"

Repair_Frontier :: struct {
	using default_named: Default_Named,
	rules:        [dynamic]^Repair_Rule,
	cached_rules: [dynamic]^Repair_Rule,
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
