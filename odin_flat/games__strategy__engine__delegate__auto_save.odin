package game

// Java: games.strategy.engine.delegate.AutoSave (annotation @interface)
// Annotations are erased at runtime; the declared flags are carried as fields.
Auto_Save :: struct {
	before_step_start: bool,
	after_step_start:  bool,
	after_step_end:    bool,
}
