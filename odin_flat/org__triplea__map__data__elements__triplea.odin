package game

Triplea :: struct {
	minimum_version: string,
}

triplea_get_minimum_version :: proc(self: ^Triplea) -> string {
	return self.minimum_version
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Triplea

