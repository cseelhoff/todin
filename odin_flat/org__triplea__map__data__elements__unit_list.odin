package game

Unit_List :: struct {
	units: [dynamic]^Unit_List_Unit,
}

unit_list_get_units :: proc(self: ^Unit_List) -> [dynamic]^Unit_List_Unit {
	return self.units
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.UnitList

