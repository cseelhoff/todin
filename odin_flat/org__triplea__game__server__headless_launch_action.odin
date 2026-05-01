package game

Headless_Launch_Action :: struct {
	headless_game_server: ^Headless_Game_Server,
}

@(private="file")
headless_launch_action_skip_map_resource_loading: bool = false

headless_launch_action_new :: proc(server: ^Headless_Game_Server) -> ^Headless_Launch_Action {
	self := new(Headless_Launch_Action)
	self.headless_game_server = server
	return self
}

headless_launch_action_set_skip_map_resource_loading :: proc(self: ^Headless_Launch_Action, value: bool) {
	headless_launch_action_skip_map_resource_loading = value
}

