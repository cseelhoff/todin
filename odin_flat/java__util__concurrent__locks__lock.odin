package game

// JDK shim: java.util.concurrent.locks.Lock — single-threaded snapshot harness, no-op.

Lock :: struct {}

lock_lock :: proc(self: ^Lock) {}
lock_unlock :: proc(self: ^Lock) {}
lock_try_lock :: proc(self: ^Lock) -> bool { return true }
