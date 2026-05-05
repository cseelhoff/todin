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

// Java: public RulesAttachment(String name, Attachable attachable, GameData gameData)
//   super(name, attachable, gameData);
// Non-zero Java field-initializer defaults span the parent chain
// (AbstractPlayerRulesAttachment ⊃ AbstractRulesAttachment ⊃
// AbstractConditionsAttachment ⊃ DefaultAttachment) plus the class itself:
//   RulesAttachment:               techCount = -1, atWarCount = -1
//   AbstractRulesAttachment:       eachMultiple = 1, switched = true,
//                                  territoryCount = -1
//   AbstractConditionsAttachment:  conditionType = AND, chance = DEFAULT_CHANCE
rules_attachment_new :: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^Rules_Attachment {
	self := new(Rules_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	self.tech_count = -1
	self.at_war_count = -1
	self.each_multiple = 1
	self.switched = true
	self.territory_count = -1
	self.condition_type = "AND"
	self.chance = "1:1"
	return self
}
