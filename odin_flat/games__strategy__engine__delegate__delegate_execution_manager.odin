package game

Delegate_Execution_Manager :: struct {
	read_write_lock:              ^Reentrant_Read_Write_Lock,
	current_thread_has_read_lock: ^Thread_Local,
	is_game_over:                 bool,
}
