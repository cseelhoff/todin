package game

// Java: games.strategy.triplea.settings.GameSetting<T> (interface)
// Modelled as a vtable struct. Concrete subclasses (e.g. ClientSetting<T>)
// populate `concrete` and `get_value` in their constructor. The Java
// generic `T` is erased to `rawptr` here — callers cast back to the
// concrete type they expect.

Game_Setting :: struct {
        concrete:  rawptr,
        // Optional<T> getValue(): returns (value_ptr, present).
        get_value: proc(self: ^Game_Setting) -> (rawptr, bool),
}

// Java: default T GameSetting.getValueOrThrow()
//   return getValue().orElseThrow();
game_setting_get_value_or_throw :: proc(self: ^Game_Setting) -> rawptr {
        v, ok := self.get_value(self)
        if !ok {
                panic("GameSetting.getValueOrThrow: no value present")
        }
        return v
}
