package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.lookandfeel.LookAndFeel

Look_And_Feel :: struct {}

look_and_feel_is_color_dark :: proc(color: Color) -> bool {
	luma := (0.299 * f64(color_get_red(color))
		+ 0.587 * f64(color_get_green(color))
		+ 0.114 * f64(color_get_blue(color))) / 255.0
	return luma < 0.5
}

