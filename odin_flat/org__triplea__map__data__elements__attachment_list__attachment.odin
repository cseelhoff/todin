package game

Attachment_List_Attachment :: struct {
	foreach:    string,
	name:       string,
	attach_to:  string,
	java_class: string,
	type:       string,
	options:    [dynamic]^Attachment_List_Attachment_Option,
}

attachment_list_attachment_get_attach_to :: proc(self: ^Attachment_List_Attachment) -> string {
	return self.attach_to
}

attachment_list_attachment_get_foreach :: proc(self: ^Attachment_List_Attachment) -> string {
	return self.foreach
}

attachment_list_attachment_get_java_class :: proc(self: ^Attachment_List_Attachment) -> string {
	return self.java_class
}

attachment_list_attachment_get_name :: proc(self: ^Attachment_List_Attachment) -> string {
	return self.name
}

attachment_list_attachment_get_options :: proc(self: ^Attachment_List_Attachment) -> [dynamic]^Attachment_List_Attachment_Option {
	return self.options
}

attachment_list_attachment_get_type :: proc(self: ^Attachment_List_Attachment) -> string {
	return self.type
}

