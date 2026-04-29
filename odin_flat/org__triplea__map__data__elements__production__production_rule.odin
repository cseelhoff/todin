package game

Production_Rule :: struct {
	name:    string,
	costs:   [dynamic]^Production_Rule_Cost,
	results: [dynamic]^Production_Rule_Result,
}

