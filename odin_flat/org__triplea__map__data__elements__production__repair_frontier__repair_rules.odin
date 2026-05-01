package game

Production_Repair_Frontier_Repair_Rules :: struct {
	name: string,
}

production_repair_frontier_repair_rules_get_name :: proc(self: ^Production_Repair_Frontier_Repair_Rules) -> string {
	return self.name
}

