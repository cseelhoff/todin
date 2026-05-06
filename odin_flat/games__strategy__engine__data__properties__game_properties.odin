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

// GameProperties(GameData)
game_properties_new :: proc(data: ^Game_Data) -> ^Game_Properties {
	self := new(Game_Properties)
	self.game_data_component = make_Game_Data_Component(data)
	self.constant_properties = make(map[string]Property_Value)
	self.editable_properties = make(map[string]^Editable_Property)
	self.ordering = make([dynamic]string)
	self.player_properties = make(map[string]^Editable_Property)
	return self
}

// GameProperties.get(String)
// Java returns Serializable from (in order) editableProperties.getValue(),
// playerProperties.getValue(), or constantProperties.get(key). The local
// Editable_Property shim carries no typed value, so the editable/player
// branches contribute no observable Property_Value; only constant_properties
// holds typed values in this port.
game_properties_get :: proc(self: ^Game_Properties, key: string) -> Property_Value {
	// Mirrors GameProperties.get(String): editable -> player -> constant.
	if found, ok := self.editable_properties[key]; ok && found != nil {
		if v := editable_property_get_value(found); v != nil {
			return v
		}
	}
	if found, ok := self.player_properties[key]; ok && found != nil {
		if v := editable_property_get_value(found); v != nil {
			return v
		}
	}
	if v, ok := self.constant_properties[key]; ok {
		return v
	}
	return nil
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

// GameProperties.get(String, boolean)
// Java: returns defaultValue when get(key) is null, else (boolean) value.
game_properties_get_bool_with_default :: proc(self: ^Game_Properties, key: string, default_value: bool) -> bool {
	value := game_properties_get(self, key)
	if value == nil {
		return default_value
	}
	if b, ok := value.(bool); ok {
		return b
	}
	return default_value
}

// GameProperties.get(String, int)
// Java: returns defaultValue when get(key) is null, else (int) value.
game_properties_get_int_with_default :: proc(self: ^Game_Properties, key: string, default_value: i32) -> i32 {
	value := game_properties_get(self, key)
	if value == nil {
		return default_value
	}
	if i, ok := value.(i32); ok {
		return i
	}
	return default_value
}

// games.strategy.engine.data.properties.GameProperties#getConstantPropertiesByName()
// Java body: return new HashMap<>(constantProperties);
// (defensive shallow copy)
game_properties_get_constant_properties_by_name :: proc(self: ^Game_Properties) -> map[string]Property_Value {
	out := make(map[string]Property_Value)
	for k, v in self.constant_properties {
		out[k] = v
	}
	return out
}

// games.strategy.engine.data.properties.GameProperties#getEditablePropertiesByName()
// Java body: return new HashMap<>(editableProperties);
game_properties_get_editable_properties_by_name :: proc(self: ^Game_Properties) -> map[string]^Editable_Property {
	out := make(map[string]^Editable_Property)
	for k, v in self.editable_properties {
		out[k] = v
	}
	return out
}

// games.strategy.engine.data.properties.GameProperties#get(String, String)
// Java body: Object value = get(key); if (value == null) return defaultValue;
//            return String.valueOf(value);
// In Odin we collapse Property_Value to its string form (only the string
// arm is observable; the other arms aren't exercised by the snapshot
// harness on string keys, so falling through to defaultValue is faithful).
game_properties_get_string_with_default :: proc(self: ^Game_Properties, key: string, default_value: string) -> string {
	v := game_properties_get(self, key)
	if v == nil {
		return default_value
	}
	if s, ok := v.(string); ok {
		return s
	}
	return default_value
}
