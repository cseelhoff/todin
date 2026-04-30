package game

Territory_Listener :: struct {
	attachment_changed: proc(self: ^Territory_Listener, territory: ^Territory),
	owner_changed:      proc(self: ^Territory_Listener, territory: ^Territory),
	units_changed:      proc(self: ^Territory_Listener, territory: ^Territory),
}

territory_listener_attachment_changed :: proc(self: ^Territory_Listener, territory: ^Territory) {
	if self != nil && self.attachment_changed != nil {
		self.attachment_changed(self, territory)
	}
}

territory_listener_owner_changed :: proc(self: ^Territory_Listener, territory: ^Territory) {
	if self != nil && self.owner_changed != nil {
		self.owner_changed(self, territory)
	}
}

territory_listener_units_changed :: proc(self: ^Territory_Listener, territory: ^Territory) {
	if self != nil && self.units_changed != nil {
		self.units_changed(self, territory)
	}
}

