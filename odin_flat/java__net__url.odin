package game

// JDK shim: java.net.URL — value type holding the URL string.
// The AI snapshot harness does not actually load resources, so the
// shim only carries the textual form. Optional<URL> is modeled in
// callers as ^Url with nil = empty (project convention).

Url :: struct {
	value: string,
}

url_new :: proc(value: string) -> ^Url {
	self := new(Url)
	self.value = value
	return self
}

url_to_string :: proc(self: ^Url) -> string {
	return self.value
}

url_to_uri :: proc(self: ^Url) -> ^Uri {
	return uri_new(self.value)
}
url_open_connection :: proc(self: ^Url) -> ^Url_Connection {
	if self == nil { return nil }
	return url_connection_new(self)
}