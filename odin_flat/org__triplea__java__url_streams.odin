package game

Url_Streams :: struct {}

url_streams_new :: proc() -> ^Url_Streams {
	self := new(Url_Streams)
	return self
}

// Java: lambda$new$0(URL) — body of the default urlConnectionFactory
// initialized in UrlStreams(): (url) -> { try { return url.openConnection(); }
// catch (IOException e) { throw new RuntimeException(e); } }
url_streams_lambda_new_0 :: proc(url: ^Url) -> ^Url_Connection {
	return url_open_connection(url)
}

// Java: URLConnection newUrlConnection(URL url)
url_streams_new_url_connection :: proc(self: ^Url_Streams, url: ^Url) -> ^Url_Connection {
	_ = self
	connection := url_streams_lambda_new_0(url)
	url_connection_set_default_use_caches(connection, false)
	url_connection_set_use_caches(connection, false)
	return connection
}

// Java: Optional<InputStream> newStream(final URL url)
//   try {
//     final URLConnection connection = newUrlConnection(url);
//     return Optional.of(connection.getInputStream());
//   } catch (final IOException e) { ... return Optional.empty(); }
// Odin: Optional<InputStream> collapses to ^Input_Stream (nil ≡ empty).
url_streams_new_stream :: proc(self: ^Url_Streams, url: ^Url) -> ^Input_Stream {
	connection := url_streams_new_url_connection(self, url)
	if connection == nil {
		return nil
	}
	return url_connection_get_input_stream(connection)
}
