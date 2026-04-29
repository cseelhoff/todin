package game

Count_Down_Latch_Handler :: struct {
	latches_to_close_on_shutdown: [dynamic]^Count_Down_Latch,
	is_shut_down:                 bool,
	release_latch_on_interrupt:   bool,
}
