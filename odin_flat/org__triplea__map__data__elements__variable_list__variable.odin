package game

Variable_List_Variable :: struct {
	name:     string,
	elements: [dynamic]^Variable_List_Variable_Element,
}

variable_list_variable_get_name :: proc(self: ^Variable_List_Variable) -> string {
	return self.name
}

variable_list_variable_get_elements :: proc(self: ^Variable_List_Variable) -> [dynamic]^Variable_List_Variable_Element {
	return self.elements
}

