package game

// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.precache.UnitComposition
//   - games.strategy.triplea.odds.calculator.precache.UnitComposition.Entry
//
// Canonical, order-independent identity of a collection of units used
// for cache keying and for reconstructing synthetic units from a cached
// battle result.

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"

// Java: record UnitComposition.Entry(String unitTypeName, String ownerName,
//                                    int hits, int count)
Unit_Composition_Entry :: struct {
	unit_type_name: string,
	owner_name:     string,
	hits:           i32,
	count:          i32,
}

// Java: final class UnitComposition { final List<Entry> entries; ... }
Unit_Composition :: struct {
	entries: [dynamic]Unit_Composition_Entry,
}

// Java: Entry#toCanonicalToken()
//   return unitTypeName + "|" + ownerName + "|" + hits + "x" + count;
unit_composition_entry_to_canonical_token :: proc(
	e: Unit_Composition_Entry, allocator := context.allocator,
) -> string {
	return fmt.aprintf("%s|%s|%dx%d", e.unit_type_name, e.owner_name, e.hits, e.count, allocator = allocator)
}

// Java: UnitComposition.from(Collection<Unit> units)
//   build (type, owner, hits) -> count, sort by (type, owner, hits).
unit_composition_from_units :: proc(
	units: [dynamic]^Unit, allocator := context.allocator,
) -> ^Unit_Composition {
	self := new(Unit_Composition, allocator)
	self.entries = make([dynamic]Unit_Composition_Entry, allocator)
	if len(units) == 0 {
		return self
	}

	// (type, owner, hits) -> count, preserving first-encounter metadata.
	// `key` packs the triple with a 0x01 separator so insertion order can be
	// recovered (purely for `from`'s subsequent stable sort).
	counts := make(map[string]i32, allocator = context.temp_allocator)
	defer delete(counts)
	meta_type   := make(map[string]string, allocator = context.temp_allocator)
	defer delete(meta_type)
	meta_owner  := make(map[string]string, allocator = context.temp_allocator)
	defer delete(meta_owner)
	meta_hits   := make(map[string]i32, allocator = context.temp_allocator)
	defer delete(meta_hits)

	for unit in units {
		type_name: string
		if unit_type := unit_get_type(unit); unit_type == nil {
			type_name = "?"
		} else {
			type_name = default_named_get_name(&unit_type.named_attachable.default_named)
		}
		owner_name: string
		if owner := unit_get_owner(unit); owner == nil {
			owner_name = "?"
		} else {
			owner_name = default_named_get_name(&owner.named_attachable.default_named)
		}
		hits := unit_get_hits(unit)
		key := fmt.aprintf("%s\x01%s\x01%d", type_name, owner_name, hits, allocator = context.temp_allocator)
		counts[key] = counts[key] + 1
		if _, present := meta_type[key]; !present {
			meta_type[key]  = type_name
			meta_owner[key] = owner_name
			meta_hits[key]  = hits
		}
	}

	// Materialise then sort (mirrors Java's `sorted.sort(...)`).
	for key, count in counts {
		append(&self.entries, Unit_Composition_Entry{
			unit_type_name = meta_type[key],
			owner_name     = meta_owner[key],
			hits           = meta_hits[key],
			count          = count,
		})
	}
	slice.sort_by(self.entries[:], proc(a, b: Unit_Composition_Entry) -> bool {
		if c := strings.compare(a.unit_type_name, b.unit_type_name); c != 0 { return c < 0 }
		if c := strings.compare(a.owner_name,     b.owner_name);     c != 0 { return c < 0 }
		return a.hits < b.hits
	})
	return self
}

// Java: UnitComposition.ofEntries(List<Entry> entries) — constructs from
// already-canonical entries (for deserialization). Caller transfers ownership.
unit_composition_of_entries :: proc(
	entries: [dynamic]Unit_Composition_Entry, allocator := context.allocator,
) -> ^Unit_Composition {
	self := new(Unit_Composition, allocator)
	self.entries = entries
	return self
}

// Java: UnitComposition#totalCount()
unit_composition_total_count :: proc(self: ^Unit_Composition) -> i32 {
	if self == nil { return 0 }
	total: i32 = 0
	for e in self.entries {
		total += e.count
	}
	return total
}

// Java: UnitComposition#toCanonicalString()
//   "type|owner|HxN,type|owner|HxN" — empty composition becomes "-".
unit_composition_to_canonical_string :: proc(
	self: ^Unit_Composition, allocator := context.allocator,
) -> string {
	if self == nil || len(self.entries) == 0 {
		return strings.clone("-", allocator)
	}
	sb: strings.Builder
	strings.builder_init(&sb, allocator)
	for e, i in self.entries {
		if i > 0 {
			strings.write_byte(&sb, ',')
		}
		fmt.sbprintf(&sb, "%s|%s|%dx%d", e.unit_type_name, e.owner_name, e.hits, e.count)
	}
	return strings.to_string(sb)
}

// Helper used by Stored_Scenario.WhoWon parsing in the codec path.
@(private)
unit_composition_parse_i32 :: proc(s: string) -> (i32, bool) {
	v, ok := strconv.parse_i64(s)
	return i32(v), ok
}
