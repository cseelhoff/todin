package game

Xml_Game_Element_Mapper_Attachment_Factory :: struct {
	new_attachment: proc(name: string, attachable: ^Attachable, game_data: ^Game_Data) -> ^I_Attachment,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.gameparser.XmlGameElementMapper$AttachmentFactory

