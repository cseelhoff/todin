package game

// Pro_My_Move_Options mirrors Java's `ProMyMoveOptions`. The Java
// implementation uses `LinkedHashMap` for the four unit→territories
// maps so that iteration order matches insertion order. Odin's plain
// `map` is unordered, which causes the AI to pick different units when
// multiple have identical sort keys (move count, unit value, type
// name) — a real divergence we observed in the WW2v5 determinism
// probe at r=1 i=14 russianBattle.
//
// Workaround (without changing every map-typed signature in the AI
// surface): keep the maps as-is for fast lookup, and maintain a
// PARALLEL insertion-order slice for each map. The AI sort helpers
// use this slice as the stable-sort tiebreaker, replacing the
// previous Uuid-byte tiebreak that was deterministic but did not
// match Java's LinkedHashMap order.
//
// IMPORTANT for future Java→Odin conversions: any time the Java
// source uses a `LinkedHashMap` (or relies on `Collection` iteration
// order populated from an ordered source), the Odin port must either
// use a wrapping struct with a parallel ordered key list or otherwise
// recover Java's iteration order. Plain `map[K]V` will silently break
// AI determinism. See games__strategy__triplea__delegate__matches.odin
// (game_player_equals) for the related pointer-equality vs
// semantic-equality pattern.
Pro_My_Move_Options :: struct {
	territory_map:            map[^Territory]^Pro_Territory,
	unit_move_map:            map[^Unit]map[^Territory]struct{},
	transport_move_map:       map[^Unit]map[^Territory]struct{},
	bombard_map:              map[^Unit]map[^Territory]struct{},
	transport_list:           [dynamic]^Pro_Transport,
	bomber_move_map:          map[^Unit]map[^Territory]struct{},
	// Parallel insertion-order key slices (LinkedHashMap-equivalent).
	// Append a unit ONCE the first time it is inserted into the
	// matching map. See `pro_my_move_options_record_*` helpers.
	unit_move_map_order:      [dynamic]^Unit,
	transport_move_map_order: [dynamic]^Unit,
	bombard_map_order:        [dynamic]^Unit,
	bomber_move_map_order:    [dynamic]^Unit,
}

pro_my_move_options_new :: proc() -> ^Pro_My_Move_Options {
	self := new(Pro_My_Move_Options)
	self.territory_map = make(map[^Territory]^Pro_Territory)
	self.unit_move_map = make(map[^Unit]map[^Territory]struct{})
	self.transport_move_map = make(map[^Unit]map[^Territory]struct{})
	self.bombard_map = make(map[^Unit]map[^Territory]struct{})
	self.transport_list = make([dynamic]^Pro_Transport)
	self.bomber_move_map = make(map[^Unit]map[^Territory]struct{})
	self.unit_move_map_order = make([dynamic]^Unit)
	self.transport_move_map_order = make([dynamic]^Unit)
	self.bombard_map_order = make([dynamic]^Unit)
	self.bomber_move_map_order = make([dynamic]^Unit)
	return self
}

// Record insertion-order helpers. Idempotent: each unit is appended
// at most once per map. Call AFTER inserting into the underlying map
// (or any time you know the unit will be a key of that map).
pro_my_move_options_record_unit_move :: proc(self: ^Pro_My_Move_Options, u: ^Unit) {
	if _, present := self.unit_move_map[u]; !present {
		// New key: append to order slice.
		append(&self.unit_move_map_order, u)
	}
}
pro_my_move_options_record_transport_move :: proc(self: ^Pro_My_Move_Options, u: ^Unit) {
	if _, present := self.transport_move_map[u]; !present {
		append(&self.transport_move_map_order, u)
	}
}
pro_my_move_options_record_bombard :: proc(self: ^Pro_My_Move_Options, u: ^Unit) {
	if _, present := self.bombard_map[u]; !present {
		append(&self.bombard_map_order, u)
	}
}
pro_my_move_options_record_bomber_move :: proc(self: ^Pro_My_Move_Options, u: ^Unit) {
	if _, present := self.bomber_move_map[u]; !present {
		append(&self.bomber_move_map_order, u)
	}
}

// Returns the insertion-order slice for unit_move_map. Callers should
// NOT mutate the returned slice. Used by sort helpers to recover
// Java LinkedHashMap iteration order as a stable-sort tiebreaker.
pro_my_move_options_get_unit_move_map_order :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Unit {
	return self.unit_move_map_order
}
pro_my_move_options_get_transport_move_map_order :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Unit {
	return self.transport_move_map_order
}
pro_my_move_options_get_bombard_map_order :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Unit {
	return self.bombard_map_order
}
pro_my_move_options_get_bomber_move_map_order :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Unit {
	return self.bomber_move_map_order
}

pro_my_move_options_get_territory_map :: proc(self: ^Pro_My_Move_Options) -> ^map[^Territory]^Pro_Territory {
	return &self.territory_map
}

// Iterate `territory_map` in master-game-data order. Java's
// `LinkedHashMap<Territory, ProTerritory>` is populated by walking
// `data.getMap().getTerritories()` (the master list) and inserting
// hits, so iteration order = master-list order. Odin's plain `map`
// hashes pointer values and is non-deterministic across runs; this
// helper recovers Java's order. Caller must `defer delete(<result>)`.
pro_my_move_options_sorted_territory_keys :: proc(
	self: ^Pro_My_Move_Options,
	data: ^Game_Data,
) -> [dynamic]^Territory {
	out: [dynamic]^Territory
	all_terrs := game_map_get_territories(game_data_get_map(data))
	defer delete(all_terrs)
	for t in all_terrs {
		if _, ok := self.territory_map[t]; ok {
			append(&out, t)
		}
	}
	return out
}

pro_my_move_options_get_unit_move_map :: proc(self: ^Pro_My_Move_Options) -> ^map[^Unit]map[^Territory]struct{} {
	return &self.unit_move_map
}

pro_my_move_options_get_transport_move_map :: proc(self: ^Pro_My_Move_Options) -> ^map[^Unit]map[^Territory]struct{} {
	return &self.transport_move_map
}

pro_my_move_options_get_bombard_map :: proc(self: ^Pro_My_Move_Options) -> ^map[^Unit]map[^Territory]struct{} {
	return &self.bombard_map
}

pro_my_move_options_get_transport_list :: proc(self: ^Pro_My_Move_Options) -> [dynamic]^Pro_Transport {
	return self.transport_list
}

pro_my_move_options_get_bomber_move_map :: proc(self: ^Pro_My_Move_Options) -> ^map[^Unit]map[^Territory]struct{} {
	return &self.bomber_move_map
}

// games.strategy.triplea.ai.pro.data.ProMyMoveOptions#<init>(ProMyMoveOptions, ProData)
// Java copy constructor.
pro_my_move_options_new_copy :: proc(other: ^Pro_My_Move_Options, pro_data: ^Pro_Data) -> ^Pro_My_Move_Options {
	self := pro_my_move_options_new()
	for t, pt in other.territory_map {
		self.territory_map[t] = pro_territory_new_from_other(pt, pro_data)
	}
	// Preserve insertion order: iterate the parallel order slice and
	// copy in source order. Any entries not in the order slice (legacy
	// inserters that haven't been migrated yet) are appended after.
	_um_seen := make(map[^Unit]struct{}); defer delete(_um_seen)
	for u in other.unit_move_map_order {
		if terrs, ok := other.unit_move_map[u]; ok {
			self.unit_move_map[u] = terrs
			append(&self.unit_move_map_order, u)
			_um_seen[u] = {}
		}
	}
	for u, terrs in other.unit_move_map {
		if _, seen := _um_seen[u]; !seen {
			self.unit_move_map[u] = terrs
			append(&self.unit_move_map_order, u)
		}
	}
	_tm_seen := make(map[^Unit]struct{}); defer delete(_tm_seen)
	for u in other.transport_move_map_order {
		if terrs, ok := other.transport_move_map[u]; ok {
			self.transport_move_map[u] = terrs
			append(&self.transport_move_map_order, u)
			_tm_seen[u] = {}
		}
	}
	for u, terrs in other.transport_move_map {
		if _, seen := _tm_seen[u]; !seen {
			self.transport_move_map[u] = terrs
			append(&self.transport_move_map_order, u)
		}
	}
	_bd_seen := make(map[^Unit]struct{}); defer delete(_bd_seen)
	for u in other.bombard_map_order {
		if terrs, ok := other.bombard_map[u]; ok {
			self.bombard_map[u] = terrs
			append(&self.bombard_map_order, u)
			_bd_seen[u] = {}
		}
	}
	for u, terrs in other.bombard_map {
		if _, seen := _bd_seen[u]; !seen {
			self.bombard_map[u] = terrs
			append(&self.bombard_map_order, u)
		}
	}
	for tr in other.transport_list {
		append(&self.transport_list, tr)
	}
	_bm_seen := make(map[^Unit]struct{}); defer delete(_bm_seen)
	for u in other.bomber_move_map_order {
		if terrs, ok := other.bomber_move_map[u]; ok {
			self.bomber_move_map[u] = terrs
			append(&self.bomber_move_map_order, u)
			_bm_seen[u] = {}
		}
	}
	for u, terrs in other.bomber_move_map {
		if _, seen := _bm_seen[u]; !seen {
			self.bomber_move_map[u] = terrs
			append(&self.bomber_move_map_order, u)
		}
	}
	return self
}

