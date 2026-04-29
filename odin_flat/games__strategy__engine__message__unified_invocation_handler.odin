package game

Unified_Invocation_Handler :: struct {
	using parent:   Wrapped_Invocation_Handler,
	messenger:      ^Unified_Messenger,
	end_point_name: string,
	ignore_results: bool,
}

