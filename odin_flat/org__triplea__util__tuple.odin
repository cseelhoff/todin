package game

Tuple :: struct($A, $B: typeid) {
	first:  A,
	second: B,
}

tuple_new :: proc($A, $B: typeid, first: A, second: B) -> ^Tuple(A, B) {
	t := new(Tuple(A, B))
	t.first = first
	t.second = second
	return t
}

tuple_get_first :: proc(self: ^Tuple($A, $B)) -> A {
	return self.first
}

tuple_get_second :: proc(self: ^Tuple($A, $B)) -> B {
	return self.second
}

tuple_of :: proc(first: rawptr, second: rawptr) -> ^Tuple(rawptr, rawptr) {
	return tuple_new(rawptr, rawptr, first, second)
}

