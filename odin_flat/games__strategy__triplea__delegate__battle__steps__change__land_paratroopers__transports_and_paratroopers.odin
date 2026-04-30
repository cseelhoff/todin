package game

Land_Paratroopers_Transports_And_Paratroopers :: struct {
	air_transports: [dynamic]^Unit,
	paratroopers:   [dynamic]^Unit,
}

land_paratroopers_transports_and_paratroopers_has_paratroopers :: proc(self: ^Land_Paratroopers_Transports_And_Paratroopers) -> bool {
	return len(self.air_transports) > 0 && len(self.paratroopers) > 0
}
