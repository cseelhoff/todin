package game

Attachment_Property_Reset :: struct {
	using change: Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	old_value:       rawptr,
	property:        string,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.AttachmentPropertyReset

attachment_property_reset_new :: proc(attachment: ^I_Attachment, property: string) -> ^Attachment_Property_Reset {
	if attachment == nil {
		panic("null attachment")
	}
	self := new(Attachment_Property_Reset)
	self.kind = .Attachment_Property_Reset
	self.attached_to = i_attachment_get_attached_to(attachment)
	self.attachment_name = i_attachment_get_name(attachment)
	self.old_value = mutable_property_get_value(i_attachment_get_property_or_throw(attachment, property))
	self.property = property
	return self
}

