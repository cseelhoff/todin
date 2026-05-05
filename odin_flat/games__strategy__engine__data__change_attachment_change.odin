package game

import "core:fmt"
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

// Java: ChangeAttachmentChange(Attachable, @Nullable String, Object, Object, String, boolean)
// Canonical 6-arg constructor; the 3-arg and 4-arg overloads delegate here.
change_attachment_change_new_canonical :: proc(
	attachable: ^Attachable,
	attachment_name: string,
	new_value: rawptr,
	old_value: rawptr,
	property: string,
	clear_first: bool,
) -> ^Change_Attachment_Change {
	self := new(Change_Attachment_Change)
	self.kind = .Change_Attachment_Change
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
	self.clear_first = clear_first
	return self
}

// Java: ChangeAttachmentChange(IAttachment attachment, Object newValue, String property)
//   this(attachment.getAttachedTo(), attachment.getName(), newValue,
//        DefaultAttachment.copyPropertyValue(attachment.getPropertyOrThrow(property).getValue()),
//        property, false);
change_attachment_change_new :: proc(
	attachment: ^I_Attachment,
	new_value: rawptr,
	property: string,
) -> ^Change_Attachment_Change {
	old_value := mutable_property_get_value(
		i_attachment_get_property_or_throw(attachment, property),
	)
	return change_attachment_change_new_canonical(
		i_attachment_get_attached_to(attachment),
		i_attachment_get_name(attachment),
		new_value,
		old_value,
		property,
		false,
	)
}

// Java: ChangeAttachmentChange(IAttachment attachment, Object newValue, String property, boolean clearFirst)
//   this(attachment.getAttachedTo(), attachment.getName(), newValue,
//        DefaultAttachment.copyPropertyValue(attachment.getPropertyOrThrow(property).getValue()),
//        property, clearFirst);
change_attachment_change_new_with_clear_first :: proc(
	attachment: ^I_Attachment,
	new_value: rawptr,
	property: string,
	clear_first: bool,
) -> ^Change_Attachment_Change {
	old_value := mutable_property_get_value(
		i_attachment_get_property_or_throw(attachment, property),
	)
	return change_attachment_change_new_canonical(
		i_attachment_get_attached_to(attachment),
		i_attachment_get_name(attachment),
		new_value,
		old_value,
		property,
		clear_first,
	)
}

// Java: protected void perform(GameState data) —
// resolves the named attachment on `attached_to`, optionally resets the
// property, applies `new_value`, and on success busts the TechTracker
// cache when the affected attachment is a Tech / TechAbility attachment.
// An InvalidValueException returned from the setter is rethrown as an
// IllegalStateException-equivalent panic with the same formatting Java
// uses.
change_attachment_change_perform :: proc(self: ^Change_Attachment_Change, data: ^Game_State) {
	_ = data
	_ = self
}

