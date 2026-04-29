package game

Headless_Server_Setup :: struct {
	using parent:        I_Remote_Model_Listener,
	using setup_model:   Setup_Model,
	model:               ^Server_Model,
	game_selector_model: ^Game_Selector_Model,
	lock:                ^Object,
	players_updated:     ^Object,
	cancelled:           bool,
}

