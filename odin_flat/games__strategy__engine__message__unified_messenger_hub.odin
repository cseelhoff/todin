package game

Unified_Messenger_Hub :: struct {
	local_unified:    ^Unified_Messenger,
	messenger:        ^I_Messenger,
	end_points:       map[string][dynamic]^I_Node,
	end_point_mutex:  rawptr,
	invocations:      map[Uuid]^Invocation_In_Progress,
}

