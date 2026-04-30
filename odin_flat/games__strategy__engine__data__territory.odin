package game

// games.strategy.engine.data.Territory
//
// extends NamedAttachable implements NamedUnitHolder, Comparable<Territory>

Territory :: struct {
	using named_attachable: Named_Attachable,
	water:                bool,
	owner:                ^Game_Player,
	unit_collection:      ^Unit_Collection,
	territory_attachment: ^Territory_Attachment,
}

territory_to_string :: proc(self: ^Territory) -> string {
	return default_named_get_name(&self.named_attachable.default_named)
}

// games.strategy.engine.data.Territory#isOwnedBy(GamePlayer)
territory_is_owned_by :: proc(self: ^Territory, player: ^Game_Player) -> bool {
	// Java: return getOwner().equals(player);
	// GamePlayer does not override equals, so this is reference identity.
	return self.owner == player
}

// Mirrors Java's `Territory.compareTo`, which delegates to
// `String.compareTo` on the territory name. Java's contract returns
// the lexicographic byte/char difference; for the ASCII territory
// names used by the engine this matches a byte-wise compare.
territory_compare_to :: proc(self: ^Territory, other: ^Territory) -> i32 {
	a := default_named_get_name(&self.named_attachable.default_named)
	b := default_named_get_name(&other.named_attachable.default_named)
	min_len := len(a)
	if len(b) < min_len {
		min_len = len(b)
	}
	for i in 0 ..< min_len {
		if a[i] != b[i] {
			return i32(a[i]) - i32(b[i])
		}
	}
	return i32(len(a)) - i32(len(b))
}

// games.strategy.engine.data.Territory#getType()
// Java: return UnitHolder.TERRITORY;  // the string "T"
territory_get_type :: proc(self: ^Territory) -> string {
	return "T"
}
