package game

Display_Shutdown_Message :: struct {
}

// games.strategy.engine.display.IDisplay$DisplayShutdownMessage#accept(games.strategy.engine.display.IDisplay)
i_display_display_shutdown_message_accept :: proc(self: ^Display_Shutdown_Message, display: ^I_Display) {
	i_display_shut_down(display)
}

