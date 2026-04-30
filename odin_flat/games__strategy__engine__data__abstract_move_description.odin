package game

Abstract_Move_Description :: struct {
	units: [dynamic]^Unit,
}

make_Abstract_Move_Description :: proc(units: []^Unit) -> Abstract_Move_Description {
	result := Abstract_Move_Description{}
	append(&result.units, ..units)
	return result
}
