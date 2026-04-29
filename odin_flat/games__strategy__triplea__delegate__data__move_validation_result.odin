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

