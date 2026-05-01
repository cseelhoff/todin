package game

Xml_Resource_List :: struct {
	resources: [dynamic]^Xml_Resource_List_Resource,
}

xml_resource_list_get_resources :: proc(self: ^Xml_Resource_List) -> [dynamic]^Xml_Resource_List_Resource {
	return self.resources
}
