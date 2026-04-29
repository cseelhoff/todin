package game

import "core:fmt"
import "core:strconv"
import "core:strings"

Default_Attachment :: struct {
	using game_data_component: Game_Data_Component,
	attached_to:               ^Attachable,
	name:                      string,
}

// Mirrors Java's `Objects.hash(attachedTo, name)` from `DefaultAttachment.hashCode`.
// Uses FNV-1a over the name fields to stay deterministic across runs. The
// `Attachable` struct currently has no fields, so non-nil presence is mixed in
// as a single byte rather than a pointer address (which would be run-dependent).
default_attachment_hash_code :: proc(self: ^Default_Attachment) -> i32 {
	FNV_OFFSET :: u32(2166136261)
	FNV_PRIME :: u32(16777619)

	h := FNV_OFFSET
	mix_byte :: proc(h: u32, b: u8) -> u32 {
		return (h ~ u32(b)) * FNV_PRIME
	}

	// attachedTo: nil vs non-nil marker (Attachable has no name field yet).
	h = mix_byte(h, 0 if self == nil || self.attached_to == nil else 1)
	h = mix_byte(h, 0) // separator

	if self != nil {
		for i in 0 ..< len(self.name) {
			h = mix_byte(h, self.name[i])
		}
	}

	return i32(h)
}

// Synthetic lambda: `attachmentName -> attachmentName.replaceAll("ttatch", "ttach")`
// from `DefaultAttachment.setName(String)`.
default_attachment_lambda_set_name_1 :: proc(name: string) -> string {
	result, _ := strings.replace_all(name, "ttatch", "ttach")
	return result
}

// Java: protected static <K, V> Map<K, V> getMapProperty(@Nullable Map<K, V> value)
// Returns the input map, or an empty map if the input is nil/zero.
// Odin maps have no immutable wrapper; the returned map is the same value.
default_attachment_get_map_property :: proc(value: map[$K]$V) -> map[K]V {
	return value
}

// Java: protected static boolean getBool(final String value)
// Throws an error if format is invalid. Must be either true or false ignoring case.
// Mirrors `DefaultAttachment.getBool` using `Constants.PROPERTY_TRUE` ("true") and
// `Constants.PROPERTY_FALSE` ("false") with a case-insensitive comparison. The
// Java method is static; the `self` receiver is kept to match the project's
// call-site convention but is unused.
default_attachment_get_bool :: proc(self: ^Default_Attachment, value: string) -> bool {
	_ = self
	if strings.equal_fold(value, "true") {
		return true
	} else if strings.equal_fold(value, "false") {
		return false
	}
	fmt.panicf("Attachments: %s is not a valid boolean", value)
}

// Java: protected static <T> Set<T> getSetProperty(@Nullable Set<T> value)
// Sets are represented as `map[T]struct{}`; nil maps act as the empty set.
// Odin maps have no immutable wrapper; the returned map is the same value.
default_attachment_get_set_property :: proc(value: map[$T]struct {}) -> map[T]struct {} {
	return value
}

// Mirrors Java's `DefaultAttachment.equals(Object)`. The Java implementation
// is `final` and checks: identity, runtime class equality, string-form equality
// of `attachedTo`, and equality of `name` (with a `toString()` fallback that
// composes class + attachedTo + name). The Odin signature already constrains
// both operands to `^Default_Attachment`, so the `instanceof` / `getClass`
// branch collapses to a single nil check. `Attachable` currently has no
// fields, so its `Objects.toString` reduces to nil vs non-nil identity.
default_attachment_equals :: proc(self: ^Default_Attachment, other: ^Default_Attachment) -> bool {
	if self == other {
		return true
	}
	if self == nil || other == nil {
		return false
	}
	self_attached_nil := self.attached_to == nil
	other_attached_nil := other.attached_to == nil
	if self_attached_nil != other_attached_nil {
		return false
	}
	if !self_attached_nil && self.attached_to != other.attached_to {
		return false
	}
	return self.name == other.name
}

// Java: protected static int getInt(final String value)
// Mirrors `DefaultAttachment.getInt`: parses the string as a base-10 int and
// panics with the same "Attachments: <value> is not a valid int value"
// message Java raises via `IllegalArgumentException`. The Java method is
// static; the `self` receiver is kept to match the project's call-site
// convention but is unused.
default_attachment_get_int :: proc(self: ^Default_Attachment, value: string) -> i32 {
	_ = self
	parsed, ok := strconv.parse_int(value, 10)
	if !ok {
		fmt.panicf("Attachments: %s is not a valid int value", value)
	}
	return i32(parsed)
}

// Java: protected static <T> List<T> getListProperty(@Nullable List<T> value)
// Returns the input list, or an empty list if the input is nil/zero.
// Odin's `[dynamic]T` has no immutable wrapper; the returned list is the same value.
default_attachment_get_list_property :: proc(value: [dynamic]$T) -> [dynamic]T {
	return value
}


// Java's copyPropertyValue dispatches on List/IntegerMap/Set/Map via instanceof and shallow-copies.
// Odin lacks RTTI on opaque ^Object; ported as identity since typed callers use typed copy procs directly.
default_attachment_copy_property_value :: proc(value: ^Object) -> ^Object {
        return value
}

// Java: public void setName(final String name)
// Mirrors `DefaultAttachment.setName`: stores `name`, applying the legacy 1.8
// "ttatch" -> "ttach" spelling fix via `default_attachment_lambda_set_name_1`.
// Odin strings cannot be null; the empty string represents Java's null and is
// passed through unchanged (the legacy fix is a no-op on the empty string).
default_attachment_set_name :: proc(self: ^Default_Attachment, attachment_name: string) {
	if self == nil {
		return
	}
	self.name = default_attachment_lambda_set_name_1(attachment_name)
}

// Java: protected static String[] splitOnColon(final String value)
// Mirrors `DefaultAttachment.splitOnColon`, which delegates to Guava's
// `Splitter.on(':')` (no `omitEmptyStrings`, so empty segments are kept).
// Odin strings cannot be null, so the Java `checkNotNull(value)` precondition
// is implicit. Returns a `[dynamic]string` whose elements are slices into
// `value`; the caller owns the backing array and should `delete` it.
default_attachment_split_on_colon :: proc(value: string) -> [dynamic]string {
	parts := strings.split(value, ":")
	defer delete(parts)
	result: [dynamic]string
	for p in parts {
		append(&result, p)
	}
	return result
}
