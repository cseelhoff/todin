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

