package game

// Java owner: games.strategy.net.nio.ServerQuarantineConversation
// extends QuarantineConversation

Server_Quarantine_Conversation :: struct {
	using base:       Quarantine_Conversation,
	validator:        ^I_Login_Validator,
	channel:          ^Socket_Channel,
	socket:           ^Nio_Socket,
	step:             Server_Quarantine_Conversation_Step,
	remote_name:      string,
	remote_mac:       string,
	challenge:        map[string]string,
	server_messenger: ^Server_Messenger,
}

// Java owners covered by this file:
//   - games.strategy.net.nio.ServerQuarantineConversation

