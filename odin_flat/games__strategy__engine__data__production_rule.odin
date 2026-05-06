package game

import "core:fmt"

Production_Rule :: struct {
        using default_named: Default_Named,
	costs:        Integer_Map,
	results:      Integer_Map,
	rule:         Rule,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.ProductionRule

production_rule_new :: proc(name: string, data: ^Game_Data) -> ^Production_Rule {
	self := new(Production_Rule)
	base := default_named_new(name, data)
	self.default_named = base^
	free(base)
	self.costs = Integer_Map{map_values = make(map[rawptr]i32)}
	self.results = Integer_Map{map_values = make(map[rawptr]i32)}
	self.rule = Rule{
		add_cost    = production_rule_rule_add_cost,
		get_name    = production_rule_rule_get_name,
		get_results = production_rule_rule_get_results,
	}
	self.default_named.named.kind = .Production_Rule
	return self
}

// Vtable bridges that recover the outer Production_Rule from its
// embedded Rule field, mirroring Java's `extends Rule` polymorphism.
production_rule_rule_add_cost :: proc(self: ^Rule, resource: ^Resource, quantity: i32) {
	pr := cast(^Production_Rule)(uintptr(self) - offset_of(Production_Rule, rule))
	production_rule_add_cost(pr, resource, quantity)
}

production_rule_rule_get_name :: proc(self: ^Rule) -> string {
	pr := cast(^Production_Rule)(uintptr(self) - offset_of(Production_Rule, rule))
	return default_named_get_name(&pr.default_named)
}

production_rule_rule_get_results :: proc(self: ^Rule) -> ^Integer_Map {
	pr := cast(^Production_Rule)(uintptr(self) - offset_of(Production_Rule, rule))
	return &pr.results
}

production_rule_get_costs :: proc(self: ^Production_Rule) -> Integer_Map {
	result := Integer_Map{}
	result.map_values = make(map[rawptr]i32)
	for k, v in self.costs.map_values {
		result.map_values[k] = v
	}
	return result
}

production_rule_to_string :: proc(self: ^Production_Rule) -> string {
	return fmt.aprintf("ProductionRule:%s", default_named_get_name(&self.default_named))
}

production_rule_get_results :: proc(self: ^Production_Rule) -> Integer_Map {
	return self.results
}

production_rule_add_cost :: proc(self: ^Production_Rule, resource: ^Resource, cost: i32) {
	integer_map_put(&self.costs, rawptr(resource), cost)
}

