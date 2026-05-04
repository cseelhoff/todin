package game

import "core:fmt"

Object_Property_Change :: struct {
	using change: Change,
	object:    ^Unit,
	property:  string,
	new_value: rawptr,
	old_value: rawptr,
}

object_property_change_get_property :: proc(self: ^Object_Property_Change) -> string {
	return self.property
}

// Mirrors `new ObjectPropertyChange(Unit, String, Object)` (the package-private
// 3-arg constructor). `property.intern()` is a JVM string-interning detail with
// no Odin equivalent — strings are value-typed here. The old value is read
// from the unit's mutable property table via the inherited
// `DynamicallyModifiable.getPropertyOrThrow` default, which resolves to a
// Unit-specific `getPropertyOrEmpty` switch over the property name.
object_property_change_new :: proc(
	object: ^Unit,
	property: string,
	new_value: rawptr,
) -> ^Object_Property_Change {
	self := new(Object_Property_Change)
	self.object = object
	self.property = property
	self.new_value = new_value
	self.old_value = mutable_property_get_value(unit_get_property_or_throw(object, property))
	return self
}

// Java: protected void perform(GameState data) — applies new_value to the
// unit's named mutable property; an InvalidValueException returned from the
// setter is rethrown as an IllegalStateException-equivalent panic, matching
// the Java try/catch that wraps the failure with object/property/value
// context.
object_property_change_perform :: proc(self: ^Object_Property_Change, data: ^Game_State) {
	if err, ok := mutable_property_set_value(
		unit_get_property_or_throw(self.object, self.property),
		self.new_value,
	).(^Mutable_Property_Invalid_Value_Exception); ok && err != nil {
		panic(fmt.aprintf(
			"failed to set value '%v' on property '%s' for object '%v': %s",
			self.new_value, self.property, self.object, err.message,
		))
	}
}
