package game

Pro_My_Move_Options :: struct {
	territory_map:      map[^Territory]^Pro_Territory,
	unit_move_map:      map[^Unit]map[^Territory]struct{},
	transport_move_map: map[^Unit]map[^Territory]struct{},
	bombard_map:        map[^Unit]map[^Territory]struct{},
	transport_list:     [dynamic]^Pro_Transport,
	bomber_move_map:    map[^Unit]map[^Territory]struct{},
}

