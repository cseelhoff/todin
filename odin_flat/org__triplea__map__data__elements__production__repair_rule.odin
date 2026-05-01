package game

Production_Repair_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Production_Rule_Cost,
	results: [dynamic]^Production_Rule_Result,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Production$RepairRule

production_repair_rule_get_name :: proc(self: ^Production_Repair_Rule) -> string {
	return self.name
}

production_repair_rule_get_costs :: proc(self: ^Production_Repair_Rule) -> [dynamic]^Production_Rule_Cost {
	return self.costs
}

production_repair_rule_get_rule_results :: proc(self: ^Production_Repair_Rule) -> [dynamic]^Production_Rule_Result {
	return self.results
}

