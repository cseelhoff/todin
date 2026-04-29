package game

Xml_Game_Element_Mapper :: struct {
	delegate_factories_by_type_name:   map[string]proc() -> ^I_Delegate,
	attachment_factories_by_type_name: map[string]^Xml_Game_Element_Mapper_Attachment_Factory,
}

