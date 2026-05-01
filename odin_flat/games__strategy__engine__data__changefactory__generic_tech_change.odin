package game

Generic_Tech_Change :: struct {
	using change:    Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	new_value:       bool,
	old_value:       bool,
	property:        string,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.changefactory.GenericTechChange

generic_tech_change_new :: proc(
	attachment: ^Tech_Attachment,
	new_value: bool,
	property: string,
) -> ^Generic_Tech_Change {
	if attachment == nil {
		panic("null attachment")
	}
	self := new(Generic_Tech_Change)
	self.attached_to = attachment.attached_to
	self.attachment_name = attachment.name
	old_value, _ := tech_attachment_has_generic_tech(attachment, property)
	self.old_value = old_value
	self.new_value = new_value
	self.property = property
	return self
}
