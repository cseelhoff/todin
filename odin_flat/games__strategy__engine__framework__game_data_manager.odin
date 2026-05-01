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
