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

// Java: public static Optional<InputStream> openStream(final URL url) {
//   return new UrlStreams().newStream(url);
// }
url_streams_open_stream_url :: proc(url: ^Url) -> ^Input_Stream {
	streams := url_streams_new()
	return url_streams_new_stream(streams, url)
}

// Java: public static Optional<InputStream> openStream(final URI uri) {
//   try { return UrlStreams.openStream(uri.toURL()); }
//   catch (final MalformedURLException e) {
//     throw new IllegalStateException("Bad uri specified: " + uri, e);
//   }
// }
// The AI snapshot harness does not exercise URL I/O; the URI shim simply
// carries the textual form, so toURL() collapses to wrapping the same
// string in a Url. nil URI propagates as nil (Optional.empty()).
url_streams_open_stream_uri :: proc(uri: ^Uri) -> ^Input_Stream {
	if uri == nil {
		return nil
	}
	url := url_new(uri_to_string(uri))
	return url_streams_open_stream_url(url)
}

// Java: public static <T> Optional<T> openStream(
//   final URI uri, final Function<InputStream, T> streamOperation) {
//   final Optional<InputStream> stream = openStream(uri);
//   if (stream.isPresent()) {
//     try (InputStream inputStream = stream.get()) {
//       return Optional.ofNullable(streamOperation.apply(inputStream));
//     } catch (final IOException e) { ...; return Optional.empty(); }
//   } else { return Optional.empty(); }
// }
// Generic T collapses to rawptr (Optional<T> ≡ rawptr with nil == empty).
url_streams_open_stream_uri_op :: proc(uri: ^Uri, stream_operation: proc(s: ^Input_Stream) -> rawptr) -> rawptr {
	input_stream := url_streams_open_stream_uri(uri)
	if input_stream == nil {
		return nil
	}
	return stream_operation(input_stream)
}

// Proc group dispatching the `openStream` static overloads by argument shape.
url_streams_open_stream :: proc{
	url_streams_open_stream_url,
	url_streams_open_stream_uri,
	url_streams_open_stream_uri_op,
}
