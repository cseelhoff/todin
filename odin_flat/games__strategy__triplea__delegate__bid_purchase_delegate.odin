package game

Bid_Purchase_Delegate :: struct {
	using purchase_delegate: Purchase_Delegate,
	bid:     i32,
	spent:   i32,
	has_bid: bool,
}
