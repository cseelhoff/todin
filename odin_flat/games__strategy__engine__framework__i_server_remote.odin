package game

// Java owner: games.strategy.engine.framework.IServerRemote
//
// Java declares IServerRemote as a pure-callback interface (extends
// IRemote) with no fields. Each abstract method is modeled as a
// proc-typed field; concrete implementers install their function at
// construction time. Dispatch procs (`i_server_remote_*`) are the
// public entry points.

I_Server_Remote :: struct {
	get_saved_game: proc(self: ^I_Server_Remote) -> []u8,
}

// games.strategy.engine.framework.IServerRemote#getSavedGame()
i_server_remote_get_saved_game :: proc(self: ^I_Server_Remote) -> []u8 {
	return self.get_saved_game(self)
}

