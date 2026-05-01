package game

// JDK shim: java.util.prefs.Preferences. Single-process snapshot harness;
// preferences are kept in-memory only.

Preferences :: struct {
	values: map[string]string,
}

preferences_new :: proc() -> ^Preferences {
	p := new(Preferences)
	p.values = make(map[string]string)
	return p
}

preferences_user_node_for_package :: proc() -> ^Preferences {
	return preferences_new()
}

preferences_get :: proc(self: ^Preferences, key: string, default_value: string) -> string {
	if self == nil {
		return default_value
	}
	if v, ok := self.values[key]; ok {
		return v
	}
	return default_value
}

preferences_put :: proc(self: ^Preferences, key: string, value: string) {
	if self == nil {
		return
	}
	self.values[key] = value
}

preferences_remove :: proc(self: ^Preferences, key: string) {
	if self == nil {
		return
	}
	delete_key(&self.values, key)
}

preferences_flush :: proc(self: ^Preferences) {
	// No-op in snapshot harness.
}
