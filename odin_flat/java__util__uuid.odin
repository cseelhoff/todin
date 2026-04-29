package game

// JDK shim: java.util.UUID
// Value-type wrapper around a 128-bit identifier. Stored as a string in
// canonical 8-4-4-4-12 hex form for the snapshot harness; the few callers
// that round-trip a UUID only need equality and string formatting, both of
// which work directly on the underlying string.

Uuid :: struct {
    value: string,
}

uuid_new :: proc(s: string) -> ^Uuid {
    u := new(Uuid)
    u.value = s
    return u
}

uuid_to_string :: proc(self: ^Uuid) -> string {
    return self.value
}

uuid_equals :: proc(a: ^Uuid, b: ^Uuid) -> bool {
    if a == nil || b == nil { return a == b }
    return a.value == b.value
}
