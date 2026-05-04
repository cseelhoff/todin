package game

// games.strategy.triplea.settings.ProtectedStringClientSetting
//
// ClientSetting<char[]> subclass that stores encrypted Strings via a
// CredentialManager. The AI snapshot harness only needs the
// constructor (transitively reached); encode/decodeValue and the
// CredentialManager helpers aren't required here.
//
// Mirrors the Path_Client_Setting shape: parent ctor is invoked for
// its bookkeeping side-effects (listener slice init, name/type), and
// the subclass retains the fields the rest of this package's procs
// would touch.
Protected_String_Client_Setting :: struct {
	name: string,
}

// Java: ProtectedStringClientSetting(final String name) {
//   super(char[].class, name);
// }
// The two-arg super call resolves to ClientSetting(Class<T>, String)
// which in turn delegates to the three-arg form with a null default
// (client_setting_new_no_default → client_setting_new(..., nil)).
protected_string_client_setting_new :: proc(name: string) -> ^Protected_String_Client_Setting {
	// super(char[].class, name): char[] is a Java reference type with
	// no direct Odin counterpart at the Client_Setting rawptr-default
	// level, so we invoke the parent ctor purely for its bookkeeping.
	// Use a sentinel typeid; the harness never reads it back.
	_ = client_setting_new_no_default(typeid_of([]u8), name)
	s := new(Protected_String_Client_Setting)
	s.name = name
	return s
}

