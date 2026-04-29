package game

Attachment_List_Attachment :: struct {
	foreach:    string,
	name:       string,
	attach_to:  string,
	java_class: string,
	type:       string,
	options:    [dynamic]^Attachment_List_Attachment_Option,
}

