package game

Image_Scroll_Model :: struct {
	x:          i32,
	y:          i32,
	box_width:  i32,
	box_height: i32,
	max_width:  i32,
	max_height: i32,
	scroll_x:   bool,
	scroll_y:   bool,
	listeners:  [dynamic]proc(),
}
// Java owners covered by this file:
//   - games.strategy.ui.ImageScrollModel

