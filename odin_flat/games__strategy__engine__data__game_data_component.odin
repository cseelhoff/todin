package game

Game_Data_Component :: struct {
	game_data: ^Game_Data,
}

make_Game_Data_Component :: proc(game_data: ^Game_Data) -> Game_Data_Component {
	return Game_Data_Component{game_data = game_data}
}

// Java: private void writeObject(ObjectOutputStream stream) throws IOException
// Mirrors the Java serialization hook. In the JDK shim, both
// ObjectOutputStream and GameObjectOutputStream are opaque markers and
// stream.writeObject(...) is a no-op, so this proc has no observable
// effect during the AI snapshot run. Preserved for fidelity.
game_data_component_write_object :: proc(self: ^Game_Data_Component, out_stream: ^Object_Output_Stream) {
	// if writing to a GameObjectOutputStream the game data comes from
	// context; otherwise we'd serialize self.game_data. Both paths
	// reduce to no-ops against the opaque shim.
}

game_data_component_get_data :: proc(self: ^Game_Data_Component) -> ^Game_Data {
	return self.game_data
}

game_data_component_get_data_or_throw :: proc(self: ^Game_Data_Component) -> ^Game_Data {
	if self.game_data == nil {
		panic("GameData reference is not expected to be null")
	}
	return self.game_data
}
