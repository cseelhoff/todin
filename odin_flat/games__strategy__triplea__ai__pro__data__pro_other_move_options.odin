package game

Pro_Other_Move_Options :: struct {
	max_move_map: map[^Territory]^Pro_Territory,
	move_maps:    map[^Territory][dynamic]^Pro_Territory,
}

pro_other_move_options_new :: proc() -> ^Pro_Other_Move_Options {
	self := new(Pro_Other_Move_Options)
	self.max_move_map = make(map[^Territory]^Pro_Territory)
	self.move_maps = make(map[^Territory][dynamic]^Pro_Territory)
	return self
}

pro_other_move_options_get_max :: proc(self: ^Pro_Other_Move_Options, t: ^Territory) -> ^Pro_Territory {
	return self.max_move_map[t]
}

pro_other_move_options_get_all :: proc(self: ^Pro_Other_Move_Options, t: ^Territory) -> [dynamic]^Pro_Territory {
	if t in self.move_maps {
		return self.move_maps[t]
	}
	return make([dynamic]^Pro_Territory)
}

pro_other_move_options_lambda_new_move_maps_0 :: proc(key: ^Territory) -> [dynamic]^Pro_Territory {
	return make([dynamic]^Pro_Territory)
}

pro_other_move_options_new_move_maps :: proc(move_map_list: [dynamic]map[^Territory]^Pro_Territory) -> map[^Territory][dynamic]^Pro_Territory {
	result := make(map[^Territory][dynamic]^Pro_Territory)
	for move_map in move_map_list {
		for t, pro_terr in move_map {
			if !(t in result) {
				result[t] = pro_other_move_options_lambda_new_move_maps_0(t)
			}
			list := result[t]
			append(&list, pro_terr)
			result[t] = list
		}
	}
	return result
}

