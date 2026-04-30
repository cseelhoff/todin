package game

Property_List_Property_Property_Builder :: struct {
	name:            string,
	editable:        bool,
	player:          string,
	value:           string,
	min:             i32,
	max:             i32,
	value_property:  ^Property_List_Property_Value,
	number_property: ^Property_List_Property_Xml_Number_Tag,
}

