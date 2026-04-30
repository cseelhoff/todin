package game

import "core:os"
import "core:strconv"

// games.strategy.engine.framework.startup.SystemPropertyReader
// Java @UtilityClass — no instance fields. Procs ported in Phase B.

// Java: boolean serverIsPassworded() — !Strings.isNullOrEmpty(System.getProperty(SERVER_PASSWORD)).
// SERVER_PASSWORD = "triplea.server.password".
system_property_reader_server_is_passworded :: proc() -> bool {
	return os.get_env("triplea.server.password") != ""
}

// Java: Optional<InetAddress> customHost() — reads "customHost" system property.
// Odin: returns the raw host string (empty if unset). Hostname resolution is
// deferred to callers; Odin has no direct stdlib equivalent of InetAddress.
system_property_reader_custom_host :: proc() -> string {
	return os.get_env("customHost")
}

// Java: customHost -> { try { return InetAddress.getByName(customHost); }
//                      catch (UnknownHostException e) {
//                        throw new IllegalArgumentException("Invalid host address: " + customHost); } }
// Odin: no InetAddress in stdlib, so we mirror the validation semantics —
// returns (host, ok). ok=false signals what Java would raise as
// IllegalArgumentException ("Invalid host address: <customHost>").
lambda_system_property_reader_custom_host_0 :: proc(s: string) -> (host: string, ok: bool) {
	if s == "" {
		return "", false
	}
	return s, true
}

// Java: Optional<Integer> customPort() — reads "customPort" via Integer.getInteger.
// Odin: returns (port, ok); ok=false when unset or unparseable.
system_property_reader_custom_port :: proc() -> (port: int, ok: bool) {
	raw := os.get_env("customPort")
	if raw == "" {
		return 0, false
	}
	return strconv.parse_int(raw)
}

// Java: String gameComments() — reads LOBBY_GAME_COMMENTS ("triplea.lobby.game.comments").
// Odin: returns the env var value or "" when unset.
system_property_reader_game_comments :: proc() -> string {
	return os.get_env("triplea.lobby.game.comments")
}
