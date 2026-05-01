package game

// `Properties` doubles as the Odin shim for java.util.Properties.
// games.strategy.triplea.Properties is a Java static utility class with no
// instance state, so the same struct can also serve as the JDK shim used by
// NotificationMessages, OrderedProperties, UserActionText, PoliticsText, etc.
Properties :: struct {
	values: map[string]string,
}

properties_new :: proc() -> ^Properties {
	p := new(Properties)
	p.values = make(map[string]string)
	return p
}

properties_get_property :: proc(self: ^Properties, key: string) -> string {
	if self == nil {
		return ""
	}
	if v, ok := self.values[key]; ok {
		return v
	}
	return ""
}

properties_get_property_or_default :: proc(self: ^Properties, key: string, default_value: string) -> string {
	if self == nil {
		return default_value
	}
	if v, ok := self.values[key]; ok {
		return v
	}
	return default_value
}

properties_set_property :: proc(self: ^Properties, key: string, value: string) {
	if self == nil {
		return
	}
	self.values[key] = value
}

// Java owners covered by this file:
//   - games.strategy.triplea.Properties (static utility class)
//   - java.util.Properties (JDK shim — see procs above)

