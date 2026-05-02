package game

import "core:strings"

Abstract_Input_Stream_Property_Reader :: struct {
	using abstract_property_reader: Abstract_Property_Reader,
	property_source_name:           string,
	// Vtable hook for the abstract `newInputStream()` method. Concrete
	// subclasses set this in their constructor to forward into their
	// own typed proc.
	new_input_stream:               proc(self: ^Abstract_Input_Stream_Property_Reader) -> ^Input_Stream,
}

// Forwarder installed on the parent's `read_property_internal` vtable
// slot. It downcasts the parent pointer back to this type and calls
// the typed proc below.
abstract_input_stream_property_reader_read_property_internal_forwarder :: proc(
	self: ^Abstract_Property_Reader,
	key: string,
) -> string {
	return abstract_input_stream_property_reader_read_property_internal(
		transmute(^Abstract_Input_Stream_Property_Reader)self,
		key,
	)
}

// Java: protected AbstractInputStreamPropertyReader(final String propertySourceName) {
//     checkNotNull(propertySourceName);
//     this.propertySourceName = propertySourceName;
// }
abstract_input_stream_property_reader_new :: proc(property_source_name: string) -> ^Abstract_Input_Stream_Property_Reader {
	assert(property_source_name != "")
	self := new(Abstract_Input_Stream_Property_Reader)
	self.property_source_name = property_source_name
	self.read_property_internal = abstract_input_stream_property_reader_read_property_internal_forwarder
	return self
}

// Java: protected final String readPropertyInternal(final String key) {
//     try (InputStream inputStream = newInputStream()) {
//         final Properties props = new Properties();
//         props.load(inputStream);
//         return props.getProperty(key);
//     } catch (FileNotFoundException e) { throw IllegalStateException(...); }
//       catch (IOException e)            { throw IllegalStateException(...); }
// }
//
// The harness's `Input_Stream` shim is a plain in-memory byte buffer,
// so the equivalent of `Properties.load` is to scan the bytes as a
// Java `.properties` text file and look up `key`. Returns "" when the
// key is absent (matches the parent reader's null-handling, which
// trims the value via `strings.trim_space`).
abstract_input_stream_property_reader_read_property_internal :: proc(
	self: ^Abstract_Input_Stream_Property_Reader,
	key: string,
) -> string {
	stream := self.new_input_stream(self)
	defer input_stream_close(stream)

	text := string(stream.data[:])
	for line in strings.split_lines_iterator(&text) {
		trimmed := strings.trim_left_space(line)
		if len(trimmed) == 0 { continue }
		if trimmed[0] == '#' || trimmed[0] == '!' { continue }
		// Find the first `=` or `:` separator (Java .properties syntax).
		sep := -1
		for i in 0 ..< len(trimmed) {
			c := trimmed[i]
			if c == '=' || c == ':' {
				sep = i
				break
			}
			if c == ' ' || c == '\t' || c == '\f' {
				sep = i
				break
			}
		}
		k: string
		v: string
		if sep < 0 {
			k = strings.trim_right_space(trimmed)
			v = ""
		} else {
			k = strings.trim_right_space(trimmed[:sep])
			rest := trimmed[sep + 1:]
			// Java skips additional separator/whitespace chars between key
			// and value.
			rest = strings.trim_left(rest, " \t\f=:")
			v = strings.trim_right_space(rest)
		}
		if k == key {
			return v
		}
	}
	return ""
}

