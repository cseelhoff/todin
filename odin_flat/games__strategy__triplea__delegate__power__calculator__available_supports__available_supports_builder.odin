package game

// Lombok @Builder for AvailableSupports. Mirrors AvailableSupports fields.
Available_Supports_Available_Supports_Builder :: struct {
        support_rules:        map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
        support_units:        map[^Unit_Support_Attachment]^Available_Supports_Support_Details,
        units_giving_support: map[^Unit]^Integer_Map,
}

available_supports_available_supports_builder_new :: proc() -> ^Available_Supports_Available_Supports_Builder {
        self := new(Available_Supports_Available_Supports_Builder)
        return self
}

available_supports_available_supports_builder_support_rules :: proc(
        self: ^Available_Supports_Available_Supports_Builder,
        support_rules: map[^Unit_Support_Attachment_Bonus_Type][dynamic]^Unit_Support_Attachment,
) -> ^Available_Supports_Available_Supports_Builder {
        self.support_rules = support_rules
        return self
}

available_supports_available_supports_builder_support_units :: proc(
        self: ^Available_Supports_Available_Supports_Builder,
        support_units: map[^Unit_Support_Attachment]^Available_Supports_Support_Details,
) -> ^Available_Supports_Available_Supports_Builder {
        self.support_units = support_units
        return self
}

// AvailableSupports build()  — Lombok-generated builder finalizer.
available_supports_available_supports_builder_build :: proc(
        self: ^Available_Supports_Available_Supports_Builder,
) -> ^Available_Supports {
        return available_supports_new(self.support_rules, self.support_units)
}
