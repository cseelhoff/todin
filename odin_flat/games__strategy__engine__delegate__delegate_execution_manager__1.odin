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

// games.strategy.engine.delegate.DelegateExecutionManager$1#invoke(Object, Method, Object[])
// Java:
//   if (super.shouldHandle(method, args)) return super.handle(method, args);
//   assertGameNotOver();
//   enterDelegateExecution();
//   try { return method.invoke(implementor, args); }
//   catch (InvocationTargetException ite) { assertGameNotOver(); throw ite.getCause(); }
//   catch (RuntimeException re)            { assertGameNotOver(); throw re; }
//   finally { leaveDelegateExecution(); }
//
// The Odin port has no java.lang.reflect.Proxy machinery, so the proxy/
// method/args triple is collapsed to (method-name, args). The handler
// is unreachable in the AI snapshot harness — newInboundImplementation
// returns the implementor directly — so the actual reflective call is
// dropped (same approach as PlayerBridge$GameOverInvocationHandler).
// We still preserve the gameOver gate, the read-lock bookkeeping, and
// the equals/hashCode/toString fast path through the embedded
// WrappedInvocationHandler super-procs, by synthesizing a stub Method
// carrying only the name (the only field shouldHandle/handle inspect).
delegate_execution_manager_1_invoke :: proc(
	self:        ^Delegate_Execution_Manager_1,
	method_name: string,
	args:        []rawptr,
) -> rawptr {
	stub_method := Method{name = method_name}
	if wrapped_invocation_handler_should_handle(&self.wrapped_invocation_handler, &stub_method, args) {
		return wrapped_invocation_handler_handle(&self.wrapped_invocation_handler, &stub_method, args)
	}
	delegate_execution_manager_assert_game_not_over(self.outer)
	delegate_execution_manager_enter_delegate_execution(self.outer)
	defer delegate_execution_manager_leave_delegate_execution(self.outer)
	// method.invoke(implementor, args): no reflection in the Odin port,
	// and this handler is bypassed by newInboundImplementation, so
	// there is nothing to forward to. Mirror the GameOverInvocationHandler
	// port and return nil. The implementor capture is intentionally
	// retained on the struct for fidelity with the Java closure.
	_ = self.implementor
	_ = args
	return nil
}
