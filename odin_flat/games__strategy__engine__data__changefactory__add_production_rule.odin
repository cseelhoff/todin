package game

Add_Production_Rule :: struct {
	using parent: Change,
	rule:         ^Production_Rule,
	frontier:     ^Production_Frontier,
}

