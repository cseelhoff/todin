package game

Async_Runner :: struct {}

// Java: AsyncRunner.runAsync(Runnable) — default threadpool variant.
async_runner_run_async :: proc(runnable: proc()) -> ^Exception_Handler {
	return exception_handler_new(runnable, nil)
}

// Java: AsyncRunner.runAsync(Runnable, Executor) — caller-provided executor variant.
async_runner_run_async_executor :: proc(runnable: proc(), executor: proc(task: proc())) -> ^Exception_Handler {
	return exception_handler_new(runnable, executor)
}

