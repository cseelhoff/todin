package game

Repair_Rules :: struct {
	using game_data_component: Game_Data_Component,
	repair_rules:              map[string]^Repair_Rule,
}

repair_rules_new :: proc(data: ^Game_Data) -> ^Repair_Rules {
	self := new(Repair_Rules)
	self.game_data_component = make_Game_Data_Component(data)
	self.repair_rules = make(map[string]^Repair_Rule)
	return self
}

repair_rules_get_repair_rule :: proc(self: ^Repair_Rules, name: string) -> ^Repair_Rule {
	return self.repair_rules[name]
}

repair_rules_add_repair_rule :: proc(self: ^Repair_Rules, pf: ^Repair_Rule) {
	self.repair_rules[default_named_get_name(&pf.default_named)] = pf
}

