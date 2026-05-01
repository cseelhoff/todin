package game

import "core:fmt"

// Ported from games.strategy.engine.data.gameparser.GameParsingValidation
// Phase A: type only.

Game_Parsing_Validation :: struct {
	data: ^Game_Data,
}

make_Game_Parsing_Validation :: proc(data: ^Game_Data) -> ^Game_Parsing_Validation {
	self := new(Game_Parsing_Validation)
	self.data = data
	return self
}

// Java: static void validateForeachVariables(
//   final List<String> foreachVariables,
//   final Map<String, List<String>> variables,
//   final String foreach) throws GameParseException
// Returns nil on success or a heap-allocated Game_Parse_Exception on failure
// (mirroring Java's checked-exception throw).
game_parsing_validation_validate_foreach_variables :: proc(
	foreach_variables: [dynamic]string,
	variables: map[string][dynamic]string,
	foreach: string,
) -> ^Game_Parse_Exception {
	if len(foreach_variables) == 0 {
		return nil
	}
	// !variables.keySet().containsAll(foreachVariables)
	for v in foreach_variables {
		if _, ok := variables[v]; !ok {
			return make_Game_Parse_Exception(
				fmt.aprintf("Attachment has invalid variables in foreach: %s", foreach),
			)
		}
	}
	length := len(variables[foreach_variables[0]])
	for foreach_variable in foreach_variables {
		foreach_value := variables[foreach_variable]
		if length != len(foreach_value) {
			return make_Game_Parse_Exception(
				fmt.aprintf(
					"Attachment foreach variables must have same number of elements: %s",
					foreach,
				),
			)
		}
	}
	return nil
}

