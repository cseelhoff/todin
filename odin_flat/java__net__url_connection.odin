package game

// JDK shim: java.net.URLConnection — opaque marker. The AI snapshot
// harness never opens real network connections; URL.openConnection()
// returns a placeholder so callers compile.

Url_Connection :: struct {
	url: ^Url,
}

url_connection_new :: proc(url: ^Url) -> ^Url_Connection {
	self := new(Url_Connection)
	self.url = url
	return self
}

url_connection_get_url :: proc(self: ^Url_Connection) -> ^Url {
	if self == nil { return nil }
	return self.url
}

url_connection_get_input_stream :: proc(self: ^Url_Connection) -> ^Input_Stream {
	_ = self
	return nil
}

url_connection_connect :: proc(self: ^Url_Connection) {
	_ = self
}

url_connection_set_default_use_caches :: proc(self: ^Url_Connection, use_caches: bool) {
	_ = self
	_ = use_caches
}

url_connection_set_use_caches :: proc(self: ^Url_Connection, use_caches: bool) {
	_ = self
	_ = use_caches
}
