package game

Production_Rule_Result :: struct {
	resource_or_unit: string,
	quantity:         i32,
}

production_rule_result_get_quantity :: proc(self: ^Production_Rule_Result) -> i32 {
	return self.quantity
}

production_rule_result_get_resource_or_unit :: proc(self: ^Production_Rule_Result) -> string {
	return self.resource_or_unit
}

