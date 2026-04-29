package game

Territory_Listener :: struct {
	units_changed:      proc(territory: ^Territory),
	owner_changed:      proc(territory: ^Territory),
	attachment_changed: proc(territory: ^Territory),
}

