package game

Production_Production_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Production_Rule_Cost,
	results: [dynamic]^Production_Rule_Result,
}

production_production_rule_get_name :: proc(self: ^Production_Production_Rule) -> string {
	return self.name
}

production_production_rule_get_costs :: proc(self: ^Production_Production_Rule) -> [dynamic]^Production_Rule_Cost {
	return self.costs
}

production_production_rule_get_rule_results :: proc(self: ^Production_Production_Rule) -> [dynamic]^Production_Rule_Result {
	return self.results
}

