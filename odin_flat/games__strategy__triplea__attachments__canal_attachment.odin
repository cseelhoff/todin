package game

import "core:fmt"
import "core:strings"

CANAL_ATTACHMENT_PREFIX :: "canalAttachment"

Canal_Attachment :: struct {
	using default_attachment: Default_Attachment,
	canal_name: string,
	land_territories: map[^Territory]struct{},
	excluded_units: map[^Unit_Type]struct{},
	can_not_move_through_during_combat_move: bool,
}

// Java: @Getter private String canalName = ""; -> public String getCanalName()
canal_attachment_get_canal_name :: proc(self: ^Canal_Attachment) -> string {
	return self.canal_name
}

// Java: public boolean getCanNotMoveThroughDuringCombatMove()
canal_attachment_get_can_not_move_through_during_combat_move :: proc(
	self: ^Canal_Attachment,
) -> bool {
	return self.can_not_move_through_during_combat_move
}

// Java: public Set<Territory> getLandTerritories()
//   return getSetProperty(landTerritories);
// `getSetProperty` is the identity for non-nil maps; an unset map field is
// the empty set in Odin (zero-valued maps act as empty maps for read-only
// iteration), matching Java's `Set.of()` for the null case.
canal_attachment_get_land_territories :: proc(
	self: ^Canal_Attachment,
) -> map[^Territory]struct {} {
	return default_attachment_get_set_property(self.land_territories)
}

// Java: private void setCanalName(final String name) { canalName = name.intern(); }
// Odin has no string interning; storing the string directly preserves
// identity-by-content for equality comparisons used by `hasCanal`.
canal_attachment_set_canal_name :: proc(self: ^Canal_Attachment, name: string) {
	self.canal_name = name
}

// Java: private void setLandTerritories(final String landTerritories) throws GameParseException
// Splits on ':' and resolves each segment through `getData().getMap()
// .getTerritoryOrNull`. Java raises `GameParseException` on the first
// unknown territory; the project's convention (e.g. `game_parser_get_player_id`)
// is to surface the same condition as a `panicf` carrying Java's message.
canal_attachment_set_land_territories :: proc(
	self: ^Canal_Attachment,
	land_territories: string,
) {
	terrs: map[^Territory]struct{}
	game_data := game_data_component_get_data(
		&self.default_attachment.game_data_component,
	)
	game_map := game_data_get_map(game_data)
	parts := default_attachment_split_on_colon(land_territories)
	defer delete(parts)
	for territory_name in parts {
		territory := game_map_get_territory_or_null(game_map, territory_name)
		if territory == nil {
			fmt.panicf(
				"TerritoryAttachment: No territory found for %s; Setting landTerritories not possible with value %s",
				territory_name,
				land_territories,
			)
		}
		terrs[territory] = {}
	}
	self.land_territories = terrs
}

// Java: static CanalAttachment get(final Territory t, final String nameOfAttachment)
//   return getAttachment(t, nameOfAttachment, CanalAttachment.class);
// Inlines `DefaultAttachment.getAttachment`'s `Optional.ofNullable(...).
// orElseThrow(IllegalStateException::new)` since the Odin port lacks RTTI
// for `attachmentType.cast`. Named with `_by_name` to disambiguate from the
// Predicate overload below.
canal_attachment_get_by_name :: proc(
	t: ^Territory,
	name_of_attachment: string,
) -> ^Canal_Attachment {
	raw := named_attachable_get_attachment(&t.named_attachable, name_of_attachment)
	if raw == nil {
		owner_name := default_named_get_name(&t.named_attachable.default_named)
		fmt.panicf(
			"No attachment named '%s' of type 'CanalAttachment' for object named '%s'",
			name_of_attachment,
			owner_name,
		)
	}
	return cast(^Canal_Attachment)raw
}

// Java: private static List<CanalAttachment> get(final Territory t,
//                                                Predicate<CanalAttachment> cond)
// Streams `t.getAttachments().values()`, retains entries whose name starts
// with `Constants.CANAL_ATTACHMENT_PREFIX`, casts to `CanalAttachment`, and
// keeps those matching `cond`. Named with `_by_predicate` to disambiguate
// from the String overload above. The predicate uses the project's
// closure-capture convention (`proc(rawptr, ^T) -> bool` paired with a
// `rawptr` ctx) since callers (e.g. the public Route overload) capture the
// surrounding canal name / route.
canal_attachment_get_by_predicate :: proc(
	t: ^Territory,
	cond: proc(rawptr, ^Canal_Attachment) -> bool,
	cond_ctx: rawptr,
) -> [dynamic]^Canal_Attachment {
	result: [dynamic]^Canal_Attachment
	for name, attachment in t.named_attachable.attachments {
		if !strings.has_prefix(name, CANAL_ATTACHMENT_PREFIX) {
			continue
		}
		ca := cast(^Canal_Attachment)attachment
		if cond(cond_ctx, ca) {
			append(&result, ca)
		}
	}
	return result
}

// Java synthetic lambda from `CanalAttachment.getPropertyOrEmpty`:
//   () -> false
// Used as the default-value supplier in
// `MutableProperty.ofMapper(getBool, setCanNotMoveThroughDuringCombatMove,
// getCanNotMoveThroughDuringCombatMove, () -> false)` for the
// `canNotMoveThroughDuringCombatMove` property. Pure constant.
canal_attachment_lambda_get_property_or_empty_5 :: proc() -> bool {
	return false
}
