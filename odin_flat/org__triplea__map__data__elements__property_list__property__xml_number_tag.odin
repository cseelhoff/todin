package game

Property_List_Property_Xml_Number_Tag :: struct {
	min: i32,
	max: i32,
}

property_list_property_xml_number_tag_new :: proc() -> ^Property_List_Property_Xml_Number_Tag {
	self := new(Property_List_Property_Xml_Number_Tag)
	return self
}

