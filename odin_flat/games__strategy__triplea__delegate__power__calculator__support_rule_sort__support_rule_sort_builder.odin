package game

Support_Rule_Sort_Builder :: struct {
	side:     ^Battle_State_Side,
	friendly: ^bool,
	roll:     proc(^Unit_Support_Attachment) -> bool,
	strength: proc(^Unit_Support_Attachment) -> bool,
}
