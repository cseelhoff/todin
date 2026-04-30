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

