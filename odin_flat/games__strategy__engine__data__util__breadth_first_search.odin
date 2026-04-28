package game

Breadth_First_Search :: struct {
	map_:                 ^Game_Map,
	visited:              map[^Territory]struct {},
	territories_to_check: [dynamic]^Territory,
	neighbor_condition:   proc(a: ^Territory, b: ^Territory) -> bool,
}

