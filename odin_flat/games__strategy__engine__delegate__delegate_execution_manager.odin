package game

Delegate_Execution_Manager :: struct {
	read_write_lock:              ^Reentrant_Read_Write_Lock,
	current_thread_has_read_lock: ^Thread_Local,
	is_game_over:                 bool,
}

make_Delegate_Execution_Manager :: proc() -> Delegate_Execution_Manager {
	return Delegate_Execution_Manager{}
}

// Initial-value supplier for the `currentThreadHasReadLock` ThreadLocal
// (`ThreadLocal.withInitial(() -> Boolean.FALSE)`).
delegate_execution_manager_lambda_new_0 :: proc() -> bool {
	return false
}

// Java: returns true if the write lock was acquired within the timeout.
// The AI snapshot harness is single-threaded, so the write lock is
// always immediately available and acquisition succeeds.
delegate_execution_manager_block_delegate_execution :: proc(
	self: ^Delegate_Execution_Manager,
	timeout_ms: i32,
) -> bool {
	_ = timeout_ms
	_ = self
	return true
}

delegate_execution_manager_current_thread_has_read_lock :: proc(
	self: ^Delegate_Execution_Manager,
) -> bool {
	tl := self.current_thread_has_read_lock
	if tl == nil || !tl.has_set {
		return delegate_execution_manager_lambda_new_0()
	}
	v, ok := tl.value.(bool)
	if !ok {
		return false
	}
	return v
}

// Java: `readWriteLock.readLock().unlock(); currentThreadHasReadLock.set(FALSE);`
// The single-threaded AI snapshot harness models the lock as a no-op
// marker, so only the per-thread flag needs to be cleared.
delegate_execution_manager_leave_delegate_execution :: proc(
	self: ^Delegate_Execution_Manager,
) {
	if self.current_thread_has_read_lock == nil {
		self.current_thread_has_read_lock = thread_local_new()
	}
	thread_local_set(self.current_thread_has_read_lock, false)
}

// Java: `readWriteLock.writeLock().unlock();`
// In the single-threaded harness the write lock is a no-op marker,
// so resuming delegate execution has no observable state change.
delegate_execution_manager_resume_delegate_execution :: proc(
	self: ^Delegate_Execution_Manager,
) {
	_ = self
}

// Java: `isGameOver = true;`
delegate_execution_manager_set_game_over :: proc(self: ^Delegate_Execution_Manager) {
	self.is_game_over = true
}

// Java: `if (isGameOver) throw new GameOverException("Game Over");`
delegate_execution_manager_assert_game_not_over :: proc(self: ^Delegate_Execution_Manager) {
	if self.is_game_over {
		panic("Game Over")
	}
}

// Java: `newOutboundImplementation(Object implementor, Class<?>[] interfaces)`
//   assertGameNotOver();
//   InvocationHandler ih = (proxy, method, args) -> { ... method.invoke(implementor, args) ... };
//   return Proxy.newProxyInstance(implementor.getClass().getClassLoader(), interfaces, ih);
//
// The Odin port has no java.lang.reflect.Proxy machinery and the AI
// snapshot harness wires concrete delegate instances directly, so the
// reflective proxy collapses to a pass-through that simply returns the
// implementor after the gameOver gate. Same approach as
// newInboundImplementation and the WrappedInvocationHandler family.
delegate_execution_manager_new_outbound_implementation :: proc(
	self:       ^Delegate_Execution_Manager,
	implementor: rawptr,
	interfaces:  []typeid,
) -> rawptr {
	delegate_execution_manager_assert_game_not_over(self)
	_ = interfaces
	return implementor
}

// Synthetic lambda body of the InvocationHandler created in
// newOutboundImplementation:
//   (proxy, method, args) -> {
//     assertGameNotOver();
//     boolean threadLocks = currentThreadHasReadLock();
//     if (threadLocks) leaveDelegateExecution();
//     try { return method.invoke(implementor, args); }
//     catch (InvocationTargetException e) {
//       if (e.getCause() instanceof MessengerException) throw new GameOverException("Game Over!");
//       assertGameNotOver();
//       throw e;
//     } finally { if (threadLocks) enterDelegateExecution(); }
//   }
//
// Unreachable in the AI snapshot harness because
// newOutboundImplementation returns the implementor directly (no
// proxy is built). Mirror the same shape used for the inbound inner
// class (Delegate_Execution_Manager_1.invoke) and the
// PlayerBridge$GameOverInvocationHandler port: preserve the
// gameOver gate and the read-lock bookkeeping; drop the reflective
// method.invoke (no reflection in the Odin port) and return nil.
delegate_execution_manager_lambda_new_outbound_implementation_1 :: proc(
	self:        ^Delegate_Execution_Manager,
	implementor: rawptr,
	proxy:       rawptr,
	method_name: string,
	args:        []rawptr,
) -> rawptr {
	delegate_execution_manager_assert_game_not_over(self)
	thread_locks := delegate_execution_manager_current_thread_has_read_lock(self)
	if thread_locks {
		delegate_execution_manager_leave_delegate_execution(self)
	}
	defer if thread_locks {
		delegate_execution_manager_enter_delegate_execution(self)
	}
	// method.invoke(implementor, args): no reflection in the Odin
	// port, and this handler is bypassed because
	// newOutboundImplementation returns the implementor directly,
	// so there is nothing to forward to.
	_ = implementor
	_ = proxy
	_ = method_name
	_ = args
	return nil
}

// Java: `newInboundImplementation(Object implementor, Class<?>[] interfaces)`
//   assertGameNotOver();
//   InvocationHandler ih = new WrappedInvocationHandler(implementor) { ... };
//   return Proxy.newProxyInstance(implementor.getClass().getClassLoader(), interfaces, ih);
//
// As with the outbound counterpart, the Odin port skips the reflective
// proxy and returns the implementor directly. The synthetic
// InvocationHandler is ported as Delegate_Execution_Manager_1 in the
// sibling file but is unreachable from this entry point.
delegate_execution_manager_new_inbound_implementation :: proc(
	self:       ^Delegate_Execution_Manager,
	implementor: rawptr,
	interfaces:  []typeid,
) -> rawptr {
	delegate_execution_manager_assert_game_not_over(self)
	_ = interfaces
	return implementor
}

// Java: `checkState(!currentThreadHasReadLock(), "Already locked?");
//        readWriteLock.readLock().lock();
//        currentThreadHasReadLock.set(Boolean.TRUE);`
// In the single-threaded AI snapshot harness the read lock is a no-op
// marker, so only the per-thread flag is observable.
delegate_execution_manager_enter_delegate_execution :: proc(self: ^Delegate_Execution_Manager) {
	if delegate_execution_manager_current_thread_has_read_lock(self) {
		panic("Already locked?")
	}
	if self.current_thread_has_read_lock == nil {
		self.current_thread_has_read_lock = thread_local_new()
	}
	thread_local_set(self.current_thread_has_read_lock, true)
}
