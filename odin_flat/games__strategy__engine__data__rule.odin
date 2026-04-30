package game

// Java owner: games.strategy.engine.data.Rule
//
// Pure-interface superclass for ProductionRule and RepairRule;
// methods modeled as proc-typed fields, with `rule_*` dispatch
// procs as public entry points.

Rule :: struct {
	add_cost: proc(self: ^Rule, resource: ^Resource, quantity: i32),
}

// games.strategy.engine.data.Rule#addCost(Resource, int)
rule_add_cost :: proc(self: ^Rule, resource: ^Resource, quantity: i32) {
	self.add_cost(self, resource, quantity)
}

