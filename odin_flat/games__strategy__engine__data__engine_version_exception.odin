package game

import "core:fmt"

// Ported from games.strategy.engine.data.EngineVersionException
// A checked exception that indicates a game engine is not compatible with a map.

Engine_Version_Exception :: struct {
	message: string,
}

// Java: public EngineVersionException(final String minimumVersionFound, final Path xmlFileBeingParsed)
engine_version_exception_new :: proc(message: string, path: Path) -> ^Engine_Version_Exception {
	self := new(Engine_Version_Exception)
	current := product_version_reader_get_current_version()
	current_str := version_to_string_lambda_0(current)
	self.message = fmt.aprintf(
		"Current engine version: %s, is not compatible with version: %s, required by game-XML: %s",
		current_str,
		message,
		path_to_string(path),
	)
	return self
}

