package game

Production :: struct {
	production_rules:     [dynamic]^Production_Production_Rule,
	repair_rules:         [dynamic]^Production_Repair_Rule,
	repair_frontiers:     [dynamic]^Production_Repair_Frontier,
	production_frontiers: [dynamic]^Production_Production_Frontier,
	player_productions:   [dynamic]^Production_Player_Production,
	player_repairs:       [dynamic]^Production_Player_Repair,
}

production_get_production_rules :: proc(self: ^Production) -> [dynamic]^Production_Production_Rule {
	return self.production_rules
}

production_get_repair_rules :: proc(self: ^Production) -> [dynamic]^Production_Repair_Rule {
	return self.repair_rules
}

production_get_repair_frontiers :: proc(self: ^Production) -> [dynamic]^Production_Repair_Frontier {
	return self.repair_frontiers
}

production_get_production_frontiers :: proc(self: ^Production) -> [dynamic]^Production_Production_Frontier {
	return self.production_frontiers
}

production_get_player_productions :: proc(self: ^Production) -> [dynamic]^Production_Player_Production {
	return self.player_productions
}

production_get_player_repairs :: proc(self: ^Production) -> [dynamic]^Production_Player_Repair {
	return self.player_repairs
}
