package game

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

