package game

// Ported from games.strategy.triplea.ai.pro.data.ProTransport
// The result of an AI amphibious movement analysis.

Pro_Transport :: struct {
	transport:         ^Unit,
	transport_map:     map[^Territory]map[^Territory]struct{},
	sea_transport_map: map[^Territory]map[^Territory]struct{},
}
