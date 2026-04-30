package game

Client_Login_Validator_Builder :: struct {
	server_messenger: ^I_Server_Messenger,
	password:         string,
}

make_Client_Login_Validator_Client_Login_Validator_Builder :: proc() -> Client_Login_Validator_Builder {
	return Client_Login_Validator_Builder{}
}

client_login_validator_builder_server_messenger :: proc(self: ^Client_Login_Validator_Builder, server_messenger: ^I_Server_Messenger) -> ^Client_Login_Validator_Builder { self.server_messenger = server_messenger; return self }
