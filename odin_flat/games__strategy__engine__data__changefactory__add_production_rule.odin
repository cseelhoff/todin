package game

Add_Production_Rule :: struct {
	using change: Change,
	rule:         ^Production_Rule,
	frontier:     ^Production_Frontier,
}

add_production_rule_new :: proc(rule: ^Production_Rule, frontier: ^Production_Frontier) -> ^Add_Production_Rule {
	assert(rule != nil)
	assert(frontier != nil)
	self := new(Add_Production_Rule)
	self.kind = .Add_Production_Rule
	self.rule = rule
	self.frontier = frontier
	self.perform = add_production_rule_v_perform
	return self
}

add_production_rule_v_perform :: proc(self: ^Change, data: ^Game_State) {
	add_production_rule_perform(cast(^Add_Production_Rule)self, data)
}

add_production_rule_perform :: proc(self: ^Add_Production_Rule, data: ^Game_State) {
	production_frontier_add_rule(self.frontier, self.rule)
}

