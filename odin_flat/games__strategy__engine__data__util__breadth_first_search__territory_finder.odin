package game

Breadth_First_Search_Territory_Finder :: struct {
	using visitor: Breadth_First_Search_Visitor,
	destination: ^Territory,
	distance_found: i32,
}

make_Breadth_First_Search_Territory_Finder :: proc(target: ^Territory) -> ^Breadth_First_Search_Territory_Finder {
	self := new(Breadth_First_Search_Territory_Finder)
	self.destination = target
	self.distance_found = -1
	return self
}

breadth_first_search_territory_finder_get_distance_found :: proc(self: ^Breadth_First_Search_Territory_Finder) -> i32 {
	return self.distance_found
}

breadth_first_search_territory_finder_visit :: proc(self: ^Breadth_First_Search_Territory_Finder, territory: ^Territory, distance: i32) -> bool {
	if self.destination == territory {
		self.distance_found = distance
		return false
	}
	return true
}
