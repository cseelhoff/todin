package game

// games.strategy.engine.data.GamePlayer
//
// A nation/AI/human player slot. Implements Named, so embeds Named so the
// snapshot harness can read player.named.base.name.

Game_Player :: struct {
	using named:        Named,
	optional:           bool,
	can_be_disabled:    bool,
	is_disabled:        bool,
	who_am_i:           string,
	resources:          ^Resource_Collection,
	tech_attachment:    ^Tech_Attachment,
	production_frontier: ^Production_Frontier,
}
