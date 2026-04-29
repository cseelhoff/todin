package game

Unified_Messenger :: struct {
	messenger:           ^I_Messenger,
	local_end_points:    map[string]^End_Point,
	pending_invocations: map[Uuid]^Count_Down_Latch,
	results:             map[Uuid]^Remote_Method_Call_Results,
	hub:                 ^Unified_Messenger_Hub,
}

