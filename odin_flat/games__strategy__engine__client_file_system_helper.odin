package game

Client_File_System_Helper :: struct {}

// Java: ClientFileSystemHelper.USER_ROOT_FOLDER_NAME = "triplea"
USER_ROOT_FOLDER_NAME :: "triplea"

// Static field: ClientFileSystemHelper.codeSourceLocation
client_file_system_helper_code_source_location: Maybe(Path)

client_file_system_helper_set_code_source_folder :: proc(source_folder: Path) {
        client_file_system_helper_code_source_location = source_folder
}

// Mirrors ClientFileSystemHelper.getUserRootFolder():
//   final Path userHome = Path.of(SystemProperties.getUserHome());
//   final Path rootDir = userHome.resolve("Documents").resolve(USER_ROOT_FOLDER_NAME);
//   return Files.exists(rootDir) ? rootDir : userHome.resolve(USER_ROOT_FOLDER_NAME);
client_file_system_helper_get_user_root_folder :: proc() -> Path {
        user_home := path_of(system_properties_get_user_home())
        documents := path_resolve(user_home, "Documents")
        root_dir := path_resolve(documents, USER_ROOT_FOLDER_NAME)
        if files_exists(root_dir) {
                return root_dir
        }
        return path_resolve(user_home, USER_ROOT_FOLDER_NAME)
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
