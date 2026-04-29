package game

// Lombok @Builder for AvailableSupports. Mirrors AvailableSupports fields.
Available_Supports_Builder :: struct {
	support_rules:        map[^Bonus_Type][dynamic]^Unit_Support_Attachment,
	support_units:        map[^Unit_Support_Attachment]^Support_Details,
	units_giving_support: map[^Unit]^Integer_Map_Unit,
}

