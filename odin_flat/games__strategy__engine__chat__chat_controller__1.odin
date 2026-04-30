package game

// Java owners covered by this file:
//   - games.strategy.engine.chat.ChatController$1
// Anonymous inner class implementing IConnectionChangeListener.
// Captures enclosing ChatController instance.

Chat_Controller_1 :: struct {
	outer: ^Chat_Controller,
}

make_Chat_Controller_1 :: proc(outer: ^Chat_Controller) -> ^Chat_Controller_1 {
	self := new(Chat_Controller_1)
	self.outer = outer
	return self
}

