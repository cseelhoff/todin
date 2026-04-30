package game

Client_Login_Validator :: struct {
	engine_version:   ^Version,
	server_messenger: ^I_Server_Messenger,
	password:         string,
}
