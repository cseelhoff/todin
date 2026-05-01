package game

Unified_Invocation_Handler :: struct {
	using wrapped_invocation_handler: Wrapped_Invocation_Handler,
	messenger:      ^Unified_Messenger,
	end_point_name: string,
	ignore_results: bool,
}

unified_invocation_handler_new :: proc(
	messenger: ^Unified_Messenger,
	end_point_name: string,
	ignore_results: bool,
) -> ^Unified_Invocation_Handler {
	// Java: super(endPointName); equality/hashCode based on end point name.
	// In the Odin port the wrapped handler's `delegate` is an opaque
	// rawptr identity; use the address of the stored end_point_name
	// field as that identity (stable for the lifetime of the heap
	// allocation).
	self := new(Unified_Invocation_Handler)
	self.messenger = messenger
	self.end_point_name = end_point_name
	self.ignore_results = ignore_results
	self.wrapped_invocation_handler.delegate = rawptr(&self.end_point_name)
	return self
}

