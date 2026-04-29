package game

// JDK shim: java.net.InetAddress is a value type wrapping a host
// name / IP literal. The AI snapshot harness does not perform real
// DNS resolution; we keep the host-string and (optional) numeric
// address bytes only.

Inet_Address :: struct {
	host_name: string,
	address:   [dynamic]u8, // 4 bytes for IPv4, 16 for IPv6, empty for unresolved
}

inet_address_get_by_name :: proc(host: string) -> ^Inet_Address {
	a := new(Inet_Address)
	a.host_name = host
	return a
}

inet_address_get_local_host :: proc() -> ^Inet_Address {
	a := new(Inet_Address)
	a.host_name = "localhost"
	return a
}

inet_address_get_host_name :: proc(self: ^Inet_Address) -> string {
	return self.host_name
}

inet_address_get_host_address :: proc(self: ^Inet_Address) -> string {
	return self.host_name
}
