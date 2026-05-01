package game

Property_List :: struct {
	properties: [dynamic]^Property_List_Property,
}

property_list_get_properties :: proc(self: ^Property_List) -> [dynamic]^Property_List_Property {
	return self.properties
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.PropertyList

