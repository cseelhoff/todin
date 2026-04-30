package game

Pro_My_Move_Options :: struct {
	territory_map:      map[^Territory]^Pro_Territory,
	unit_move_map:      map[^Unit]map[^Territory]struct{},
	transport_move_map: map[^Unit]map[^Territory]struct{},
	bombard_map:        map[^Unit]map[^Territory]struct{},
	transport_list:     [dynamic]^Pro_Transport,
	bomber_move_map:    map[^Unit]map[^Territory]struct{},
}

pro_my_move_options_new :: proc() -> ^Pro_My_Move_Options {
	self := new(Pro_My_Move_Options)
	self.territory_map = make(map[^Territory]^Pro_Territory)
	self.unit_move_map = make(map[^Unit]map[^Territory]struct{})
	self.transport_move_map = make(map[^Unit]map[^Territory]struct{})
	self.bombard_map = make(map[^Unit]map[^Territory]struct{})
	self.transport_list = make([dynamic]^Pro_Transport)
	self.bomber_move_map = make(map[^Unit]map[^Territory]struct{})
	return self
}

pro_my_move_options_get_territory_map :: proc(self: ^Pro_My_Move_Options) -> map[^Territory]^Pro_Territory {
	return self.territory_map
}

pro_my_move_options_get_unit_move_map :: proc(self: ^Pro_My_Move_Options) -> map[^Unit]map[^Territory]struct{} {
	return self.unit_move_map
}

pro_my_move_options_get_transport_move_map :: proc(self: ^Pro_My_Move_Options) -> map[^Unit]map[^Territory]struct{} {
	return self.transport_move_map
}

pro_my_move_options_get_bombard_map :: proc(self: ^Pro_My_Move_Options) -> map[^Unit]map[^Territory]struct{} {
	return self.bombard_map
}

pro_my_move_options_get_transport_list :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Pro_Transport {
	return self.transport_list
}

pro_my_move_options_get_bomber_move_map :: proc(self: ^Pro_My_Move_Options) -> map[^Unit]map[^Territory]struct{} {
	return self.bomber_move_map
}

