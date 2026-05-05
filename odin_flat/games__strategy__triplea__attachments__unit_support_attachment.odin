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
			fmt.panicf("%s side must be defence or offence%s", side, err)
		}
	}
	self.side = side
	return self
}

// Java: public UnitSupportAttachment(
//           final String name, final Attachable attachable, final GameData gameData) {
//   super(name, attachable, gameData);
// }
// Mirrors the `DefaultAttachment` super-constructor inline on the embedded
// `default_attachment` field (per its doc-comment, subclass constructors
// allocate their own concrete struct and initialize the base by hand).
unit_support_attachment_new :: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^Unit_Support_Attachment {
	self := new(Unit_Support_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	return self
}

// Java: private static Set<UnitType> getTargets(final UnitTypeList unitTypeList)
//   Set<UnitType> types = Set.of();
//   for (final UnitSupportAttachment rule : get(unitTypeList)) {
//     if (rule.getBonusType().isOldArtilleryRule()) {
//       types = rule.getUnitType();
//       if (rule.getName().startsWith(Constants.SUPPORT_RULE_NAME_OLD_TEMP_FIRST)) {
//         final UnitType attachedTo = (UnitType) rule.getAttachedTo();
//         attachedTo.removeAttachment(rule.getName());
//         rule.setAttachedTo(null);
//       }
//     }
//   }
//   return types;
// `Constants.SUPPORT_RULE_NAME_OLD_TEMP_FIRST = "supportAttachment" + "ArtyOld" + "TempFirst"`.
unit_support_attachment_get_targets :: proc(unit_type_list: ^Unit_Type_List) -> map[^Unit_Type]struct {} {
	types: map[^Unit_Type]struct {}
	rules := unit_support_attachment_get_for_unit_type_list(unit_type_list)
	defer delete(rules)
	for rule, _ in rules {
		bt := unit_support_attachment_get_bonus_type(rule)
		if bt != nil && unit_support_attachment_bonus_type_is_old_artillery_rule(bt) {
			types = unit_support_attachment_get_unit_type(rule)
			if strings.has_prefix(rule.default_attachment.name, "supportAttachmentArtyOldTempFirst") {
				attached_to := cast(^Unit_Type)rule.default_attachment.attached_to
				if attached_to != nil {
					named_attachable_remove_attachment(&attached_to.named_attachable, rule.default_attachment.name)
				}
				default_attachment_set_attached_to(&rule.default_attachment, nil)
			}
		}
	}
	return types
}

// Java: static void addRule(final UnitType type, final GameData data, final boolean first)
//     throws GameParseException
//   final String attachmentName =
//       (first ? Constants.SUPPORT_RULE_NAME_OLD_TEMP_FIRST : Constants.SUPPORT_RULE_NAME_OLD)
//           + type.getName();
//   final UnitSupportAttachment rule = new UnitSupportAttachment(attachmentName, type, data);
//   rule.setBonus(1);
//   rule.setBonusType(Constants.OLD_ART_RULE_NAME);
//   rule.setDice(PropertyName.STRENGTH.value);
//   rule.setFaction(PropertyName.ALLIED.value);
//   rule.setImpArtTech(true);
//   rule.setNumber(first ? 0 : 1);
//   rule.setSide(PropertyName.OFFENCE.value);
//   rule.addUnitTypes(first ? Set.of(type) : getTargets(data.getUnitTypeList()));
//   if (!first) {
//     rule.setPlayers(new ArrayList<>(data.getPlayerList().getPlayers()));
//   }
//   type.addAttachment(attachmentName, rule);
//
// `Constants.SUPPORT_RULE_NAME_OLD = "supportAttachmentArtyOld"`,
// `Constants.SUPPORT_RULE_NAME_OLD_TEMP_FIRST = "supportAttachmentArtyOldTempFirst"`,
// `Constants.OLD_ART_RULE_NAME = "ArtyOld"`. PropertyName values are the
// lowercase Java field names: `strength`, `allied`, `offence`.
unit_support_attachment_add_rule :: proc(type: ^Unit_Type, data: ^Game_Data, first: bool) {
	prefix := "supportAttachmentArtyOldTempFirst" if first else "supportAttachmentArtyOld"
	type_name := default_named_get_name(&type.named_attachable.default_named)
	attachment_name := strings.concatenate({prefix, type_name})

	rule := unit_support_attachment_new(attachment_name, cast(^Attachable)type, data)
	unit_support_attachment_set_bonus(rule, 1)
	unit_support_attachment_set_bonus_type(rule, "ArtyOld")
	unit_support_attachment_set_dice(rule, "strength")
	unit_support_attachment_set_faction(rule, "allied")
	unit_support_attachment_set_imp_art_tech(rule, true)
	unit_support_attachment_set_number(rule, 0 if first else 1)
	unit_support_attachment_set_side(rule, "offence")

	if first {
		single: map[^Unit_Type]struct {}
		single[type] = {}
		unit_support_attachment_add_unit_types(rule, single)
		delete(single)
	} else {
		targets := unit_support_attachment_get_targets(game_data_get_unit_type_list(data))
		unit_support_attachment_add_unit_types(rule, targets)
		delete(targets)
	}

	if !first {
		players_src := player_list_get_players(game_data_get_player_list(data))
		players_copy: [dynamic]^Game_Player
		for p in players_src {
			append(&players_copy, p)
		}
		unit_support_attachment_set_players(rule, players_copy)
	}

	named_attachable_add_attachment(&type.named_attachable, attachment_name, cast(^I_Attachment)rule)
}

// Java: static void addTarget(final UnitType type, final GameData data) throws GameParseException
//   boolean first = true;
//   for (final UnitSupportAttachment rule : get(data.getUnitTypeList())) {
//     if (rule.getBonusType().isOldArtilleryRule()) {
//       rule.addUnitTypes(Set.of(type));
//       first = false;
//     }
//   }
//   if (first) { addRule(type, data, true); }
unit_support_attachment_add_target :: proc(type: ^Unit_Type, data: ^Game_Data) {
	first := true
	rules := unit_support_attachment_get_for_unit_type_list(game_data_get_unit_type_list(data))
	defer delete(rules)
	for rule, _ in rules {
		bt := unit_support_attachment_get_bonus_type(rule)
		if bt != nil && unit_support_attachment_bonus_type_is_old_artillery_rule(bt) {
			single: map[^Unit_Type]struct {}
			single[type] = {}
			unit_support_attachment_add_unit_types(rule, single)
			delete(single)
			first = false
		}
	}
	if first {
		unit_support_attachment_add_rule(type, data, true)
	}
}

