package game

import "core:io"

Game_Object_Input_Stream :: struct {
	using object_input_stream: Object_Input_Stream,
	data_source:  ^Game_Object_Stream_Factory,
	input:        io.Reader,
}

make_Game_Object_Input_Stream :: proc(factory: ^Game_Object_Stream_Factory, input: io.Reader) -> ^Game_Object_Input_Stream {
	stream := new(Game_Object_Input_Stream)
	stream.data_source = factory
	stream.input = input
	return stream
}

game_object_input_stream_get_data :: proc(self: ^Game_Object_Input_Stream) -> ^Game_Data {
	return game_object_stream_factory_get_data(self.data_source)
}

// games.strategy.engine.data.GameObjectInputStream#resolveObject(java.lang.Object)
//
// Java's overridden ObjectInputStream.resolveObject dispatches on the
// runtime type of the deserialized object: GameData → swap in the
// dataSource's live GameData; GameObjectStreamData → resolve to the
// corresponding live Named via getReference; Unit → resolveUnit; anything
// else → return as-is. Since Odin lacks Java's `instanceof`, we model the
// java.lang.Object input as a typed union of the three dispatch arms plus
// a passthrough rawptr for the fallback case (matching the same dispatch
// the output-stream replaceObject port relies on).
Resolve_Object_Input :: union {
	^Game_Data,
	^Game_Object_Stream_Data,
	^Unit,
	rawptr,
}

Resolve_Object_Output :: union {
	^Game_Data,
	^Named,
	^Unit,
	rawptr,
}

game_object_input_stream_resolve_object :: proc(self: ^Game_Object_Input_Stream, obj: Resolve_Object_Input) -> Resolve_Object_Output {
	switch v in obj {
	case ^Game_Data:
		return game_object_stream_factory_get_data(self.data_source)
	case ^Game_Object_Stream_Data:
		return game_object_stream_data_get_reference(v, game_object_input_stream_get_data(self))
	case ^Unit:
		return game_object_input_stream_resolve_unit(self, v)
	case rawptr:
		return v
	}
	return nil
}

// games.strategy.engine.data.GameObjectInputStream#resolveUnit(Unit)
//
// Java acquires a read lock on the game data, then looks up the unit by id
// in the data's UnitsList. If a local copy already exists, it is returned
// (preserving == identity across deserialization). Otherwise, when the
// ClientSetting.showSerializeFeatures flag is set, Java rebuilds the unit
// via `new Unit(id, type, owner, data)`; otherwise it reuses the incoming
// unit. The chosen unit is registered in the UnitsList and returned.
//
// The single-threaded port treats the read lock as a no-op (matches
// game_data_acquire_read_lock) and the showSerializeFeatures branch as
// always-false, since ClientSetting is not ported. This preserves the
// dominant runtime behavior: reuse the deserialized unit instance.
game_object_input_stream_resolve_unit :: proc(self: ^Game_Object_Input_Stream, unit: ^Unit) -> ^Unit {
	data := game_object_stream_factory_get_data(self.data_source)
	game_data_acquire_read_lock(data)
	local := units_list_get(game_data_get_units(data), unit.id)
	if local != nil {
		return local
	}
	new_local := unit
	units_list_put(game_data_get_units(data), new_local)
	return new_local
}
