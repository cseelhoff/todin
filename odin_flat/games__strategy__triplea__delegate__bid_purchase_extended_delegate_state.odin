package game

Bid_Purchase_Extended_Delegate_State :: struct {
	super_state: rawptr,
	bid:         i32,
	spent:       i32,
	has_bid:     bool,
}

bid_purchase_extended_delegate_state_new :: proc() -> ^Bid_Purchase_Extended_Delegate_State {
	self := new(Bid_Purchase_Extended_Delegate_State)
	return self
}

