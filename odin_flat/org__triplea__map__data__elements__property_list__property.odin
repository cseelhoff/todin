package game

Property_List_Property :: struct {
	name:            string,
	editable:        bool,
	player:          string,
	value:           string,
	min:             i32,
	max:             i32,
	value_property:  ^Property_List_Property_Value,
	number_property: ^Property_List_Property_Xml_Number_Tag,
}

property_list_property_get_name :: proc(self: ^Property_List_Property) -> string {
	return self.name
}

property_list_property_get_editable :: proc(self: ^Property_List_Property) -> bool {
	return self.editable
}

property_list_property_get_min :: proc(self: ^Property_List_Property) -> i32 {
	return self.min
}

property_list_property_get_max :: proc(self: ^Property_List_Property) -> i32 {
	return self.max
}

property_list_property_get_value_property :: proc(self: ^Property_List_Property) -> ^Property_List_Property_Value {
	return self.value_property
}

property_list_property_get_number_property :: proc(self: ^Property_List_Property) -> ^Property_List_Property_Xml_Number_Tag {
	return self.number_property
}

