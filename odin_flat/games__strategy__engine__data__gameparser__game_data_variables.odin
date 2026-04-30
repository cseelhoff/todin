package game

import "core:strings"

Game_Data_Variables :: struct {
	variables: map[string][dynamic]string,
}

make_Game_Data_Variables :: proc(variables: map[string][dynamic]string) -> Game_Data_Variables {
	return Game_Data_Variables{variables = variables}
}

game_data_variables_replace_foreach_variables :: proc(s: string, vars: map[string]string) -> string {
	result := s
	allocated := false
	for key, value in vars {
		replacement := value
		new_result, was_alloc := strings.replace_all(result, key, replacement)
		if allocated {
			delete(result)
		}
		result = new_result
		allocated = was_alloc || allocated
	}
	if !allocated {
		return strings.clone(result)
	}
	return result
}

@(private = "file")
find_nested_variables :: proc(
	value: string,
	variables: ^map[string][dynamic]string,
	out: ^[dynamic]string,
) {
	nested, ok := variables[value]
	if !ok {
		append(out, value)
		return
	}
	for s in nested {
		find_nested_variables(s, variables, out)
	}
}

game_data_variables_parse :: proc(variable_list: ^Variable_List) -> ^Game_Data_Variables {
	result := new(Game_Data_Variables)
	if variable_list == nil {
		return result
	}
	for current in variable_list.variables {
		name := strings.concatenate({"$", current.name, "$"})
		values: [dynamic]string
		for element in current.elements {
			find_nested_variables(element.name, &result.variables, &values)
		}
		result.variables[name] = values
	}
	return result
}

game_data_variables_replace_variables :: proc(self: ^Game_Data_Variables, s: string) -> string {
	result := s
	allocated := false
	for key, value in self.variables {
		if strings.contains(result, key) {
			joined := strings.join(value[:], ":")
			new_result, _ := strings.replace_all(result, key, joined)
			delete(joined)
			if allocated {
				delete(result)
			}
			result = new_result
			allocated = true
		}
	}
	if !allocated {
		return strings.clone(result)
	}
	return result
}
game_data_variables_create_foreach_variables_map :: proc(
	foreach_variables: []string,
	current_index: int,
	variables: ^map[string][dynamic]string,
) -> map[string]string {
	foreach_map := make(map[string]string)
	for foreach_variable in foreach_variables {
		foreach_value := variables[foreach_variable]
		stripped, _ := strings.replace_all(foreach_variable, "$", "")
		key := strings.concatenate({"@", stripped, "@"})
		delete(stripped)
		foreach_map[key] = foreach_value[current_index]
	}
	return foreach_map
}