package game

String_Client_Setting :: struct {}

// Java: StringClientSetting(final String name, final String defaultValue) {
//         super(String.class, name, defaultValue);
//       }
// The owner struct is an empty Phase-A marker (no harness field references
// it). We still invoke the parent constructor for fidelity with the Java
// super(...) call; its return is discarded because String_Client_Setting
// has no field in which to store the parent state. `default_value` is the
// String literal itself; pass its address as rawptr to match
// client_setting_new's signature.
string_client_setting_new :: proc(name: string, default_value: string) -> ^String_Client_Setting {
	dv := new(string)
	dv^ = default_value
	_ = client_setting_new(string, name, rawptr(dv))
	return new(String_Client_Setting)
}
