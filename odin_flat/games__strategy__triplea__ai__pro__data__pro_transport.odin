package game

// Ported from games.strategy.triplea.ai.pro.data.ProTransport
// The result of an AI amphibious movement analysis.

Pro_Transport :: struct {
	transport:         ^Unit,
	transport_map:     map[^Territory]map[^Territory]struct{},
	sea_transport_map: map[^Territory]map[^Territory]struct{},
}

pro_transport_new :: proc(transport: ^Unit) -> ^Pro_Transport {
	self := new(Pro_Transport)
	self.transport = transport
	self.transport_map = make(map[^Territory]map[^Territory]struct{})
	self.sea_transport_map = make(map[^Territory]map[^Territory]struct{})
	return self
}

pro_transport_lambda_add_territories_0 :: proc(key: ^Territory) -> map[^Territory]struct{} {
	return make(map[^Territory]struct{})
}

pro_transport_lambda_add_sea_territories_1 :: proc(key: ^Territory) -> map[^Territory]struct{} {
	return make(map[^Territory]struct{})
}

pro_transport_add_territories :: proc(
	self: ^Pro_Transport,
	attack_territories: map[^Territory]struct{},
	load_from_territories: map[^Territory]struct{},
) {
	for t, _ in attack_territories {
		if !(t in self.transport_map) {
			self.transport_map[t] = pro_transport_lambda_add_territories_0(t)
		}
		set := &self.transport_map[t]
		for lf, _ in load_from_territories {
			set^[lf] = struct{}{}
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

pro_transport_get_sea_transport_map :: proc(self: ^Pro_Transport) -> map[^Territory]map[^Territory]struct{} {
	return self.sea_transport_map
}
