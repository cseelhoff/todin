package game

import "core:fmt"

// games.strategy.engine.data.properties.GameProperties
//
// Constant + editable properties. Property_Value is a small union covering
// the JSON primitive types we observe in serialized snapshots.

Property_Value :: union {
	bool,
	i32,
	f64,
	string,
}

Game_Properties :: struct {
	using game_data_component: Game_Data_Component,
	constant_properties: map[string]Property_Value,
	editable_properties: map[string]^Editable_Property,
	ordering: [dynamic]string,
	player_properties: map[string]^Editable_Property,
}

game_properties_add_editable_property :: proc(self: ^Game_Properties, property: ^Editable_Property) {
	self.editable_properties[property.name] = property
	append(&self.ordering, property.name)
}

game_properties_add_player_property :: proc(self: ^Game_Properties, property: ^Editable_Property) {
	self.player_properties[property.name] = property
}

// GameProperties.getEditableProperties()
game_properties_get_editable_properties :: proc(self: ^Game_Properties) -> [dynamic]^Editable_Property {
	properties: [dynamic]^Editable_Property
	for property_name in self.ordering {
		if property, ok := self.editable_properties[property_name]; ok {
			append(&properties, property)
		}
	}
	return properties
}

// GameProperties.getPlayerProperty(String)
// Java returns Optional<IEditableProperty<?>>; in Odin we collapse
// Optional.empty() to a nil pointer.
game_properties_get_player_property :: proc(self: ^Game_Properties, name: string) -> ^Editable_Property {
	property, ok := self.player_properties[name]
	if !ok {
		return nil
	}
	return property
}

// GameProperties.lambda$ensurePropertyPuIncomeBonusFor$1(String, String)
// () -> new IllegalArgumentException("Property not found: %s or %s", ...)
game_properties_lambda_ensure_property_pu_income_bonus_for_1 :: proc(property_key: string, old_property_key: string) -> ^Throwable {
	t := new(Throwable)
	t.message = fmt.aprintf("Property not found: %s or %s", property_key, old_property_key)
	return t
}

// GameProperties.lambda$getPlayerPropertyOrThrow$0(String)
// () -> new IllegalArgumentException("Property not found: %s", ...)
game_properties_lambda_get_player_property_or_throw_0 :: proc(property_key: string) -> ^Throwable {
	t := new(Throwable)
	t.message = fmt.aprintf("Property not found: %s", property_key)
	return t
}

// GameProperties.set(String, java.io.Serializable)
// Serializable is a JDK marker interface; modeled here as rawptr per
// llm-instructions. A nil value unbinds the key (mirrors the Java
// `value == null` branch removing from constantProperties + ordering).
game_properties_set :: proc(self: ^Game_Properties, key: string, value: rawptr) {
	if value == nil {
		delete_key(&self.constant_properties, key)
		for ordered_key, idx in self.ordering {
			if ordered_key == key {
				ordered_remove(&self.ordering, idx)
				break
			}
		}
	} else {
		append(&self.ordering, key)
	}
}
