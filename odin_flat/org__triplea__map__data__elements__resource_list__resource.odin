package game

Xml_Resource_List_Resource :: struct {
	name:             string,
	is_displayed_for: string,
}

xml_resource_list_resource_get_name :: proc(self: ^Xml_Resource_List_Resource) -> string {
	return self.name
}

xml_resource_list_resource_get_is_displayed_for :: proc(self: ^Xml_Resource_List_Resource) -> string {
	return self.is_displayed_for
}

