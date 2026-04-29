package game

Bid_Purchase_Delegate :: struct {
	using parent: Purchase_Delegate,
	bid:     i32,
	spent:   i32,
	has_bid: bool,
}
