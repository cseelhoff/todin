package game

Generic_Tech_Change :: struct {
	using change:    Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	new_value:       bool,
	old_value:       bool,
	property:        string,
}
