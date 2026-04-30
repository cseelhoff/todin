package game

// Java owner: games.strategy.engine.data.Rule
//
// Pure-interface superclass for ProductionRule and RepairRule;
// methods modeled as proc-typed fields, with `rule_*` dispatch
// procs as public entry points.

Rule :: struct {
	add_cost:    proc(self: ^Rule, resource: ^Resource, quantity: i32),
	get_name:    proc(self: ^Rule) -> string,
	get_results: proc(self: ^Rule) -> ^Integer_Map,
}

// games.strategy.engine.data.Rule#addCost(Resource, int)
rule_add_cost :: proc(self: ^Rule, resource: ^Resource, quantity: i32) {
	self.add_cost(self, resource, quantity)
}

// games.strategy.engine.data.Rule#getName()
rule_get_name :: proc(self: ^Rule) -> string {
	return self.get_name(self)
}

// games.strategy.engine.data.Rule#getResults()
rule_get_results :: proc(self: ^Rule) -> ^Integer_Map {
	return self.get_results(self)
}


// games.strategy.engine.data.Rule#getResults()
rule_get_results :: proc(self: ^Rule) -> ^Integer_Map {
	return self.get_results(self)
}
