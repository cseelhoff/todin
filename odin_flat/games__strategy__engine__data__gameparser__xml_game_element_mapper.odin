package game

import "core:fmt"

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

