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

// games.strategy.triplea.delegate.AbstractDelegate#<init>()
// Java's implicit no-arg constructor. All fields default to their zero
// value (empty strings, nil pointers).
abstract_delegate_new :: proc() -> ^Abstract_Delegate {
	self := new(Abstract_Delegate)
	return self
}

// games.strategy.triplea.delegate.AbstractDelegate#initialize(String, String)
// Stores the internal name (in the embedded I_Delegate slot) and the
// human-readable display name.
abstract_delegate_initialize :: proc(self: ^Abstract_Delegate, name: string, display_name: string) {
	self.name = name
	self.display_name = display_name
}

// games.strategy.triplea.delegate.AbstractDelegate#getName()
abstract_delegate_get_name :: proc(self: ^Abstract_Delegate) -> string {
	return self.name
}

// games.strategy.triplea.delegate.AbstractDelegate#getDisplayName()
abstract_delegate_get_display_name :: proc(self: ^Abstract_Delegate) -> string {
	return self.display_name
}

// games.strategy.triplea.delegate.AbstractDelegate#getBridge()
abstract_delegate_get_bridge :: proc(self: ^Abstract_Delegate) -> ^Delegate_Bridge {
	return self.bridge
}

// games.strategy.triplea.delegate.AbstractDelegate#end()
// Java body: "// nothing to do here". Subclasses override.
abstract_delegate_end :: proc(self: ^Abstract_Delegate) {
}

// games.strategy.triplea.delegate.AbstractDelegate#saveState()
// Java returns null; subclasses override to return their own Serializable
// state struct. Odin mirrors this with a nil rawptr.
abstract_delegate_save_state :: proc(self: ^Abstract_Delegate) -> rawptr {
	return nil
}

// games.strategy.triplea.delegate.AbstractDelegate#loadState(Serializable)
// Java body: "// nothing to save". Subclasses override.
abstract_delegate_load_state :: proc(self: ^Abstract_Delegate, state: rawptr) {
}

// games.strategy.triplea.delegate.AbstractDelegate#getData()
// Java body: return bridge.getData();
abstract_delegate_get_data :: proc(self: ^Abstract_Delegate) -> ^Game_Data {
	return i_delegate_bridge_get_data(self.bridge)
}

// games.strategy.triplea.delegate.AbstractDelegate#setDelegateBridgeAndPlayer(IDelegateBridge)
// Java body: bridge = delegateBridge; player = delegateBridge.getGamePlayer();
abstract_delegate_set_delegate_bridge_and_player_no_websocket :: proc(
	self: ^Abstract_Delegate,
	delegate_bridge: ^I_Delegate_Bridge,
) {
	self.bridge = delegate_bridge
	self.player = i_delegate_bridge_get_game_player(delegate_bridge)
}

// games.strategy.triplea.delegate.AbstractDelegate#setDelegateBridgeAndPlayer(IDelegateBridge, ClientNetworkBridge)
// Java body: bridge = delegateBridge; player = delegateBridge.getGamePlayer();
//            this.clientNetworkBridge = clientNetworkBridge;
abstract_delegate_set_delegate_bridge_and_player_with_websocket :: proc(
	self: ^Abstract_Delegate,
	delegate_bridge: ^I_Delegate_Bridge,
	client_network_bridge: ^Client_Network_Bridge,
) {
	self.bridge = delegate_bridge
	self.player = i_delegate_bridge_get_game_player(delegate_bridge)
	self.client_network_bridge = client_network_bridge
}

