package game

Uri_Client_Setting :: struct {}

// Java: UriClientSetting(final String name, final URI defaultValue) { super(URI.class, name, defaultValue); }
// Mirrors the two-arg constructor by delegating to the parent ClientSetting
// constructor. The Odin Uri_Client_Setting struct carries no extra state of
// its own; the parent allocation models Java's `super(...)` call. The
// snapshot harness never reads/writes URI client settings, so the parent
// instance is allocated for fidelity and discarded — a no-default-value
// instance with the same shape as Java's `super`.
uri_client_setting_new :: proc(name: string, default_value: ^Uri) -> ^Uri_Client_Setting {
	_ = client_setting_new(Uri, name, rawptr(default_value))
	return new(Uri_Client_Setting)
}
