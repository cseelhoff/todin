package game

Map_Selection_Listener :: struct {
	territory_selected: proc(territory: ^Territory, md: ^Mouse_Details),
	mouse_entered:      proc(territory: ^Territory),
	mouse_moved:        proc(territory: ^Territory, md: ^Mouse_Details),
}

