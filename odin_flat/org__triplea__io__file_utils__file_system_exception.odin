package game

import "core:fmt"

// Ported from org.triplea.io.FileUtils.FileSystemException
// Runtime exception wrapping an IOException with a hint to check
// available disk space.

File_Utils_File_System_Exception :: struct {
	using exception: Exception,
}

// org.triplea.io.FileUtils.FileSystemException#<init>(java.io.IOException)
//
// Java:
//   FileSystemException(final IOException e) {
//       super("File system exception (check available disk space), " + e.getMessage(), e);
//   }
//
// The Odin port has no dedicated Io_Exception shim, so the cause is
// accepted as ^Throwable (java.io.IOException is a Throwable). The
// cause's message is folded into the Exception cause chain following
// the convention used in client_file_system_helper.
file_utils_file_system_exception_new :: proc(cause: ^Throwable) -> ^File_Utils_File_System_Exception {
	self := new(File_Utils_File_System_Exception)
	cause_msg := ""
	if cause != nil {
		cause_msg = cause.message
		self.exception.cause = exception_new(cause.message)
	}
	self.exception.message = fmt.aprintf(
		"File system exception (check available disk space), %s",
		cause_msg,
	)
	return self
}

