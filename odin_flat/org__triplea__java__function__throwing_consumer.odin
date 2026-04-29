package game

// Java: @FunctionalInterface ThrowingConsumer<T, E extends Throwable>
//   void accept(T value) throws E;
// Odin port: generic T is erased to rawptr; checked exception E is
// surfaced as an Odin error value returned by the proc.
Throwing_Consumer :: struct {
	accept: proc(value: rawptr) -> Maybe(string),
}

