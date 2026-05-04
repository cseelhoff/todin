package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.lookandfeel.LookAndFeel

Look_And_Feel :: struct {}

look_and_feel_get_substance_look_and_feel_manager :: proc() -> ^Substance_Look_And_Feel_Manager {
	return cast(^Substance_Look_And_Feel_Manager)services_try_load_any(Substance_Look_And_Feel_Manager)
}

look_and_feel_is_color_dark :: proc(color: Color) -> bool {
	luma := (0.299 * f64(color_get_red(color))
		+ 0.587 * f64(color_get_green(color))
		+ 0.114 * f64(color_get_blue(color))) / 255.0
	return luma < 0.5
}

// Java: games.strategy.engine.framework.lookandfeel.LookAndFeel#lambda$initialize$0(GameSetting)
// Swing UI listener body (setupLookAndFeel + SettingsWindow.updateLookAndFeel +
// JOptionPane.showMessageDialog) — out of scope for the AI-snapshot harness.
look_and_feel_lambda_initialize_0 :: proc(self: ^Look_And_Feel, game_setting: ^Game_Setting) {
	// Swing UI listener body — out of scope for the AI-snapshot harness
}

