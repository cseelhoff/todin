package game

// Java: games.strategy.engine.delegate.IDelegate
// Interface — Java declares `String getName()`. Odin mirrors this with a
// `name: string` field; concrete delegates embed `using i_delegate: I_Delegate`
// (transitively via Abstract_Delegate) so polymorphic name lookups through
// `^I_Delegate` resolve to the same storage as `concrete.name`.

I_Delegate :: struct {
	name:                                    string,
	delegate_currently_requires_user_input: proc(self: ^I_Delegate) -> bool,
	end:                                     proc(self: ^I_Delegate),
	get_display_name:                        proc(self: ^I_Delegate) -> string,
	get_name:                                proc(self: ^I_Delegate) -> string,
	get_remote_type:                         proc(self: ^I_Delegate) -> typeid,
	initialize:                              proc(self: ^I_Delegate, name: string, display_name: string),
	load_state:                              proc(self: ^I_Delegate, state: rawptr),
	save_state:                              proc(self: ^I_Delegate) -> rawptr,
	set_delegate_bridge_and_player:          proc(self: ^I_Delegate, bridge: ^I_Delegate_Bridge, client_network_bridge: ^Client_Network_Bridge),
	start:                                   proc(self: ^I_Delegate),
}

// games.strategy.engine.delegate.IDelegate#saveState()
// Java returns `Serializable` — an opaque serializable state object. Odin
// uses `rawptr` so concrete delegates can return a pointer to their own
// state struct, which `load_state` later casts back to the same type.
i_delegate_save_state :: proc(self: ^I_Delegate) -> rawptr {
	return self.save_state(self)
}

// games.strategy.engine.delegate.IDelegate#loadState(Serializable)
// Java parameter `Serializable state` → Odin `state: rawptr`. Concrete
// delegates cast the opaque pointer back to their state struct type.
i_delegate_load_state :: proc(self: ^I_Delegate, state: rawptr) {
	self.load_state(self, state)
}

// games.strategy.engine.delegate.IDelegate#initialize(String, String)
// Uses `name` as the internal unique name and `display_name` for UI display.
i_delegate_initialize :: proc(self: ^I_Delegate, name: string, display_name: string) {
	self.initialize(self, name, display_name)
}

// games.strategy.engine.delegate.IDelegate#getName()
i_delegate_get_name :: proc(self: ^I_Delegate) -> string {
	return self.get_name(self)
}

// games.strategy.engine.delegate.IDelegate#getDisplayName()
i_delegate_get_display_name :: proc(self: ^I_Delegate) -> string {
	return self.get_display_name(self)
}

// games.strategy.engine.delegate.IDelegate#delegateCurrentlyRequiresUserInput()
i_delegate_delegate_currently_requires_user_input :: proc(self: ^I_Delegate) -> bool {
	return self.delegate_currently_requires_user_input(self)
}

// games.strategy.engine.delegate.IDelegate#end()
i_delegate_end :: proc(self: ^I_Delegate) {
	self.end(self)
}

// games.strategy.engine.delegate.IDelegate#start()
// Called before the delegate will run.
i_delegate_start :: proc(self: ^I_Delegate) {
	self.start(self)
}

// games.strategy.engine.delegate.IDelegate#getRemoteType()
// Java returns `Class<? extends IRemote>`; Odin uses `typeid`.
i_delegate_get_remote_type :: proc(self: ^I_Delegate) -> typeid {
	return self.get_remote_type(self)
}

// games.strategy.engine.delegate.IDelegate#setDelegateBridgeAndPlayer(IDelegateBridge, ClientNetworkBridge)
// Called before the delegate will run and before `start` is called. The
// two-argument overload also wires up a `ClientNetworkBridge` for delegates
// that need to communicate over the websocket lobby connection.
i_delegate_set_delegate_bridge_and_player :: proc(self: ^I_Delegate, bridge: ^I_Delegate_Bridge, client_network_bridge: ^Client_Network_Bridge) {
	self.set_delegate_bridge_and_player(self, bridge, client_network_bridge)
}

