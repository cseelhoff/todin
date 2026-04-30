package game

import "core:fmt"
import "core:os"

// Java owners covered by this file:
//   - games.strategy.engine.framework.system.SystemProperties

System_Properties :: struct {}

// Mirrors SystemProperties.getOperatingSystem(): returns the OS name.
// Java reads System.getProperty("os.name"); Odin uses the ODIN_OS constant.
system_properties_get_operating_system :: proc() -> string {
        return fmt.tprintf("%v", ODIN_OS)
}

// Mirrors SystemProperties.getUserHome(): System.getProperty("user.home").
system_properties_get_user_home :: proc() -> string {
        return os.get_env("HOME")
}

// Mirrors SystemProperties.getUserName(): System.getProperty("user.name").
system_properties_get_user_name :: proc() -> string {
        return os.get_env("USER")
}
