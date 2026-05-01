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

// Java: private void parseDiceSides(final DiceSides diceSides)
//   data.setDiceSides(diceSides == null ? 6 : diceSides.getValue());
game_parser_parse_dice_sides :: proc(self: ^Game_Parser, dice_sides: ^Dice_Sides) {
	if dice_sides == nil {
		game_data_set_dice_sides(self.data, 6)
	} else {
		game_data_set_dice_sides(self.data, dice_sides_get_value(dice_sides))
	}
}

// Java: private void parseUnits(final UnitList unitList)
//   unitList.getUnits().stream()
//       .map(UnitList.Unit::getName)
//       .map(name -> new UnitType(name, data))
//       .forEach(data.getUnitTypeList()::addUnitType);
// `UnitList` here is the XML element class `org.triplea.map.data.elements.UnitList`,
// mapped to `Unit_List` in the Odin port (the engine's `UnitsList` is `Units_List`).
game_parser_parse_units :: proc(self: ^Game_Parser, unit_list: ^Unit_List) {
	for u in unit_list_get_units(unit_list) {
		ut := game_parser_lambda_parse_units_16(self, u.name)
		unit_type_list_add_unit_type(game_data_get_unit_type_list(self.data), ut)
	}
}

// Java: private GamePlayer getPlayerId(final String name) throws GameParseException
//   return getPlayerIdOptional(name).orElseThrow(() -> new GameParseException(...));
// Synthetic throw supplier that captures `name` and constructs the exception.
// Mirrored as a panicking proc.
game_parser_lambda_get_player_id_3 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find player name: %s", name)
}

// Java: private RelationshipType getRelationshipType(final String name)
//   return Optional.ofNullable(data.getRelationshipTypeList().getRelationshipType(name))
//       .orElseThrow(() -> new GameParseException("Could not find relationship type: %s"));
game_parser_get_relationship_type :: proc(self: ^Game_Parser, name: string) -> ^Relationship_Type {
	rt := relationship_type_list_get_relationship_type(
		game_data_get_relationship_type_list(self.data),
		name,
	)
	if rt == nil {
		fmt.panicf("Could not find relationship type: %s", name)
	}
	return rt
}

// Synthetic throw supplier for getRelationshipType (captures `name`).
game_parser_lambda_get_relationship_type_4 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find relationship type: %s", name)
}

// Java: private TerritoryEffect getTerritoryEffect(final String name)
//   return Optional.ofNullable(data.getTerritoryEffectList().get(name))
//       .orElseThrow(() -> new GameParseException("Could not find territory effect: %s"));
// Odin: TerritoryEffectList is exposed as map[string]^Territory_Effect on Game_Data.
game_parser_get_territory_effect :: proc(self: ^Game_Parser, name: string) -> ^Territory_Effect {
	tel := game_data_get_territory_effect_list(self.data)
	te := tel[name]
	if te == nil {
		fmt.panicf("Could not find territory effect: %s", name)
	}
	return te
}

// Synthetic throw supplier for getTerritoryEffect (captures `name`).
game_parser_lambda_get_territory_effect_5 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find territory effect: %s", name)
}

// Java: private ProductionRule getProductionRule(final String name)
//   return Optional.ofNullable(data.getProductionRuleList().getProductionRule(name))
//       .orElseThrow(() -> new GameParseException("Could not find production rule: %s"));
game_parser_get_production_rule :: proc(self: ^Game_Parser, name: string) -> ^Production_Rule {
	pr := production_rule_list_get_production_rule(
		game_data_get_production_rule_list(self.data),
		name,
	)
	if pr == nil {
		fmt.panicf("Could not find production rule: %s", name)
	}
	return pr
}

// Synthetic throw supplier for getProductionRule (captures `name`).
game_parser_lambda_get_production_rule_6 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find production rule: %s", name)
}

// Java: private RepairRule getRepairRule(final String name)
//   return Optional.ofNullable(data.getRepairRules().getRepairRule(name))
//       .orElseThrow(() -> new GameParseException("Could not find repair rule: %s"));
game_parser_get_repair_rule :: proc(self: ^Game_Parser, name: string) -> ^Repair_Rule {
	rr := repair_rules_get_repair_rule(game_data_get_repair_rules(self.data), name)
	if rr == nil {
		fmt.panicf("Could not find repair rule: %s", name)
	}
	return rr
}

// Synthetic throw supplier for getRepairRule (captures `name`).
game_parser_lambda_get_repair_rule_7 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find repair rule: %s", name)
}

// Java: private Territory getTerritory(final String name)
//   return Optional.ofNullable(data.getMap().getTerritoryOrNull(name))
//       .orElseThrow(() -> new GameParseException("Could not find territory: %s"));
game_parser_get_territory :: proc(self: ^Game_Parser, name: string) -> ^Territory {
	t := game_map_get_territory_or_null(game_data_get_map(self.data), name)
	if t == nil {
		fmt.panicf("Could not find territory: %s", name)
	}
	return t
}

// Synthetic throw supplier for getTerritory (captures `name`).
game_parser_lambda_get_territory_8 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find territory: %s", name)
}

// Java: private Optional<UnitType> getUnitTypeOptional(final String name)
//   return data.getUnitTypeList().getUnitType(name);
// Per port convention, Optional<X> is mirrored as ^X (nil = absent).
game_parser_get_unit_type_optional :: proc(self: ^Game_Parser, name: string) -> ^Unit_Type {
	return unit_type_list_get_unit_type(game_data_get_unit_type_list(self.data), name)
}

// Java: private Optional<Resource> getResourceOptional(final String name)
//   return data.getResourceList().getResourceOptional(name);
// Per port convention, Optional<X> is mirrored as ^X (nil = absent).
game_parser_get_resource_optional :: proc(self: ^Game_Parser, name: string) -> ^Resource {
	return resource_list_get_resource_optional(game_data_get_resource_list(self.data), name)
}

// Java: private TechAdvance getTechnology(final String name)
//   final TechnologyFrontier frontier = data.getTechnologyFrontier();
//   return Optional.ofNullable(frontier.getAdvanceByName(name))
//       .or(() -> Optional.ofNullable(frontier.getAdvanceByProperty(name)))
//       .orElseThrow(() -> new GameParseException("Could not find technology: %s"));
game_parser_get_technology :: proc(self: ^Game_Parser, name: string) -> ^Tech_Advance {
	frontier := game_data_get_technology_frontier(self.data)
	ta := technology_frontier_get_advance_by_name(frontier, name)
	if ta == nil {
		ta = technology_frontier_get_advance_by_property(frontier, name)
	}
	if ta == nil {
		fmt.panicf("Could not find technology: %s", name)
	}
	return ta
}

// Synthetic `or` supplier for getTechnology (captures `frontier` and `name`).
//   () -> Optional.ofNullable(frontier.getAdvanceByProperty(name))
// Returns ^Tech_Advance (nil = absent) per Optional convention.
game_parser_lambda_get_technology_9 :: proc(
	frontier: ^Technology_Frontier,
	name: string,
) -> ^Tech_Advance {
	return technology_frontier_get_advance_by_property(frontier, name)
}

// Synthetic throw supplier for getTechnology (captures `name`).
game_parser_lambda_get_technology_10 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find technology: %s", name)
}

// Java: private IDelegate getDelegate(final String name)
//   return data.getDelegateOptional(name)
//       .orElseThrow(() -> new GameParseException("Could not find delegate: %s"));
game_parser_get_delegate :: proc(self: ^Game_Parser, name: string) -> ^I_Delegate {
	d := game_data_get_delegate_optional(self.data, name)
	if d == nil {
		fmt.panicf("Could not find delegate: %s", name)
	}
	return d
}

// Synthetic throw supplier for getDelegate (captures `name`).
game_parser_lambda_get_delegate_11 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find delegate: %s", name)
}

// Java: private ProductionFrontier getProductionFrontier(final String name)
//   return Optional.ofNullable(data.getProductionFrontierList().getProductionFrontier(name))
//       .orElseThrow(() -> new GameParseException("Could not find production frontier: %s"));
game_parser_get_production_frontier :: proc(self: ^Game_Parser, name: string) -> ^Production_Frontier {
	pf := production_frontier_list_get_production_frontier(
		game_data_get_production_frontier_list(self.data),
		name,
	)
	if pf == nil {
		fmt.panicf("Could not find production frontier: %s", name)
	}
	return pf
}

// Synthetic throw supplier for getProductionFrontier (captures `name`).
game_parser_lambda_get_production_frontier_12 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find production frontier: %s", name)
}

// Java: private RepairFrontier getRepairFrontier(final String name)
//   return Optional.ofNullable(data.getRepairFrontierList().getRepairFrontier(name))
//       .orElseThrow(() -> new GameParseException("Could not find repair frontier: %s"));
game_parser_get_repair_frontier :: proc(self: ^Game_Parser, name: string) -> ^Repair_Frontier {
	rf := repair_frontier_list_get_repair_frontier(
		game_data_get_repair_frontier_list(self.data),
		name,
	)
	if rf == nil {
		fmt.panicf("Could not find repair frontier: %s", name)
	}
	return rf
}

// Synthetic throw supplier for getRepairFrontier (captures `name`).
game_parser_lambda_get_repair_frontier_13 :: proc(name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Could not find repair frontier: %s", name)
}

// Synthetic throw supplier for parseDelegates (captures `className`):
//   () -> new GameParseException(String.format("Class <%s> is not a delegate.", className))
game_parser_lambda_parse_delegates_22 :: proc(class_name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Class <%s> is not a delegate.", class_name)
}

// Synthetic throw supplier for parseAttachment (captures `className`):
//   () -> new GameParseException(String.format(
//       "Attachment of type %s could not be instantiated", className))
game_parser_lambda_parse_attachment_23 :: proc(class_name: string) -> ^Game_Parse_Exception {
	fmt.panicf("Attachment of type %s could not be instantiated", class_name)
}

// Synthetic throw supplier for setOptions (captures `name` and `attachment`):
//   () -> new GameParseException(String.format(
//       "Missing property definition for option ''%s'' in attachment ''%s''",
//       name, attachment.getName()))
game_parser_lambda_set_options_24 :: proc(
	name: string,
	attachment: ^I_Attachment,
) -> ^Game_Parse_Exception {
	fmt.panicf(
		"Missing property definition for option '%s' in attachment '%s'",
		name,
		i_attachment_get_name(attachment),
	)
}

// Synthetic outer lambda from GameParser.parse(Path, boolean)'s
// gameData.ifPresent(...) call (captures `xmlFile`, takes `data`):
//   data ->
//       FileUtils.findFileInParentFolders(xmlFile, MAP_YAML_FILE_NAME)
//           .flatMap(MapDescriptionYaml::fromFile)
//           .ifPresent(mapDescriptionYaml -> {
//               data.setGameName(mapDescriptionYaml.findGameNameFromXmlFileName(xmlFile));
//               data.setMapName(mapDescriptionYaml.getMapName());
//           });
// The inner ifPresent body is inlined here (it is the only call site).
game_parser_lambda_parse_1 :: proc(xml_file: Path, data: ^Game_Data) {
	yaml_path := file_utils_find_file_in_parent_folders(xml_file, MAP_YAML_FILE_NAME)
	if yaml_path == nil {
		return
	}
	yaml, ok := map_description_yaml_from_file(yaml_path^)
	if !ok || yaml == nil {
		return
	}
	game_data_set_game_name(
		data,
		map_description_yaml_find_game_name_from_xml_file_name(yaml, xml_file),
	)
	game_data_set_map_name(data, map_description_yaml_get_map_name(yaml))
}
