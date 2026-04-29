package game

Game_Map :: struct {
	using parent:     Game_Data_Component,
	territories:      [dynamic]^Territory,
	connections:      map[^Territory]map[^Territory]struct{},
	territory_lookup: map[string]^Territory,
	grid_dimensions:  []i32,
}
