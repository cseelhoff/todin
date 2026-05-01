package game

import "core:fmt"

Integer_Client_Setting :: struct {
	using client_setting: Client_Setting,
}

// Java owners covered by this file:
//   - games.strategy.triplea.settings.IntegerClientSetting

// Java: protected String encodeValue(final Integer value) { return value.toString(); }
integer_client_setting_encode_value :: proc(self: ^Integer_Client_Setting, value: i32) -> string {
	return fmt.aprintf("%d", value)
}

