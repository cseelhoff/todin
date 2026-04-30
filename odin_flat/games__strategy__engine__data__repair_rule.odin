package game

import "core:fmt"

Repair_Rule :: struct {
        using default_named: Default_Named,
	costs:        ^Integer_Map,
	results:      ^Integer_Map,
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

repair_rule_to_string :: proc(self: ^Repair_Rule) -> string {
	return fmt.aprintf("RepairRule:%s", default_named_get_name(&self.default_named))
}

// Java owners covered by this file:
//   - games.strategy.engine.data.RepairRule

