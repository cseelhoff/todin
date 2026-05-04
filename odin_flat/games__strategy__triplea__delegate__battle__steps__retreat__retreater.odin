package game

// Retreater is a Java interface; Odin port uses an embedded vtable of
// proc-pointers + an opaque self_raw to dispatch polymorphically.
// Concrete subtypes (RetreaterGeneral, RetreaterAirAmphibious,
// RetreaterPartialAmphibious) wire these pointers in their _new ctors.
// Forward references resolve at the package level.
Retreater :: struct {
	self_raw:                  rawptr,
	get_retreat_units:         proc(self_raw: rawptr) -> [dynamic]^Unit,
	get_possible_retreat_sites: proc(self_raw: rawptr, retreat_units: [dynamic]^Unit) -> [dynamic]^Territory,
	get_retreat_type:          proc(self_raw: rawptr) -> Must_Fight_Battle_Retreat_Type,
	compute_changes:           proc(self_raw: rawptr, retreat_to: ^Territory) -> ^Retreater_Retreat_Changes,
}

