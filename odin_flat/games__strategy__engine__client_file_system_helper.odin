package game

Client_File_System_Helper :: struct {}

// Static field: ClientFileSystemHelper.codeSourceLocation
client_file_system_helper_code_source_location: Maybe(Path)

client_file_system_helper_set_code_source_folder :: proc(source_folder: Path) {
	client_file_system_helper_code_source_location = source_folder
}
