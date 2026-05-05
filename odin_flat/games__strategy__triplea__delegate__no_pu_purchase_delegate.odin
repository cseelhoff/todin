package game

No_Pu_Purchase_Delegate :: struct {
	using purchase_delegate: Purchase_Delegate,
	is_pacific: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.NoPuPurchaseDelegate


// Stub: not on WW2v5 AI test path.
no_pu_purchase_delegate_new :: proc() -> ^No_Pu_Purchase_Delegate {
	return new(No_Pu_Purchase_Delegate)
}
