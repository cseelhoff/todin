package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.SupportRuleSort

Support_Rule_Sort :: struct {
	side:     Battle_State_Side,
	friendly: bool,
	roll:     proc(u: ^Unit_Support_Attachment) -> bool,
	strength: proc(u: ^Unit_Support_Attachment) -> bool,
}

