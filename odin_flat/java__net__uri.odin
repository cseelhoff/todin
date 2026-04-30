package game

// JDK shim: java.net.URI — value type holding the URI string.

Uri :: struct {
	value: string,
}

uri_new :: proc(value: string) -> ^Uri {
	self := new(Uri)
	self.value = value
	return self
}

uri_to_string :: proc(self: ^Uri) -> string {
	return self.value
}
