package game

Sent_Messages_History :: struct {
	history:          [dynamic]string,
	history_position: i32,
}

make_Sent_Messages_History :: proc() -> Sent_Messages_History {
	return Sent_Messages_History{
		history          = make([dynamic]string),
		history_position = 0,
	}
}

sent_messages_history_append :: proc(self: ^Sent_Messages_History, s: string) {
	append(&self.history, s)
	self.history_position = i32(len(self.history))
	if len(self.history) > 100 {
		remove_range(&self.history, 0, 50)
	}
}
