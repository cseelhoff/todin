package game

I_Remote_Messenger :: struct {}

// Dispatch helpers. The stored pointer always points to a Remote_Messenger
// (the only concrete implementation). Cast and forward.
i_remote_messenger_get_remote :: proc(self: ^I_Remote_Messenger, name: ^Remote_Name) -> ^I_Remote {
	return remote_messenger_get_remote_default(cast(^Remote_Messenger)self, name)
}

i_remote_messenger_register_remote :: proc(self: ^I_Remote_Messenger, implementor: rawptr, name: ^Remote_Name) {
	remote_messenger_register_remote(cast(^Remote_Messenger)self, implementor, name)
}

// Java: void unregisterRemote(RemoteName name) — removes the implementor from
// the unified messenger. The AI snapshot harness never reaches the cleanup
// path, but we route through the concrete unregister proc for parity.
i_remote_messenger_unregister_remote :: proc(self: ^I_Remote_Messenger, name: ^Remote_Name) {
	remote_messenger_unregister_remote(cast(^Remote_Messenger)self, name)
}


