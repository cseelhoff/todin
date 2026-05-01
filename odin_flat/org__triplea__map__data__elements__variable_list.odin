package game

Variable_List :: struct {
	variables: [dynamic]^Variable_List_Variable,
}

variable_list_get_variables :: proc(self: ^Variable_List) -> [dynamic]^Variable_List_Variable {
	return self.variables
}

