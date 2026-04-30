package game

Messenger_Exception :: struct {
	message: string,
}

messenger_exception_new :: proc(message: string) -> ^Messenger_Exception {
	self := new(Messenger_Exception)
	self.message = message
	return self
}

