package game

Remove_Production_Rule :: struct {
	using change: Change,
	rule:         ^Production_Rule,
	frontier:     ^Production_Frontier,
}

remove_production_rule_new :: proc(rule: ^Production_Rule, frontier: ^Production_Frontier) -> ^Remove_Production_Rule {
	assert(rule != nil)
	assert(frontier != nil)
	self := new(Remove_Production_Rule)
	self.kind = .Remove_Production_Rule
	self.rule = rule
	self.frontier = frontier
	return self
}

