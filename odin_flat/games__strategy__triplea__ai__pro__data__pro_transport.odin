package game

// Ported from games.strategy.triplea.ai.pro.data.ProTransport
// The result of an AI amphibious movement analysis.

Pro_Transport :: struct {
	transport:         ^Unit,
	transport_map:     map[^Territory]map[^Territory]struct{},
	sea_transport_map: map[^Territory]map[^Territory]struct{},
	// Parallel to `transport_map`: the load-from territories for each unload
	// territory in Java's LinkedHashSet INSERTION order. Java's
	// `ProTransport.transportMap` value is a LinkedHashSet, so its iteration
	// order is the order territories were first added across the accumulating
	// `addTerritories` calls (each call iterating its own source HashSet in
	// bucket order). The cargo selection's stable sort preserves this order
	// for the armour/artillery tie (snap 0038), so it must be tracked exactly;
	// the plain `transport_map` is kept only for membership/`in` checks.
	transport_map_order: map[^Territory][dynamic]^Territory,
}

pro_transport_new :: proc(transport: ^Unit) -> ^Pro_Transport {
	self := new(Pro_Transport)
	self.transport = transport
	self.transport_map = make(map[^Territory]map[^Territory]struct{})
	self.sea_transport_map = make(map[^Territory]map[^Territory]struct{})
	self.transport_map_order = make(map[^Territory][dynamic]^Territory)
	return self
}

pro_transport_lambda_add_territories_0 :: proc(key: ^Territory) -> map[^Territory]struct{} {
	return make(map[^Territory]struct{})
}

pro_transport_lambda_add_sea_territories_1 :: proc(key: ^Territory) -> map[^Territory]struct{} {
	return make(map[^Territory]struct{})
}

// `load_from_order` must already be in Java's source-HashSet iteration order
// (the caller sorts it by Java HashMap bucket). We append into each unload
// territory's order list with LinkedHashSet dedup semantics (first-seen
// position wins), mirroring `linkedHashSet.addAll(loadFromTerritories)`.
pro_transport_add_territories :: proc(
	self: ^Pro_Transport,
	attack_territories: map[^Territory]struct{},
	load_from_order: []^Territory,
) {
	for t, _ in attack_territories {
		if !(t in self.transport_map) {
			self.transport_map[t] = pro_transport_lambda_add_territories_0(t)
			self.transport_map_order[t] = make([dynamic]^Territory)
		}
		set := &self.transport_map[t]
		order := &self.transport_map_order[t]
		for lf in load_from_order {
			if !(lf in set^) {
				set^[lf] = struct{}{}
				append(order, lf)
			}
		}
	}
}

pro_transport_add_sea_territories :: proc(
	self: ^Pro_Transport,
	attack_territories: map[^Territory]struct{},
	load_from_territories: map[^Territory]struct{},
) {
	for t, _ in attack_territories {
		if !(t in self.sea_transport_map) {
			self.sea_transport_map[t] = pro_transport_lambda_add_sea_territories_1(t)
		}
		set := &self.sea_transport_map[t]
		for lf, _ in load_from_territories {
			set^[lf] = struct{}{}
		}
	}
}

pro_transport_get_transport :: proc(self: ^Pro_Transport) -> ^Unit {
	return self.transport
}

pro_transport_get_transport_map :: proc(self: ^Pro_Transport) -> map[^Territory]map[^Territory]struct{} {
	return self.transport_map
}

// Insertion-ordered load-from territories per unload territory (Java
// LinkedHashSet order). Use this at cargo-selection sites where the order
// breaks unit ties; `get_transport_map` is for membership checks only.
pro_transport_get_transport_map_order :: proc(self: ^Pro_Transport) -> map[^Territory][dynamic]^Territory {
	return self.transport_map_order
}

pro_transport_get_sea_transport_map :: proc(self: ^Pro_Transport) -> map[^Territory]map[^Territory]struct{} {
	return self.sea_transport_map
}
