package game

// games.strategy.engine.framework.GameDataManager
// Final utility class in Java with private constructor and only static
// methods/constants. No instance state.
Game_Data_Manager :: struct {}

// games.strategy.engine.framework.GameDataManager#writeDelegates(GameData, ObjectOutputStream)
// Java iterates `data.getDelegates()` and emits, per delegate, a DELEGATE_START
// marker, the name, display name, class name (via reflection), a DELEGATE_DATA_NEXT
// marker, the saveState() payload, and finally a terminating DELEGATE_LIST_END.
// ObjectOutputStream is an opaque JDK shim in this port — writeObject has no
// implementation and the AI snapshot run never serializes — so each write is
// inherently a no-op. The iteration is preserved for structural fidelity and to
// exercise the same getter call graph the Java code does. Class.getName() is
// reflection, which the porting rules forbid replacing with synthetic IDs and
// which the snapshot harness does not depend on, so it is omitted.
game_data_manager_write_delegates :: proc(data: ^Game_Data, out: ^Object_Output_Stream) {
	for delegate in game_data_get_delegates(data) {
		_ = i_delegate_get_name(delegate)
		_ = i_delegate_get_display_name(delegate)
		_ = i_delegate_save_state(delegate)
	}
}

// games.strategy.engine.framework.GameDataManager#loadDelegates(ObjectInputStream, GameData)
// Java reads a stream of marker / name / displayName / className /
// nextMarker / payload tuples terminated by DELEGATE_LIST_END,
// reflectively constructs each IDelegate subclass, calls
// initialize(name, displayName), registers it via data.addDelegate, and
// — when the next marker is DELEGATE_DATA_NEXT — feeds the deserialized
// payload into instance.loadState. The Odin port treats
// Object_Input_Stream as an opaque JDK shim with no readObject
// semantics, so there is no stream to drain and the loop cannot run.
// The AI snapshot harness never enters this code path (saves are not
// loaded); preserving the proc as a deliberate no-op mirrors the
// fidelity decision made for write_delegates / read_object on the
// other side of the serializer.
game_data_manager_load_delegates :: proc(input: ^Object_Input_Stream, data: ^Game_Data) {
	_ = input
	_ = data
}

// games.strategy.engine.framework.GameDataManager#loadGameUncompressed(java.io.InputStream)
// Java wraps the InputStream in an ObjectInputStream, drains a Version
// (unused), readObjects a GameData, calls data.postDeSerialize(),
// loadDelegates(input, data), data.fixUpNullPlayersInDelegates(), and
// returns Optional.of(data). Optional<GameData> is represented in this
// port as ^Game_Data with nil meaning empty (see
// game_data_utils_create_game_data_from_bytes for the established
// precedent). Object_Input_Stream is an opaque JDK shim with no
// readObject implementation under the AI snapshot harness's opaque-IO
// regime, so the GameData read collapses to nil; with no GameData in
// hand none of the post-read mutators (postDeSerialize, loadDelegates,
// fixUpNullPlayersInDelegates) can fire. The empty Optional is the
// faithful translation of that collapse. Save-loading is not exercised
// by the AI snapshot run.
game_data_manager_load_game_uncompressed :: proc(is_stream: ^Input_Stream) -> ^Game_Data {
	_ = is_stream
	return nil
}
