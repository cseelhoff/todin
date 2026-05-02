package game

Named_Attachable :: struct {
	using default_named: Default_Named,
	attachments: map[string]^I_Attachment,
}

named_attachable_new :: proc(name: string, data: ^Game_Data) -> ^Named_Attachable {
	self := new(Named_Attachable)
	base := default_named_new(name, data)
	self.default_named = base^
	free(base)
	self.attachments = make(map[string]^I_Attachment)
	return self
}

named_attachable_get_attachment :: proc(self: ^Named_Attachable, key: string) -> ^I_Attachment {
	return self.attachments[key]
}

named_attachable_get_attachments :: proc(self: ^Named_Attachable) -> map[string]^I_Attachment {
	return self.attachments
}

named_attachable_add_attachment :: proc(self: ^Named_Attachable, key: string, value: ^I_Attachment) {
	self.attachments[key] = value
}

named_attachable_remove_attachment :: proc(self: ^Named_Attachable, key_string: string) {
	delete_key(&self.attachments, key_string)
}
