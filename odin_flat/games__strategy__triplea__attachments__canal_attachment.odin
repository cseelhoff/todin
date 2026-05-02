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

// Java synthetic lambda from `CanalAttachment.getPropertyOrEmpty`'s
// `MutableProperty.ofMapper(DefaultAttachment::getBool, ...)` arm. Javac
// emits a static bridge `lambda$getPropertyOrEmpty$4(String) -> Boolean`
// because the functional interface (`ThrowingFunction<String, Boolean, ?>`)
// returns the boxed type while `DefaultAttachment.getBool` returns the
// primitive `boolean`. The Odin port has no boxing distinction; the
// bridge is a thin forwarder. `getBool` is static in Java; the Odin
// signature carries an unused `self` for project convention, so we pass
// `nil`.
canal_attachment_lambda_get_property_or_empty_4 :: proc(value: string) -> bool {
	return default_attachment_get_bool(nil, value)
}

// Java synthetic lambda inside `CanalAttachment.setLandTerritories(String)`:
//   () -> new GameParseException(
//             MessageFormat.format("TerritoryAttachment: No territory found for {0}; ...",
//                                  territoryName, landTerritories))
// Captured locals: `territoryName`, `landTerritories`. Used as the
// `Optional.orElseThrow(Supplier)` argument when `getTerritory(...)` is
// empty. Returns the exception object; the caller decides how to surface
// it. (`set_land_territories` in this file currently inlines the panic
// for callsite ergonomics, but the Java-bytecode-equivalent helper is
// preserved here.)
canal_attachment_lambda_set_land_territories_3 :: proc(
	territory_name: string,
	land_territories: string,
) -> ^Game_Parse_Exception {
	return make_Game_Parse_Exception(
		fmt.aprintf(
			"TerritoryAttachment: No territory found for %s; Setting landTerritories not possible with value %s",
			territory_name,
			land_territories,
		),
	)
}

// Java synthetic lambda inside private `get(Territory, Predicate)`:
//   attachment -> attachment.getName().startsWith(Constants.CANAL_ATTACHMENT_PREFIX)
// The stream operates on `Map<String, IAttachment>.values()`, so the
// parameter type is `IAttachment`. No captured environment.
canal_attachment_lambda_get_2 :: proc(attachment: ^I_Attachment) -> bool {
	return strings.has_prefix(i_attachment_get_name(attachment), CANAL_ATTACHMENT_PREFIX)
}

// Java synthetic lambda inside `hasCanal(Territory, String)`:
//   canalAttachment -> canalAttachment.getCanalName().equals(canalName)
// Captures `canalName`. Uses Java `String.equals`; Odin string equality
// (`==`) is content-based so it matches.
canal_attachment_lambda_has_canal_0 :: proc(
	canal_name: string,
	canal_attachment: ^Canal_Attachment,
) -> bool {
	return canal_attachment_get_canal_name(canal_attachment) == canal_name
}

// Captured environment for the `hasCanal` lambda when adapting it to
// the rawptr-keyed Predicate convention used by
// `canal_attachment_get_by_predicate`.
Canal_Attachment_Has_Canal_Ctx :: struct {
	canal_name: string,
}

canal_attachment_has_canal_predicate_thunk :: proc(
	ctx: rawptr,
	ca: ^Canal_Attachment,
) -> bool {
	c := cast(^Canal_Attachment_Has_Canal_Ctx)ctx
	return canal_attachment_lambda_has_canal_0(c.canal_name, ca)
}

// Java: private static boolean hasCanal(final Territory t, final String canalName)
//   return !get(t, ca -> ca.getCanalName().equals(canalName)).isEmpty();
// Uses the Predicate overload of `get`. The result list is allocated by
// `_by_predicate`; we must release it (and the captured ctx) once the
// emptiness check is done so callers don't leak temporaries.
canal_attachment_has_canal :: proc(t: ^Territory, canal_name: string) -> bool {
	ctx := new(Canal_Attachment_Has_Canal_Ctx)
	defer free(ctx)
	ctx.canal_name = canal_name
	matches := canal_attachment_get_by_predicate(
		t,
		canal_attachment_has_canal_predicate_thunk,
		ctx,
	)
	defer delete(matches)
	return len(matches) != 0
}

// Captured environment for the `get(Territory, Route)` lambda
// (`lambda$get$1`, ported separately at a higher method_layer). The ctx
// carries the captured `onRoute` reference.
Canal_Attachment_Get_By_Route_Ctx :: struct {
	route: ^Route,
}

canal_attachment_get_by_route_predicate_thunk :: proc(
	ctx: rawptr,
	attachment: ^Canal_Attachment,
) -> bool {
	c := cast(^Canal_Attachment_Get_By_Route_Ctx)ctx
	return canal_attachment_is_canal_on_route(
		canal_attachment_get_canal_name(attachment),
		c.route,
	)
}

// Java: public static List<CanalAttachment> get(final Territory t, final Route onRoute)
//   return get(t, attachment -> isCanalOnRoute(attachment.getCanalName(), onRoute));
// Delegates to the Predicate overload. Ownership: the returned dynamic
// array is owned by the caller (mirrors the existing `_by_predicate`
// contract); the small captured ctx is leaked intentionally for the
// duration of the call — `_by_predicate` does not retain it past return,
// but the caller can't free it without knowing the layout, so we free
// it here before returning.
canal_attachment_get :: proc(
	t: ^Territory,
	on_route: ^Route,
) -> [dynamic]^Canal_Attachment {
	ctx := new(Canal_Attachment_Get_By_Route_Ctx)
	defer free(ctx)
	ctx.route = on_route
	return canal_attachment_get_by_predicate(
		t,
		canal_attachment_get_by_route_predicate_thunk,
		ctx,
	)
}

// Java: public CanalAttachment(String name, Attachable attachable, GameData gameData)
//   super(name, attachable, gameData);
// Java's body chains directly to `DefaultAttachment(name, attachable, gameData)`;
// all instance fields use their declared defaults (`canalName = ""`,
// `landTerritories = null`, `excludedUnits = null`,
// `canNotMoveThroughDuringCombatMove = false`), which match Odin's zero
// values for `string`, the two `map` fields, and `bool` respectively, so
// no extra initialization is required.
// Per `default_attachment_new`'s contract ("subclass constructors should
// allocate their own concrete struct and embed/initialize via field
// assignment instead of calling this proc directly"), we replicate the
// `DefaultAttachment` super-constructor inline on the embedded
// `default_attachment` field — the same pattern used by
// `relationship_type_attachment_new`.
canal_attachment_new :: proc(
	name: string,
	attachable: ^Attachable,
	game_data: ^Game_Data,
) -> ^Canal_Attachment {
	self := new(Canal_Attachment)
	self.default_attachment.game_data_component = make_Game_Data_Component(game_data)
	default_attachment_set_name(&self.default_attachment, name)
	default_attachment_set_attached_to(&self.default_attachment, attachable)
	return self
}

// Java: public Set<UnitType> getExcludedUnits()
//   if (excludedUnits == null) {
//     return new HashSet<>(
//         CollectionUtils.getMatches(
//             getData().getUnitTypeList().getAllUnitTypes(), Matches.unitTypeIsAir()));
//   }
//   return excludedUnits;
// The Odin field `excluded_units` is `map[^Unit_Type]struct{}`; we cannot
// distinguish a Java `null` from an explicitly-set empty `HashSet` without
// changing the struct shape, so this port follows the existing
// "len == 0 ⇒ unset" convention used elsewhere in
// `attachments/unit_attachment.odin`. When the set is empty we synthesize
// the air-units default (Java's `CollectionUtils.getMatches(allUnitTypes,
// Matches.unitTypeIsAir())`); otherwise we return the stored set
// directly.
//
// Note on `collection_utils_get_matches`: its signature operates on
// `[dynamic]rawptr` with a non-capturing `proc(rawptr) -> bool`
// predicate, while `matches_unit_type_is_air()` produces the project's
// `(proc(rawptr, ^Unit_Type) -> bool, rawptr)` Predicate pair. Bridging
// the two would require fabricating a wrapper closure; the Java source
// is itself a single-pass filter, so we inline the loop here, calling
// the underlying `matches_pred_unit_type_is_air` thunk directly.
canal_attachment_get_excluded_units :: proc(self: ^Canal_Attachment) -> map[^Unit_Type]struct{} {
	if len(self.excluded_units) == 0 {
		result: map[^Unit_Type]struct{}
		data := game_data_component_get_data(&self.default_attachment.game_data_component)
		utl := game_data_get_unit_type_list(data)
		all := unit_type_list_get_all_unit_types(utl)
		for ut in all {
			if matches_pred_unit_type_is_air(nil, ut) {
				result[ut] = {}
			}
		}
		return result
	}
	return self.excluded_units
}

// Java: private static boolean isCanalOnRoute(final String canalName, final Route route)
//   boolean previousTerritoryHasCanal = false;
//   for (final Territory t : route) {
//     boolean currentTerritoryHasCanal = hasCanal(t, canalName);
//     if (previousTerritoryHasCanal && currentTerritoryHasCanal) {
//       return true;
//     }
//     previousTerritoryHasCanal = currentTerritoryHasCanal;
//   }
//   return false;
// Direct port. Iteration uses `route_iterator`, the established Odin
// surface for `for (Territory t : route)`. The proc is static in Java,
// so it takes no `self` parameter.
canal_attachment_is_canal_on_route :: proc(canal_name: string, route: ^Route) -> bool {
	previous_territory_has_canal := false
	territories := route_iterator(route)
	defer delete(territories)
	for t in territories {
		current_territory_has_canal := canal_attachment_has_canal(t, canal_name)
		if previous_territory_has_canal && current_territory_has_canal {
			return true
		}
		previous_territory_has_canal = current_territory_has_canal
	}
	return false
}
