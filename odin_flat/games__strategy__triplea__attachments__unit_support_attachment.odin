package game

Unit_Support_Attachment_Bonus_Type :: struct {
	name:  string,
	count: i32,
}

Unit_Support_Attachment_Property_Name :: enum {
	AA_ROLL,
	AA_STRENGTH,
	ALLIED,
	BONUS,
	BONUS_TYPE,
	DEFENCE,
	DICE,
	ENEMY,
	FACTION,
	IMP_ART_TECH,
	NUMBER,
	OFFENCE,
	PLAYERS,
	ROLL,
	SIDE,
	STRENGTH,
	UNIT_TYPE,
}

Unit_Support_Attachment :: struct {
	using parent: Default_Attachment,
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

