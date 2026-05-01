package game

import "core:strings"

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

// Port of `RulesAttachment.isSatisfied(Map<ICondition, Boolean>)`.
// Looks up `this` in the supplied tested-conditions map and returns the
// pre-computed result, mirroring Java's `Preconditions.checkNotNull` /
// `checkState` invariants with Odin asserts.
rules_attachment_is_satisfied :: proc(
	self: ^Rules_Attachment,
	tested_conditions: map[^I_Condition]bool,
) -> bool {
	assert(self != nil)
	assert(tested_conditions != nil)
	key := cast(^I_Condition)rawptr(self)
	value, ok := tested_conditions[key]
	assert(ok)
	return value
}

// ---------------------------------------------------------------------------
// getNationalObjectives(GamePlayer)
// Java: returns every RulesAttachment on `player` whose name starts with
// Constants.RULES_OBJECTIVE_PREFIX ("objectiveAttachment"). The Odin port
// follows the same prefix-based discriminator convention used by
// `trigger_attachment_get_triggers` because RulesAttachments are
// registered under that exact prefix (see XmlGameElementMapper).
// ---------------------------------------------------------------------------
rules_attachment_get_national_objectives :: proc(
	player: ^Game_Player,
) -> map[^Rules_Attachment]struct{} {
	nat_objs: map[^Rules_Attachment]struct{}
	attachments := named_attachable_get_attachments(&player.named_attachable)
	for name, att in attachments {
		if !strings.has_prefix(name, "objectiveAttachment") {
			continue
		}
		nat_objs[cast(^Rules_Attachment)att] = {}
	}
	return nat_objs
}

