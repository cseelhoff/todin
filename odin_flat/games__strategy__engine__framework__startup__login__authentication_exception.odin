package game

Authentication_Exception :: struct {
	using parent: Exception,
}

make_Authentication_Exception :: proc(message: string) -> Authentication_Exception {
	return Authentication_Exception{parent = Exception{message = message}}
}

make_Authentication_Exception_2 :: proc(message: string, cause: rawptr) -> Authentication_Exception {
	return Authentication_Exception{parent = Exception{message = message, cause = cast(^Exception)cause}}
}
