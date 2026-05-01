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

change_attachment_change_get_attachment_name :: proc(self: ^Change_Attachment_Change) -> string {
	return self.attachment_name
}

change_attachment_change_new :: proc(
	attachable: ^Attachable,
	attachment_name: string,
	new_value: rawptr,
	old_value: rawptr,
	property: string,
	get_raw_property: bool,
) -> ^Change_Attachment_Change {
	self := new(Change_Attachment_Change)
	// Optional.ofNullable(attachmentName).map(name -> name.replaceAll("ttatch", "ttach")).orElse(null)
	if len(attachment_name) > 0 {
		self.attachment_name = change_attachment_change_lambda_new_0(attachment_name)
	} else {
		self.attachment_name = ""
	}
	self.attached_to = attachable
	self.new_value = new_value
	self.old_value = old_value
	self.property = property
	self.clear_first = get_raw_property
	return self
}

