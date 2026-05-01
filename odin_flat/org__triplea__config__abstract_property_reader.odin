package game

Abstract_Property_Reader :: struct {
	using property_reader: Property_Reader,
}

abstract_property_reader_new :: proc() -> ^Abstract_Property_Reader {
	self := new(Abstract_Property_Reader)
	return self
}
