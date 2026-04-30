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
