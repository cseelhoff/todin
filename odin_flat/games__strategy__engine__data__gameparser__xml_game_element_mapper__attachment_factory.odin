package game

// Java owner: games.strategy.engine.data.gameparser.XmlGameElementMapper$AttachmentFactory
//
// Functional interface (single abstract method) modeled with a proc-typed
// field installed by concrete implementers. The dispatch proc
// `xml_game_element_mapper_attachment_factory_new_attachment` is the public
// entry point.

Xml_Game_Element_Mapper_Attachment_Factory :: struct {
	new_attachment: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment,
}

// games.strategy.engine.data.gameparser.XmlGameElementMapper$AttachmentFactory#newAttachment(java.lang.String,games.strategy.engine.data.Attachable,games.strategy.engine.data.GameData)
xml_game_element_mapper_attachment_factory_new_attachment :: proc(self: ^Xml_Game_Element_Mapper_Attachment_Factory, name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment {
	return self.new_attachment(self, name, attachable, game_data)
}

