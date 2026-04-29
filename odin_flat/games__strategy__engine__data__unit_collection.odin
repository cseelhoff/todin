package game

Unit_Collection :: struct {
	using game_data_component: Game_Data_Component,
	units:        [dynamic]^Unit,
	holder:       ^Named_Unit_Holder,
}
