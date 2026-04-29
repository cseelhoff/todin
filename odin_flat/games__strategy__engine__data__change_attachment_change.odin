package game

import "core:strings"

Change_Attachment_Change :: struct {
	using change: Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	new_value:       rawptr,
	old_value:       rawptr,
	property:        string,
	clear_first:     bool,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.ChangeAttachmentChange

// Synthetic constructor lambda: `name -> name.replaceAll("ttatch", "ttach")`
// from `ChangeAttachmentChange(Attachable, String, Object, Object, String, boolean)`.
change_attachment_change_lambda_new_0 :: proc(property: string) -> string {
	result, _ := strings.replace_all(property, "ttatch", "ttach")
	return result
}

