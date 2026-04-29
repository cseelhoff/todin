package game

Support_Rule_Sort_Support_Rule_Sort_Builder :: struct {
	side:     Battle_State_Side,
	friendly: bool,
	roll:     proc(u: ^Unit_Support_Attachment) -> bool,
	strength: proc(u: ^Unit_Support_Attachment) -> bool,
}
