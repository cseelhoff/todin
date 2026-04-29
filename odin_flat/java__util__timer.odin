package game

// JDK shim: java.util.Timer / java.util.TimerTask
// Synchronous in-process implementation; the AI snapshot harness is single-
// threaded and never advances real wall-clock time. start/cancel just flip
// flags and store the schedule so callers that round-trip a Timer compile.

Timer :: struct {
    name:       string,
    cancelled:  bool,
    scheduled:  ^Timer_Task,
    delay_ms:   i64,
    period_ms:  i64,
}

Timer_Task :: struct {
    run: proc(),
}

timer_new :: proc(name: string = "") -> ^Timer {
    t := new(Timer)
    t.name = name
    return t
}

timer_schedule_at_fixed_rate :: proc(self: ^Timer, task: ^Timer_Task, delay_ms: i64, period_ms: i64) {
    self.scheduled = task
    self.delay_ms = delay_ms
    self.period_ms = period_ms
}

timer_cancel :: proc(self: ^Timer) {
    self.cancelled = true
}

timer_task_new :: proc(run: proc()) -> ^Timer_Task {
    t := new(Timer_Task)
    t.run = run
    return t
}
