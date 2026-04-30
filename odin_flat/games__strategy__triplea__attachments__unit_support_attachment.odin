package game

import "core:strings"

Unit_Support_Attachment :: struct {
	using default_attachment: Default_Attachment,
	unit_type:    map[^Unit_Type]struct{},
	offence:      bool,
	defence:      bool,
	roll:         bool,
	strength:     bool,
	aa_roll:      bool,
	aa_strength:  bool,
	bonus:        i32,
	number:       i32,
	allied:       bool,
	enemy:        bool,
	bonus_type:   ^Unit_Support_Attachment_Bonus_Type,
	players:      [dynamic]^Game_Player,
	imp_art_tech: bool,
	dice:         string,
	side:         string,
	faction:      string,
}

// Java: public static Set<UnitSupportAttachment> get(final UnitType u)
//   return u.getAttachments().values().stream()
//       .filter(a -> a.getName().startsWith(Constants.SUPPORT_ATTACHMENT_PREFIX))
//       .map(UnitSupportAttachment.class::cast)
//       .collect(Collectors.toSet());
// `Constants.SUPPORT_ATTACHMENT_PREFIX = "supportAttachment"`.
unit_support_attachment_get :: proc(u: ^Unit_Type) -> map[^Unit_Support_Attachment]struct {} {
	result: map[^Unit_Support_Attachment]struct {}
	if u == nil {
		return result
	}
	atts := named_attachable_get_attachments(&u.named_attachable)
	for name, a in atts {
		if strings.has_prefix(name, "supportAttachment") {
			result[cast(^Unit_Support_Attachment)a] = {}
		}
	}
	return result
}

// Java: private void addUnitTypes(final Set<UnitType> types)
//   if (unitType == null) { unitType = new HashSet<>(); }
//   unitType.addAll(types);
unit_support_attachment_add_unit_types :: proc(self: ^Unit_Support_Attachment, types: map[^Unit_Type]struct {}) {
	if self.unit_type == nil {
		self.unit_type = make(map[^Unit_Type]struct {})
	}
	for t, _ in types {
		self.unit_type[t] = {}
	}
}

// Java: private void resetDice()
//   dice = null; roll = false; strength = false; aaRoll = false; aaStrength = false;
unit_support_attachment_reset_dice :: proc(self: ^Unit_Support_Attachment) {
	self.dice = ""
	self.roll = false
	self.strength = false
	self.aa_roll = false
	self.aa_strength = false
}

// Java: public boolean getAaRoll() { return aaRoll; }
unit_support_attachment_get_aa_roll :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.aa_roll
}

// Java: public boolean getAaStrength() { return aaStrength; }
unit_support_attachment_get_aa_strength :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.aa_strength
}

// Java: public boolean getAllied() { return allied; }
unit_support_attachment_get_allied :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.allied
}

// Java: @Getter private int bonus; → public int getBonus() { return bonus; }
unit_support_attachment_get_bonus :: proc(self: ^Unit_Support_Attachment) -> i32 {
	return self.bonus
}

// Java: public @Nullable BonusType getBonusType() { return bonusType; }
unit_support_attachment_get_bonus_type :: proc(self: ^Unit_Support_Attachment) -> ^Unit_Support_Attachment_Bonus_Type {
	return self.bonus_type
}

// Java: public boolean getDefence() { return defence; }
unit_support_attachment_get_defence :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.defence
}

// Java: public boolean getEnemy() { return enemy; }
unit_support_attachment_get_enemy :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.enemy
}

// Java: public boolean getImpArtTech() { return impArtTech; }
unit_support_attachment_get_imp_art_tech :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.imp_art_tech
}

// Java: @Getter private int number; → public int getNumber() { return number; }
unit_support_attachment_get_number :: proc(self: ^Unit_Support_Attachment) -> i32 {
	return self.number
}

// Java: public boolean getOffence() { return offence; }
unit_support_attachment_get_offence :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.offence
}

// Java: public List<GamePlayer> getPlayers() { return getListProperty(players); }
unit_support_attachment_get_players :: proc(self: ^Unit_Support_Attachment) -> [dynamic]^Game_Player {
	return default_attachment_get_list_property(self.players)
}

// Java: public boolean getRoll() { return roll; }
unit_support_attachment_get_roll :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.roll
}

// Java: public boolean getStrength() { return strength; }
unit_support_attachment_get_strength :: proc(self: ^Unit_Support_Attachment) -> bool {
	return self.strength
}

// Java: public @Nullable Set<UnitType> getUnitType() { return unitType; }
unit_support_attachment_get_unit_type :: proc(self: ^Unit_Support_Attachment) -> map[^Unit_Type]struct {} {
	return self.unit_type
}

// Java: public UnitSupportAttachment setBonus(final int bonus) { this.bonus = bonus; return this; }
unit_support_attachment_set_bonus :: proc(self: ^Unit_Support_Attachment, bonus: i32) -> ^Unit_Support_Attachment {
	self.bonus = bonus
	return self
}

// Java: public UnitSupportAttachment setImpArtTech(final boolean tech) { impArtTech = tech; return this; }
unit_support_attachment_set_imp_art_tech :: proc(self: ^Unit_Support_Attachment, tech: bool) -> ^Unit_Support_Attachment {
	self.imp_art_tech = tech
	return self
}

// Java: public UnitSupportAttachment setNumber(final int number) { this.number = number; return this; }
unit_support_attachment_set_number :: proc(self: ^Unit_Support_Attachment, number: i32) -> ^Unit_Support_Attachment {
	self.number = number
	return self
}

// Java: public UnitSupportAttachment setPlayers(final List<GamePlayer> value) { players = value; return this; }
unit_support_attachment_set_players :: proc(self: ^Unit_Support_Attachment, value: [dynamic]^Game_Player) -> ^Unit_Support_Attachment {
	self.players = value
	return self
}

