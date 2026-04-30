package game

Mutable_Property_Invalid_Value_Exception :: struct {
	message: string,
	cause:   ^Throwable,
}

make_Mutable_Property_Invalid_Value_Exception :: proc(message: string, cause: ^Throwable) -> Mutable_Property_Invalid_Value_Exception {
	return Mutable_Property_Invalid_Value_Exception{
		message = message,
		cause   = cause,
	}
}
