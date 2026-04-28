package game

// games.strategy.engine.data.properties.AbstractEditableProperty
//
// Java's editable-property hierarchy (Boolean/Number/String) all share name+value.
// Defined here as the concrete struct the harness consumes; subtype-specific
// fields are added in their own files.

Editable_Property :: struct {
	name:  string,
	value: Property_Value,
}
