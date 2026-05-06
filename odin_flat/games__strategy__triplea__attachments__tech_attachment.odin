package game

Tech_Attachment :: struct {
	using default_attachment: Default_Attachment,
	tech_cost: i32,
	heavy_bomber: bool,
	long_range_air: bool,
	jet_power: bool,
	rocket: bool,
	industrial_technology: bool,
	super_sub: bool,
	destroyer_bombard: bool,
	improved_artillery_support: bool,
	paratroopers: bool,
	increased_factory_production: bool,
	war_bonds: bool,
	mechanized_infantry: bool,
	aa_radar: bool,
	shipyards: bool,
	generic_tech: map[string]bool,
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.TechAttachment

// Java: public TechAttachment(final String name, final Attachable attachable,
//                             final GameData gameData) {
//   super(name, attachable, gameData);
//   setGenericTechs();
// }
// Java's `super(...)` is the DefaultAttachment constructor, which sets the
// component's GameData, the attachment name, and the attached-to owner; in
// the port that work lives in `default_attachment_new`. Rather than calling
// it (which would allocate a separate Default_Attachment), we replicate its
// three steps inline so the embedded `default_attachment` value on the
// freshly allocated Tech_Attachment is initialized in place. The Java field
// initializers (`techCost = 5`, all booleans `false`, `genericTech = new
// HashMap<>()`) are reproduced by `new(Tech_Attachment)` (zeroing) plus an
// explicit `tech_cost = 5`; the `genericTech` map is left nil here and
// allocated lazily by `tech_attachment_set_generic_techs` on first insert,
// matching the "empty collections default to null" comment on the Java
// class. Finally we invoke `set_generic_techs` to seed the map from the
// game's technology frontier exactly as Java does.
tech_attachment_new :: proc(name: string, attachable: ^Attachable, data: ^Game_Data) -> ^Tech_Attachment {
	self := new(Tech_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	self.tech_cost = 5
	tech_attachment_set_generic_techs(self)
	return self
}

tech_attachment_get_tech_cost :: proc(self: ^Tech_Attachment) -> i32 {
	return self.tech_cost
}

tech_attachment_get_heavy_bomber :: proc(self: ^Tech_Attachment) -> bool {
	return self.heavy_bomber
}

tech_attachment_get_long_range_air :: proc(self: ^Tech_Attachment) -> bool {
	return self.long_range_air
}

tech_attachment_get_jet_power :: proc(self: ^Tech_Attachment) -> bool {
	return self.jet_power
}

tech_attachment_get_rocket :: proc(self: ^Tech_Attachment) -> bool {
	return self.rocket
}

tech_attachment_get_super_sub :: proc(self: ^Tech_Attachment) -> bool {
	return self.super_sub
}

tech_attachment_get_improved_artillery_support :: proc(self: ^Tech_Attachment) -> bool {
	return self.improved_artillery_support
}

tech_attachment_get_paratroopers :: proc(self: ^Tech_Attachment) -> bool {
	return self.paratroopers
}

tech_attachment_get_increased_factory_production :: proc(self: ^Tech_Attachment) -> bool {
	return self.increased_factory_production
}

tech_attachment_get_war_bonds :: proc(self: ^Tech_Attachment) -> bool {
	return self.war_bonds
}

tech_attachment_get_mechanized_infantry :: proc(self: ^Tech_Attachment) -> bool {
	return self.mechanized_infantry
}

tech_attachment_get_aa_radar :: proc(self: ^Tech_Attachment) -> bool {
	return self.aa_radar
}

tech_attachment_get_shipyards :: proc(self: ^Tech_Attachment) -> bool {
	return self.shipyards
}

tech_attachment_set_tech_cost :: proc(self: ^Tech_Attachment, s: string) {
	self.tech_cost = default_attachment_get_int(&self.default_attachment, s)
}

tech_attachment_set_heavy_bomber :: proc(self: ^Tech_Attachment, s: string) {
	self.heavy_bomber = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_long_range_air :: proc(self: ^Tech_Attachment, s: string) {
	self.long_range_air = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_jet_power :: proc(self: ^Tech_Attachment, s: string) {
	self.jet_power = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_rocket :: proc(self: ^Tech_Attachment, s: string) {
	self.rocket = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_super_sub :: proc(self: ^Tech_Attachment, s: string) {
	self.super_sub = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_improved_artillery_support :: proc(self: ^Tech_Attachment, s: string) {
	self.improved_artillery_support = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_paratroopers :: proc(self: ^Tech_Attachment, s: string) {
	self.paratroopers = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_increased_factory_production :: proc(self: ^Tech_Attachment, s: string) {
	self.increased_factory_production = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_war_bonds :: proc(self: ^Tech_Attachment, s: string) {
	self.war_bonds = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_mechanized_infantry :: proc(self: ^Tech_Attachment, s: string) {
	self.mechanized_infantry = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_aa_radar :: proc(self: ^Tech_Attachment, s: string) {
	self.aa_radar = default_attachment_get_bool(&self.default_attachment, s)
}

tech_attachment_set_shipyards :: proc(self: ^Tech_Attachment, s: string) {
	self.shipyards = default_attachment_get_bool(&self.default_attachment, s)
}

// Java returns Boolean (nullable). Returns (value, present).
tech_attachment_has_generic_tech :: proc(self: ^Tech_Attachment, name: string) -> (bool, bool) {
	v, ok := self.generic_tech[name]
	return v, ok
}

// Java: private void setGenericTechs() {
//   for (final TechAdvance ta : getData().getTechnologyFrontier()) {
//     if (ta instanceof GenericTechAdvance && ((GenericTechAdvance) ta).getAdvance() == null) {
//       genericTech.put(ta.getProperty().intern(), Boolean.FALSE);
//     }
//   }
// }
// `instanceof GenericTechAdvance` becomes the `is_generic` discriminator on
// Tech_Advance (no RTTI). String interning is a no-op in Odin (string
// equality is content-based). The `genericTech` map is allocated lazily on
// first insert to mirror Java's "empty collections default to null"
// memory-saving comment in the class doc.
tech_attachment_set_generic_techs :: proc(self: ^Tech_Attachment) {
	data := game_data_component_get_data(&self.default_attachment.game_data_component)
	if data == nil {
		return
	}
	frontier := game_data_get_technology_frontier(data)
	if frontier == nil {
		return
	}
	for ta in technology_frontier_get_techs(frontier) {
		if !ta.is_generic {
			continue
		}
		generic := cast(^Generic_Tech_Advance)ta
		if generic_tech_advance_get_advance(generic) != nil {
			continue
		}
		if self.generic_tech == nil {
			self.generic_tech = make(map[string]bool)
		}
		self.generic_tech[tech_advance_get_property(ta)] = false
	}
}

// Java: @Override public Optional<MutableProperty<?>> getPropertyOrEmpty(
//          final @NonNls String propertyName)
// A `switch` over the 15 property names, each case wrapping the matching
// (Integer-setter, String-setter, getter, resetter) triple in a fresh
// `MutableProperty`. The Odin slot model uses `(proc, ctx: rawptr)` pairs
// (see `mutable_property.odin`); the captured environment is just the
// `^Tech_Attachment` self pointer, so we pass it as `ctx` and let each
// thunk cast it back. Getters allocate a fresh boxed value on the heap to
// mirror Java's autoboxing — callers that go through `MutableProperty
// .getValue()` already treat the result as a typed pointer. The default
// arm returns `nil`, modelling Java's `Optional.empty()`.
//
// Note: the Java case label `"aARadar"` (lowercase 'a', uppercase 'A',
// capital 'R') is reproduced verbatim — XML/save game data identifies the
// AA-radar tech by exactly that string, so the Odin port must match it.
tech_attachment_get_property_or_empty :: proc(
	self: ^Tech_Attachment,
	property_name: string,
) -> Maybe(^Mutable_Property) {
	switch property_name {
	case "techCost":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).tech_cost = (cast(^i32)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					tech_attachment_set_tech_cost(cast(^Tech_Attachment)ctx, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(i32)
					out^ = (cast(^Tech_Attachment)ctx).tech_cost
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).tech_cost = 5
				},
				ctx = self,
			},
		)
	case "heavyBomber":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).heavy_bomber = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.heavy_bomber = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).heavy_bomber
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).heavy_bomber = false
				},
				ctx = self,
			},
		)
	case "longRangeAir":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).long_range_air = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.long_range_air = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).long_range_air
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).long_range_air = false
				},
				ctx = self,
			},
		)
	case "jetPower":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).jet_power = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.jet_power = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).jet_power
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).jet_power = false
				},
				ctx = self,
			},
		)
	case "rocket":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).rocket = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.rocket = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).rocket
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).rocket = false
				},
				ctx = self,
			},
		)
	case "industrialTechnology":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).industrial_technology = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.industrial_technology = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).industrial_technology
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).industrial_technology = false
				},
				ctx = self,
			},
		)
	case "superSub":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).super_sub = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.super_sub = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).super_sub
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).super_sub = false
				},
				ctx = self,
			},
		)
	case "destroyerBombard":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).destroyer_bombard = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.destroyer_bombard = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).destroyer_bombard
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).destroyer_bombard = false
				},
				ctx = self,
			},
		)
	case "improvedArtillerySupport":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).improved_artillery_support = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.improved_artillery_support = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).improved_artillery_support
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).improved_artillery_support = false
				},
				ctx = self,
			},
		)
	case "paratroopers":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).paratroopers = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.paratroopers = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).paratroopers
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).paratroopers = false
				},
				ctx = self,
			},
		)
	case "increasedFactoryProduction":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).increased_factory_production = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.increased_factory_production = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).increased_factory_production
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).increased_factory_production = false
				},
				ctx = self,
			},
		)
	case "warBonds":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).war_bonds = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.war_bonds = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).war_bonds
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).war_bonds = false
				},
				ctx = self,
			},
		)
	case "mechanizedInfantry":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).mechanized_infantry = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.mechanized_infantry = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).mechanized_infantry
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).mechanized_infantry = false
				},
				ctx = self,
			},
		)
	case "aARadar":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).aa_radar = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.aa_radar = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).aa_radar
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).aa_radar = false
				},
				ctx = self,
			},
		)
	case "shipyards":
		return mutable_property_of(
			Mutable_Property_Setter_Slot{
				fn = proc(ctx: rawptr, v: rawptr) -> Maybe(string) {
					(cast(^Tech_Attachment)ctx).shipyards = (cast(^bool)v)^
					return nil
				},
				ctx = self,
			},
			Mutable_Property_String_Setter_Slot{
				fn = proc(ctx: rawptr, v: string) -> Maybe(string) {
					s := cast(^Tech_Attachment)ctx
					s.shipyards = default_attachment_get_bool(&s.default_attachment, v)
					return nil
				},
				ctx = self,
			},
			Mutable_Property_Getter_Slot{
				fn = proc(ctx: rawptr) -> rawptr {
					out := new(bool)
					out^ = (cast(^Tech_Attachment)ctx).shipyards
					return out
				},
				ctx = self,
			},
			Mutable_Property_Resetter_Slot{
				fn = proc(ctx: rawptr) {
					(cast(^Tech_Attachment)ctx).shipyards = false
				},
				ctx = self,
			},
		)
	}
	return nil
}


// games.strategy.triplea.attachments.TechAttachment#getDestroyerBombard()
tech_attachment_get_destroyer_bombard :: proc(self: ^Tech_Attachment) -> bool {
	return self.destroyer_bombard
}

// games.strategy.triplea.attachments.TechAttachment#getIndustrialTechnology()
tech_attachment_get_industrial_technology :: proc(self: ^Tech_Attachment) -> bool {
	return self.industrial_technology
}

// games.strategy.triplea.attachments.TechAttachment#getGenericTech()
// Lombok @Getter on `private final Map<String, Boolean> genericTech = new HashMap<>();`.
tech_attachment_get_generic_tech :: proc(self: ^Tech_Attachment) -> map[string]bool {
	return self.generic_tech
}
