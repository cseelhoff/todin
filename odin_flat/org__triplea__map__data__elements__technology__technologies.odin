package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Technology$Technologies

Technology_Technologies :: struct {
	tech_names: [dynamic]^Technology_Technologies_Tech_Name,
}

technology_technologies_get_tech_names :: proc(self: ^Technology_Technologies) -> [dynamic]^Technology_Technologies_Tech_Name {
	return self.tech_names
}

