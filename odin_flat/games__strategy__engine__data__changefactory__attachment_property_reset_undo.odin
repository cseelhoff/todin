package game

Attachment_Property_Reset_Undo :: struct {
	using change: Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	new_value:       rawptr,
	property:        string,
}

