package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataUtils#translateIntoOtherGameData
//
// Java rebinds an arbitrary game-data object graph into a different
// GameData via an ObjectOutputStream → GameObjectInputStream round
// trip. Odin has no reflective serializer, so we use the (preserved)
// UUIDs as cross-clone unit identity. Mirror the active half of the
// Java helper for unit collections, which is what BattleCalculator's
// translateCollectionIntoOtherGameData call site actually needs.

translate_units_by_uuid :: proc(target: ^Game_Data, src: [dynamic]^Unit) -> [dynamic]^Unit {
	out := make([dynamic]^Unit, 0, len(src))
	if target == nil || target.units_list == nil {
		for u in src {
			append(&out, u)
		}
		return out
	}
	for u in src {
		if u == nil {
			continue
		}
		if cu, ok := target.units_list.units[u.id]; ok {
			append(&out, cu)
		} else {
			// Unit not in clone (e.g. allocated post-clone for a
			// purchased reinforcement). Java's serializer would have
			// re-encoded the object faithfully; we fall back to the
			// original pointer so the calc still has something to act on.
			append(&out, u)
		}
	}
	return out
}
