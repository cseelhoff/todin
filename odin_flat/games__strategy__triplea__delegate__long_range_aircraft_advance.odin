package game

Long_Range_Aircraft_Advance :: struct {
	using tech_advance: Tech_Advance,
}

// Java: LongRangeAircraftAdvance(GameData data) — public constructor that
// forwards to `super(TECH_NAME_LONG_RANGE_AIRCRAFT, data)`.
// TECH_NAME_LONG_RANGE_AIRCRAFT is the "Long Range Aircraft" constant
// inherited from TechAdvance. Mirrors the pattern used by the other concrete
// tech-advance constructors (e.g. heavy_bomber_advance_new): allocates a
// concrete Long_Range_Aircraft_Advance, initializes the embedded
// Named_Attachable's name and the Tech_Advance's GameData pointer, and wires
// the polymorphic `has_tech` dispatch field so callers using the abstract
// `^Tech_Advance` get the correct subtype behavior (Java's virtual-dispatch
// override of `hasTech`).
long_range_aircraft_advance_new :: proc(data: ^Game_Data) -> ^Long_Range_Aircraft_Advance {
	s := new(Long_Range_Aircraft_Advance)
	s.named.base.name = "Long Range Aircraft"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return long_range_aircraft_advance_has_tech(transmute(^Long_Range_Aircraft_Advance)self, ta)
	}
	return s
}

long_range_aircraft_advance_get_property :: proc(self: ^Long_Range_Aircraft_Advance) -> string {
	return "longRangeAir"
}

long_range_aircraft_advance_has_tech :: proc(self: ^Long_Range_Aircraft_Advance, ta: ^Tech_Attachment) -> bool {
	return tech_attachment_get_long_range_air(ta)
}

