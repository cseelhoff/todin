package game

// Port of games.strategy.triplea.attachments.RulesAttachment (Phase A: type only).

Rules_Attachment :: struct {
	using abstract_player_rules_attachment: Abstract_Player_Rules_Attachment,
	techs: [dynamic]^Tech_Advance,
	tech_count: i32,
	relationship: [dynamic]string,
	is_ai: ^bool,
	at_war_players: map[^Game_Player]struct{},
	at_war_count: i32,
	destroyed_tuv: string,
	battle: [dynamic]Tuple(string, [dynamic]^Territory),
	allied_ownership_territories: [dynamic]string,
	direct_ownership_territories: [dynamic]string,
	allied_exclusion_territories: [dynamic]string,
	direct_exclusion_territories: [dynamic]string,
	enemy_exclusion_territories: [dynamic]string,
	enemy_surface_exclusion_territories: [dynamic]string,
	direct_presence_territories: [dynamic]string,
	allied_presence_territories: [dynamic]string,
	enemy_presence_territories: [dynamic]string,
	unit_presence: ^Integer_Map,
}

