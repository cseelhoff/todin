package game

import "core:fmt"
import "core:strconv"
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
		game_parser_lambda_parse_player_list_17(self, current)
	}
}

// Synthetic forEach lambda from parsePlayerList (#17):
//   current ->
//     data.getPlayerList().addPlayerId(
//         new GamePlayer(
//             current.getName(),
//             Optional.ofNullable(current.getOptional()).orElse(false),
//             Optional.ofNullable(current.getCanBeDisabled()).orElse(false),
//             Optional.ofNullable(current.getDefaultType()).orElse(PLAYER_TYPE_HUMAN_LABEL),
//             Optional.ofNullable(current.getIsHidden()).orElse(false),
//             data));
// Captures `data` (via self.data). PLAYER_TYPE_HUMAN_LABEL resolves
// to "Human" in the English resource bundle, which is the value the
// snapshot harness pins.
game_parser_lambda_parse_player_list_17 :: proc(self: ^Game_Parser, current: ^Xml_Player_List_Player) {
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

// Java: private Optional<GamePlayer> getPlayerIdOptional(final String name)
//   return Optional.ofNullable(data.getPlayerList().getPlayerId(name));
// Per port convention, Optional<X> -> ^X (nil = absent).
game_parser_get_player_id_optional :: proc(self: ^Game_Parser, name: string) -> ^Game_Player {
	return player_list_get_player_id(game_data_get_player_list(self.data), name)
}

// Java: private Resource getResourceOrThrow(final String name)
//   try { return data.getResourceList().getResourceOrThrow(name); }
//   catch (IllegalArgumentException e) { throw new GameParseException(e.getMessage(), e); }
// resource_list_get_resource_or_throw already panics on miss; the
// Java rewrap is a no-op for behavior beyond message text.
game_parser_get_resource_or_throw :: proc(self: ^Game_Parser, name: string) -> ^Resource {
	return resource_list_get_resource_or_throw(game_data_get_resource_list(self.data), name)
}

// Java: private UnitType getUnitType(final String name)
//   try { return data.getUnitTypeList().getUnitTypeOrThrow(name); }
//   catch (IllegalArgumentException e) { throw new GameParseException(e.getMessage(), e); }
game_parser_get_unit_type :: proc(self: ^Game_Parser, name: string) -> ^Unit_Type {
	return unit_type_list_get_unit_type_or_throw(game_data_get_unit_type_list(self.data), name)
}

// Java: private boolean isEngineCompatibleWithMap(final Triplea tripleA)
//   return tripleA == null
//       || tripleA.getMinimumVersion().isBlank()
//       || engineVersion.isCompatibleWithMapMinimumEngineVersion(
//           new Version(tripleA.getMinimumVersion()));
game_parser_is_engine_compatible_with_map :: proc(self: ^Game_Parser, triplea: ^Triplea) -> bool {
	if triplea == nil {
		return true
	}
	min_v := triplea_get_minimum_version(triplea)
	if len(strings.trim_space(min_v)) == 0 {
		return true
	}
	return version_is_compatible_with_map_minimum_engine_version(
		self.engine_version,
		version_new(min_v),
	)
}

// Synthetic inner lambda from GameParser.parse(Path, boolean):
//   mapDescriptionYaml -> {
//       data.setGameName(mapDescriptionYaml.findGameNameFromXmlFileName(xmlFile));
//       data.setMapName(mapDescriptionYaml.getMapName());
//   }
// Captures `data` and `xmlFile` from the outer ifPresent.
game_parser_lambda_parse_0 :: proc(
	data: ^Game_Data,
	xml_file: Path,
	map_description_yaml: ^Map_Description_Yaml,
) {
	game_data_set_game_name(
		data,
		map_description_yaml_find_game_name_from_xml_file_name(map_description_yaml, xml_file),
	)
	game_data_set_map_name(data, map_description_yaml_get_map_name(map_description_yaml))
}

// Synthetic forEach lambda from parseProperties (#20):
//   playerId -> data.getProperties().addPlayerProperty(
//       new NumberProperty(Constants.getPropertyNameIncomePercentageFor(playerId),
//           null, 999, 0, 100));
// Captures `data` (via self.data). The Editable_Property shim only
// stores the property name; max=999/min=0/value=100 from the Java
// NumberProperty constructor are not observable through the shim.
game_parser_lambda_parse_properties_20 :: proc(self: ^Game_Parser, player_id: ^Game_Player) {
	prop := new(Editable_Property)
	prop.name = constants_get_property_name_income_percentage_for(player_id)
	game_properties_add_player_property(game_data_get_properties(self.data), prop)
}

// Synthetic forEach lambda from parseProperties (#21):
//   playerId -> data.getProperties().addPlayerProperty(
//       new NumberProperty(Constants.getPropertyNamePuIncomeBonusFor(playerId),
//           null, 999, 0, 0));
game_parser_lambda_parse_properties_21 :: proc(self: ^Game_Parser, player_id: ^Game_Player) {
	prop := new(Editable_Property)
	prop.name = constants_get_property_name_pu_income_bonus_for(player_id)
	game_properties_add_player_property(game_data_get_properties(self.data), prop)
}

// Java: private void parseDelegates(final List<GamePlay.Delegate> delegateList)
//   for each: load class via xmlGameElementMapper.newDelegate(className),
//   throw GameParseException("Class <%s> is not a delegate.") on miss,
//   then delegate.initialize(name, displayName ?? name) and
//   data.addDelegate(delegate).
game_parser_parse_delegates :: proc(
	self: ^Game_Parser,
	delegate_list: [dynamic]^Game_Play_Delegate,
) {
	for current in delegate_list {
		class_name := current.java_class
		delegate := xml_game_element_mapper_new_delegate(self.xml_game_element_mapper, class_name)
		if delegate == nil {
			fmt.panicf("Class <%s> is not a delegate.", class_name)
		}
		name := current.name
		display_name := current.display
		if display_name == "" {
			display_name = name
		}
		i_delegate_initialize(delegate, name, display_name)
		game_data_add_delegate(self.data, delegate)
	}
}

// Java: private void parseFrontierRules(
//     final List<Production.ProductionFrontier.FrontierRules> elements,
//     final ProductionFrontier frontier) throws GameParseException
//   for each: frontier.addRule(getProductionRule(element.getName()));
game_parser_parse_frontier_rules :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Production_Frontier_Frontier_Rules,
	frontier: ^Production_Frontier,
) {
	for element in elements {
		production_frontier_add_rule(frontier, game_parser_get_production_rule(self, element.name))
	}
}

// Java: List<GamePlayer> parsePlayersFromIsDisplayedFor(final String encodedPlayerNames)
//   for each `:`-split name: lookup in data.getPlayerList(); throw
//   GameParseException("Parse resources could not find player: %s") on miss.
game_parser_parse_players_from_is_displayed_for :: proc(
	self: ^Game_Parser,
	encoded_player_names: string,
) -> [dynamic]^Game_Player {
	players: [dynamic]^Game_Player
	parts := strings.split(encoded_player_names, ":")
	defer delete(parts)
	for player_name in parts {
		player := player_list_get_player_id(game_data_get_player_list(self.data), player_name)
		if player == nil {
			fmt.panicf("Parse resources could not find player: %s", player_name)
		}
		append(&players, player)
	}
	return players
}

// Java: private void parseProperties(final PropertyList propertyList)
//
// For each property element:
//   - Skip when name is null.
//   - Map the legacy property name via LegacyPropertyMapper.
//   - Pull the value either from the <value> child (valueProperty.data)
//     or the `value` attribute.
//   - If editable is null/false, infer the type and store the casted
//     value as a constant property via properties.set(...).
//   - Otherwise, build the typed editable property (Boolean / Number /
//     String) and add it; for Number, min/max come from current.getMin()
//     / .getMax() with fallback to the embedded number_property tag
//     (mirroring the Java Optional.or(...) chain).
//
// Modeling pragmas:
//   - Property_List_Property models Java's `Boolean editable` /
//     `Integer min` / `Integer max` as plain `bool` / `i32` (zero-default,
//     so we cannot distinguish unset from zero). The min/max fallback
//     therefore consults the embedded number_property whenever it is
//     present, instead of strictly only when current.min/max is null.
//   - The Editable_Property shim only carries `name`; the typed Boolean
//     / Number / String property values are not stored through the shim
//     in this port, but the property_name registration matches Java.
//
// After processing properties, add an Income_Percentage and a
// Pu_Income_Bonus per-player NumberProperty, mirroring the Java
// `data.getPlayerList().forEach(...)` pair.
game_parser_parse_properties :: proc(self: ^Game_Parser, property_list: ^Property_List) {
	properties := game_data_get_properties(self.data)

	for current in property_list_get_properties(property_list) {
		if current.name == "" {
			continue
		}
		property_name := legacy_property_mapper_map_property_name(current.name)

		// Optional.ofNullable(current.getValueProperty()).map(Value::getData)
		//     .orElseGet(current::getValue)
		value: string
		if current.value_property != nil {
			value = current.value_property.data
		} else {
			value = current.value
		}

		if !current.editable {
			casted_value := property_value_type_inference_cast_to_inferred_type(value)
			boxed := new(Property_Value)
			boxed^ = casted_value
			game_properties_set(properties, property_name, rawptr(boxed))
		} else {
			data_type := property_value_type_inference_infer_type(value)
			ep := new(Editable_Property)
			ep.name = property_name

			if data_type == typeid_of(bool) {
				_ = strings.equal_fold(value, "true") // matches BooleanProperty default
			} else if data_type == typeid_of(i32) {
				min_val := current.min
				if current.number_property != nil {
					if v, ok := game_parser_lambda_parse_properties_18(current); ok {
						min_val = v
					}
				}
				max_val := current.max
				if current.number_property != nil {
					if v, ok := game_parser_lambda_parse_properties_19(current); ok {
						max_val = v
					}
				}
				int_val: i32 = 0
				if value != "" {
					parsed, _ := strconv.parse_int(value, 10)
					int_val = i32(parsed)
				}
				_, _, _ = min_val, max_val, int_val // NumberProperty fields not stored through Editable_Property shim
			}

			game_properties_add_editable_property(properties, ep)
		}
	}

	for player_id in player_list_get_players(game_data_get_player_list(self.data)) {
		game_parser_lambda_parse_properties_20(self, player_id)
	}
	for player_id in player_list_get_players(game_data_get_player_list(self.data)) {
		game_parser_lambda_parse_properties_21(self, player_id)
	}
}

// Java: private void parseRepairFrontierRules(
//     final List<Production.RepairFrontier.RepairRules> elements,
//     final RepairFrontier frontier) throws GameParseException
//   for each: frontier.addRule(getRepairRule(element.getName()));
game_parser_parse_repair_frontier_rules :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Repair_Frontier_Repair_Rules,
	frontier: ^Repair_Frontier,
) {
	for element in elements {
		repair_frontier_add_rule(frontier, game_parser_get_repair_rule(self, element.name))
	}
}

// Java: private void parseResults(final Rule dataRule, final Production.Rule mapRule)
//   List<Production.Rule.Result> ruleResults = mapRule.getRuleResults();
//   if empty: throw GameParseException("No results for rule: %s")
//   for each: locate either Resource or UnitType by name (Optional.or chain),
//   throw GameParseException("Could not find resource or unit: %s") on miss,
//   then dataRule.addResult(result.get(), quantity).
//
// Modeling pragma: Java's `Production.Rule` parent is modeled as the
// empty placeholder `Map_Data_Production_Rule`; its only useful payload
// (`getRuleResults()`) is type-specific to the concrete subclass
// (Production_Production_Rule vs Production_Repair_Rule). Callers
// extract the results list themselves and pass it directly here.
game_parser_parse_results :: proc(
	self: ^Game_Parser,
	data_rule: ^Rule,
	rule_results: [dynamic]^Production_Rule_Result,
) {
	if len(rule_results) == 0 {
		fmt.panicf("No results for rule: %s", rule_get_name(data_rule))
	}
	for current in rule_results {
		resource_or_unit := current.resource_or_unit
		result_resource := game_parser_get_resource_optional(self, resource_or_unit)
		result_unit_type: ^Unit_Type
		if result_resource == nil {
			result_unit_type = game_parser_get_unit_type_optional(self, resource_or_unit)
		}
		if result_resource == nil && result_unit_type == nil {
			fmt.panicf("Could not find resource or unit: %s", resource_or_unit)
		}
		quantity := current.quantity
		if result_resource != nil {
			rule_add_result(data_rule, &result_resource.named_attachable, quantity)
		} else {
			rule_add_result(data_rule, &result_unit_type.named_attachable, quantity)
		}
	}
}

// Java: private void parseConnections(
//     final List<org.triplea.map.data.elements.Map.Connection> connections)
//     throws GameParseException
//   for each: addConnection(getTerritory(t1), getTerritory(t2)).
game_parser_parse_connections :: proc(
	self: ^Game_Parser,
	connections: [dynamic]^Map_Connection,
) {
	for current in connections {
		t1 := game_parser_get_territory(self, current.t1)
		t2 := game_parser_get_territory(self, current.t2)
		game_map_add_connection(game_data_get_map(self.data), t1, t2)
	}
}

// Java: private void parseCategoryTechs(
//     final List<Technology.PlayerTech.Category.Tech> elements,
//     final TechnologyFrontier frontier) throws GameParseException
//   For each tech: look up by property first, then by name on the
//   data-wide TechnologyFrontier; throw "Could not find technology: %s"
//   on miss; otherwise frontier.addAdvance(ta).
game_parser_parse_category_techs :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Technology_Player_Tech_Category_Tech,
	frontier: ^Technology_Frontier,
) {
	all_techs := game_data_get_technology_frontier(self.data)
	for current in elements {
		ta := technology_frontier_get_advance_by_property(all_techs, current.name)
		if ta == nil {
			ta = technology_frontier_get_advance_by_name(all_techs, current.name)
		}
		if ta == nil {
			fmt.panicf("Could not find technology: %s", current.name)
		}
		technology_frontier_add_advance(frontier, ta)
	}
}

// Java: private void parseSteps(final List<GamePlay.Sequence.Step> stepList)
//     throws GameParseException
//
// For each Step:
//   - resolve delegate via getDelegate(current.getDelegate()) (throws on miss);
//   - resolve player via getPlayerIdOptional(current.getPlayer()).orElse(null);
//   - if player is null but the XML named one (non-blank), throw
//     "The step %s wants a player with the name of ''%s''..." matching
//     Java's doubled-single-quote literal text;
//   - parse step properties;
//   - displayName follows the Java `null + isBlank` pattern: stays null
//     when display is whitespace-only (`isBlank()` true), otherwise
//     copied verbatim (including null/empty);
//   - construct the GameStep and apply maxRunCount when present and > 0;
//   - data.getSequence().addStep(step).
//
// Modeling pragma: Game_Play_Sequence_Step.display / .player are plain
// `string` (no Optional<String>). We treat empty string as Java's null.
// The Java `current.getMaxRunCount() != null && > 0` guard becomes
// `current.max_run_count != nil && current.max_run_count^ > 0`.
game_parser_parse_steps :: proc(
	self: ^Game_Parser,
	step_list: [dynamic]^Game_Play_Sequence_Step,
) {
	for current in step_list {
		delegate := game_parser_get_delegate(self, current.delegate)
		player := game_parser_get_player_id_optional(self, current.player)
		if player == nil && current.player != "" && strings.trim_space(current.player) != "" {
			fmt.panicf(
				"The step %s wants a player with the name of '%s', but that player cannot be found. Make sure the player's name is spelled correctly.",
				current.name,
				current.player,
			)
		}
		name := current.name
		step_properties := game_parser_parse_step_properties(current.step_properties)
		// Java: displayName = null;
		//       if (current.getDisplay() == null || !current.getDisplay().isBlank())
		//           displayName = current.getDisplay();
		display_name := ""
		if current.display == "" || strings.trim_space(current.display) != "" {
			display_name = current.display
		}
		step := game_step_new(name, display_name, player, delegate, self.data, step_properties)
		if current.max_run_count != nil && current.max_run_count^ > 0 {
			game_step_set_max_run_count(step, current.max_run_count^)
		}
		game_sequence_add_step(game_data_get_sequence(self.data), step)
	}
}

// Java: private void parseUnitPlacement(
//     final List<Initialize.UnitInitialize.UnitPlacement> elements)
//     throws GameParseException
//
// For each placement element:
//   - resolve territory and unit type (both throw on miss);
//   - hits := Optional.ofNullable(hitsTaken).orElse(0); enforce
//     `0 <= hits <= unitAttachment.hitPoints - 1`;
//   - unitDamage := Optional.ofNullable(unitDamage).orElse(0);
//     enforce `>= 0`;
//   - if owner is null/blank, owner = territory.getData().getPlayerList()
//     .getNullPlayer(); else owner = getPlayerIdOptional(...).orElse(null);
//   - territory.getUnitCollection().addAll(type.create(quantity, owner,
//     false, hits, unitDamage)).
game_parser_parse_unit_placement :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Initialize_Unit_Initialize_Unit_Placement,
) {
	for current in elements {
		territory := game_parser_get_territory(self, current.territory)
		type := game_parser_get_unit_type(self, current.unit_type)
		owner_string := current.owner
		hits: i32 = 0
		if current.hits_taken != nil {
			hits = current.hits_taken^
		}
		max_hits := unit_attachment_get_hit_points(unit_type_get_unit_attachment(type)) - 1
		if hits < 0 || hits > max_hits {
			fmt.panicf(
				"Unit placement issue for unit type %s in territory %s: hitsTaken is %d, but cannot be less than zero or greater than %d (one less than total hitPoints)",
				default_named_get_name(&type.named_attachable.default_named),
				default_named_get_name(&territory.named_attachable.default_named),
				hits,
				max_hits,
			)
		}

		unit_damage: i32 = 0
		if current.unit_damage != nil {
			unit_damage = current.unit_damage^
		}
		if unit_damage < 0 {
			fmt.panicf(
				"Unit placement issue for unit type %s in territory %s: unitDamage is %d, but cannot be less than zero",
				default_named_get_name(&type.named_attachable.default_named),
				default_named_get_name(&territory.named_attachable.default_named),
				unit_damage,
			)
		}

		owner: ^Game_Player
		if owner_string == "" || strings.trim_space(owner_string) == "" {
			territory_data := game_data_component_get_data(
				&territory.named_attachable.default_named.game_data_component,
			)
			owner = player_list_get_null_player(game_data_get_player_list(territory_data))
		} else {
			owner = game_parser_get_player_id_optional(self, current.owner)
		}
		quantity := current.quantity
		units := unit_type_create_5(type, quantity, owner, false, hits, unit_damage)
		unit_collection_add_all(territory_get_unit_collection(territory), units)
	}
}

// Java: private List<Tuple<String, String>> setOptions(
//     final IAttachment attachment,
//     final List<AttachmentList.Attachment.Option> options,
//     final Map<String, String> foreach) throws GameParseException
//
// For each option element:
//   - skip when name or value is null (modeled here as empty);
//   - decapitalize the option name and run it through the legacy
//     property-name mapper (the Java code also calls .intern(); the
//     Odin port has no string-intern table — semantically equivalent
//     for a referentially-pure pipeline);
//   - throw when the resulting name is empty;
//   - skip names the legacy mapper says to ignore;
//   - countAndValue := count.isNullOrEmpty ? value : count + ":" + value;
//   - skip if any empty foreach variable substring appears in
//     countAndValue (mirrors containsEmptyForeachVariable);
//   - apply foreach + variable interpolation, then the legacy
//     option-value mapper;
//   - look up the property on the attachment (panic on miss — Java
//     throws GameParseException via Optional.orElseThrow with the
//     message text built by lambda_set_options_24 above) and call
//     setValue(finalValue). MutableProperty.setValue dispatches to
//     setStringValue when value is a String; finalValue is always a
//     String here, so we route through mutable_property_set_string_value.
//   - record (name, finalValue) in the result list.
//
// Modeling pragma: Java's outer try/catch rewraps unrelated
// RuntimeExceptions into a GameParseException carrying `xmlUri` and
// `attachment`. Odin panics propagate unchanged; we forfeit the
// rewrap (it only affects the human-readable error text on a fail
// path that real games never hit) but preserve every observable
// success-path effect.
game_parser_set_options :: proc(
	self: ^Game_Parser,
	attachment: ^I_Attachment,
	options: [dynamic]^Attachment_List_Attachment_Option,
	foreach: map[string]string,
) -> [dynamic]^Tuple(string, string) {
	results: [dynamic]^Tuple(string, string)
	for option in options {
		option_name := option.name
		value := option.value
		if option_name == "" || value == "" {
			continue
		}
		// decapitalize the property name for backwards compatibility
		name := legacy_property_mapper_map_legacy_option_name(
			game_parser_decapitalize(option_name),
		)
		if name == "" {
			fmt.panicf(
				"Option name with zero length for attachment: %s",
				i_attachment_get_name(attachment),
			)
		}
		if legacy_property_mapper_ignore_option_name(name, value) {
			continue
		}
		count := option.count
		count_and_value: string
		if count == "" {
			count_and_value = value
		} else {
			count_and_value = fmt.aprintf("%s:%s", count, value)
		}
		if game_parser_contains_empty_foreach_variable(count_and_value, foreach) {
			continue // Skip adding option if contains empty foreach variable
		}
		value_with_foreach := game_data_variables_replace_foreach_variables(
			count_and_value,
			foreach,
		)
		interpolated_value := game_data_variables_replace_variables(
			self.variables,
			value_with_foreach,
		)
		final_value := legacy_property_mapper_map_legacy_option_value(
			name,
			interpolated_value,
		)
		prop := i_attachment_get_property_or_throw(attachment, name)
		_ = mutable_property_set_string_value(prop, final_value)
		append(&results, tuple_new(string, string, name, final_value))
	}
	_ = self.xml_uri // Java rewraps unexpected exceptions with xmlUri; see modeling pragma.
	return results
}

// Synthetic map lambda from parseRelationshipTypes (#14):
//   name -> new RelationshipType(name, data)
// Captures `data` (via self.data).
game_parser_lambda_parse_relationship_types_14 :: proc(self: ^Game_Parser, name: string) -> ^Relationship_Type {
	return relationship_type_new(name, self.data)
}

// Synthetic forEach lambda from parseTerritoryEffects (#15):
//   name -> data.getTerritoryEffectList().put(name, new TerritoryEffect(name, data))
// Captures `data` (via self.data). Mirrors the Java side's direct
// `Map.put` on TerritoryEffectList; the Odin port models
// TerritoryEffectList as `map[string]^Territory_Effect` exposed
// directly through `game_data_get_territory_effect_list`.
game_parser_lambda_parse_territory_effects_15 :: proc(self: ^Game_Parser, name: string) {
	tel := game_data_get_territory_effect_list(self.data)
	tel[name] = territory_effect_new(name, self.data)
}

// Java: private Attachable findAttachment(
//     final AttachmentList.Attachment element,
//     final String type,
//     final Map<String, String> foreach) throws GameParseException
//
// Replaces foreach variables in the `attachTo` value, then dispatches by
// type to the appropriate getter (each of which throws on miss). Mirrors
// the Java switch/`default: throw GameParseException("Type not found...")`.
//
// Modeling pragma: ^Attachable in this port is the function-pointer
// "interface" struct (games/strategy/engine/data/Attachable.odin); concrete
// owners (Unit_Type, Territory, Resource, Territory_Effect, Game_Player,
// Relationship_Type, Tech_Advance) are returned via raw pointer cast,
// matching the convention used elsewhere in odin_flat/ (see e.g.
// `cast(^Attachable)type` in unit_support_attachment_new and
// `ta.attached_to = cast(^Attachable)self` in game_player.odin).
game_parser_find_attachment :: proc(
	self: ^Game_Parser,
	element: ^Attachment_List_Attachment,
	type: string,
	foreach: map[string]string,
) -> ^Attachable {
	attach_to := game_data_variables_replace_foreach_variables(element.attach_to, foreach)
	switch type {
	case "unitType":
		return cast(^Attachable)game_parser_get_unit_type(self, attach_to)
	case "territory":
		return cast(^Attachable)game_parser_get_territory(self, attach_to)
	case "resource":
		return cast(^Attachable)game_parser_get_resource_or_throw(self, attach_to)
	case "territoryEffect":
		return cast(^Attachable)game_parser_get_territory_effect(self, attach_to)
	case "player":
		return cast(^Attachable)game_parser_get_player_id(self, attach_to)
	case "relationship":
		return cast(^Attachable)game_parser_get_relationship_type(self, attach_to)
	case "technology":
		return cast(^Attachable)game_parser_get_technology(self, attach_to)
	case:
		fmt.panicf("Type not found to attach to: %s", type)
	}
	return nil
}

// Java: private void parseTerritories(
//     final List<org.triplea.map.data.elements.Map.Territory> territories)
//   for each: data.getMap().addTerritory(
//       new Territory(current.getName(),
//                     Optional.ofNullable(current.getWater()).orElse(false),
//                     data));
// Modeling pragma: Map_Territory.water is a plain `bool` (not Optional<Boolean>);
// the Odin default of `false` already matches Java's orElse(false).
game_parser_parse_territories :: proc(
	self: ^Game_Parser,
	territories: [dynamic]^Map_Territory,
) {
	for current in territories {
		is_water := current.water
		game_map_add_territory(
			game_data_get_map(self.data),
			territory_new(current.name, is_water, self.data),
		)
	}
}

// Java: private void parseAlliances(final Game game) throws GameParseException
//
// 1. For each <alliance> entry in game.getPlayerList().getAlliances(),
//    add (player, allianceName) to AllianceTracker.
// 2. For each player in data.getPlayerList():
//    - allies = allianceTracker.getAllies(currentPlayer)
//    - enemies = HashSet<>(players); enemies.removeAll(allies)
//    - both sets remove currentPlayer
//    - setRelationship(self, ally, defaultAlliedRelationship)
//    - setRelationship(self, enemy, defaultWarRelationship)
game_parser_parse_alliances :: proc(self: ^Game_Parser, game: ^Game) {
	alliance_tracker := game_data_get_alliance_tracker(self.data)
	players := player_list_get_players(game_data_get_player_list(self.data))

	for current in xml_player_list_get_alliances(game_get_player_list(game)) {
		p1 := game_parser_get_player_id(self, current.player)
		alliance := current.alliance
		alliance_tracker_add_to_alliance(alliance_tracker, p1, alliance)
	}

	relationship_tracker := game_data_get_relationship_tracker(self.data)
	relationship_type_list := game_data_get_relationship_type_list(self.data)

	for current_player in players {
		// Java: Set<GamePlayer> allies = allianceTracker.getAllies(currentPlayer);
		allies := alliance_tracker_get_allies(alliance_tracker, current_player)
		// Java: Set<GamePlayer> enemies = new HashSet<>(players); enemies.removeAll(allies);
		enemies: map[^Game_Player]struct {}
		for p in players {
			enemies[p] = {}
		}
		for ally in allies {
			delete_key(&enemies, ally)
		}
		// remove self from enemies and from allies
		delete_key(&enemies, current_player)
		delete_key(&allies, current_player)

		default_allied := relationship_type_list_get_default_allied_relationship(
			relationship_type_list,
		)
		for allied_player in allies {
			relationship_tracker_set_relationship(
				relationship_tracker,
				current_player,
				allied_player,
				default_allied,
			)
		}
		default_war := relationship_type_list_get_default_war_relationship(
			relationship_type_list,
		)
		for enemy_player in enemies {
			relationship_tracker_set_relationship(
				relationship_tracker,
				current_player,
				enemy_player,
				default_war,
			)
		}
	}
}

// Java: private void parseRelationInitialize(
//     final Initialize.RelationshipInitialize relations) throws GameParseException
//   if (!relations.getRelationships().isEmpty()) {
//     final RelationshipTracker tracker = data.getRelationshipTracker();
//     for each: tracker.setRelationship(p1, p2, r, roundValue);
//   }
// The 4-arg setRelationship is `relationship_tracker_set_relationship_with_round`.
game_parser_parse_relation_initialize :: proc(
	self: ^Game_Parser,
	relations: ^Initialize_Relationship_Initialize,
) {
	if len(relations.relationships) == 0 {
		return
	}
	tracker := game_data_get_relationship_tracker(self.data)
	for current in relations.relationships {
		p1 := game_parser_get_player_id(self, current.player1)
		p2 := game_parser_get_player_id(self, current.player2)
		r := game_parser_get_relationship_type(self, current.type)
		round_value := current.round_value
		relationship_tracker_set_relationship_with_round(tracker, p1, p2, r, round_value)
	}
}

// Java: private void parseOwner(final Initialize.OwnerInitialize elements)
//   for each: getTerritory(t).setOwner(getPlayerId(owner));
game_parser_parse_owner :: proc(
	self: ^Game_Parser,
	elements: ^Initialize_Owner_Initialize,
) {
	for current in elements.territory_owners {
		territory := game_parser_get_territory(self, current.territory)
		owner := game_parser_get_player_id(self, current.owner)
		territory_set_owner(territory, owner)
	}
}

// Java: private void parseHeldUnits(final List<Initialize.UnitInitialize.HeldUnits> elements)
//   for each: player.getUnitCollection().addAll(type.create(quantity, player));
// `type.create(quantity, player)` is the 2-arg overload → unit_type_create_2.
game_parser_parse_held_units :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Initialize_Unit_Initialize_Held_Units,
) {
	for current in elements {
		player := game_parser_get_player_id(self, current.player)
		type := game_parser_get_unit_type(self, current.unit_type)
		quantity := current.quantity
		units := unit_type_create_2(type, quantity, player)
		unit_collection_add_all(game_player_get_unit_collection(player), units)
	}
}

// Java: private void parseResourceInitialization(
//     final Initialize.ResourceInitialize elements) throws GameParseException
//   for each: player.getResources().addResource(resource, quantity);
game_parser_parse_resource_initialization :: proc(
	self: ^Game_Parser,
	elements: ^Initialize_Resource_Initialize,
) {
	for current in elements.resources_given {
		player := game_parser_get_player_id(self, current.player)
		resource := game_parser_get_resource_or_throw(self, current.resource)
		quantity := current.quantity
		resource_collection_add_resource(game_player_get_resources(player), resource, quantity)
	}
}

// Java: private void parseProductionFrontiers(
//     final List<Production.ProductionFrontier> elements) throws GameParseException
//   for each: build new ProductionFrontier(name, data), parseFrontierRules(...),
//   then frontiers.addProductionFrontier(frontier).
game_parser_parse_production_frontiers :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Production_Frontier,
) {
	frontiers := game_data_get_production_frontier_list(self.data)
	for current in elements {
		name := current.name
		frontier := production_frontier_new(name, self.data)
		game_parser_parse_frontier_rules(self, current.frontier_rules, frontier)
		production_frontier_list_add_production_frontier(frontiers, frontier)
	}
}

// Java: private void parseRepairFrontiers(
//     final List<Production.RepairFrontier> elements) throws GameParseException
//
// Modeling pragma: Production_Repair_Frontier.repair_rules is a
// `[dynamic]Production_Repair_Frontier_Repair_Rules` (value, not pointer)
// while `game_parser_parse_repair_frontier_rules` takes a
// `[dynamic]^Production_Repair_Frontier_Repair_Rules`. Rather than
// allocating a parallel pointer slice, we inline the per-element loop
// here (the helper just iterates and calls
// `repair_frontier_add_rule(getRepairRule(element.name))`).
game_parser_parse_repair_frontiers :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Repair_Frontier,
) {
	frontiers := game_data_get_repair_frontier_list(self.data)
	for current in elements {
		name := current.name
		frontier := repair_frontier_new(name, self.data)
		for i in 0 ..< len(current.repair_rules) {
			element := &current.repair_rules[i]
			repair_frontier_add_rule(
				frontier,
				game_parser_get_repair_rule(self, element.name),
			)
		}
		repair_frontier_list_add_repair_frontier(frontiers, frontier)
	}
}

// Java: private void parsePlayerProduction(
//     final List<Production.PlayerProduction> elements) throws GameParseException
//   for each: getPlayerId(player).setProductionFrontier(getProductionFrontier(frontier));
game_parser_parse_player_production :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Player_Production,
) {
	for current in elements {
		player := game_parser_get_player_id(self, current.player)
		frontier := game_parser_get_production_frontier(self, current.frontier)
		game_player_set_production_frontier(player, frontier)
	}
}

// Java: private void parsePlayerRepair(
//     final List<Production.PlayerRepair> elements) throws GameParseException
//   for each: getPlayerId(player).setRepairFrontier(getRepairFrontier(frontier));
game_parser_parse_player_repair :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Player_Repair,
) {
	for current in elements {
		player := game_parser_get_player_id(self, current.player)
		repair_frontier := game_parser_get_repair_frontier(self, current.frontier)
		game_player_set_repair_frontier(player, repair_frontier)
	}
}

// Java: private void parseCategories(
//     final List<Technology.PlayerTech.Category> elements,
//     final TechnologyFrontierList categories) throws GameParseException
//   for each: tf := new TechnologyFrontier(name, data); parseCategoryTechs(techs, tf);
//   categories.addTechnologyFrontier(tf).
game_parser_parse_categories :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Technology_Player_Tech_Category,
	categories: ^Technology_Frontier_List,
) {
	for current in elements {
		technology_frontier := technology_frontier_new(current.name, self.data)
		game_parser_parse_category_techs(self, current.techs, technology_frontier)
		technology_frontier_list_add_technology_frontier(categories, technology_frontier)
	}
}

// Java: private void parseResources(
//     final org.triplea.map.data.elements.ResourceList resourceList)
//     throws GameParseException
//
//   for each Resource element:
//     - if isDisplayedFor is null/empty, build a Resource with the
//       full player list (data.getPlayerList().getPlayers());
//     - else if isDisplayedFor equalsIgnoreCase("NONE") (the
//       RESOURCE_IS_DISPLAY_FOR_NONE constant), build the no-players
//       form via Resource(name, data);
//     - else split isDisplayedFor on ':' via
//       parsePlayersFromIsDisplayedFor and pass the resolved players.
//   then data.getResourceList().addResource(resource).
//
// Modeling pragma: `Xml_Resource_List_Resource.is_displayed_for` is a
// plain `string`; empty string represents Java null/empty (the
// orElse(...) chain collapses both into the first branch).
game_parser_parse_resources :: proc(self: ^Game_Parser, resource_list: ^Xml_Resource_List) {
	for resource in resource_list.resources {
		name := resource.name
		is_displayed_for := resource.is_displayed_for
		if len(is_displayed_for) == 0 {
			players := player_list_get_players(game_data_get_player_list(self.data))
			r := resource_new(name, self.data, players[:])
			resource_list_add_resource(game_data_get_resource_list(self.data), r)
		} else if strings.equal_fold(is_displayed_for, "NONE") {
			r := resource_new_simple(name, self.data)
			resource_list_add_resource(game_data_get_resource_list(self.data), r)
		} else {
			players := game_parser_parse_players_from_is_displayed_for(self, is_displayed_for)
			r := resource_new(name, self.data, players[:])
			resource_list_add_resource(game_data_get_resource_list(self.data), r)
		}
	}
}

// Java: private void parseProductionRules(
//     final List<Production.ProductionRule> elements) throws GameParseException
//   for each: rule = new ProductionRule(current.getName(), data);
//             parseProductionCosts(rule, current.getCosts());
//             parseResults(rule, current);
//             data.getProductionRuleList().addProductionRule(rule).
// `parseResults` in the Odin port takes the rule-results list directly
// (see comment at game_parser_parse_results); we pass current.results.
game_parser_parse_production_rules :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Production_Rule,
) {
	for current in elements {
		name := current.name
		rule := production_rule_new(name, self.data)
		game_parser_parse_production_costs(self, rule, current.costs)
		game_parser_parse_results(self, rule, current.results)
		production_rule_list_add_production_rule(
			game_data_get_production_rule_list(self.data),
			rule,
		)
	}
}

// Java: private void parseRepairRules(
//     final List<Production.RepairRule> elements) throws GameParseException
//   for each: rule = new RepairRule(current.getName(), data);
//             parseRepairCosts(rule, current.getCosts());
//             parseResults(rule, current);
//             data.getRepairRules().addRepairRule(rule).
//
// Modeling pragma: the 2-arg Java RepairRule(name, data) ctor delegates
// to the 4-arg one with `new IntegerMap<>()` for both costs and results;
// the Odin port exposes only the 4-arg `repair_rule_new`, so we pass
// freshly-allocated empty Integer_Maps to mirror the Java default.
game_parser_parse_repair_rules :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Production_Repair_Rule,
) {
	for current in elements {
		rule := repair_rule_new(current.name, self.data, integer_map_new(), integer_map_new())
		game_parser_parse_repair_costs(self, rule, current.costs)
		game_parser_parse_results(self, rule, current.results)
		repair_rules_add_repair_rule(game_data_get_repair_rules(self.data), rule)
	}
}

// Java: private void parsePlayerTech(final List<Technology.PlayerTech> elements)
//     throws GameParseException
//   for each: GamePlayer player = getPlayerId(current.getPlayer());
//             TechnologyFrontierList categories = player.getTechnologyFrontierList();
//             parseCategories(current.getCategories(), categories).
game_parser_parse_player_tech :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Technology_Player_Tech,
) {
	for current in elements {
		player := game_parser_get_player_id(self, current.player)
		categories := game_player_get_technology_frontier_list(player)
		game_parser_parse_categories(self, current.categories, categories)
	}
}

// Java: private void parseTechs(
//     final List<Technology.Technologies.TechName> elements,
//     final TechnologyFrontier allTechsFrontier)
//
// For each TechName(name, tech):
//   - if tech is non-null and not blank, build a GenericTechAdvance
//     wrapping the predefined advance keyed by `tech`;
//   - otherwise, try to look up the predefined advance by `name`;
//     Java catches IllegalArgumentException to fall back to a
//     bare-name GenericTechAdvance with a null inner advance.
//
// Odin pragma: `tech_advance_find_defined_advance_and_create_advance`
// panics on an unknown name (no IllegalArgumentException), so the
// Java try/catch is emulated by probing the predefined-technology
// map up front; only known keys are dispatched, mirroring the Java
// behavior without unwinding panics.
game_parser_parse_techs :: proc(
	self: ^Game_Parser,
	elements: [dynamic]^Technology_Technologies_Tech_Name,
	all_techs_frontier: ^Technology_Frontier,
) {
	for current in elements {
		name := current.name
		tech := current.tech
		ta: ^Tech_Advance
		if len(strings.trim_space(tech)) > 0 {
			inner := tech_advance_find_defined_advance_and_create_advance(tech, self.data)
			gta := generic_tech_advance_new(name, inner, self.data)
			ta = cast(^Tech_Advance)gta
		} else {
			predefined := tech_advance_new_predefined_technology_map()
			defer delete(predefined)
			if _, ok := predefined[name]; ok {
				ta = tech_advance_find_defined_advance_and_create_advance(name, self.data)
			} else {
				gta := generic_tech_advance_new(name, nil, self.data)
				ta = cast(^Tech_Advance)gta
			}
		}
		technology_frontier_add_advance(all_techs_frontier, ta)
	}
}

// Java: private void parseAttachment(
//     final AttachmentList.Attachment current,
//     final Map<String, String> foreach) throws GameParseException
//
// Resolves the target Attachable via findAttachment (defaulting to
// "unitType" when current.getType() is null), substitutes foreach
// variables in the attachment name, applies the legacy spelling
// fix-up ("ttatchment" -> "ttachment"), constructs the IAttachment
// via xmlGameElementMapper.newAttachment(...), wires it onto the
// attachable, applies its options via setOptions, and — when
// collectAttachmentOrderAndValues is true — appends an
// (attachment, optionValues) Tuple to data's attachment-order list.
//
// The orElseThrow synthetic supplier is `game_parser_lambda_parse_attachment_23`.
game_parser_parse_attachment :: proc(
	self: ^Game_Parser,
	current: ^Attachment_List_Attachment,
	foreach: map[string]string,
) {
	class_name := current.java_class
	type := current.type
	if len(type) == 0 {
		type = "unitType"
	}
	attachable := game_parser_find_attachment(self, current, type, foreach)
	name := game_data_variables_replace_foreach_variables(current.name, foreach)
	// Only replace if needed, as replaceAll() can be slow.
	if strings.contains(name, "ttatchment") {
		name, _ = strings.replace_all(name, "ttatchment", "ttachment")
	}
	attachment := xml_game_element_mapper_new_attachment(
		self.xml_game_element_mapper,
		class_name,
		name,
		attachable,
		self.data,
	)
	if attachment == nil {
		game_parser_lambda_parse_attachment_23(class_name)
	}
	// replace-all to automatically correct legacy (1.8) attachment spelling
	attachable_add_attachment(attachable, name, attachment)

	attachment_option_values := game_parser_set_options(
		self,
		attachment,
		current.options,
		foreach,
	)
	// keep a list of attachment references in the order they were added
	if self.collect_attachment_order_and_values {
		game_data_add_to_attachment_order_and_values(
			self.data,
			tuple_new(
				^I_Attachment,
				[dynamic]^Tuple(string, string),
				attachment,
				attachment_option_values,
			),
		)
	}
}
