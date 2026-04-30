package game

Breadth_First_Search_Visitor :: struct {
	visit: proc(self: ^Breadth_First_Search_Visitor, territory: ^Territory, distance: i32) -> bool,
}

breadth_first_search_visitor_visit :: proc(self: ^Breadth_First_Search_Visitor, territory: ^Territory, distance: i32) -> bool {
	return self.visit(self, territory, distance)
}

