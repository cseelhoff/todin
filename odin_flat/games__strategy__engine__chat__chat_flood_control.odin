package game

Chat_Flood_Control :: struct {
	lock:          struct {},
	message_count: map[^User_Name]i32,
	clear_time:    i64,
}

// Java owners covered by this file:
//   - games.strategy.engine.chat.ChatFloodControl

