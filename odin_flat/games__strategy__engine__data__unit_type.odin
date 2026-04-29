package game

// games.strategy.engine.data.UnitType
//
// A class of units (e.g. "infantry", "fighter"). Carries its UnitAttachment.

Unit_Type :: struct {
	using named_attachable: Named_Attachable,
	unit_attachment:        ^Unit_Attachment,
}
