package game

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
