package game

I_Chat_Controller :: struct {
	join_chat: proc(self: ^I_Chat_Controller) -> [dynamic]^Chat_Participant,
	leave_chat: proc(self: ^I_Chat_Controller),
	set_status: proc(self: ^I_Chat_Controller, new_status: string),
}

// games.strategy.engine.chat.IChatController#joinChat()
i_chat_controller_join_chat :: proc(self: ^I_Chat_Controller) -> [dynamic]^Chat_Participant {
        return self.join_chat(self)
}

// games.strategy.engine.chat.IChatController#leaveChat()
i_chat_controller_leave_chat :: proc(self: ^I_Chat_Controller) {
        self.leave_chat(self)
}

// games.strategy.engine.chat.IChatController#setStatus(java.lang.String)
i_chat_controller_set_status :: proc(self: ^I_Chat_Controller, new_status: string) {
        self.set_status(self, new_status)
}
