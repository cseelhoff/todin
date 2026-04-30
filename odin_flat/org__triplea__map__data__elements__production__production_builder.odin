package game

// Ported from org.triplea.map.data.elements.Production$ProductionBuilder
// (Lombok @Builder for Production).
Production_Production_Builder :: struct {
	production_rules:     [dynamic]^Production_Production_Rule,
	repair_rules:         [dynamic]^Production_Repair_Rule,
	repair_frontiers:     [dynamic]^Production_Repair_Frontier,
	production_frontiers: [dynamic]^Production_Production_Frontier,
	player_productions:   [dynamic]^Production_Player_Production,
	player_repairs:       [dynamic]^Production_Player_Repair,
}

