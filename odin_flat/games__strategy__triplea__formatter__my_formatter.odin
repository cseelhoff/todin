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
my_formatter_as_dice :: proc(rolls: []i32) -> string {
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
