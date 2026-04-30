package game

// JDK shim: java.awt.Color. Per llm-instructions §"Value objects",
// Color is a pure value type (RGBA components 0-255). The AI snapshot
// harness exposes Color values via map data (player nationality colors,
// etc.) — no real graphics rendering happens.

Color :: struct {
	red:   i32,
	green: i32,
	blue:  i32,
	alpha: i32,
}

color_new :: proc(r, g, b: i32, a: i32 = 255) -> Color {
	return Color{red = r, green = g, blue = b, alpha = a}
}

// Mirrors java.awt.Color(int rgb), where rgb packs as 0xRRGGBB (alpha=255).
color_from_rgb :: proc(rgb: i32) -> Color {
	return Color{
		red   = (rgb >> 16) & 0xff,
		green = (rgb >>  8) & 0xff,
		blue  =  rgb        & 0xff,
		alpha = 255,
	}
}

color_get_red :: proc(self: Color) -> i32 {
	return self.red
}

color_get_green :: proc(self: Color) -> i32 {
	return self.green
}

color_get_blue :: proc(self: Color) -> i32 {
	return self.blue
}

color_get_alpha :: proc(self: Color) -> i32 {
	return self.alpha
}

color_get_rgb :: proc(self: Color) -> i32 {
	return (self.alpha << 24) | (self.red << 16) | (self.green << 8) | self.blue
}

color_equals :: proc(a, b: Color) -> bool {
	return a.red == b.red && a.green == b.green && a.blue == b.blue && a.alpha == b.alpha
}
