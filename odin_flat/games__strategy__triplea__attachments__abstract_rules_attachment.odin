package game

Abstract_Rules_Attachment :: struct {
	using parent:    Abstract_Conditions_Attachment,
	each_multiple:   i32,
	players:         [dynamic]^Game_Player,
	objective_value: i32,
	uses:            i32,
	turns:           map[i32]i32,
	switched:        bool,
	game_property:   string,
	count_each:      bool,
	territory_count: i32,
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.AbstractRulesAttachment

