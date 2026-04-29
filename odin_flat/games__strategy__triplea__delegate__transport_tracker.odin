package game

Transport_Tracker :: struct {}

Allied_Air_Transport_Change :: struct {
	change:     ^Composite_Change,
	allied_air: [dynamic]^Unit,
}

