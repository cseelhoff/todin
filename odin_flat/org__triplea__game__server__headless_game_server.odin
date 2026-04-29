package game

Headless_Game_Server :: struct {
	available_games:       ^Installed_Maps_Listing,
	game_selector_model:   ^Game_Selector_Model,
	headless_server_setup: ^Headless_Server_Setup,
	game:                  ^Server_Game,
}

