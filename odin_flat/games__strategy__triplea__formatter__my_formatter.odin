package game

import "core:fmt"
import "core:strings"

My_Formatter :: struct {}

// Java private static String pluralize(final String in)
// Static `plural` map exceptions:
//   armour    -> armour
//   infantry  -> infantry
//   artillery -> artilleries
//   factory   -> factories
// Else: words ending in "man" -> "...men"; otherwise append "s".
my_formatter_pluralize :: proc(s: string) -> string {
	switch s {
	case "armour":
		return "armour"
	case "infantry":
		return "infantry"
	case "artillery":
		return "artilleries"
	case "factory":
		return "factories"
	}
	if strings.has_suffix(s, "man") {
		idx := strings.last_index(s, "man")
		return fmt.aprintf("%s%s", s[:idx], "men")
	}
	return fmt.aprintf("%ss", s)
}

// Java public static String attachmentNameToText(final String attachmentGetName)
// Replaces a known attachment-name prefix with a human-readable form,
// then collapses underscores to spaces, doubled spaces to single, and
// trims trailing whitespace. Constants values are inlined from
// games.strategy.triplea.Constants.
my_formatter_attachment_name_to_text :: proc(attachment_get_name: string) -> string {
	to_text := attachment_get_name
	replace_prefix :: proc(s, prefix, replacement: string) -> (string, bool) {
		if strings.has_prefix(s, prefix) {
			return fmt.aprintf("%s%s", replacement, s[len(prefix):]), true
		}
		return s, false
	}
	ok: bool
	if to_text, ok = replace_prefix(to_text, "relationshipTypeAttachment", "Relationship Type "); ok {
	} else if to_text, ok = replace_prefix(to_text, "techAttachment", "Player Techs "); ok {
	} else if to_text, ok = replace_prefix(to_text, "unitAttachment", "Unit Type Properties "); ok {
	} else if to_text, ok = replace_prefix(to_text, "territoryAttachment", "Territory Properties "); ok {
	} else if to_text, ok = replace_prefix(to_text, "canalAttachment", "Canal "); ok {
	} else if to_text, ok = replace_prefix(to_text, "territoryEffectAttachment", "Territory Effect "); ok {
	} else if to_text, ok = replace_prefix(to_text, "supportAttachment", "Support "); ok {
	} else if to_text, ok = replace_prefix(to_text, "objectiveAttachment", "Objective "); ok {
	} else if to_text, ok = replace_prefix(to_text, "conditionAttachment", "Condition "); ok {
	} else if to_text, ok = replace_prefix(to_text, "triggerAttachment", "Trigger "); ok {
	} else if to_text, ok = replace_prefix(to_text, "rulesAttachment", "Rules "); ok {
	} else if to_text, ok = replace_prefix(to_text, "playerAttachment", "Player Properties "); ok {
	} else if to_text, ok = replace_prefix(to_text, "politicalActionAttachment", "Political Action "); ok {
	} else if to_text, ok = replace_prefix(to_text, "userActionAttachment", "Action "); ok {
	} else if to_text, ok = replace_prefix(to_text, "techAbilityAttachment", "Tech Properties "); ok {
	}
	to_text, _ = strings.replace_all(to_text, "_", " ")
	to_text, _ = strings.replace_all(to_text, "  ", " ")
	to_text = strings.trim_space(to_text)
	return to_text
}

// Synthetic Java lambda from `asDice(int[])`: `roll -> roll + 1`.
my_formatter_lambda_as_dice_1 :: proc(roll: i32) -> i32 {
	return roll + 1
}

// Java public static String asDice(final int[] rolls)
// Returns "none" for null/empty; otherwise comma-joined `roll+1` values.
// Renamed from `my_formatter_as_dice` to free the bare name for the
// DiceRoll overload; the int[] variant takes the `_ints` suffix.
my_formatter_as_dice_ints :: proc(rolls: []i32) -> string {
	if rolls == nil || len(rolls) == 0 {
		return "none"
	}
	b := strings.builder_make()
	for r, i in rolls {
		if i > 0 {
			strings.write_string(&b, ",")
		}
		fmt.sbprintf(&b, "%d", my_formatter_lambda_as_dice_1(r))
	}
	return strings.to_string(b)
}

// Java public static String unitsToText(final Collection<Unit> units)
// Groups units by (UnitType, Owner) — equivalent to Java's `UnitOwner`
// equals/hashCode of `(type, owner)` — counts each group, and emits
// "<q> <type>[s] owned by the <owner>" joined by ", " with a final " and ".
// HashMap iteration order is unspecified in Java; Odin map iteration
// matches that lack of guarantee, so the relative ordering matches the
// non-deterministic Java behavior.
my_formatter_units_to_text :: proc(units: [dynamic]^Unit) -> string {
	Key :: struct {
		type:  ^Unit_Type,
		owner: ^Game_Player,
	}
	quantities := make(map[Key]i64)
	defer delete(quantities)
	for unit in units {
		k := Key{type = unit_get_type(unit), owner = unit_get_owner(unit)}
		quantities[k] = quantities[k] + 1
	}

	b := strings.builder_make()
	count_ref := i32(len(quantities))
	for key, quantity in quantities {
		fmt.sbprintf(&b, "%d ", quantity)
		type_name := default_named_get_name(&key.type.named_attachable.default_named)
		if quantity > 1 {
			strings.write_string(&b, my_formatter_pluralize(type_name))
		} else {
			strings.write_string(&b, type_name)
		}
		strings.write_string(&b, " owned by the ")
		owner_name := default_named_get_name(&key.owner.named_attachable.default_named)
		strings.write_string(&b, owner_name)
		count_ref -= 1
		if count_ref > 1 {
			strings.write_string(&b, ", ")
		} else if count_ref == 1 {
			strings.write_string(&b, " and ")
		}
	}
	return strings.to_string(b)
}

// Java private lambda from `unitsToText`:
//   (owner, quantity) -> { buf.append(...); ... }
// Captures the StringBuilder and AtomicInteger countRef. In Odin we
// hoist the body to a free proc taking explicit ^strings.Builder and
// ^i32 parameters; the actual `unitsToText` proc above inlines the
// loop so this free proc is kept for fidelity with the method_key list.
my_formatter_lambda_units_to_text_0 :: proc(
	buf: ^strings.Builder,
	count_ref: ^i32,
	owner: ^Unit_Owner,
	quantity: i64,
) {
	fmt.sbprintf(buf, "%d ", quantity)
	type_name := default_named_get_name(
		&unit_owner_get_type(owner).named_attachable.default_named,
	)
	if quantity > 1 {
		strings.write_string(buf, my_formatter_pluralize(type_name))
	} else {
		strings.write_string(buf, type_name)
	}
	strings.write_string(buf, " owned by the ")
	owner_name := default_named_get_name(
		&unit_owner_get_owner(owner).named_attachable.default_named,
	)
	strings.write_string(buf, owner_name)
	count_ref^ -= 1
	if count_ref^ > 1 {
		strings.write_string(buf, ", ")
	} else if count_ref^ == 1 {
		strings.write_string(buf, " and ")
	}
}

// Java public static String pluralize(final String in, final int quantity)
// quantity == -1 || quantity == 1 → return as-is, else fall through to
// the 1-arg pluralize.
my_formatter_pluralize_quantity :: proc(s: string, quantity: i32) -> string {
	if quantity == -1 || quantity == 1 {
		return s
	}
	return my_formatter_pluralize(s)
}

// Java public static String unitsToTextNoOwner(Collection<Unit>, GamePlayer)
// Histograms the units by UnitType (filtered by owner if owner != nil),
// sorts the resulting types by name, and emits "<q> <type>[s]" joined
// by ", " with a final " and ".
my_formatter_units_to_text_no_owner :: proc(
	units: [dynamic]^Unit,
	owner: ^Game_Player,
) -> string {
	im := integer_map_new()
	defer free(im)
	for unit in units {
		if owner == nil || owner == unit_get_owner(unit) {
			integer_map_add(im, rawptr(unit_get_type(unit)), 1)
		}
	}

	keys := integer_map_key_set(im)
	defer delete(keys)
	// Sort on unit name (stable insertion sort: small N, no allocations).
	sorted: [dynamic]^Unit_Type
	defer delete(sorted)
	for k in keys {
		t := cast(^Unit_Type)k
		inserted := false
		t_name := default_named_get_name(&t.named_attachable.default_named)
		for i in 0 ..< len(sorted) {
			cur_name := default_named_get_name(&sorted[i].named_attachable.default_named)
			if t_name < cur_name {
				inject_at(&sorted, i, t)
				inserted = true
				break
			}
		}
		if !inserted {
			append(&sorted, t)
		}
	}

	buf := strings.builder_make()
	count := i32(len(sorted))
	for type in sorted {
		quantity := integer_map_get_int(im, rawptr(type))
		fmt.sbprintf(&buf, "%d ", quantity)
		t_name := default_named_get_name(&type.named_attachable.default_named)
		if quantity > 1 {
			strings.write_string(&buf, my_formatter_pluralize(t_name))
		} else {
			strings.write_string(&buf, t_name)
		}
		count -= 1
		if count > 1 {
			strings.write_string(&buf, ", ")
		}
		if count == 1 {
			strings.write_string(&buf, " and ")
		}
	}
	return strings.to_string(buf)
}

// Java public static String asDice(final DiceRoll roll)
// Returns "none" for null/empty; otherwise comma-joined `getDie(i).getValue()+1`.
my_formatter_as_dice :: proc(roll: ^Dice_Roll) -> string {
	if roll == nil || dice_roll_is_empty(roll) {
		return "none"
	}
	buf := strings.builder_make()
	n := dice_roll_size(roll)
	for i: i32 = 0; i < n; i += 1 {
		fmt.sbprintf(&buf, "%d", die_get_value(dice_roll_get_die(roll, i)) + 1)
		if i + 1 < n {
			strings.write_string(&buf, ",")
		}
	}
	return strings.to_string(buf)
}

// Java public static String asDice(final List<Die> rolls)
// Returns "none" for null/empty; otherwise comma-joined `rolls[i].getValue()+1`.
my_formatter_as_dice_list :: proc(rolls: [dynamic]^Die) -> string {
	if rolls == nil || len(rolls) == 0 {
		return "none"
	}
	buf := strings.builder_make()
	for i in 0 ..< len(rolls) {
		fmt.sbprintf(&buf, "%d", die_get_value(rolls[i]) + 1)
		if i + 1 < len(rolls) {
			strings.write_string(&buf, ",")
		}
	}
	return strings.to_string(buf)
}

// Java public static String defaultNamedToTextList(
//     Collection<? extends DefaultNamed>, String separator, boolean showQuantity)
// Histograms a list of DefaultNamed, sorts by name, emits either
// "<name>" or "<q> <name>[s]" entries joined by `separator` with a
// final " and ".
my_formatter_default_named_to_text_list :: proc(
	list: [dynamic]^Default_Named,
	separator: string,
	show_quantity: bool,
) -> string {
	im := integer_map_new()
	defer free(im)
	for unit in list {
		if unit == nil || len(default_named_get_name(unit)) == 0 {
			panic("Unit or Resource no longer exists?!?")
		}
		integer_map_add(im, rawptr(unit), 1)
	}
	keys := integer_map_key_set(im)
	defer delete(keys)
	// Sort by name.
	sorted: [dynamic]^Default_Named
	defer delete(sorted)
	for k in keys {
		t := cast(^Default_Named)k
		inserted := false
		t_name := default_named_get_name(t)
		for i in 0 ..< len(sorted) {
			if t_name < default_named_get_name(sorted[i]) {
				inject_at(&sorted, i, t)
				inserted = true
				break
			}
		}
		if !inserted {
			append(&sorted, t)
		}
	}

	buf := strings.builder_make()
	count := i32(len(sorted))
	for type in sorted {
		if show_quantity {
			quantity := integer_map_get_int(im, rawptr(type))
			fmt.sbprintf(&buf, "%d ", quantity)
			t_name := default_named_get_name(type)
			if quantity > 1 {
				strings.write_string(&buf, my_formatter_pluralize(t_name))
			} else {
				strings.write_string(&buf, t_name)
			}
		} else {
			strings.write_string(&buf, default_named_get_name(type))
		}
		count -= 1
		if count > 1 {
			strings.write_string(&buf, separator)
		}
		if count == 1 {
			strings.write_string(&buf, " and ")
		}
	}
	return strings.to_string(buf)
}

// Java public static String integerUnitMapToString(
//     IntegerMap<? extends Unit>, String separator, String assignment,
//     boolean valueBeforeKey)
// Concatenates "<sep><key|val><assign><val|key>" for each entry then
// strips the leading separator.
my_formatter_integer_unit_map_to_string :: proc(
	im: ^Integer_Map,
	separator: string,
	assignment: string,
	value_before_key: bool,
) -> string {
	buf := strings.builder_make()
	entries := integer_map_entry_set(im)
	defer delete(entries)
	for entry in entries {
		strings.write_string(&buf, separator)
		current := cast(^Unit)entry.key
		val := entry.value
		t := unit_get_type(current)
		t_name := default_named_get_name(&t.named_attachable.default_named)
		if value_before_key {
			fmt.sbprintf(&buf, "%d%s%s", val, assignment, t_name)
		} else {
			fmt.sbprintf(&buf, "%s%s%d", t_name, assignment, val)
		}
	}
	// Java: buf.toString().replaceFirst(separator, "") — strip first occurrence.
	s := strings.to_string(buf)
	if idx := strings.index(s, separator); idx >= 0 {
		return strings.concatenate({s[:idx], s[idx + len(separator):]})
	}
	return s
}
