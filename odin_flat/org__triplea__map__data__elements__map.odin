package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Map

Map :: struct {
	territories: [dynamic]^Map_Territory,
	connections: [dynamic]^Map_Connection,
}

map_get_territories :: proc(self: ^Map) -> [dynamic]^Map_Territory {
	return self.territories
}

map_get_connections :: proc(self: ^Map) -> [dynamic]^Map_Connection {
	return self.connections
}

