package game

import "core:strings"

Abstract_Property_Reader :: struct {
        using property_reader:   Property_Reader,
        // Vtable hook for the abstract `readPropertyInternal(String)` method.
        // Concrete subclasses set this in their constructor to forward into
        // their own typed proc. Returns the raw property value (may be "").
        read_property_internal:  proc(self: ^Abstract_Property_Reader, key: string) -> string,
}

abstract_property_reader_new :: proc() -> ^Abstract_Property_Reader {
	self := new(Abstract_Property_Reader)
	return self
}

abstract_property_reader_read_property :: proc(self: ^Abstract_Property_Reader, key: string) -> string {
	raw: string = ""
	if self.read_property_internal != nil {
		raw = self.read_property_internal(self, key)
	}
	return strings.trim_space(raw)
}
