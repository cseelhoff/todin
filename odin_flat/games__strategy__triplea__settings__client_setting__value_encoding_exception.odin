package game

// Java owners covered by this file:
//   - games.strategy.triplea.settings.ClientSetting$ValueEncodingException

Client_Setting_Value_Encoding_Exception :: struct {
	using exception: Exception,
}

client_setting_value_encoding_exception_new :: proc(cause: ^Throwable) -> ^Client_Setting_Value_Encoding_Exception {
	self := new(Client_Setting_Value_Encoding_Exception)
	if cause != nil {
		self.message = cause.message
	}
	return self
}

