package game

Dummy_Delegate_Bridge :: struct {
	random_source:    ^Plain_Random_Source,
	display:          ^Headless_Display,
	sound_channel:    ^Headless_Sound_Channel,
	attacking_player: ^Dummy_Player,
	defending_player: ^Dummy_Player,
	attacker:         ^Game_Player,
	writer:           ^Delegate_History_Writer,
	all_changes:      ^Composite_Change,
	game_data:        ^Game_Data,
	battle:           ^Must_Fight_Battle,
	tuv_calculator:   ^Tuv_Costs_Calculator,
}
