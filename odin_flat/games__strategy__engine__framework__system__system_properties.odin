package game

import "core:fmt"

// Java owners covered by this file:
//   - games.strategy.engine.framework.system.SystemProperties

System_Properties :: struct {}

// Mirrors SystemProperties.getOperatingSystem(): returns the OS name.
// Java reads System.getProperty("os.name"); Odin uses the ODIN_OS constant.
system_properties_get_operating_system :: proc() -> string {
	return fmt.tprintf("%v", ODIN_OS)
}

