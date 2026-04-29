package game

I_Abstract_Place_Delegate :: struct {
	using i_abstract_move_delegate: I_Abstract_Move_Delegate,
}

I_Abstract_Place_Delegate_Bid_Mode :: enum {
	BID,
	NOT_BID,
}
