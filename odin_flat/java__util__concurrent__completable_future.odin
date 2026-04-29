package game

// JDK shim: CompletableFuture - synchronous in-process implementation; the AI snapshot harness is single-threaded.

Completable_Future :: struct {
	completed: bool,
	value:     rawptr,
}

completable_future_new :: proc() -> ^Completable_Future {
	return new(Completable_Future)
}

completable_future_complete :: proc(self: ^Completable_Future, value: rawptr) -> bool {
	if self.completed {
		return false
	}
	self.completed = true
	self.value = value
	return true
}

completable_future_is_done :: proc(self: ^Completable_Future) -> bool {
	return self.completed
}

completable_future_get :: proc(self: ^Completable_Future) -> rawptr {
	return self.value
}
