package game

Unit_Type_Comparator :: struct {}

unit_type_comparator_new :: proc() -> ^Unit_Type_Comparator {
	self := new(Unit_Type_Comparator)
	return self
}

