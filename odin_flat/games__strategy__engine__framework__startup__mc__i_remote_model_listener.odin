package game

I_Remote_Model_Listener :: struct {
	player_list_changed:    proc(self: ^I_Remote_Model_Listener),
	players_taken_changed:  proc(self: ^I_Remote_Model_Listener),
}

i_remote_model_listener_player_list_changed :: proc(self: ^I_Remote_Model_Listener) {
	if self == nil do return
	if self.player_list_changed != nil {
		self.player_list_changed(self)
	}
}

i_remote_model_listener_players_taken_changed :: proc(self: ^I_Remote_Model_Listener) {
	if self == nil do return
	if self.players_taken_changed != nil {
		self.players_taken_changed(self)
	}
}

