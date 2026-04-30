package game

// Java: games.strategy.engine.delegate.AutoSave (annotation @interface)
Auto_Save :: struct {
	before_step_start: bool,
	after_step_start:  bool,
	after_step_end:    bool,
}

auto_save_after_step_end :: proc(self: ^Auto_Save) -> bool {
	return self.after_step_end
}

auto_save_after_step_start :: proc(self: ^Auto_Save) -> bool {
	return self.after_step_start
}

auto_save_before_step_start :: proc(self: ^Auto_Save) -> bool { return self.before_step_start }
