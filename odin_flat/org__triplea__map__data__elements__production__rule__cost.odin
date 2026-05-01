package game

Production_Rule_Cost :: struct {
	resource: string,
	quantity: i32,
}

production_rule_cost_get_quantity :: proc(self: ^Production_Rule_Cost) -> i32 {
	return self.quantity
}

production_rule_cost_get_resource :: proc(self: ^Production_Rule_Cost) -> string {
	return self.resource
}

