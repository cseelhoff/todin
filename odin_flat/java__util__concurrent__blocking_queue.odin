package game

// JDK shim: java.util.concurrent.BlockingQueue — synchronous
// in-process queue. The AI snapshot harness is single-threaded,
// so put/take reduce to plain push/pop on a dynamic array. We
// store rawptr items so the queue is generic across element
// types (callers cast on the way out).

Blocking_Queue :: struct {
	items: [dynamic]rawptr,
}

blocking_queue_new :: proc() -> ^Blocking_Queue {
	q := new(Blocking_Queue)
	q.items = make([dynamic]rawptr)
	return q
}

blocking_queue_put :: proc(self: ^Blocking_Queue, item: rawptr) {
	append(&self.items, item)
}

blocking_queue_offer :: proc(self: ^Blocking_Queue, item: rawptr) -> bool {
	append(&self.items, item)
	return true
}

blocking_queue_take :: proc(self: ^Blocking_Queue) -> rawptr {
	if len(self.items) == 0 {
		return nil
	}
	head := self.items[0]
	ordered_remove(&self.items, 0)
	return head
}

blocking_queue_poll :: proc(self: ^Blocking_Queue) -> rawptr {
	if len(self.items) == 0 {
		return nil
	}
	head := self.items[0]
	ordered_remove(&self.items, 0)
	return head
}

blocking_queue_size :: proc(self: ^Blocking_Queue) -> i32 {
	return i32(len(self.items))
}

blocking_queue_is_empty :: proc(self: ^Blocking_Queue) -> bool {
	return len(self.items) == 0
}
