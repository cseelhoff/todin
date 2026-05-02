package game

Bid_Purchase_Delegate :: struct {
	using purchase_delegate: Purchase_Delegate,
	bid:     i32,
	spent:   i32,
	has_bid: bool,
}

// games.strategy.triplea.delegate.BidPurchaseDelegate#loadState(java.io.Serializable)
// Casts the opaque Serializable to BidPurchaseExtendedDelegateState, replays
// the embedded super state via PurchaseDelegate.loadState, and copies bid /
// spent / hasBid back onto the delegate.
bid_purchase_delegate_load_state :: proc(self: ^Bid_Purchase_Delegate, state: rawptr) {
	s := cast(^Bid_Purchase_Extended_Delegate_State)state
	purchase_delegate_load_state(&self.purchase_delegate, s.super_state)
	self.bid = s.bid
	self.spent = s.spent
	self.has_bid = s.has_bid
}
