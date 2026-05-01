package game

Thread_Runner :: struct {}

thread_runner_run_in_new_thread :: proc(runnable: proc()) {
	t := thread_new(runnable)
	thread_start(t)
}

