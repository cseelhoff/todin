package game

import "core:fmt"

Resource_Property_Reader :: struct {
	using abstract_input_stream_property_reader: Abstract_Input_Stream_Property_Reader,
	resource_name:                               string,
}

// Synthetic lambda for `newInputStream`'s
// `orElseThrow(() -> new FileNotFoundException("Resource not found: " + resourceName))`:
// a Supplier<FileNotFoundException> that builds the exception whose
// message embeds the captured resource name.
resource_property_reader_lambda_new_input_stream_0 :: proc(resource_name: string) -> ^File_Not_Found_Exception {
	return file_not_found_exception_new(fmt.aprintf("Resource not found: %s", resource_name))
}

// Forwarder installed on the parent's `new_input_stream` vtable slot.
resource_property_reader_new_input_stream_forwarder :: proc(
	self: ^Abstract_Input_Stream_Property_Reader,
) -> ^Input_Stream {
	return resource_property_reader_new_input_stream(transmute(^Resource_Property_Reader)self)
}

// Java: public ResourcePropertyReader(final String resourceName) {
//     super("resource(" + checkNotNull(resourceName) + ")");
//     this.resourceName = resourceName;
// }
resource_property_reader_new :: proc(name: string) -> ^Resource_Property_Reader {
	assert(name != "")
	self := new(Resource_Property_Reader)
	parent := abstract_input_stream_property_reader_new(fmt.aprintf("resource(%s)", name))
	self.abstract_input_stream_property_reader = parent^
	self.new_input_stream = resource_property_reader_new_input_stream_forwarder
	self.resource_name = name
	return self
}

// Java: protected InputStream newInputStream() throws FileNotFoundException {
//     return Optional.ofNullable(
//             Thread.currentThread().getContextClassLoader().getResourceAsStream(resourceName))
//         .orElseThrow(() -> new FileNotFoundException("Resource not found: " + resourceName));
// }
resource_property_reader_new_input_stream :: proc(self: ^Resource_Property_Reader) -> ^Input_Stream {
	stream := class_loader_get_resource_as_stream(
		thread_get_context_class_loader(thread_current_thread()),
		self.resource_name,
	)
	if stream != nil {
		return stream
	}
	ex := resource_property_reader_lambda_new_input_stream_0(self.resource_name)
	panic(fmt.aprintf("FileNotFoundException: %s", ex.message))
}

