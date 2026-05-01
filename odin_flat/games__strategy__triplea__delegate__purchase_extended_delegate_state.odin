package game

Purchase_Extended_Delegate_State :: struct {
	super_state:              rawptr,
	need_to_initialize:       bool,
	pending_production_rules: ^Integer_Map,
}

purchase_extended_delegate_state_new :: proc() -> ^Purchase_Extended_Delegate_State {
	s := new(Purchase_Extended_Delegate_State)
	return s
}

