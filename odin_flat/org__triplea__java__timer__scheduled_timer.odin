package game

Scheduled_Timer :: struct {
	task:          proc(),
	delay_millis:  i64,
	period_millis: i64,
	timer:         rawptr,
	running:       bool,
}

