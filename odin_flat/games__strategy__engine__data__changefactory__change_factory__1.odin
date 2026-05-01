package game

Change_Factory_1 :: struct {
	using change: Change,
}

change_factory_1_is_empty :: proc(self: ^Change_Factory_1) -> bool {
	return true
}

change_factory_1_perform :: proc(self: ^Change_Factory_1, state: ^Game_State) {
}

change_factory_1_new :: proc() -> ^Change_Factory_1 {
	self := new(Change_Factory_1)
	return self
}
