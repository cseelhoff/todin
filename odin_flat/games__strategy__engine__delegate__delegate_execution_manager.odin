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
