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

// Java: public void setAttachedTo(Attachable attachedTo) (Lombok @Setter)
// Mirrors `DefaultAttachment.setAttachedTo`: stores the `attachable` reference
// on the receiver. Java's Lombok-generated setter performs no validation.
default_attachment_set_attached_to :: proc(self: ^Default_Attachment, attachable: ^Attachable) {
	if self == nil {
		return
	}
	self.attached_to = attachable
}

// Java: protected String thisErrorMsg() { return ", for: " + this; }
// Mirrors `DefaultAttachment.thisErrorMsg`. Java's `+` on a non-String operand
// implicitly dispatches to `this.toString()`; Odin requires the explicit call
// to `default_attachment_to_string`. Returns a freshly allocated string owned
// by the caller (the Java GC equivalent — caller must `delete` when done).
default_attachment_this_error_msg :: proc(self: ^Default_Attachment) -> string {
	rendered := default_attachment_to_string(self)
	defer delete(rendered)
	return fmt.aprintf(", for: %s", rendered)
}

// Java: @Override public String toString()
// Mirrors `DefaultAttachment.toString`:
//   getClass().getSimpleName() + " attached to: " + attachedTo
//     + " with name: " + Optional.ofNullable(name).orElse("<no name>")
// Odin lacks RTTI for `getClass().getSimpleName()`; the literal class name
// "DefaultAttachment" is used (subclasses that override `toString` will
// supply their own simple name). `Attachable` has no fields/`toString`
// override in the port, so its rendering follows Java's `Object.toString`
// shape: "null" for nil, otherwise an identity tag using the pointer.
// Java strings can be null; in Odin the empty string represents that, and
// is rendered as "<no name>". Returns a heap-allocated string owned by the
// caller.
default_attachment_to_string :: proc(self: ^Default_Attachment) -> string {
	attached_to_str: string
	attached_to_owned := false
	if self == nil || self.attached_to == nil {
		attached_to_str = "null"
	} else {
		attached_to_str = fmt.aprintf("Attachable@%p", self.attached_to)
		attached_to_owned = true
	}
	defer if attached_to_owned do delete(attached_to_str)

	name_str: string = "<no name>"
	if self != nil && self.name != "" {
		name_str = self.name
	}
	return fmt.aprintf(
		"DefaultAttachment attached to: %s with name: %s",
		attached_to_str,
		name_str,
	)
}

// Java: public String getRawPropertyString(final String property)
//   return getProperty(property).map(MutableProperty::getValue).map(Object::toString).orElse(null);
// Java's `getProperty` is `DynamicallyModifiable.getProperty`, dispatched via
// the concrete subclass's `getPropertyOrEmpty`. The Odin `Default_Attachment`
// struct does not embed `Dynamically_Modifiable`, so there is no get-property
// table reachable from `^Default_Attachment` alone; concrete subclasses keep
// their own property maps and own `getRawPropertyString` shapes. Likewise
// `Mutable_Property.getter` returns `rawptr`, for which Odin has no generic
// `Object::toString` (the same RTTI gap noted on
// `default_attachment_copy_property_value`). The faithful translation of
// `getProperty(property).orElse(null)` from Default_Attachment scope is
// therefore the empty string (Odin's null-string sentinel) — every property
// lookup at this scope is `Optional.empty()`.
default_attachment_get_raw_property_string :: proc(self: ^Default_Attachment, name: string) -> string {
	_ = self
	_ = name
	return ""
}

// Java synthetic lambda from `DefaultAttachment.getAttachment`:
//   () -> new IllegalStateException(String.format(
//       "No attachment named '%s' of type '%s' for object named '%s'",
//       attachmentName, attachmentType, namedAttachable.getName()))
// Builds the IllegalStateException that `Optional.orElseThrow` raises when a
// requested attachment is missing. The Odin port has a `Throwable` shim
// (`java.lang.Throwable`) but no dedicated IllegalStateException type, so we
// allocate a `Throwable` carrying the formatted message — callers raise it
// the same way they do other Throwable values in the port. `attachmentType`
// is rendered via `class_to_string` to mirror Java's `Class.toString` (the
// "class <fqn>" form is irrelevant here because the message embeds the class
// name as a single `%s`, which Java resolves through `Class.toString` on the
// argument). The returned Throwable is heap-allocated; the caller owns it
// and the message string it carries.
default_attachment_lambda_get_attachment_0 :: proc(
	attachment_name: string,
	attachment_type: ^Class,
	named_attachable: ^Named_Attachable,
) -> ^Throwable {
	type_str := class_to_string(attachment_type)
	owner_name: string
	if named_attachable != nil {
		owner_name = named_attachable.named.base.name
	}
	t := new(Throwable)
	t.message = fmt.aprintf(
		"No attachment named '%s' of type '%s' for object named '%s'",
		attachment_name,
		type_str,
		owner_name,
	)
	return t
}

// Java: protected DefaultAttachment(String name, Attachable attachable, GameData gameData)
// Constructor → calls super(gameData), setName(name), setAttachedTo(attachable).
// Allocates a fresh `Default_Attachment` and applies the same setter chain
// the Java constructor does, so the legacy "ttatch" -> "ttach" spelling fix
// in `set_name` is honored. Subclass constructors should allocate their own
// concrete struct and embed/initialize via field assignment instead of
// calling this proc directly.
default_attachment_new :: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^Default_Attachment {
	self := new(Default_Attachment)
	self.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(self, name)
	default_attachment_set_attached_to(self, attachable)
	return self
}

// Java: protected static <T extends IAttachment> T getAttachment(
//           NamedAttachable namedAttachable, String attachmentName, Class<T> attachmentType)
// Java performs a reflective `attachmentType.cast(...)` and throws an
// IllegalStateException when the attachment is missing. Odin lacks runtime
// type checks on `^I_Attachment`; the port reduces to a name lookup on the
// owner's attachment map, returning the stored `^I_Attachment` (the caller
// performs the typed reinterpret_cast at the call site, mirroring the
// pattern used by e.g. `unit_attachment_get` in the port). When the
// attachment is missing the proc panics with the same message Java's
// IllegalStateException carries (built via
// `default_attachment_lambda_get_attachment_0`). The `Class` token is kept
// for fidelity with the Java signature and for the error message; it is
// otherwise unused at runtime.
default_attachment_get_attachment :: proc(
	named_attachable: ^Named_Attachable,
	attachment_name: string,
	attachment_type: ^Class,
) -> ^I_Attachment {
	if named_attachable == nil {
		panic("namedAttachable must not be null")
	}
	if attachment_type == nil {
		panic("attachmentType must not be null")
	}
	result := named_attachable_get_attachment(named_attachable, attachment_name)
	if result == nil {
		err := default_attachment_lambda_get_attachment_0(
			attachment_name,
			attachment_type,
			named_attachable,
		)
		message := err.message
		fmt.panicf("%s", message)
	}
	return result
}

// Java: protected Optional<Territory> getTerritory(@Nullable String territoryName)
// Returns the Territory looked up by name on the GameData's GameMap, or nil
// when the name is not registered. Odin uses `nil` as the empty-Optional
// sentinel; Java's `Optional.ofNullable` collapses to a direct nil pass-through.
default_attachment_get_territory :: proc(self: ^Default_Attachment, territory_name: string) -> ^Territory {
	if self == nil {
		return nil
	}
	data := game_data_component_get_data(&self.game_data_component)
	if data == nil {
		return nil
	}
	gmap := game_data_get_map(data)
	if gmap == nil {
		return nil
	}
	return game_map_get_territory_or_null(gmap, territory_name)
}

// Java: public UnitType getUnitTypeOrThrow(String unitType) throws GameParseException
// Mirrors `getDataOrThrow().getUnitTypeList().getUnitType(unitType)
//   .orElseThrow(() -> new GameParseException("No unit type: " + unitType + thisErrorMsg()))`.
// Java raises GameParseException; the port panics with the same message string,
// constructed by `default_attachment_lambda_get_unit_type_or_throw_3`.
default_attachment_get_unit_type_or_throw :: proc(self: ^Default_Attachment, unit_type: string) -> ^Unit_Type {
	data := game_data_component_get_data_or_throw(&self.game_data_component)
	utl := game_data_get_unit_type_list(data)
	ut := unit_type_list_get_unit_type(utl, unit_type)
	if ut == nil {
		err := default_attachment_lambda_get_unit_type_or_throw_3(self, unit_type)
		message := err.message
		fmt.panicf("%s", message)
	}
	return ut
}

// Java synthetic lambda from `DefaultAttachment.getUnitTypeOrThrow`:
//   () -> new GameParseException("No unit type: " + unitType + thisErrorMsg())
// Builds the GameParseException raised when a unit type lookup fails. The
// returned exception is heap-allocated and owns its message string; the
// caller takes ownership.
default_attachment_lambda_get_unit_type_or_throw_3 :: proc(
	self: ^Default_Attachment,
	unit_type: string,
) -> ^Game_Parse_Exception {
	suffix := default_attachment_this_error_msg(self)
	defer delete(suffix)
	message := fmt.aprintf("No unit type: %s%s", unit_type, suffix)
	return make_Game_Parse_Exception(message)
}

// Java synthetic lambda from `DefaultAttachment.parsePlayerList`:
//   () -> new GameParseException(MessageFormat.format(
//       "DefaultAttachment: Parsing PlayerList with value {0} not possible; No player found for {1}",
//       value, name))
// Builds the GameParseException raised when a player-name segment in a
// colon-separated PlayerList does not resolve to a known player. Returns a
// heap-allocated exception whose message string is owned by the caller.
default_attachment_lambda_parse_player_list_2 :: proc(
	value: string,
	name: string,
) -> ^Game_Parse_Exception {
	message := fmt.aprintf(
		"DefaultAttachment: Parsing PlayerList with value %s not possible; No player found for %s",
		value,
		name,
	)
	return make_Game_Parse_Exception(message)
}

// Java: protected static <T> IntegerMap<T> getIntegerMapProperty(@Nullable IntegerMap<T> value)
//   if (value == null) return IntegerMap.of();
//   return IntegerMap.unmodifiableViewOf(value);
// Odin lacks an immutable-view wrapper for `Integer_Map`, so the non-nil
// branch returns the input pointer directly (matching the pattern used by
// `default_attachment_get_list_property` / `_get_map_property` /
// `_get_set_property`). The nil branch allocates a fresh empty
// `Integer_Map` to mirror Java's `IntegerMap.of()` empty-instance return.
default_attachment_get_integer_map_property :: proc(value: ^Integer_Map) -> ^Integer_Map {
	if value == nil {
		return integer_map_new()
	}
	return value
}

// Java: protected Optional<GamePlayer> getPlayerByName(String name)
//   return Optional.ofNullable(getData().getPlayerList().getPlayerId(name));
// Odin uses `nil` as the empty-Optional sentinel; Java's `Optional.ofNullable`
// collapses to a direct nil pass-through. Mirrors the chain
// `getData() -> getPlayerList() -> getPlayerId(name)`.
default_attachment_get_player_by_name :: proc(self: ^Default_Attachment, name: string) -> ^Game_Player {
	if self == nil {
		return nil
	}
	data := game_data_component_get_data(&self.game_data_component)
	if data == nil {
		return nil
	}
	pl := game_data_get_player_list(data)
	if pl == nil {
		return nil
	}
	return player_list_get_player_id(pl, name)
}
