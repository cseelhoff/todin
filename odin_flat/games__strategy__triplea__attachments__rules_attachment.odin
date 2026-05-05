package game

import "core:strconv"
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

// Java: AbstractPlayerRulesAttachment.java line 45 — Lombok @Getter on
// `protected @Nullable String[] movementRestrictionTerritories`.
// Forwarded through the embedded `Abstract_Player_Rules_Attachment`.
rules_attachment_get_movement_restriction_territories :: proc(
	self: ^Rules_Attachment,
) -> [dynamic]string {
	return self.movement_restriction_territories
}

// Java: AbstractPlayerRulesAttachment.java line 148-150
//   public boolean isMovementRestrictionTypeAllowed() {
//     return MOVEMENT_RESTRICTION_TYPE_ALLOWED.equals(movementRestrictionType);
//   }
// MOVEMENT_RESTRICTION_TYPE_ALLOWED is the string literal "allowed".
rules_attachment_is_movement_restriction_type_allowed :: proc(
	self: ^Rules_Attachment,
) -> bool {
	return self.movement_restriction_type == "allowed"
}

// Java: AbstractPlayerRulesAttachment.java line 152-154
//   public boolean isMovementRestrictionTypeDisallowed() {
//     return MOVEMENT_RESTRICTION_TYPE_DISALLOWED.equals(movementRestrictionType);
//   }
// MOVEMENT_RESTRICTION_TYPE_DISALLOWED is the string literal "disallowed".
rules_attachment_is_movement_restriction_type_disallowed :: proc(
	self: ^Rules_Attachment,
) -> bool {
	return self.movement_restriction_type == "disallowed"
}

// Java: AbstractRulesAttachment.java line 349-405 —
//   public Set<Territory> getListedTerritories(
//       String[] list, boolean testFirstItemForCount, boolean mustSetTerritoryCount)
// Validates that every name in `list` resolves to a real Territory on the
// game map and returns the collected territories. Special tokens
// ("each" / "controlled" / "controlledNoWater" / "original" /
// "originalNoWater" / "all" / "map" / "enemy") drive the count-tracking
// fields rather than naming a territory; an integer in the first slot
// (when `testFirstItemForCount`) is interpreted as the territory count.
// Mirrors the Java shape but returns `[dynamic]^Territory` per the call
// site at matches.odin:5980 (`for lt in listed { ... }`).
rules_attachment_get_listed_territories :: proc(
	self:                         ^Rules_Attachment,
	list:                         [dynamic]string,
	test_first_item_for_count:    bool,
	must_set_territory_count:     bool,
) -> [dynamic]^Territory {
	territories: [dynamic]^Territory
	seen: map[^Territory]struct{}
	defer delete(seen)

	// null/empty/"" cases mirror Java's early return with an empty set.
	if list == nil || len(list) == 0 ||
	   (len(list) == 1 && len(list[0]) == 0) {
		return territories
	}

	have_set_count := false
	game_map := game_data_get_map(game_data_component_get_data(&self.game_data_component))

	for i in 0 ..< len(list) {
		name := list[i]
		if name == "each" {
			self.count_each = true
			if must_set_territory_count {
				have_set_count = true
				self.territory_count = 1
			}
			continue
		}
		// "group commands" — break out of the validation loop entirely.
		if name == "controlled" ||
		   name == "controlledNoWater" ||
		   name == "original" ||
		   name == "originalNoWater" ||
		   name == "all" ||
		   name == "map" ||
		   name == "enemy" {
			break
		}
		if test_first_item_for_count && i == 0 {
			parsed, ok := strconv.parse_int(name)
			if ok {
				if must_set_territory_count {
					have_set_count = true
					self.territory_count = i32(parsed)
				}
				continue
			}
			// Fall through: name is not an integer, treat as a territory name.
		}
		territory := game_map_get_territory_or_null(game_map, name)
		if territory == nil {
			panic(strings.concatenate({"No territory called: ", name}))
		}
		if _, dup := seen[territory]; !dup {
			seen[territory] = {}
			append(&territories, territory)
		}
	}
	if must_set_territory_count && !have_set_count {
		self.territory_count = i32(len(territories))
	}
	return territories
}
