package game

// JDK shim: AtomicInteger - single-threaded harness; non-atomic implementation suffices.

Atomic_Integer :: struct {
	value: i32,
}

atomic_integer_new :: proc(initial: i32 = 0) -> ^Atomic_Integer {
	a := new(Atomic_Integer)
	a.value = initial
	return a
}

atomic_integer_get :: proc(self: ^Atomic_Integer) -> i32 {
	return self.value
}

atomic_integer_set :: proc(self: ^Atomic_Integer, v: i32) {
	self.value = v
}

atomic_integer_increment_and_get :: proc(self: ^Atomic_Integer) -> i32 {
	self.value += 1
	return self.value
}

atomic_integer_decrement_and_get :: proc(self: ^Atomic_Integer) -> i32 {
	self.value -= 1
	return self.value
}

atomic_integer_get_and_increment :: proc(self: ^Atomic_Integer) -> i32 {
	v := self.value
	self.value += 1
	return v
}

atomic_integer_get_and_set :: proc(self: ^Atomic_Integer, v: i32) -> i32 {
	prev := self.value
	self.value = v
	return prev
}

atomic_integer_add_and_get :: proc(self: ^Atomic_Integer, delta: i32) -> i32 {
	self.value += delta
	return self.value
}

atomic_integer_compare_and_set :: proc(self: ^Atomic_Integer, expected: i32, new_val: i32) -> bool {
	if self.value == expected {
		self.value = new_val
		return true
	}
	return false
}
