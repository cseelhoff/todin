package game

import "core:fmt"
import "core:strings"

Xml_Game_Element_Mapper :: struct {
	delegate_factories_by_type_name:   map[string]proc() -> ^I_Delegate,
	attachment_factories_by_type_name: map[string]^Xml_Game_Element_Mapper_Attachment_Factory,
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#handleMissingObject(java.lang.String,java.lang.String)
//
// Java emits a single multi-line slf4j `log.error(...)` describing the missing
// engine object. Odin convention in this port is `fmt.eprintln` (mirrors the
// `messengers_chat_transmitter` / `unit_deserialization_error_lazy_message`
// handling of slf4j logging). The message text is reproduced verbatim, joined
// from the same string literals Java concatenates with `+`.
xml_game_element_mapper_handle_missing_object :: proc(object_type_name: string, object_name: string) {
	fmt.eprintln(
		"Could not find ",
		object_type_name,
		" '",
		object_name,
		"'. This can be a map configuration problem, and would need to be fixed in the ",
		"map XML. Or the map XML is using a feature from a newer game engine version, ",
		"and you will need to install the latest TripleA for it to be enabled. Meanwhile, ",
		"the functionality provided by this ",
		object_type_name,
		" will not available.",
		sep = "",
	)
}

// --- AttachmentFactory adapter procs ----------------------------------------
//
// Java uses constructor method references (`CanalAttachment::new`) to satisfy
// the `AttachmentFactory` SAM interface. Odin's bare `proc` type cannot close
// over a constructor identity, so each builtin attachment gets a tiny adapter
// proc whose body forwards to the corresponding `*_new` constructor and casts
// the concrete result to `^I_Attachment` (the engine's vtable handle).

@(private = "file")
xgem_canal_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)canal_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_player_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)player_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_political_action_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)political_action_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_relationship_type_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)relationship_type_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_rules_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)rules_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_tech_ability_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)tech_ability_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_tech_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)tech_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_territory_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)territory_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_territory_effect_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)territory_effect_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_trigger_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)trigger_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_unit_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)unit_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_unit_support_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)unit_support_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_user_action_attachment_factory_new :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return cast(^I_Attachment)user_action_attachment_new(name, attachable, game_data)
}

@(private = "file")
xgem_make_attachment_factory :: proc(fn: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment) -> ^Xml_Game_Element_Mapper_Attachment_Factory {
	f := new(Xml_Game_Element_Mapper_Attachment_Factory)
	f.new_attachment = fn
	return f
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#newAttachmentFactories(java.util.Map)
//
// Mirrors the Java ImmutableMap.builder() chain: 13 hard-coded class-name keys
// pointing at constructor method-refs, followed by `.putAll(auxiliary)` which
// allows callers (tests) to override or extend the set. The returned map is a
// freshly-allocated `map[string]^Xml_Game_Element_Mapper_Attachment_Factory`.
xml_game_element_mapper_new_attachment_factories :: proc(auxiliary_attachment_factories_by_type_name: map[string]^Xml_Game_Element_Mapper_Attachment_Factory) -> map[string]^Xml_Game_Element_Mapper_Attachment_Factory {
	result := make(map[string]^Xml_Game_Element_Mapper_Attachment_Factory)
	result["CanalAttachment"]            = xgem_make_attachment_factory(xgem_canal_attachment_factory_new)
	result["PlayerAttachment"]           = xgem_make_attachment_factory(xgem_player_attachment_factory_new)
	result["PoliticalActionAttachment"]  = xgem_make_attachment_factory(xgem_political_action_attachment_factory_new)
	result["RelationshipTypeAttachment"] = xgem_make_attachment_factory(xgem_relationship_type_attachment_factory_new)
	result["RulesAttachment"]            = xgem_make_attachment_factory(xgem_rules_attachment_factory_new)
	result["TechAbilityAttachment"]      = xgem_make_attachment_factory(xgem_tech_ability_attachment_factory_new)
	result["TechAttachment"]             = xgem_make_attachment_factory(xgem_tech_attachment_factory_new)
	result["TerritoryAttachment"]        = xgem_make_attachment_factory(xgem_territory_attachment_factory_new)
	result["TerritoryEffectAttachment"]  = xgem_make_attachment_factory(xgem_territory_effect_attachment_factory_new)
	result["TriggerAttachment"]          = xgem_make_attachment_factory(xgem_trigger_attachment_factory_new)
	result["UnitAttachment"]             = xgem_make_attachment_factory(xgem_unit_attachment_factory_new)
	result["UnitSupportAttachment"]      = xgem_make_attachment_factory(xgem_unit_support_attachment_factory_new)
	result["UserActionAttachment"]       = xgem_make_attachment_factory(xgem_user_action_attachment_factory_new)
	for k, v in auxiliary_attachment_factories_by_type_name {
		result[k] = v
	}
	return result
}

// --- TwoIfBySea delegate Suppliers ------------------------------------------

@(private = "file")
xgem_two_if_by_sea_end_turn_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)two_if_by_sea_end_turn_delegate_new()
}

@(private = "file")
xgem_two_if_by_sea_init_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)initialization_delegate_new()
}

@(private = "file")
xgem_two_if_by_sea_place_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)place_delegate_new()
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#newTwoIfBySeaDelegateFactories()
//
// Returns the legacy three-entry map of fully-qualified `games.strategy.twoIfBySea.*`
// type names → IDelegate suppliers. Kept separate from the main delegate map for
// the same backwards-compatibility reason called out in Java's
// @SuppressWarnings("deprecation").
xml_game_element_mapper_new_two_if_by_sea_delegate_factories :: proc() -> map[string]proc() -> ^I_Delegate {
	result := make(map[string]proc() -> ^I_Delegate)
	result["games.strategy.twoIfBySea.delegate.EndTurnDelegate"] = xgem_two_if_by_sea_end_turn_delegate_supplier
	result["games.strategy.twoIfBySea.delegate.InitDelegate"]    = xgem_two_if_by_sea_init_delegate_supplier
	result["games.strategy.twoIfBySea.delegate.PlaceDelegate"]   = xgem_two_if_by_sea_place_delegate_supplier
	return result
}

// --- IDelegate Suppliers (constructor method-ref adapters) ------------------
//
// Java uses `XxxDelegate::new` to satisfy `Supplier<IDelegate>`. Odin's bare
// `proc()` cannot close over a constructor identity, so each builtin delegate
// gets a tiny supplier proc whose body forwards to the corresponding `*_new`
// constructor and casts the concrete result to `^I_Delegate` (the engine's
// vtable handle). Forward-references to constructors defined in higher
// method_layer files are resolved at the package level.

@(private = "file")
xgem_battle_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)battle_delegate_new()
}

@(private = "file")
xgem_bid_place_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)bid_place_delegate_new()
}

@(private = "file")
xgem_bid_purchase_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)bid_purchase_delegate_new()
}

@(private = "file")
xgem_end_round_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)end_round_delegate_new()
}

@(private = "file")
xgem_end_turn_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)end_turn_delegate_new()
}

@(private = "file")
xgem_initialization_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)initialization_delegate_new()
}

@(private = "file")
xgem_move_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)move_delegate_new()
}

@(private = "file")
xgem_no_air_check_place_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)no_air_check_place_delegate_new()
}

@(private = "file")
xgem_no_pu_end_turn_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)no_pu_end_turn_delegate_new()
}

@(private = "file")
xgem_no_pu_purchase_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)no_pu_purchase_delegate_new()
}

@(private = "file")
xgem_place_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)place_delegate_new()
}

@(private = "file")
xgem_politics_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)politics_delegate_new()
}

@(private = "file")
xgem_purchase_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)purchase_delegate_new()
}

@(private = "file")
xgem_random_start_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)random_start_delegate_new()
}

@(private = "file")
xgem_special_move_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)special_move_delegate_new()
}

@(private = "file")
xgem_tech_activation_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)tech_activation_delegate_new()
}

@(private = "file")
xgem_technology_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)technology_delegate_new()
}

@(private = "file")
xgem_user_action_delegate_supplier :: proc() -> ^I_Delegate {
	return cast(^I_Delegate)user_action_delegate_new()
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#newDelegateFactories(java.util.Map)
//
// Mirrors the Java ImmutableMap.builder() chain: 18 hard-coded short-name keys
// pointing at constructor method-refs, followed by the legacy twoIfBySea
// entries via `.putAll(newTwoIfBySeaDelegateFactories())`, and finally
// `.putAll(auxiliary)` so callers (tests) can override or extend the set. The
// returned map is a freshly-allocated `map[string]proc() -> ^I_Delegate`.
xml_game_element_mapper_new_delegate_factories :: proc(auxiliary_delegate_factories_by_type_name: map[string]proc() -> ^I_Delegate) -> map[string]proc() -> ^I_Delegate {
	result := make(map[string]proc() -> ^I_Delegate)
	result["BattleDelegate"]          = xgem_battle_delegate_supplier
	result["BidPlaceDelegate"]        = xgem_bid_place_delegate_supplier
	result["BidPurchaseDelegate"]     = xgem_bid_purchase_delegate_supplier
	result["EndRoundDelegate"]        = xgem_end_round_delegate_supplier
	result["EndTurnDelegate"]         = xgem_end_turn_delegate_supplier
	result["InitializationDelegate"]  = xgem_initialization_delegate_supplier
	result["MoveDelegate"]            = xgem_move_delegate_supplier
	result["NoAirCheckPlaceDelegate"] = xgem_no_air_check_place_delegate_supplier
	result["NoPUEndTurnDelegate"]     = xgem_no_pu_end_turn_delegate_supplier
	result["NoPUPurchaseDelegate"]    = xgem_no_pu_purchase_delegate_supplier
	result["PlaceDelegate"]           = xgem_place_delegate_supplier
	result["PoliticsDelegate"]        = xgem_politics_delegate_supplier
	result["PurchaseDelegate"]        = xgem_purchase_delegate_supplier
	result["RandomStartDelegate"]     = xgem_random_start_delegate_supplier
	result["SpecialMoveDelegate"]     = xgem_special_move_delegate_supplier
	result["TechActivationDelegate"]  = xgem_tech_activation_delegate_supplier
	result["TechnologyDelegate"]      = xgem_technology_delegate_supplier
	result["UserActionDelegate"]      = xgem_user_action_delegate_supplier
	two_if_by_sea := xml_game_element_mapper_new_two_if_by_sea_delegate_factories()
	for k, v in two_if_by_sea {
		result[k] = v
	}
	delete(two_if_by_sea)
	for k, v in auxiliary_delegate_factories_by_type_name {
		result[k] = v
	}
	return result
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#newDelegate(java.lang.String)
//
// Java strips the `games.strategy.triplea.delegate.` prefix via a regex, looks
// up the resulting short name in `delegateFactoriesByTypeName`, and returns
// `Optional<IDelegate>` — present if found, empty (after logging) otherwise.
// Odin convention here is `^I_Delegate` with `nil` standing in for
// `Optional.empty()`.
xml_game_element_mapper_new_delegate :: proc(self: ^Xml_Game_Element_Mapper, type_name: string) -> ^I_Delegate {
	normalized_type_name := type_name
	prefix :: "games.strategy.triplea.delegate."
	if strings.has_prefix(normalized_type_name, prefix) {
		normalized_type_name = normalized_type_name[len(prefix):]
	}
	delegate_factory, ok := self.delegate_factories_by_type_name[normalized_type_name]
	if ok {
		return delegate_factory()
	}
	xml_game_element_mapper_handle_missing_object("delegate", type_name)
	return nil
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper#newAttachment(java.lang.String,java.lang.String,games.strategy.engine.data.Attachable,games.strategy.engine.data.GameData)
//
// Java strips everything up to and including the last '.' from the type name
// (so fully-qualified or short class names both work), looks up the
// `AttachmentFactory` in `attachmentFactoriesByTypeName`, and returns
// `Optional<IAttachment>`. Odin convention here is `^I_Attachment` with `nil`
// standing in for `Optional.empty()`.
xml_game_element_mapper_new_attachment :: proc(self: ^Xml_Game_Element_Mapper, type_name: string, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	short_type_name := type_name
	dot_index := strings.last_index(short_type_name, ".")
	if dot_index != -1 {
		short_type_name = short_type_name[dot_index + 1:]
	}
	attachment_factory, ok := self.attachment_factories_by_type_name[short_type_name]
	if ok {
		return xml_game_element_mapper_attachment_factory_new_attachment(attachment_factory, name, attachable, game_data)
	}
	xml_game_element_mapper_handle_missing_object("attachment", short_type_name)
	return nil
}

