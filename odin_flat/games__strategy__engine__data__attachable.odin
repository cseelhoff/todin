package game

Attachable :: struct {
	add_attachment: proc(self: ^Attachable, key: string, value: ^I_Attachment),
	get_attachment: proc(self: ^Attachable, key: string) -> ^I_Attachment,
	get_attachments: proc(self: ^Attachable) -> map[string]^I_Attachment,
}

// games.strategy.engine.data.Attachable#addAttachment(java.lang.String,games.strategy.engine.data.IAttachment)
attachable_add_attachment :: proc(self: ^Attachable, key: string, value: ^I_Attachment) {
	self.add_attachment(self, key, value)
}

// games.strategy.engine.data.Attachable#getAttachment(java.lang.String)
attachable_get_attachment :: proc(self: ^Attachable, key: string) -> ^I_Attachment {
	return self.get_attachment(self, key)
}

// games.strategy.engine.data.Attachable#getAttachments()
attachable_get_attachments :: proc(self: ^Attachable) -> map[string]^I_Attachment {
	return self.get_attachments(self)
}
