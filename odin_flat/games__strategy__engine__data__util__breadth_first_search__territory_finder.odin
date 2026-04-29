package game

Breadth_First_Search_Territory_Finder :: struct {
	using visitor: Breadth_First_Search_Visitor,
	destination: ^Territory,
	distance_found: i32,
}

