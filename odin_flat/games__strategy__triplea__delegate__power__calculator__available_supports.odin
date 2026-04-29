package game

// Tracks the available support that a collection of units can give to other units.
// Once a support is used, it will no longer be available for other units to use.
Available_Supports :: struct {
	support_rules:        map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units:        map[^Unit_Support_Attachment]^Available_Supports_Support_Details,
	units_giving_support: map[^Unit]^Integer_Map,
}

