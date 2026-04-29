package game

Chat_Controller :: struct {
	messengers:                 ^Messengers,
	server_messenger:           ^Server_Messenger,
	chat_name:                  string,
	chatters:                   map[^I_Node]I_Chat_Controller_Tag,
	chatter_ids:                map[^I_Node]^Player_Chat_Id,
	chatter_status:             map[^User_Name]string,
	mutex:                      ^Object,
	chat_channel:               string,
	ping_thread:                ^Scheduled_Executor_Service,
	connection_change_listener: ^I_Connection_Change_Listener,
}
