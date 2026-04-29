package game

import "core:fmt"

// Each slot pairs a function pointer with a ctx rawptr so a slot can
// model a Java lambda's captured environment (e.g. the synthetic
// string-setter built inside ofMapper that captures the user-supplied
// `setter` and `mapper`). Non-capturing factories pass `ctx = nil`.
Mutable_Property_Setter_Slot :: struct {
	fn:  proc(ctx: rawptr, value: rawptr) -> Maybe(string),
	ctx: rawptr,
}

Mutable_Property_String_Setter_Slot :: struct {
	fn:  proc(ctx: rawptr, value: string) -> Maybe(string),
	ctx: rawptr,
}

Mutable_Property_Getter_Slot :: struct {
	fn:  proc(ctx: rawptr) -> rawptr,
	ctx: rawptr,
}

Mutable_Property_Resetter_Slot :: struct {
	fn:  proc(ctx: rawptr),
	ctx: rawptr,
}

Mutable_Property :: struct {
	setter:        Mutable_Property_Setter_Slot,
	string_setter: Mutable_Property_String_Setter_Slot,
	getter:        Mutable_Property_Getter_Slot,
	resetter:      Mutable_Property_Resetter_Slot,
}

Mutable_Property_Invalid_Value_Exception :: struct {
	message: string,
	cause:   ^Mutable_Property_Invalid_Value_Exception,
}


// cast(Object) — instance. Java does an unchecked (T) value cast; in this
// rawptr-erased port T is rawptr, so the cast is the identity.
mutable_property_cast :: proc(self: ^Mutable_Property, value: rawptr) -> rawptr {
	_ = self
	return value
}

// getValue() — instance. Returns getter.get().
mutable_property_get_value :: proc(self: ^Mutable_Property) -> rawptr {
	return self.getter.fn(self.getter.ctx)
}

// noGetter() — static factory returning a Supplier that always throws.
mutable_property_no_getter_impl :: proc(ctx: rawptr) -> rawptr {
	_ = ctx
	panic("No Getter has been defined!")
}
mutable_property_no_getter :: proc() -> Mutable_Property_Getter_Slot {
	return Mutable_Property_Getter_Slot{fn = mutable_property_no_getter_impl, ctx = nil}
}

// noResetter() — static factory returning a Runnable that always throws.
mutable_property_no_resetter_impl :: proc(ctx: rawptr) {
	_ = ctx
	panic("No Resetter has been defined!")
}
mutable_property_no_resetter :: proc() -> Mutable_Property_Resetter_Slot {
	return Mutable_Property_Resetter_Slot{fn = mutable_property_no_resetter_impl, ctx = nil}
}

// noStringSetter() — static factory returning a string setter that throws.
mutable_property_no_string_setter_impl :: proc(ctx: rawptr, value: string) -> Maybe(string) {
	_ = ctx
	_ = value
	panic("No String Setter has been defined!")
}
mutable_property_no_string_setter :: proc() -> Mutable_Property_String_Setter_Slot {
	return Mutable_Property_String_Setter_Slot{fn = mutable_property_no_string_setter_impl, ctx = nil}
}

// of(setter, stringSetter, getter, resetter) — static constructor wrapper.
// Inlines `new MutableProperty(...)`; constructors aren't tracked in
// port.sqlite per llm-instructions.md.
mutable_property_of :: proc(
	setter: Mutable_Property_Setter_Slot,
	string_setter: Mutable_Property_String_Setter_Slot,
	getter: Mutable_Property_Getter_Slot,
	resetter: Mutable_Property_Resetter_Slot,
) -> ^Mutable_Property {
	assert(setter.fn != nil)
	assert(string_setter.fn != nil)
	assert(getter.fn != nil)
	assert(resetter.fn != nil)
	p := new(Mutable_Property)
	p.setter = setter
	p.string_setter = string_setter
	p.getter = getter
	p.resetter = resetter
	return p
}

// ofSimple(setter, getter) — wires noStringSetter/noResetter as defaults.
mutable_property_of_simple :: proc(
	setter: Mutable_Property_Setter_Slot,
	getter: Mutable_Property_Getter_Slot,
) -> ^Mutable_Property {
	return mutable_property_of(
		setter,
		mutable_property_no_string_setter(),
		getter,
		mutable_property_no_resetter(),
	)
}

// Mapper proc-type alias used by ofMapper's string-setter helper. Mirrors
// org.triplea.java.function.ThrowingFunction<String, T, Exception> with
// T erased to rawptr and the checked exception surfaced as Maybe(string).
Mutable_Property_Mapper :: #type proc(value: string) -> (rawptr, Maybe(string))

// lambda$ofMapper$4(ThrowingConsumer setter, ThrowingFunction mapper,
// String value): Java-bytecode-equivalent free-standing helper for the
// string-setter lambda built inside ofMapper, taking the captured
// `setter` and `mapper` as explicit parameters.
mutable_property_lambda_of_mapper_4 :: proc(
	setter: Mutable_Property_Setter_Slot,
	mapper: Mutable_Property_Mapper,
	value: string,
) -> Maybe(string) {
	mapped, map_err := mapper(value)
	if map_err != nil {
		return map_err
	}
	return setter.fn(setter.ctx, mapped)
}

// Captured environment for ofMapper's two synthetic lambdas:
//   stringSetter: o -> setter.accept(mapper.apply(o))
//   resetter:     () -> setter.accept(defaultValue.get())
Mutable_Property_Of_Mapper_Ctx :: struct {
	setter:        Mutable_Property_Setter_Slot,
	mapper:        Mutable_Property_Mapper,
	default_value: Mutable_Property_Getter_Slot,
}

mutable_property_of_mapper_string_setter_impl :: proc(ctx: rawptr, value: string) -> Maybe(string) {
	c := cast(^Mutable_Property_Of_Mapper_Ctx)ctx
	return mutable_property_lambda_of_mapper_4(c.setter, c.mapper, value)
}

mutable_property_of_mapper_resetter_impl :: proc(ctx: rawptr) {
	c := cast(^Mutable_Property_Of_Mapper_Ctx)ctx
	v := c.default_value.fn(c.default_value.ctx)
	err := c.setter.fn(c.setter.ctx, v)
	if err != nil {
		panic("Unexpected Error while resetting value")
	}
}

// ofMapper(mapper, setter, getter, defaultValue) — convenience factory
// that synthesises the string-setter and resetter from a single
// String→T mapper plus a defaultValue Supplier.
mutable_property_of_mapper :: proc(
	mapper: Mutable_Property_Mapper,
	setter: Mutable_Property_Setter_Slot,
	getter: Mutable_Property_Getter_Slot,
	default_value: Mutable_Property_Getter_Slot,
) -> ^Mutable_Property {
	c := new(Mutable_Property_Of_Mapper_Ctx)
	c.setter = setter
	c.mapper = mapper
	c.default_value = default_value
	return mutable_property_of(
		setter,
		Mutable_Property_String_Setter_Slot{
			fn  = mutable_property_of_mapper_string_setter_impl,
			ctx = c,
		},
		getter,
		Mutable_Property_Resetter_Slot{
			fn  = mutable_property_of_mapper_resetter_impl,
			ctx = c,
		},
	)
}

// ofString reuses one ThrowingConsumer<String> for both the typed setter
// and the string setter slot. The typed setter receives `rawptr value`
// which, for MutableProperty<String>, is a `^string`; we deref and
// delegate to the string setter. (For values constructed via setValue,
// String values flow through the string-setter branch directly so this
// adapter is mostly defensive.)
Mutable_Property_Of_String_Ctx :: struct {
	string_setter: Mutable_Property_String_Setter_Slot,
}

mutable_property_of_string_typed_setter_impl :: proc(ctx: rawptr, value: rawptr) -> Maybe(string) {
	c := cast(^Mutable_Property_Of_String_Ctx)ctx
	if value == nil {
		return c.string_setter.fn(c.string_setter.ctx, "")
	}
	s := (cast(^string)value)^
	return c.string_setter.fn(c.string_setter.ctx, s)
}

mutable_property_of_string :: proc(
	setter: Mutable_Property_String_Setter_Slot,
	getter: Mutable_Property_Getter_Slot,
	resetter: Mutable_Property_Resetter_Slot,
) -> ^Mutable_Property {
	c := new(Mutable_Property_Of_String_Ctx)
	c.string_setter = setter
	return mutable_property_of(
		Mutable_Property_Setter_Slot{
			fn  = mutable_property_of_string_typed_setter_impl,
			ctx = c,
		},
		setter,
		getter,
		resetter,
	)
}

// ofWriteOnly(setter, stringSetter) — static factory. Java:
//   return of(setter, stringSetter, noGetter(), noResetter());
mutable_property_of_write_only :: proc(
	setter: Mutable_Property_Setter_Slot,
	string_setter: Mutable_Property_String_Setter_Slot,
) -> ^Mutable_Property {
	return mutable_property_of(
		setter,
		string_setter,
		mutable_property_no_getter(),
		mutable_property_no_resetter(),
	)
}

// setStringValue(String) — instance. Calls stringSetter.accept(value),
// wrapping any returned error in an InvalidValueException. Returns nil
// on success, allocated exception on failure.
mutable_property_set_string_value :: proc(
	self: ^Mutable_Property,
	value: string,
) -> Maybe(^Mutable_Property_Invalid_Value_Exception) {
	err := self.string_setter.fn(self.string_setter.ctx, value)
	if msg, ok := err.(string); ok {
		ex := new(Mutable_Property_Invalid_Value_Exception)
		ex.message = fmt.aprintf("failed to set string property value to '%s': %s", value, msg)
		return ex
	}
	return nil
}

// setTypedValue(Object) — instance. Calls setter.accept(value),
// wrapping any returned error in an InvalidValueException.
mutable_property_set_typed_value :: proc(
	self: ^Mutable_Property,
	value: rawptr,
) -> Maybe(^Mutable_Property_Invalid_Value_Exception) {
	err := self.setter.fn(self.setter.ctx, value)
	if msg, ok := err.(string); ok {
		ex := new(Mutable_Property_Invalid_Value_Exception)
		ex.message = fmt.aprintf("failed to set typed property value: %s", msg)
		return ex
	}
	return nil
}

// setValue(Object) — instance, polymorphic dispatch in Java between
// String and T. In this rawptr-erased port we cannot distinguish a
// String from a generic Object at runtime (mirrors the simplification
// already documented on mutable_property_cast above), so always route
// through setTypedValue. Callers that hold a string explicitly invoke
// mutable_property_set_string_value, matching the Java test pattern.
mutable_property_set_value :: proc(
	self: ^Mutable_Property,
	value: rawptr,
) -> Maybe(^Mutable_Property_Invalid_Value_Exception) {
	return mutable_property_set_typed_value(self, value)
}
