package game

import "core:fmt"

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

chat_controller_start_pinger :: proc(self: ^Chat_Controller) {
	scheduled_executor_service_schedule_at_fixed_rate(
		self.ping_thread,
		chat_controller_lambda_start_pinger_0,
		180_000,
		60_000,
	)
}

CHAT_CONTROLLER_CHAT_CHANNEL :: "_ChatControl_"

chat_controller_get_chat_channel_name :: proc(chat_name: string) -> string {
	return fmt.aprintf("%s%s", CHAT_CONTROLLER_CHAT_CHANNEL, chat_name)
}

chat_controller_lambda_start_pinger_0 :: proc() {
	// No-op: chat heartbeat. AI snapshot run does not exercise real chat I/O.
}

// games.strategy.engine.chat.ChatController#deactivate()
chat_controller_deactivate :: proc(self: ^Chat_Controller) {
	// No-op: not exercised by the WW2v5 AI snapshot run.
}
