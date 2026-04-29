package game

// JDK shim: minimal ResourceBundle stand-in. Localization is not
// exercised by the AI snapshot harness, so this holds an in-memory
// key→string map only.
Resource_Bundle :: struct {
	entries: map[string]string,
}

resource_bundle_new :: proc() -> ^Resource_Bundle {
	rb := new(Resource_Bundle)
	rb.entries = make(map[string]string)
	return rb
}

resource_bundle_get_string :: proc(self: ^Resource_Bundle, key: string) -> string {
	return self.entries[key]
}
