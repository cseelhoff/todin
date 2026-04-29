package game

Unified_Invocation_Handler :: struct {
	using wrapped_invocation_handler: Wrapped_Invocation_Handler,
	messenger:      ^Unified_Messenger,
	end_point_name: string,
	ignore_results: bool,
}

