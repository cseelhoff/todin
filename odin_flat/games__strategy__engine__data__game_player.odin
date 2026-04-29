package game

// games.strategy.engine.data.GamePlayer
//
// A nation/AI/human player slot. Java extends NamedAttachable and implements
// NamedUnitHolder; the snapshot harness pins the access path
// `player.named.base.name`, so we embed `Named` directly and carry the
// attachments map alongside it.

Game_Player :: struct {
	using named:          Named,
	attachments:          map[string]^I_Attachment,
	optional:             bool,
	can_be_disabled:      bool,
	default_type:         string,
	is_hidden:            bool,
	is_disabled:          bool,
	units_held:           ^Unit_Collection,
	resources:            ^Resource_Collection,
	production_frontier:  ^Production_Frontier,
	repair_frontier:      ^Repair_Frontier,
	technology_frontiers: ^Technology_Frontier_List,
	who_am_i:             string,
	tech_attachment:      ^Tech_Attachment,
}

// Nested: GamePlayer.Type — a player type tag (e.g. human, AI).
Game_Player_Type :: struct {
	id:   string,
	name: string,
}
