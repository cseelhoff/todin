package game

Enum_Client_Setting :: struct {}

// Java: EnumClientSetting(Class<E> type, String name, E defaultValue) {
//         super(type, name, defaultValue);
//       }
// Class<E> → typeid; the enum default value is encoded as Enum.toString()
// in encodeValue, so it travels through the port as a string label.
// The owner struct is an empty Phase-A marker (no harness field
// references it), so beyond allocation there is no parent state to
// populate — the Java super() call's only effect is setting fields
// that the port has elided.
enum_client_setting_new :: proc(type: typeid, name: string, default_value: string) -> ^Enum_Client_Setting {
	_ = type
	_ = name
	_ = default_value
	return new(Enum_Client_Setting)
}
