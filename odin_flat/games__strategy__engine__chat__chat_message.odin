package game

Chat_Message :: struct {
	from:    ^User_Name,
	message: string,
}

make_Chat_Message :: proc(from: ^User_Name, message: string) -> Chat_Message {
	return Chat_Message{from = from, message = message}
}

chat_message_get_from :: proc(self: ^Chat_Message) -> ^User_Name { return self.from }

chat_message_get_message :: proc(self: ^Chat_Message) -> string { return self.message }
