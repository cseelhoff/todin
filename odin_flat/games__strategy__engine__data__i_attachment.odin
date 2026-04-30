package game

// Java owner: games.strategy.engine.data.IAttachment
//
// Pure-callback interface; methods modeled as proc-typed fields,
// with `i_attachment_*` dispatch procs as public entry points.

I_Attachment :: struct {
	validate:        proc(self: ^I_Attachment, data: ^Game_State) -> ^Game_Parse_Exception,
	get_attached_to: proc(self: ^I_Attachment) -> ^Attachable,
	get_name:        proc(self: ^I_Attachment) -> string,
}

// games.strategy.engine.data.IAttachment#validate(GameState)
i_attachment_validate :: proc(self: ^I_Attachment, data: ^Game_State) -> ^Game_Parse_Exception {
	return self.validate(self, data)
}

// games.strategy.engine.data.IAttachment#getAttachedTo()
i_attachment_get_attached_to :: proc(self: ^I_Attachment) -> ^Attachable {
	return self.get_attached_to(self)
}

// games.strategy.engine.data.IAttachment#getName()
i_attachment_get_name :: proc(self: ^I_Attachment) -> string {
	return self.get_name(self)
}

