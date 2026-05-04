package game

import "core:strings"

Bid_Purchase_Delegate :: struct {
	using purchase_delegate: Purchase_Delegate,
	bid:     i32,
	spent:   i32,
	has_bid: bool,
}

// games.strategy.triplea.delegate.BidPurchaseDelegate#<init>()
// Java's implicit no-arg constructor: `hasBid = false` is declared inline,
// `bid` and `spent` zero-init by default, and the embedded PurchaseDelegate
// chain is initialized via its own no-arg constructor (needToInitialize=true,
// pendingProductionRules=null).
bid_purchase_delegate_new :: proc() -> ^Bid_Purchase_Delegate {
	self := new(Bid_Purchase_Delegate)
	self.need_to_initialize = true
	self.pending_production_rules = nil
	self.bid = 0
	self.spent = 0
	self.has_bid = false
	return self
}

// games.strategy.triplea.delegate.BidPurchaseDelegate#getBidAmount(GameState, GamePlayer)
// Java: `data.getProperties().get(currentPlayer.getName() + " bid", 0)`.
bid_purchase_delegate_get_bid_amount :: proc(data: ^Game_State, current_player: ^Game_Player) -> i32 {
	player_name := default_named_get_name(&current_player.named_attachable.default_named)
	property_name := strings.concatenate({player_name, " bid"})
	return game_properties_get_int_with_default(game_state_get_properties(data), property_name, 0)
}

// games.strategy.triplea.delegate.BidPurchaseDelegate#doesPlayerHaveBid(GameState, GamePlayer)
// Java: `return getBidAmount(data, player) != 0;`
bid_purchase_delegate_does_player_have_bid :: proc(data: ^Game_State, player: ^Game_Player) -> bool {
	return bid_purchase_delegate_get_bid_amount(data, player) != 0
}

// games.strategy.triplea.delegate.BidPurchaseDelegate#saveState()
// Builds a BidPurchaseExtendedDelegateState wrapping the super state and
// snapshotting bid / hasBid / spent.
bid_purchase_delegate_save_state :: proc(self: ^Bid_Purchase_Delegate) -> ^Bid_Purchase_Extended_Delegate_State {
	state := bid_purchase_extended_delegate_state_new()
	state.super_state = rawptr(purchase_delegate_save_state(&self.purchase_delegate))
	state.bid = self.bid
	state.has_bid = self.has_bid
	state.spent = self.spent
	return state
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
