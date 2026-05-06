package game

import "core:fmt"
import "core:strconv"

Integer_Client_Setting :: struct {
	using client_setting: Client_Setting,
}

// Java owners covered by this file:
//   - games.strategy.triplea.settings.IntegerClientSetting

// Java: protected String encodeValue(final Integer value) { return value.toString(); }
integer_client_setting_encode_value :: proc(self: ^Integer_Client_Setting, value: i32) -> string {
	return fmt.aprintf("%d", value)
}

// Java: IntegerClientSetting(final String name) {
//         super(Integer.class, name);
//       }
// One-arg form delegates to the parent's no-default constructor; no
// autoboxing is required because there is no default value to lift.
integer_client_setting_v_encode_value :: proc(self: ^Client_Setting, value: rawptr) -> (string, bool) {
	ics := cast(^Integer_Client_Setting)self
	if value == nil {
		return "", false
	}
	v := (cast(^i32)value)^
	return integer_client_setting_encode_value(ics, v), true
}

integer_client_setting_v_decode_value :: proc(self: ^Client_Setting, encoded_value: string) -> (rawptr, bool, ^Client_Setting_Value_Encoding_Exception) {
	ics := cast(^Integer_Client_Setting)self
	v, present, err := integer_client_setting_decode_value(ics, encoded_value)
	if err != nil || !present {
		return nil, present, err
	}
	boxed := new(i32)
	boxed^ = v
	return rawptr(boxed), true, nil
}

integer_client_setting_new :: proc(name: string) -> ^Integer_Client_Setting {
	parent := client_setting_new_no_default(i32, name)
	self := new(Integer_Client_Setting)
	self.client_setting = parent^
	self.client_setting.encode_value = integer_client_setting_v_encode_value
	self.client_setting.decode_value = integer_client_setting_v_decode_value
	return self
}

// Java: IntegerClientSetting(final String name, final int defaultValue) {
//         super(Integer.class, name, defaultValue);
//       }
// `super(...)` autoboxes the primitive int into an `Integer`. Mirror that
// by heap-boxing the i32 so it fits Client_Setting's `default_value:
// rawptr` slot, then delegate to the parent constructor and copy its
// state into our embedded `client_setting` field.
integer_client_setting_new_with_default :: proc(name: string, default_value: i32) -> ^Integer_Client_Setting {
	boxed := new(i32)
	boxed^ = default_value
	parent := client_setting_new(i32, name, rawptr(boxed))
	self := new(Integer_Client_Setting)
	self.client_setting = parent^
	return self
}

// Java: protected @Nullable Integer decodeValue(final String encodedValue) throws ValueEncodingException {
//   try {
//     if (encodedValue.isEmpty()) { return null; }
//     return Integer.valueOf(encodedValue);
//   } catch (final NumberFormatException e) {
//     throw new ValueEncodingException(e);
//   }
// }
// `@Nullable Integer` → (value, present) tuple; `throws` → trailing
// error pointer (nil when no throw). Empty input maps to (0, false, nil),
// matching Java's `null` return; a non-numeric string maps to a fresh
// Client_Setting_Value_Encoding_Exception wrapping a synthetic Throwable
// modeled after Java's NumberFormatException message.
integer_client_setting_decode_value :: proc(self: ^Integer_Client_Setting, encoded_value: string) -> (value: i32, present: bool, err: ^Client_Setting_Value_Encoding_Exception) {
	if len(encoded_value) == 0 {
		return 0, false, nil
	}
	parsed, ok := strconv.parse_int(encoded_value, 10)
	if !ok {
		cause := new(Throwable)
		cause.message = fmt.aprintf("For input string: \"%s\"", encoded_value)
		return 0, false, client_setting_value_encoding_exception_new(cause)
	}
	return i32(parsed), true, nil
}

