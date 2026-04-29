package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Map

Map :: struct {
	territories: [dynamic]^Map_Territory,
	connections: [dynamic]^Map_Connection,
}

