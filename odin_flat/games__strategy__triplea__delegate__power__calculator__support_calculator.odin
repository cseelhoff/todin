package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.SupportCalculator

Support_Calculator :: struct {
	support_rules: map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units: map[^Unit_Support_Attachment]^Integer_Map_Unit,
	side:          Battle_State_Side,
	allies:        bool,
}
