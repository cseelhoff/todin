package game

import "core:fmt"
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

// Java: filter lambda inside `get(UnitType)`:
//   attachment -> attachment.getName().startsWith(Constants.SUPPORT_ATTACHMENT_PREFIX)
// `Constants.SUPPORT_ATTACHMENT_PREFIX = "supportAttachment"`.
unit_support_attachment_lambda__get__0 :: proc(attachment: ^I_Attachment) -> bool {
	return strings.has_prefix(i_attachment_get_name(attachment), "supportAttachment")
}

// Java: public static Set<UnitSupportAttachment> get(final UnitTypeList unitTypeList)
//   return unitTypeList.stream()
//       .map(UnitSupportAttachment::get)
//       .flatMap(Collection::stream)
//       .collect(Collectors.toSet());
unit_support_attachment_get_for_unit_type_list :: proc(unit_type_list: ^Unit_Type_List) -> map[^Unit_Support_Attachment]struct {} {
	result: map[^Unit_Support_Attachment]struct {}
	if unit_type_list == nil {
		return result
	}
	types := unit_type_list_stream(unit_type_list)
	defer delete(types)
	for ut in types {
		inner := unit_support_attachment_get(ut)
		for usa, _ in inner {
			result[usa] = {}
		}
		delete(inner)
	}
	return result
}

// Java: public UnitSupportAttachment setBonusType(final String type) throws GameParseException
//   final String[] s = splitOnColon(type);
//   if (s.length > 2) throw new GameParseException("bonusType can only have value and count: " + type + thisErrorMsg());
//   if (s.length == 1) bonusType = new BonusType(s[0], 1);
//   else               bonusType = new BonusType(s[1], getInt(s[0]));
//   return this;
unit_support_attachment_set_bonus_type :: proc(self: ^Unit_Support_Attachment, type_str: string) -> ^Unit_Support_Attachment {
	parts := default_attachment_split_on_colon(type_str)
	defer delete(parts)
	if len(parts) > 2 {
		err := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(err)
		fmt.panicf("bonusType can only have value and count: %s%s", type_str, err)
	}
	if len(parts) == 1 {
		one: i32 = 1
		self.bonus_type = unit_support_attachment_bonus_type_new(parts[0], &one)
	} else {
		count := default_attachment_get_int(&self.default_attachment, parts[0])
		self.bonus_type = unit_support_attachment_bonus_type_new(parts[1], &count)
	}
	return self
}

// Java: public UnitSupportAttachment setDice(final String dice) throws GameParseException
//   resetDice();
//   this.dice = dice.intern();
//   for (final String element : splitOnColon(dice)) {
//     if (equalsIgnoreCase(ROLL))         roll        = true;
//     else if (eIC(STRENGTH))             strength    = true;
//     else if (eIC(AA_ROLL))              aaRoll      = true;
//     else if (eIC(AA_STRENGTH))          aaStrength  = true;
//     else throw new GameParseException(dice + " dice must be roll, strength, AAroll, or AAstrength: " + thisErrorMsg());
//   }
//   return this;
unit_support_attachment_set_dice :: proc(self: ^Unit_Support_Attachment, dice: string) -> ^Unit_Support_Attachment {
	unit_support_attachment_reset_dice(self)
	self.dice = dice
	parts := default_attachment_split_on_colon(dice)
	defer delete(parts)
	for element in parts {
		if strings.equal_fold(element, "roll") {
			self.roll = true
		} else if strings.equal_fold(element, "strength") {
			self.strength = true
		} else if strings.equal_fold(element, "AAroll") {
			self.aa_roll = true
		} else if strings.equal_fold(element, "AAstrength") {
			self.aa_strength = true
		} else {
			err := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(err)
			fmt.panicf("%s dice must be roll, strength, AAroll, or AAstrength: %s", dice, err)
		}
	}
	return self
}

// Java: public UnitSupportAttachment setFaction(final String faction) throws GameParseException
//   this.faction = faction; allied = false; enemy = false;
//   for (final String element : splitOnColon(faction)) {
//     if (eIC(ALLIED))      allied = true;
//     else if (eIC(ENEMY))  enemy  = true;
//     else throw new GameParseException(faction + " faction must be allied, or enemy" + thisErrorMsg());
//   }
//   return this;
unit_support_attachment_set_faction :: proc(self: ^Unit_Support_Attachment, faction: string) -> ^Unit_Support_Attachment {
	self.faction = faction
	self.allied = false
	self.enemy = false
	parts := default_attachment_split_on_colon(faction)
	defer delete(parts)
	for element in parts {
		if strings.equal_fold(element, "allied") {
			self.allied = true
		} else if strings.equal_fold(element, "enemy") {
			self.enemy = true
		} else {
			err := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(err)
			fmt.panicf("%s faction must be allied, or enemy%s", faction, err)
		}
	}
	return self
}

// Java: public UnitSupportAttachment setSide(final String side) throws GameParseException
//   defence = false; offence = false;
//   for (final String element : splitOnColon(side)) {
//     if (eIC(DEFENCE))      defence = true;
//     else if (eIC(OFFENCE)) offence = true;
//     else throw new GameParseException(side + " side must be defence or offence" + thisErrorMsg());
//   }
//   this.side = side.intern();
//   return this;
unit_support_attachment_set_side :: proc(self: ^Unit_Support_Attachment, side: string) -> ^Unit_Support_Attachment {
	self.defence = false
	self.offence = false
	parts := default_attachment_split_on_colon(side)
	defer delete(parts)
	for element in parts {
		if strings.equal_fold(element, "defence") {
			self.defence = true
		} else if strings.equal_fold(element, "offence") {
			self.offence = true
		} else {
			err := default_attachment_this_error_msg(&self.default_attachment)
			defer delete(err)
			fmt.panicf("%s side must be defence or offence%s", side, err)
		}
	}
	self.side = side
	return self
}

