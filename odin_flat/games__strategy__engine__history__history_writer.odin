package game

History_Writer :: struct {
	history: ^History,
	current: ^History_Node,
}

// Java owners covered by this file:
//   - games.strategy.engine.history.HistoryWriter

history_writer_new :: proc(history: ^History) -> ^History_Writer {
	self := new(History_Writer)
	self.history = history
	return self
}

history_writer_is_current_event :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Event
}

history_writer_is_current_round :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Round
}

history_writer_is_current_step :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Step
}
