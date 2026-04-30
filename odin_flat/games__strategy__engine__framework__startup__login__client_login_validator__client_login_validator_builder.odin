package game

Client_Login_Validator_Builder :: struct {
	server_messenger: ^I_Server_Messenger,
	password:         string,
}

make_Client_Login_Validator_Client_Login_Validator_Builder :: proc() -> Client_Login_Validator_Builder {
	return Client_Login_Validator_Builder{}
}

