package game

// Java: org.triplea.java.concurrency.AsyncRunner$ExceptionHandler
// Inner static class of AsyncRunner. Holds a Runnable plus an
// optional Executor; .exceptionally(Consumer<Throwable>) launches
// the runnable on the given executor (or the default pool when
// the executor is nil) and forwards any thrown error to the
// supplied handler.
Exception_Handler :: struct {
	runnable: proc(),
	executor: proc(task: proc()),
}

exception_handler_new :: proc(runnable: proc(), executor: proc(task: proc())) -> ^Exception_Handler {
	self := new(Exception_Handler)
	self.runnable = runnable
	self.executor = executor
	return self
}

// Snapshot harness is single-threaded; "executor" runs the task synchronously and Odin has no exceptions, so on_error is never invoked.
exception_handler_exceptionally :: proc(self: ^Exception_Handler, on_error: proc(err: ^Throwable)) {
	if self == nil || self.runnable == nil {
		return
	}
	if self.executor != nil {
		self.executor(self.runnable)
	} else {
		self.runnable()
	}
	_ = on_error
}
