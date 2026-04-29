package game

Attachment_List_Option :: struct {
	name:  string,
	value: string,
	count: string,
}

Attachment_List_Attachment :: struct {
	foreach:    string,
	name:       string,
	attach_to:  string,
	java_class: string,
	type:       string,
	options:    [dynamic]^Attachment_List_Option,
}

Attachment_List :: struct {
	attachments: [dynamic]^Attachment_List_Attachment,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.AttachmentList

