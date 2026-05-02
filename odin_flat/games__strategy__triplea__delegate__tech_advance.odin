package game

Tech_Advance :: struct {
	using named_attachable: Named_Attachable,
	// Discriminator for Java `instanceof GenericTechAdvance` checks. Default
	// false; Generic_Tech_Advance constructors must set this to true. Mirrors
	// the JVM type tag without introducing reflection.
	is_generic: bool,
	// Polymorphic dispatch field for `boolean hasTech(TechAttachment)`.
	// Each predefined subtype's factory wires this to a forwarder that
	// calls the concrete `<subtype>_has_tech`. Default is a "no" so
	// callers always get a sane answer for the abstract base.
	has_tech: proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool,
}

// Public dispatch wrapper. Java: ta.hasTech(attachment).
tech_advance_has_tech :: proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
	if self.has_tech == nil {
		return false
	}
	return self.has_tech(self, ta)
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TechAdvance

// Java: Map<String, Class<? extends TechAdvance>>. Reflection is not part
// of the port surface (see llm-instructions.md "What to do when blocked"),
// so the Class<?> values are replaced with constructor function pointers
// that take a GameData and return an allocated subtype reinterpreted as
// ^Tech_Advance (every predefined subtype is a zero-field extension of
// Tech_Advance, so the in-memory layout matches).
Tech_Advance_Factory :: #type proc(data: ^Game_Data) -> ^Tech_Advance

@(private = "file")
make_super_subs_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Super_Subs_Advance)
	s.named.base.name = "Super subs"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return super_subs_advance_has_tech(transmute(^Super_Subs_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_jet_power_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Jet_Power_Advance)
	s.named.base.name = "Jet Power"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return jet_power_advance_has_tech(transmute(^Jet_Power_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_improved_shipyards_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Improved_Shipyards_Advance)
	s.named.base.name = "Shipyards"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return improved_shipyards_advance_has_tech(transmute(^Improved_Shipyards_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_aa_radar_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Aa_Radar_Advance)
	s.named.base.name = "AA Radar"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return aa_radar_advance_has_tech(transmute(^Aa_Radar_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_long_range_aircraft_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Long_Range_Aircraft_Advance)
	s.named.base.name = "Long Range Aircraft"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return long_range_aircraft_advance_has_tech(transmute(^Long_Range_Aircraft_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_heavy_bomber_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Heavy_Bomber_Advance)
	s.named.base.name = "Heavy Bomber"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return heavy_bomber_advance_has_tech(transmute(^Heavy_Bomber_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_improved_artillery_support_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Improved_Artillery_Support_Advance)
	s.named.base.name = "Improved Artillery Support"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return improved_artillery_support_advance_has_tech(transmute(^Improved_Artillery_Support_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_rockets_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Rockets_Advance)
	s.named.base.name = "Rockets Advance"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return rockets_advance_has_tech(transmute(^Rockets_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_paratroopers_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Paratroopers_Advance)
	s.named.base.name = "Paratroopers"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return paratroopers_advance_has_tech(transmute(^Paratroopers_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_increased_factory_production_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Increased_Factory_Production_Advance)
	s.named.base.name = "Increased Factory Production"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return increased_factory_production_advance_has_tech(transmute(^Increased_Factory_Production_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_war_bonds_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(War_Bonds_Advance)
	s.named.base.name = "War Bonds"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return war_bonds_advance_has_tech(transmute(^War_Bonds_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_mechanized_infantry_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Mechanized_Infantry_Advance)
	s.named.base.name = "Mechanized Infantry"
	s.game_data = data
	s.tech_advance.has_tech = proc(self: ^Tech_Advance, ta: ^Tech_Attachment) -> bool {
		return mechanized_infantry_advance_has_tech(transmute(^Mechanized_Infantry_Advance)self, ta)
	}
	return &s.tech_advance
}

@(private = "file")
make_industrial_technology_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Industrial_Technology_Advance)
	s.named.base.name = "Industrial Technology"
	s.game_data = data
	return &s.tech_advance
}

@(private = "file")
make_destroyer_bombard_tech_advance :: proc(data: ^Game_Data) -> ^Tech_Advance {
	s := new(Destroyer_Bombard_Tech_Advance)
	s.named.base.name = "Destroyer Bombard"
	s.game_data = data
	return &s.tech_advance
}

// Java: TechAdvance.newPredefinedTechnologyMap()
// Builds the property-string → constructor lookup that
// findDefinedAdvanceAndCreateAdvance consults. Order mirrors the Java
// Map.ofEntries(...) literal.
tech_advance_new_predefined_technology_map :: proc() -> map[string]Tech_Advance_Factory {
	m := make(map[string]Tech_Advance_Factory)
	m["superSub"] = make_super_subs_advance
	m["jetPower"] = make_jet_power_advance
	m["shipyards"] = make_improved_shipyards_advance
	m["aARadar"] = make_aa_radar_advance
	m["longRangeAir"] = make_long_range_aircraft_advance
	m["heavyBomber"] = make_heavy_bomber_advance
	m["improvedArtillerySupport"] = make_improved_artillery_support_advance
	m["rocket"] = make_rockets_advance
	m["paratroopers"] = make_paratroopers_advance
	m["increasedFactoryProduction"] = make_increased_factory_production_advance
	m["warBonds"] = make_war_bonds_advance
	m["mechanizedInfantry"] = make_mechanized_infantry_advance
	m["industrialTechnology"] = make_industrial_technology_advance
	m["destroyerBombard"] = make_destroyer_bombard_tech_advance
	return m
}

// Java: TechAdvance.findDefinedAdvanceAndCreateAdvance(String, GameData)
// Java looks the property name up in ALL_PREDEFINED_TECHNOLOGIES (a static
// final map populated once via newPredefinedTechnologyMap), then uses
// reflection to invoke the (GameData) constructor. Reflection is not part
// of the port (see llm-instructions.md), so the Class<?> values are factory
// procs and we invoke them directly. The Java IllegalArgumentException for
// an unknown technology becomes an Odin panic — the caller is expected to
// pass a known property string.
tech_advance_find_defined_advance_and_create_advance :: proc(technology_name: string, data: ^Game_Data) -> ^Tech_Advance {
	predefined := tech_advance_new_predefined_technology_map()
	defer delete(predefined)
	factory, ok := predefined[technology_name]
	if !ok {
		panic("not a valid technology")
	}
	return factory(data)
}

// Java: TechAdvance.equals(Object)
// Java rejects non-TechAdvance arguments via instanceof; in Odin the typed
// pointer parameter encodes that check (callers cannot pass a non-Tech_Advance
// pointer through this signature). The remaining body mirrors Java exactly:
// both names must be present and equal. Java's `name != null` guard becomes
// a `len(name) > 0` guard since Odin strings default to "" rather than nil.
tech_advance_equals :: proc(self: ^Tech_Advance, o: ^Tech_Advance) -> bool {
	if o == nil {
		return false
	}
	self_name := self.named.base.name
	other_name := o.named.base.name
	return len(other_name) > 0 && len(self_name) > 0 && self_name == other_name
}

