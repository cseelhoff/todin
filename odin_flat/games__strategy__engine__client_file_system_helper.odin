package game

import "core:fmt"

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
}

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

// Java: ClientFileSystemHelper.MAPS_FOLDER_NAME = "downloadedMaps"
MAPS_FOLDER_NAME :: "downloadedMaps"

// games.strategy.engine.ClientFileSystemHelper#getUserMapsFolder(java.util.function.Supplier)
//
// Java:
//   @VisibleForTesting
//   static Path getUserMapsFolder(final Supplier<Path> userHomeRootFolderSupplier) {
//     final Path defaultDownloadedMapsFolder =
//         userHomeRootFolderSupplier.get().resolve(MAPS_FOLDER_NAME);
//     final Optional<Path> path = ClientSetting.mapFolderOverride.getValue();
//     if (path.isPresent() && (!Files.exists(path.get()) || !Files.isWritable(path.get()))) {
//       ClientSetting.mapFolderOverride.resetValue();
//       log.warn("Invalid map override setting folder does not exist or cannot be written: {}\n"
//           + "Reverting to use default map folder location: {}", ...);
//     }
//     final Path mapsFolder =
//         ClientSetting.mapFolderOverride.getValue().orElse(defaultDownloadedMapsFolder);
//     if (!Files.exists(mapsFolder)) {
//       try { Files.createDirectories(mapsFolder); }
//       catch (IOException e) { log.error("...", mapsFolder.toAbsolutePath(), e); }
//     }
//     return mapsFolder;
//   }
//
// Functional interface Supplier<Path> → bare `proc() -> Path` (no captures).
// Optional<Path> → `Path_Client_Setting.has_current` flag (per
// path_client_setting.odin's value model: `path_client_setting_get_value`
// always returns the typed Path, and `has_current == false` mirrors
// `Optional.empty()` for the no-default `mapFolderOverride` setting).
client_file_system_helper_get_user_maps_folder :: proc(user_home_root_folder_supplier: proc() -> Path) -> Path {
	default_downloaded_maps_folder := path_resolve(user_home_root_folder_supplier(), MAPS_FOLDER_NAME)

	// final Optional<Path> path = ClientSetting.mapFolderOverride.getValue();
	override_setting := client_setting_map_folder_override()
	override_path := path_client_setting_get_value(override_setting)
	override_present := override_setting.has_current

	// if (path.isPresent() && (!Files.exists(...) || !Files.isWritable(...)))
	if override_present && (!files_exists(override_path) || !files_is_writable(override_path)) {
		path_client_setting_reset_value(override_setting)
		// log.warn(...) — no logger bound in the snapshot harness; mirror
		// the Java warning message via stderr to preserve observable
		// diagnostics without depending on slf4j.
		fmt.eprintln(
			"Invalid map override setting folder does not exist or cannot be written:",
			override_path.value,
			"\nReverting to use default map folder location:",
			default_downloaded_maps_folder.value,
		)
		override_present = false
	}

	// final Path mapsFolder =
	//     ClientSetting.mapFolderOverride.getValue().orElse(defaultDownloadedMapsFolder);
	maps_folder := default_downloaded_maps_folder
	if override_setting.has_current {
		maps_folder = path_client_setting_get_value(override_setting)
	}

	// if (!Files.exists(mapsFolder)) Files.createDirectories(mapsFolder);
	// IOException is impossible against the in-process Files shim, so the
	// Java try/catch (which only logs and swallows) collapses to the bare
	// call.
	if !files_exists(maps_folder) {
		files_create_directories(maps_folder)
	}
	return maps_folder
}
