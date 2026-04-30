package game

Air_That_Cant_Land_Util :: struct {
	bridge: ^I_Delegate_Bridge,
}

air_that_cant_land_util_new :: proc(bridge: ^I_Delegate_Bridge) -> ^Air_That_Cant_Land_Util {
	self := new(Air_That_Cant_Land_Util)
	self.bridge = bridge
	return self
}

