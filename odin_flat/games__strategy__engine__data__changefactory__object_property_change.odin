package game

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
