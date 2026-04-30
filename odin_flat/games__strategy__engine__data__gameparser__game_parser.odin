package game

import "core:fmt"
import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

Game_Parser :: struct {
	data:                              ^Game_Data,
	xml_uri:                           string,
	xml_game_element_mapper:           ^Xml_Game_Element_Mapper,
	variables:                         ^Game_Data_Variables,
	engine_version:                    ^Version,
	collect_attachment_order_and_values: bool,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.gameparser.GameParser

// Synthetic lambda from GameParser.parseProperties (#18):
//   () -> Optional.ofNullable(current.getNumberProperty())
//             .map(PropertyList.Property.XmlNumberTag::getMin)
// Returns (value, present): present=false when number_property is nil
// (mirrors Optional.empty()); otherwise the wrapped min value.
game_parser_lambda_parse_properties_18 :: proc(prop: ^Property_List_Property) -> (i32, bool) {
	if prop.number_property == nil {
		return 0, false
	}
	return prop.number_property.min, true
}


// @VisibleForTesting
// static String decapitalize(final String value)
game_parser_decapitalize :: proc(s: string) -> string {
	if len(s) == 0 {
		return ""
	}
	r, w := utf8.decode_rune_in_string(s)
	lower := unicode.to_lower(r)
	b := strings.builder_make()
	strings.write_rune(&b, lower)
	strings.write_string(&b, s[w:])
	return strings.to_string(b)
}

// Java: private GamePlayer getPlayerId(final String name) throws GameParseException
// Looks the player up via data.getPlayerList().getPlayerId(name);
// throws GameParseException when unknown — mirrored here as a panic.
game_parser_get_player_id :: proc(self: ^Game_Parser, name: string) -> ^Game_Player {
	player := player_list_get_player_id(game_data_get_player_list(self.data), name)
	if player == nil {
		fmt.panicf("Could not find player name: %s", name)
	}
	return player
}

// private boolean containsEmptyForeachVariable(final String s, final Map<String, String> foreach)
game_parser_contains_empty_foreach_variable :: proc(s: string, foreach: map[string]string) -> bool {
	for key, value in foreach {
		if len(value) == 0 && strings.contains(s, key) {
			return true
		}
	}
	return false
}

// private void parseAttachments(final AttachmentList root) throws GameParseException
game_parser_parse_attachments :: proc(self: ^Game_Parser, root: ^Attachment_List) {
	for current in root.attachments {
		foreach := current.foreach
		if len(strings.trim_space(foreach)) == 0 {
			empty: map[string]string
			game_parser_parse_attachment(self, current, empty)
		} else {
			combinations := game_data_variables_expand_variable_combinations(self.variables, foreach)
			for foreach_map in combinations {
				game_parser_parse_attachment(self, current, foreach_map)
			}
		}
	}
}

// Synthetic lambda from parseProperties:
//   () -> Optional.ofNullable(current.getNumberProperty())
//             .map(PropertyList.Property.XmlNumberTag::getMax)
// The captured `current` is the lambda's bound parameter.
// Returns (max, present).
game_parser_lambda_parse_properties_19 :: proc(prop: ^Property_List_Property) -> (i32, bool) {
        if prop == nil || prop.number_property == nil {
                return 0, false
        }
        return prop.number_property.max, true
}

// Synthetic lambda from parseUnits:
//   name -> new UnitType(name, data)
// The captured `data` reference is the outer GameParser's `data` field;
// it is not stored on Unit_Type because the Odin port of Default_Named
// does not embed Game_Data_Component. The Java constructor only stores
// `name` on Default_Named (after non-null/non-empty checks) and `data`
// on the GameDataComponent superclass.
game_parser_lambda_parse_units_16 :: proc(self: ^Game_Parser, name: string) -> ^Unit_Type {
	assert(name != "")
	ut := new(Unit_Type)
	ut.named.base.name = name
	ut.named.kind = .Unit_Type
	_ = self.data
	return ut
}

// private void parseRepairCosts(
//     final RepairRule repairRule, final List<Production.ProductionRule.Cost> elements)
//     throws GameParseException
game_parser_parse_repair_costs :: proc(
	self: ^Game_Parser,
	repair_rule: ^Repair_Rule,
	elements: [dynamic]^Production_Rule_Cost,
) {
	if len(elements) == 0 {
		fmt.panicf(
			"No costs for repair rule: %s",
			default_named_get_name(&repair_rule.default_named),
		)
	}
	game_parser_parse_costs_for_rule(self, repair_rule, elements)
}

// private Properties parseStepProperties(final List<GamePlay.Sequence.Step.StepProperty> properties)
game_parser_parse_step_properties :: proc(properties: [dynamic]^Game_Play_Sequence_Step_Step_Property) -> map[string]string {
	step_properties: map[string]string
	for p in properties {
		step_properties[p.name] = p.value
	}
	return step_properties
}

// private void parseProductionCosts(
//     final ProductionRule productionRule, final List<Production.ProductionRule.Cost> elements)
//     throws GameParseException
game_parser_parse_production_costs :: proc(
	self: ^Game_Parser,
	production_rule: ^Production_Rule,
	elements: [dynamic]^Production_Rule_Cost,
) {
	if len(elements) == 0 {
		fmt.panicf(
			"No costs for production rule: %s",
			default_named_get_name(&production_rule.default_named),
		)
	}
	game_parser_parse_costs_for_rule(self, production_rule, elements)
}

// private void parseCostsForRule(Rule rule, List<Production.Rule.Cost> elements)
//     throws GameParseException
game_parser_parse_costs_for_rule :: proc(self: ^Game_Parser, rule: ^Rule, elements: [dynamic]^Production_Rule_Cost) {
	for current in elements {
		resource := game_parser_get_resource_or_throw(self, current.resource)
		quantity := current.quantity
		rule_add_cost(rule, resource, quantity)
	}
}

// private void parsePlayerList(final PlayerList playerListData)
// `PlayerList` here is the XML element class
// (`org.triplea.map.data.elements.PlayerList`), mapped per the
// disambiguation table to `Xml_Player_List`. Mirrors Java's
// `forEach(current -> data.getPlayerList().addPlayerId(new GamePlayer(...)))`
// inline because the GamePlayer 6-arg constructor is not a separate
// proc in the Odin port; the field initialization here matches
// `GamePlayer(name, optional, canBeDisabled, defaultType, isHidden, data)`
// (including the `whoAmI = "null: no_one"` field initializer and the
// embedded UnitCollection/ResourceCollection/TechnologyFrontierList
// allocations from the Java ctor).
// `PLAYER_TYPE_HUMAN_LABEL` resolves via i18n
// ("startup.PlayerTypes.PLAYER_TYPE_HUMAN_LABEL") to the literal "Human"
// in the English resource bundle, which is the value the snapshot
// harness pins.
game_parser_parse_player_list :: proc(self: ^Game_Parser, xml_player_list: ^Xml_Player_List) {
	for current in xml_player_list.players {
		name := current.name
		optional := current.optional
		can_be_disabled := current.can_be_disabled
		default_type := current.default_type
		if default_type == "" {
			default_type = "Human"
		}
		is_hidden := current.is_hidden

		player := new(Game_Player)
		player.named_attachable.default_named.named.base.name = name
		player.named_attachable.default_named.named.kind = .Game_Player
		player.named_attachable.default_named.game_data_component.game_data = self.data
		player.optional = optional
		player.can_be_disabled = can_be_disabled
		player.default_type = default_type
		player.is_hidden = is_hidden

		units_held := new(Unit_Collection)
		units_held.game_data_component.game_data = self.data
		player.units_held = units_held

		resources := new(Resource_Collection)
		resources.game_data_component.game_data = self.data
		player.resources = resources

		tech_frontiers := new(Technology_Frontier_List)
		tech_frontiers.game_data_component.game_data = self.data
		player.technology_frontiers = tech_frontiers

		player.who_am_i = "null: no_one"

		player_list_add_player_id(game_data_get_player_list(self.data), player)
	}
}
