package game

Headless_Chat :: struct {
	chat: ^Chat,
}

make_Headless_Chat :: proc(chat: ^Chat) -> Headless_Chat {
	return Headless_Chat{chat = chat}
}
