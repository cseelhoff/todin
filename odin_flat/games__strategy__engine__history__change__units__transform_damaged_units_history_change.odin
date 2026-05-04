package game

import "core:fmt"

// Inner class Transform_Damaged_Units_History_Change_Grouped_Units is
// defined in transform_damaged_units_history_change__grouped_units.odin
// (Odin package scope is flat across odin_flat/).

Transform_Damaged_Units_History_Change :: struct {
	change:                        ^Composite_Change,
	location:                      ^Territory,
	transforming_units:            map[^Unit]^Unit,
	attribute_changes:             ^Composite_Change,
	mark_no_movement_on_new_units: bool,
}

// Java:
//   public TransformDamagedUnitsHistoryChange(
//       final Territory location,
//       final Collection<Unit> damagedUnits,
//       final boolean markNoMovementOnNewUnits) { ... }
// Mirrors the Java field initializers (`change = new CompositeChange()`,
// `transformingUnits = new HashMap<>()`, `attributeChanges =
// new CompositeChange()`) plus the constructor body that walks
// `damagedUnits`, consults each unit's
// `whenHitPointsDamagedChangesInto` map keyed by current hits, and on
// a hit translates attributes (when the tuple's first flag is set)
// and records the old→new mapping.
transform_damaged_units_history_change_new :: proc(
	location: ^Territory,
	damaged_units: [dynamic]^Unit,
	mark_no_movement_on_new_units: bool,
) -> ^Transform_Damaged_Units_History_Change {
	self := new(Transform_Damaged_Units_History_Change)
	self.change = composite_change_new()
	self.location = location
	self.transforming_units = make(map[^Unit]^Unit)
	self.attribute_changes = composite_change_new()
	self.mark_no_movement_on_new_units = mark_no_movement_on_new_units

	for unit in damaged_units {
		m := unit_attachment_get_when_hit_points_damaged_changes_into(
			unit_get_unit_attachment(unit),
		)
		hits := unit_get_hits(unit)
		tup, ok := m[hits]
		if !ok {
			continue
		}
		translate_attributes := tuple_get_first(tup)
		unit_type := tuple_get_second(tup)
		to_add := unit_type_create_2(unit_type, 1, unit_get_owner(unit))
		if translate_attributes {
			composite_change_add(
				self.attribute_changes,
				unit_utils_translate_attributes_to_other_units(unit, to_add, location),
			)
		}
		self.transforming_units[unit] = to_add[0]
	}
	return self
}

// Java: public Collection<Unit> getOldUnits()
//   return Collections.unmodifiableCollection(transformingUnits.keySet());
// The Java field has no `oldUnits` storage — the getter is a live view
// over `transformingUnits.keySet()`. In Odin we surface a fresh
// snapshot as a dynamic array of pointers (matching the convention
// used by `resource_list_get_resources`); the caller owns the
// returned array.
transform_damaged_units_history_change_get_old_units :: proc(
	self: ^Transform_Damaged_Units_History_Change,
) -> [dynamic]^Unit {
	out := make([dynamic]^Unit, 0, len(self.transforming_units))
	for old_unit, _ in self.transforming_units {
		append(&out, old_unit)
	}
	return out
}

// Java: public Collection<Unit> getNewUnits()
//   return Collections.unmodifiableCollection(transformingUnits.values());
// As with `getOldUnits`, the Java class has no `newUnits` field;
// we materialize a fresh snapshot of the map values.
transform_damaged_units_history_change_get_new_units :: proc(
	self: ^Transform_Damaged_Units_History_Change,
) -> [dynamic]^Unit {
	out := make([dynamic]^Unit, 0, len(self.transforming_units))
	for _, new_unit in self.transforming_units {
		append(&out, new_unit)
	}
	return out
}

// Java synthetic lambda from `perform`:
//   groupedByOldAndNewUnitTypes.computeIfAbsent(oldUnit.getType(), k -> new HashMap<>())
// Non-capturing; returns a fresh empty inner map keyed by ^Unit_Type
// of grouped-units pointers. The `k` parameter (the absent key) is
// ignored, mirroring the Java lambda's body.
transform_damaged_units_history_change_lambda_perform_0 :: proc(
	k: ^Unit_Type,
) -> map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units {
	return make(map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units)
}

// Java synthetic lambda from `perform`:
//   .flatMap(tmp -> tmp.values().stream())
// Non-capturing; flattens the inner map's values into a fresh
// dynamic array of grouped-units pointers (Odin's stand-in for
// the Java stream the caller iterates over). Caller owns the array.
transform_damaged_units_history_change_lambda_perform_3 :: proc(
	tmp: map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units,
) -> [dynamic]^Transform_Damaged_Units_History_Change_Grouped_Units {
	out := make([dynamic]^Transform_Damaged_Units_History_Change_Grouped_Units, 0, len(tmp))
	for _, grouped in tmp {
		append(&out, grouped)
	}
	return out
}

// Java synthetic lambda from `perform`:
//   .computeIfAbsent(newUnit.getType(), k -> new GroupedUnits())
// Non-capturing; allocates a fresh GroupedUnits when the inner map
// has no entry for the new-unit type. The `k` parameter (the absent
// key) is ignored, mirroring the Java lambda body.
transform_damaged_units_history_change_lambda_perform_1 :: proc(
	k: ^Unit_Type,
) -> ^Transform_Damaged_Units_History_Change_Grouped_Units {
	return transform_damaged_units_history_change_grouped_units_new()
}

// Java synthetic lambda from `perform` (BiConsumer for
// `transformingUnits.forEach`):
//   (oldUnit, newUnit) ->
//       groupedByOldAndNewUnitTypes
//           .computeIfAbsent(oldUnit.getType(), k -> new HashMap<>())
//           .computeIfAbsent(newUnit.getType(), k -> new GroupedUnits())
//           .addUnits(oldUnit, newUnit)
// Captures the outer `groupedByOldAndNewUnitTypes` map. Java's
// `Map.computeIfAbsent` both inserts the freshly created value when
// the key is missing AND returns it; we replicate that contract
// directly against Odin's builtin `map` (no helper proc available),
// chaining the outer and inner maps to land at the GroupedUnits
// instance and then delegating to its `add_units` proc.
transform_damaged_units_history_change_lambda_perform_2 :: proc(
	grouped_by_old_and_new_unit_types: map[^Unit_Type]map[^Unit_Type]^Transform_Damaged_Units_History_Change_Grouped_Units,
	old_unit: ^Unit,
	new_unit: ^Unit,
) {
	outer := grouped_by_old_and_new_unit_types
	old_type := unit_get_type(old_unit)
	inner, has_inner := outer[old_type]
	if !has_inner {
		inner = transform_damaged_units_history_change_lambda_perform_0(old_type)
		outer[old_type] = inner
	}
	new_type := unit_get_type(new_unit)
	grouped, has_grouped := inner[new_type]
	if !has_grouped {
		grouped = transform_damaged_units_history_change_lambda_perform_1(new_type)
		inner[new_type] = grouped
	}
	transform_damaged_units_history_change_grouped_units_add_units(grouped, old_unit, new_unit)
}

// Java synthetic lambda from `perform` (Consumer in the terminal
// `forEach` over the flat-mapped GroupedUnits stream):
//   (groupedUnits) -> {
//       final String transformTranscriptText =
//           MyFormatter.unitsToText(groupedUnits.getOldUnits())
//               + " transformed into "
//               + MyFormatter.unitsToText(groupedUnits.getNewUnits())
//               + " in "
//               + location.getName();
//       bridge.getHistoryWriter()
//             .addChildToEvent(transformTranscriptText, groupedUnits.getOldUnits());
//   }
// In Java this is a non-static synthetic instance method capturing
// `bridge` (a final local of `perform`) plus the implicit `this`
// (for `location`); the bytecode signature lists only
// `(IDelegateBridge, GroupedUnits)`. In Odin we surface `this` as
// an explicit `self` receiver so the proc body can read
// `self.location`, matching the Java semantics one-to-one.
transform_damaged_units_history_change_lambda_perform_4 :: proc(
	self: ^Transform_Damaged_Units_History_Change,
	bridge: ^I_Delegate_Bridge,
	grouped_units: ^Transform_Damaged_Units_History_Change_Grouped_Units,
) {
	old_units := transform_damaged_units_history_change_grouped_units_get_old_units(grouped_units)
	new_units := transform_damaged_units_history_change_grouped_units_get_new_units(grouped_units)
	transform_transcript_text := fmt.aprintf(
		"%s transformed into %s in %s",
		my_formatter_units_to_text(old_units),
		my_formatter_units_to_text(new_units),
		default_named_get_name(&self.location.named_attachable.default_named),
	)
	writer := i_delegate_bridge_get_history_writer(bridge)
	history_writer_add_child_to_event(writer, transform_transcript_text, old_units)
}

