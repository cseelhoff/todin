package game

Pro_Dummy_Delegate_Bridge :: struct {
	random_source: Plain_Random_Source,
	display:       ^Headless_Display,
	sound_channel: ^Headless_Sound_Channel,
	player:        ^Game_Player,
	pro_ai:        ^Abstract_Pro_Ai,
	writer:        ^Delegate_History_Writer,
	game_data:     ^Game_Data,
	all_changes:   ^Composite_Change,
}
