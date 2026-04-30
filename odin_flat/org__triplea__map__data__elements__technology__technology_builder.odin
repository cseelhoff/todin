package game

// Ported from org.triplea.map.data.elements.Technology$TechnologyBuilder
// (Lombok @Builder for Technology).
Technology_Technology_Builder :: struct {
	technologies: ^Technology_Technologies,
	player_techs: [dynamic]^Technology_Player_Tech,
}

