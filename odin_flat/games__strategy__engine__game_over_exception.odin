package game

Game_Over_Exception :: struct {
	message: string,
	cause:   string,
}

make_Game_Over_Exception :: proc(message: string) -> Game_Over_Exception {
	return Game_Over_Exception{message = message}
}

make_Game_Over_Exception_with_cause :: proc(message: string, cause: string) -> Game_Over_Exception {
	return Game_Over_Exception{message = message, cause = cause}
}
