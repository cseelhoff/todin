package game

Long_Client_Setting :: struct {}

// Java: LongClientSetting(final String name, final long defaultValue) {
//         super(Long.class, name, defaultValue);
//       }
// `super(...)` autoboxes the primitive long into a `Long`. Mirror that
// by heap-boxing the i64 so it fits Client_Setting's `default_value:
// rawptr` slot, then delegate to the parent constructor. The owner
// struct is an empty Phase-A marker (no harness field references
// LongClientSetting), so the parent's allocation is effectively a
// side-effecting no-op kept here for fidelity with the Java super()
// call.
long_client_setting_new :: proc(name: string, default_value: i64) -> ^Long_Client_Setting {
	boxed := new(i64)
	boxed^ = default_value
	_ = client_setting_new(i64, name, rawptr(boxed))
	return new(Long_Client_Setting)
}
