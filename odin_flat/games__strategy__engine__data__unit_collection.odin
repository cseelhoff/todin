package game

Unit_Collection :: struct {
	using parent: Game_Data_Component,
	units:        [dynamic]^Unit,
	holder:       ^Named_Unit_Holder,
}
