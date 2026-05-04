package game

Route_Scripted :: struct {
	using route: Route,
}

// Mirrors Java RouteScripted(Territory terr): chains to Route(Territory start,
// Territory... territories) with no extra steps, producing a "scripted" route
// whose end() returns start and whose length is treated as 1 by the
// numberOfSteps/getSteps/etc. overrides on RouteScripted.
route_scripted_new :: proc(start: ^Territory) -> ^Route_Scripted {
	r := new(Route_Scripted)
	r.start = start
	return r
}
