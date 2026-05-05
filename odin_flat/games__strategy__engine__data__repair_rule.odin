package game

import "core:fmt"

Repair_Rule :: struct {
        using default_named: Default_Named,
	costs:        ^Integer_Map,
	results:      ^Integer_Map,
	rule:         Rule,
}

repair_rule_new :: proc(name: string, data: ^Game_Data, costs: ^Integer_Map, results: ^Integer_Map) -> ^Repair_Rule {
	if costs == nil {
		panic("costs must not be null")
	}
	if results == nil {
		panic("results must not be null")
	}
	base := default_named_new(name, data)
	self := new(Repair_Rule)
	self.default_named = base^
	free(base)
	self.costs = integer_map_new_copy(costs)
	self.results = integer_map_new_copy(results)
	self.rule = Rule{
		add_cost    = repair_rule_rule_add_cost,
		get_name    = repair_rule_rule_get_name,
		get_results = repair_rule_rule_get_results,
	}
	return self
}

repair_rule_new_simple :: proc(name: string, data: ^Game_Data) -> ^Repair_Rule {
	costs := integer_map_new()
	results := integer_map_new()
	self := repair_rule_new(name, data, costs, results)
	free(costs)
	free(results)
	return self
}

repair_rule_get_costs :: proc(self: ^Repair_Rule) -> Integer_Map {
	result := Integer_Map{}
	result.map_values = make(map[rawptr]i32)
	if self.costs != nil {
		for k, v in self.costs.map_values {
			result.map_values[k] = v
		}
	}
	return result
}

repair_rule_get_results :: proc(self: ^Repair_Rule) -> ^Integer_Map {
	return self.results
}

repair_rule_add_cost :: proc(self: ^Repair_Rule, resource: ^Resource, quantity: i32) {
	integer_map_put(self.costs, rawptr(resource), quantity)
}

repair_rule_to_string :: proc(self: ^Repair_Rule) -> string {
	return fmt.aprintf("RepairRule:%s", default_named_get_name(&self.default_named))
}

// Vtable bridges that recover the outer Repair_Rule from its embedded
// Rule field, mirroring Java's `extends Rule` polymorphism.
repair_rule_rule_add_cost :: proc(self: ^Rule, resource: ^Resource, quantity: i32) {
	rr := cast(^Repair_Rule)(uintptr(self) - offset_of(Repair_Rule, rule))
	repair_rule_add_cost(rr, resource, quantity)
}

repair_rule_rule_get_name :: proc(self: ^Rule) -> string {
	rr := cast(^Repair_Rule)(uintptr(self) - offset_of(Repair_Rule, rule))
	return default_named_get_name(&rr.default_named)
}

repair_rule_rule_get_results :: proc(self: ^Rule) -> ^Integer_Map {
	rr := cast(^Repair_Rule)(uintptr(self) - offset_of(Repair_Rule, rule))
	return rr.results
}

// Java owners covered by this file:
//   - games.strategy.engine.data.RepairRule

