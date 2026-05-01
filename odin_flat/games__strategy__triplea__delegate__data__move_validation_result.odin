package game

Move_Validation_Result :: struct {
	error:                     string,
	disallowed_unit_warnings:  [dynamic]string,
	disallowed_units_list:     [dynamic][dynamic]^Unit,
	unresolved_unit_warnings:  [dynamic]string,
	unresolved_units_list:     [dynamic][dynamic]^Unit,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.data.MoveValidationResult

move_validation_result_new :: proc() -> ^Move_Validation_Result {
	r := new(Move_Validation_Result)
	r.error = ""
	r.disallowed_unit_warnings = make([dynamic]string)
	r.disallowed_units_list = make([dynamic][dynamic]^Unit)
	r.unresolved_unit_warnings = make([dynamic]string)
	r.unresolved_units_list = make([dynamic][dynamic]^Unit)
	return r
}

@(private="file")
_mvr_index_of :: proc(list: ^[dynamic]string, s: string) -> int {
	for v, i in list {
		if v == s {
			return i
		}
	}
	return -1
}

move_validation_result_add_disallowed_unit :: proc(self: ^Move_Validation_Result, warning: string, unit: ^Unit) {
	index := _mvr_index_of(&self.disallowed_unit_warnings, warning)
	if index == -1 {
		index = len(self.disallowed_unit_warnings)
		append(&self.disallowed_unit_warnings, warning)
		append(&self.disallowed_units_list, make([dynamic]^Unit))
	}
	append(&self.disallowed_units_list[index], unit)
}

move_validation_result_add_unresolved_unit :: proc(self: ^Move_Validation_Result, warning: string, unit: ^Unit) {
	index := _mvr_index_of(&self.unresolved_unit_warnings, warning)
	if index == -1 {
		index = len(self.unresolved_unit_warnings)
		append(&self.unresolved_unit_warnings, warning)
		append(&self.unresolved_units_list, make([dynamic]^Unit))
	}
	append(&self.unresolved_units_list[index], unit)
}

move_validation_result_remove_unresolved_unit :: proc(self: ^Move_Validation_Result, warning: string, unit: ^Unit) {
	index := _mvr_index_of(&self.unresolved_unit_warnings, warning)
	if index == -1 {
		return
	}
	unresolved := &self.unresolved_units_list[index]
	removed := false
	for u, i in unresolved^ {
		if u == unit {
			ordered_remove(unresolved, i)
			removed = true
			break
		}
	}
	if !removed {
		return
	}
	if len(unresolved^) == 0 {
		ordered_remove(&self.unresolved_units_list, index)
		ordered_remove(&self.unresolved_unit_warnings, index)
	}
}

move_validation_result_set_error :: proc(self: ^Move_Validation_Result, error: string) {
	self.error = error
}

move_validation_result_set_error_return_result :: proc(self: ^Move_Validation_Result, error: string) -> ^Move_Validation_Result {
	self.error = error
	return self
}

move_validation_result_get_error :: proc(self: ^Move_Validation_Result) -> string {
	return self.error
}

move_validation_result_has_error :: proc(self: ^Move_Validation_Result) -> bool {
	return len(self.error) > 0
}

move_validation_result_has_disallowed_units :: proc(self: ^Move_Validation_Result) -> bool {
	return len(self.disallowed_unit_warnings) > 0
}

move_validation_result_has_unresolved_units :: proc(self: ^Move_Validation_Result) -> bool {
	return len(self.unresolved_unit_warnings) > 0
}

move_validation_result_get_unresolved_units :: proc(self: ^Move_Validation_Result, warning: string) -> [dynamic]^Unit {
	out := make([dynamic]^Unit)
	index := _mvr_index_of(&self.unresolved_unit_warnings, warning)
	if index == -1 {
		return out
	}
	for u in self.unresolved_units_list[index] {
		append(&out, u)
	}
	return out
}

move_validation_result_get_disallowed_unit_warning :: proc(self: ^Move_Validation_Result, index: int) -> string {
	if index < 0 || index >= len(self.disallowed_unit_warnings) {
		return ""
	}
	return self.disallowed_unit_warnings[index]
}

move_validation_result_get_unresolved_unit_warning :: proc(self: ^Move_Validation_Result, index: int) -> string {
	if index < 0 || index >= len(self.unresolved_unit_warnings) {
		return ""
	}
	return self.unresolved_unit_warnings[index]
}

move_validation_result_get_total_warning_count :: proc(self: ^Move_Validation_Result) -> int {
	return len(self.unresolved_unit_warnings) + len(self.disallowed_unit_warnings)
}

