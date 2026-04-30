package game

Attachment_List_Attachment_Attachment_Builder :: struct {
	foreach:    string,
	name:       string,
	attach_to:  string,
	java_class: string,
	type:       string,
	options:    [dynamic]^Attachment_List_Attachment_Option,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.AttachmentList$Attachment$AttachmentBuilder

