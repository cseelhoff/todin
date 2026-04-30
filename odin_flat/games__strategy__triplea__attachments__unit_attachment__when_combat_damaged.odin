package game

Unit_Attachment_When_Combat_Damaged :: struct {
	damage_min: i32,
	damage_max: i32,
	effect:     string,
	unknown:    string,
}

unit_attachment_when_combat_damaged_get_damage_max :: proc(self: ^Unit_Attachment_When_Combat_Damaged) -> i32 {
	return self.damage_max
}

unit_attachment_when_combat_damaged_get_damage_min :: proc(self: ^Unit_Attachment_When_Combat_Damaged) -> i32 {
	return self.damage_min
}

unit_attachment_when_combat_damaged_get_effect :: proc(self: ^Unit_Attachment_When_Combat_Damaged) -> string {
	return self.effect
}

