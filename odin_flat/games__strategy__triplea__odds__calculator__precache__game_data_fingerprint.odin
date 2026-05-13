package game

// Java: games.strategy.triplea.odds.calculator.precache.GameDataFingerprint
//
// Stable hex-encoded SHA-256 over the parts of Game_Data that can affect
// battle simulation outcomes — dice sides + every constant + every
// editable Game_Properties entry. Conservative on purpose; tightening
// only after the cache hit-rate is measured.

import "base:runtime"
import "core:crypto/sha2"
import "core:encoding/hex"
import "core:fmt"
import "core:slice"
import "core:strings"

// Java: GameDataFingerprint.compute(GameData data) -> hex string
//
// Collects:
//   "dice=<int>\n"
//   "c:<key>=<stringified value>\n" for every constant property (sorted)
//   "e:<key>=<stringified value>\n" for every editable property (sorted)
// Hashes the concatenation with SHA-256 and returns hex.
game_data_fingerprint_compute :: proc(
	data: ^Game_Data, allocator := context.allocator,
) -> string {
	if data == nil {
		return strings.clone("no-data", allocator)
	}

	ctx: sha2.Context_256
	sha2.init_256(&ctx)

	dice_line := fmt.aprintf("dice=%d\n", game_data_get_dice_sides(data),
		allocator = context.temp_allocator)
	sha2.update(&ctx, transmute([]byte)dice_line)

	if props := game_data_get_properties(data); props != nil {
		lines := game_data_fingerprint_canonical_property_lines(props,
			context.temp_allocator)
		for line in lines {
			sha2.update(&ctx, transmute([]byte)line)
			sha2.update(&ctx, []byte{'\n'})
		}
	}

	digest: [sha2.DIGEST_SIZE_256]byte
	sha2.final(&ctx, digest[:])
	encoded := hex.encode(digest[:], allocator)
	return string(encoded)
}

// Java: GameDataFingerprint.canonicalPropertyLines(props)
//   "c:<key>=<value>" for constant_properties.entrySet()
//   "e:<key>=<value>" for editable_properties.entrySet()
//   then Collections.sort.
@(private = "file")
game_data_fingerprint_canonical_property_lines :: proc(
	props: ^Game_Properties, allocator: runtime.Allocator,
) -> [dynamic]string {
	lines := make([dynamic]string, allocator)
	consts := game_properties_get_constant_properties_by_name(props)
	defer delete(consts)
	for k, v in consts {
		append(&lines, fmt.aprintf("c:%s=%s", k,
			game_data_fingerprint_property_value_to_string(v),
			allocator = allocator))
	}
	editable := game_properties_get_editable_properties_by_name(props)
	defer delete(editable)
	for k, e in editable {
		val: Property_Value
		if e != nil { val = editable_property_get_value(e) }
		append(&lines, fmt.aprintf("e:%s=%s", k,
			game_data_fingerprint_property_value_to_string(val),
			allocator = allocator))
	}
	slice.sort(lines[:])
	return lines
}

// Java: safeToString(Object) -> "null" | value.toString().
// Odin's Property_Value is a typed union; format each variant
// deterministically so the same constant set hashes identically across runs.
@(private = "file")
game_data_fingerprint_property_value_to_string :: proc(v: Property_Value) -> string {
	if v == nil {
		return "null"
	}
	switch p in v {
	case bool:
		return p ? "true" : "false"
	case i32:
		return fmt.tprintf("%d", p)
	case f64:
		return fmt.tprintf("%g", p)
	case string:
		return p
	}
	return "null"
}
