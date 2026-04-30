package game

Production_Rule_List :: struct {
	using game_data_component: Game_Data_Component,
	production_rules: map[string]^Production_Rule,
}

production_rule_list_add_production_rule :: proc(self: ^Production_Rule_List, pf: ^Production_Rule) {
	self.production_rules[default_named_get_name(&pf.default_named)] = pf
}

production_rule_list_get_production_rules :: proc(self: ^Production_Rule_List) -> [dynamic]^Production_Rule {
	result := make([dynamic]^Production_Rule, 0, len(self.production_rules))
	for _, rule in self.production_rules {
		append(&result, rule)
	}
	return result
}

production_rule_list_get_production_rule :: proc(self: ^Production_Rule_List, name: string) -> ^Production_Rule {
	return self.production_rules[name]
}

