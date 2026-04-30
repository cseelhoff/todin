package game

// JDK shim: java.io.FileNotFoundException — value type carrying the
// missing-resource path/message. The AI snapshot harness does not
// raise these (resource loading is opaque), so the shim only models
// the exception's data, not throw semantics.

File_Not_Found_Exception :: struct {
	message: string,
}

file_not_found_exception_new :: proc(message: string) -> ^File_Not_Found_Exception {
	self := new(File_Not_Found_Exception)
	self.message = message
	return self
}

file_not_found_exception_get_message :: proc(self: ^File_Not_Found_Exception) -> string {
	return self.message
}
