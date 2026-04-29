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
