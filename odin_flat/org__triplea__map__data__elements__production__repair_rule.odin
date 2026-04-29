package game

Production_Repair_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Production_Rule_Cost,
	results: [dynamic]^Production_Rule_Result,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Production$RepairRule

