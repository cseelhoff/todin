package game

Technology :: struct {
	technologies: ^Technology_Technologies,
	player_techs: [dynamic]^Technology_Player_Tech,
}

technology_get_technologies :: proc(self: ^Technology) -> ^Technology_Technologies {
	return self.technologies
}

technology_get_player_techs :: proc(self: ^Technology) -> [dynamic]^Technology_Player_Tech {
	return self.player_techs
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Technology

