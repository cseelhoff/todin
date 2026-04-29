package game

// JDK shim: synchronous in-process implementation; the AI snapshot harness is single-threaded.
Scheduled_Executor_Service :: struct {}

scheduled_executor_service_submit :: proc(self: ^Scheduled_Executor_Service, task: proc()) {
	task()
}

scheduled_executor_service_schedule :: proc(self: ^Scheduled_Executor_Service, task: proc(), delay_ms: i64) {
	task()
}

scheduled_executor_service_schedule_at_fixed_rate :: proc(self: ^Scheduled_Executor_Service, task: proc(), initial_delay_ms: i64, period_ms: i64) {
	task()
}

scheduled_executor_service_schedule_with_fixed_delay :: proc(self: ^Scheduled_Executor_Service, task: proc(), initial_delay_ms: i64, delay_ms: i64) {
	task()
}

scheduled_executor_service_shutdown :: proc(self: ^Scheduled_Executor_Service) {}

scheduled_executor_service_shutdown_now :: proc(self: ^Scheduled_Executor_Service) {}

scheduled_executor_service_is_shutdown :: proc(self: ^Scheduled_Executor_Service) -> bool {
	return true
}
