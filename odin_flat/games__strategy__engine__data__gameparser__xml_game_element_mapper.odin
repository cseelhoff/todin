package game

Xml_Game_Element_Mapper :: struct {
	delegate_factories_by_type_name:   map[string]proc() -> ^IDelegate,
	attachment_factories_by_type_name: map[string]^Attachment_Factory,
}

