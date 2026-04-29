package game

Abstract_Delegate :: struct {
	using i_delegate:      I_Delegate,
	display_name:          string,
	player:                ^Game_Player,
	bridge:                ^Delegate_Bridge,
	client_network_bridge: ^Client_Network_Bridge,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.AbstractDelegate

