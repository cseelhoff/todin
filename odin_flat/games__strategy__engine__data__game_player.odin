package game

// games.strategy.engine.data.GamePlayer
//
// Java: `class GamePlayer extends NamedAttachable implements NamedUnitHolder`.
// Single inheritance → embed Named_Attachable as the parent. The
// NamedUnitHolder/UnitHolder interfaces contribute no fields. The harness
// access path `player.named.base.name` resolves through the chained
// `using` embeddings: Named_Attachable → Default_Named → Named.

Game_Player :: struct {
	using parent:         Named_Attachable,
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
