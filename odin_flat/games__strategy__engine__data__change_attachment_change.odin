package game

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

