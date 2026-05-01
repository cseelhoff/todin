package game

// Anonymous inner class #1 of games.strategy.engine.delegate.DelegateExecutionManager.
// Created in DelegateExecutionManager.newInboundImplementation as
//   new WrappedInvocationHandler(implementor) { ... }
// The synthetic ctor receives:
//   - the enclosing DelegateExecutionManager (outer$0),
//   - the captured `implementor` reference used by invoke(),
//   - the same `implementor` forwarded to the WrappedInvocationHandler super-ctor.
Delegate_Execution_Manager_1 :: struct {
	using wrapped_invocation_handler: Wrapped_Invocation_Handler,
	outer:       ^Delegate_Execution_Manager,
	implementor: rawptr,
}

delegate_execution_manager_1_new :: proc(outer: ^Delegate_Execution_Manager, implementor_capture: rawptr, super_implementor: rawptr) -> ^Delegate_Execution_Manager_1 {
	// super(implementor): WrappedInvocationHandler asserts the delegate is non-nil.
	assert(super_implementor != nil)
	self := new(Delegate_Execution_Manager_1)
	self.wrapped_invocation_handler.delegate = super_implementor
	self.outer = outer
	self.implementor = implementor_capture
	return self
}
