package game

// Java: games.strategy.engine.delegate.IDelegate
// Interface — Java declares `String getName()`. Odin mirrors this with a
// `name: string` field; concrete delegates embed `using i_delegate: I_Delegate`
// (transitively via Abstract_Delegate) so polymorphic name lookups through
// `^I_Delegate` resolve to the same storage as `concrete.name`.

I_Delegate :: struct {
	name:                                    string,
	// games.strategy.engine.delegate.AutoSave annotation (Java reflective
	// metadata). Concrete delegate constructors set this when the Java
	// class declares `@AutoSave(...)`; nil means the annotation is absent.
	auto_save_annotation:                    ^Auto_Save,
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
// games.strategy.engine.delegate.IDelegate#saveState()
// Java returns `Serializable` — an opaque serializable state object. Odin
// uses `rawptr` so concrete delegates can return a pointer to their own
// state struct, which `load_state` later casts back to the same type.
i_delegate_save_state :: proc(self: ^I_Delegate) -> rawptr {
	if self.save_state != nil {
		return self.save_state(self)
	}
	return nil
}

// games.strategy.engine.delegate.IDelegate#loadState(Serializable)
// Java parameter `Serializable state` → Odin `state: rawptr`. Concrete
// delegates cast the opaque pointer back to their state struct type.
i_delegate_load_state :: proc(self: ^I_Delegate, state: rawptr) {
	if self.load_state != nil {
		self.load_state(self, state)
	}
}

// games.strategy.engine.delegate.IDelegate#initialize(String, String)
// Uses `name` as the internal unique name and `display_name` for UI display.
// Default behavior mirrors AbstractDelegate.initialize: write `name` (on
// the embedded I_Delegate slot) and `display_name` (on the embedded
// Abstract_Delegate slot). Concrete delegates may install a proc-field
// override if they need to customize.
i_delegate_initialize :: proc(self: ^I_Delegate, name: string, display_name: string) {
	if self.initialize != nil {
		self.initialize(self, name, display_name)
		return
	}
	self.name = name
	(cast(^Abstract_Delegate)self).display_name = display_name
}

// games.strategy.engine.delegate.IDelegate#getName()
i_delegate_get_name :: proc(self: ^I_Delegate) -> string {
	if self.get_name != nil {
		return self.get_name(self)
	}
	return self.name
}

// games.strategy.engine.delegate.IDelegate#getDisplayName()
i_delegate_get_display_name :: proc(self: ^I_Delegate) -> string {
	if self.get_display_name != nil {
		return self.get_display_name(self)
	}
	return (cast(^Abstract_Delegate)self).display_name
}

// games.strategy.engine.delegate.IDelegate#delegateCurrentlyRequiresUserInput()
i_delegate_delegate_currently_requires_user_input :: proc(self: ^I_Delegate) -> bool {
	if self.delegate_currently_requires_user_input != nil {
		return self.delegate_currently_requires_user_input(self)
	}
	return false
}

// games.strategy.engine.delegate.IDelegate#end()
// Default mirrors AbstractDelegate.end (no-op except for casualty cache
// reset handled by abstract_delegate_end).
i_delegate_end :: proc(self: ^I_Delegate) {
	if self.end != nil {
		self.end(self)
		return
	}
	abstract_delegate_end(cast(^Abstract_Delegate)self)
}

// games.strategy.engine.delegate.IDelegate#start()
// Default mirrors AbstractDelegate.start (CasualtySelector.clearOolCache).
i_delegate_start :: proc(self: ^I_Delegate) {
	if self.start != nil {
		self.start(self)
		return
	}
	abstract_delegate_start(cast(^Abstract_Delegate)self)
}

// games.strategy.engine.delegate.IDelegate#getRemoteType()
// Java returns `Class<? extends IRemote>`; Odin uses `typeid`.
i_delegate_get_remote_type :: proc(self: ^I_Delegate) -> typeid {
	if self.get_remote_type != nil {
		return self.get_remote_type(self)
	}
	return nil
}

// games.strategy.engine.delegate.IDelegate#setDelegateBridgeAndPlayer(IDelegateBridge, ClientNetworkBridge)
// Default mirrors AbstractDelegate.setDelegateBridgeAndPlayer (with
// websocket arg): bridge + player + client_network_bridge.
i_delegate_set_delegate_bridge_and_player :: proc(self: ^I_Delegate, bridge: ^I_Delegate_Bridge, client_network_bridge: ^Client_Network_Bridge) {
	if self.set_delegate_bridge_and_player != nil {
		self.set_delegate_bridge_and_player(self, bridge, client_network_bridge)
		return
	}
	ad := cast(^Abstract_Delegate)self
	ad.bridge = bridge
	ad.player = i_delegate_bridge_get_game_player(bridge)
	ad.client_network_bridge = client_network_bridge
}

