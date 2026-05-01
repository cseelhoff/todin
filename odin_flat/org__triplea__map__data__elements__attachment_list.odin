package game

Attachment_List :: struct {
	attachments: [dynamic]^Attachment_List_Attachment,
}

attachment_list_get_attachments :: proc(self: ^Attachment_List) -> [dynamic]^Attachment_List_Attachment {
	return self.attachments
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.AttachmentList

