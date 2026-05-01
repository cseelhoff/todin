package game

// Java owner: games.strategy.engine.data.IAttachment
//
// Pure-callback interface; methods modeled as proc-typed fields,
// with `i_attachment_*` dispatch procs as public entry points.
//
// Java: `interface IAttachment extends DynamicallyModifiable`. The
// DynamicallyModifiable supertype contributes a `getPropertyOrThrow`
// (and friends) to every IAttachment. We expose that via a single
// `get_property_or_throw` callback on the vtable; concrete attachment
// types are expected to wire it to their own property map (typically
// by routing through `dynamically_modifiable_get_property_or_throw`).

I_Attachment :: struct {
	validate:              proc(self: ^I_Attachment, data: ^Game_State) -> ^Game_Parse_Exception,
	get_attached_to:       proc(self: ^I_Attachment) -> ^Attachable,
	get_name:              proc(self: ^I_Attachment) -> string,
	get_property_or_throw: proc(self: ^I_Attachment, name: string) -> ^Mutable_Property,
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

// games.strategy.engine.data.IAttachment#getPropertyOrThrow(String)
// Inherited via DynamicallyModifiable. Concrete attachments wire the
// callback to their own property table; if a vtable leaves it nil we
// panic with the same message Java's IllegalArgumentException carries.
i_attachment_get_property_or_throw :: proc(
	self: ^I_Attachment,
	name: string,
) -> ^Mutable_Property {
	if self.get_property_or_throw == nil {
		panic("IAttachment vtable missing get_property_or_throw")
	}
	return self.get_property_or_throw(self, name)
}

