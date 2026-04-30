package game

Territory_Listener :: struct {
	attachment_changed: proc(self: ^Territory_Listener, territory: ^Territory),
}

territory_listener_attachment_changed :: proc(self: ^Territory_Listener, territory: ^Territory) {
	if self != nil && self.attachment_changed != nil {
		self.attachment_changed(self, territory)
	}
}

