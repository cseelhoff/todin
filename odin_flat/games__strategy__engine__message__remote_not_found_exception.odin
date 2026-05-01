package game

Remote_Not_Found_Exception :: struct {
	using messenger_exception: Messenger_Exception,
}

remote_not_found_exception_new :: proc(message: string) -> ^Remote_Not_Found_Exception {
	self := new(Remote_Not_Found_Exception)
	self.message = message
	return self
}
