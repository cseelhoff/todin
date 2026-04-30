package game

Client_File_System_Helper :: struct {}

// Static field: ClientFileSystemHelper.codeSourceLocation
client_file_system_helper_code_source_location: Maybe(Path)

client_file_system_helper_set_code_source_folder :: proc(source_folder: Path) {
	client_file_system_helper_code_source_location = source_folder
}

// Lambda: () -> new IllegalStateException("Unable to locate root folder")
// Source: ClientFileSystemHelper.getRootFolder, passed to Optional.orElseThrow.
// No captures; returns the exception message that getRootFolder propagates.
lambda_client_file_system_helper_0 :: proc() -> string {
	return "Unable to locate root folder"
}

// games.strategy.engine.ClientFileSystemHelper#handleUnableToLocateRootFolder(java.lang.Throwable)
//
// Java:
//   private static IllegalStateException handleUnableToLocateRootFolder(final Throwable cause) {
//       return new IllegalStateException("Unable to locate root folder", cause);
//   }
//
// Odin port: IllegalStateException is modeled as ^Exception (see java__lang__exception.odin).
// The Throwable cause is wrapped into the Exception's `cause` chain, preserving the message.
client_file_system_helper_handle_unable_to_locate_root_folder :: proc(cause: ^Throwable) -> ^Exception {
	e := exception_new("Unable to locate root folder")
	if cause != nil {
		c := exception_new(cause.message)
		e.cause = c
	}
	return e
}
