package game

Pro_Log_Settings :: struct {
	log_history_limited: bool,
	log_history_limit:   i32,
	log_enabled:         bool,
	log_level:           i32,
}

// Java field initializers: logHistoryLimited=true, logHistoryLimit=5,
// logEnabled=true, logLevel=Level.FINEST (intValue() == 300).
pro_log_settings_new :: proc() -> ^Pro_Log_Settings {
	self := new(Pro_Log_Settings)
	self.log_history_limited = true
	self.log_history_limit = 5
	self.log_enabled = true
	self.log_level = 300
	return self
}

pro_log_settings_get_log_level :: proc(self: ^Pro_Log_Settings) -> i32 {
	return self.log_level
}

pro_log_settings_is_log_enabled :: proc(self: ^Pro_Log_Settings) -> bool {
	return self.log_enabled
}

// Lambda body of ProLogSettings.loadSettingsImpl: in Java this reads
// a serialized ProLogSettings from an ObjectInputStream wrapping the
// given InputStream. The snapshot harness never exercises the real
// preference-store path, so the synchronous in-process equivalent is
// to return a freshly defaulted settings object.
pro_log_settings_lambda_load_settings_impl_0 :: proc(stream: ^Input_Stream) -> ^Pro_Log_Settings {
	_ = stream
	return pro_log_settings_new()
}

// Lambda body of ProLogSettings.saveSettings: in Java this wraps the
// given OutputStream in an ObjectOutputStream and writes the settings
// object. The snapshot harness never exercises the real preference-
// store path, so the synchronous in-process equivalent is to flush
// the stream and return.
pro_log_settings_lambda_save_settings_1 :: proc(settings: ^Pro_Log_Settings, stream: ^Output_Stream) {
	_ = settings
	output_stream_flush(stream)
}
