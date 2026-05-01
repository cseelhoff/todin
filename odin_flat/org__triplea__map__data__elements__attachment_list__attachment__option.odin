package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.AttachmentList$Attachment$Option

Attachment_List_Attachment_Option :: struct {
	name:  string,
	value: string,
	count: string,
}

attachment_list_attachment_option_get_name :: proc(self: ^Attachment_List_Attachment_Option) -> string {
	return self.name
}

attachment_list_attachment_option_get_value :: proc(self: ^Attachment_List_Attachment_Option) -> string {
	return self.value
}

attachment_list_attachment_option_get_count :: proc(self: ^Attachment_List_Attachment_Option) -> string {
	return self.count
}

