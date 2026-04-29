package game

Pro_Other_Move_Options :: struct {
	max_move_map: map[^Territory]^Pro_Territory,
	move_maps:    map[^Territory][dynamic]^Pro_Territory,
}

