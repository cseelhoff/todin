package game

Predicate_Builder :: struct {
	predicate: proc(o: rawptr) -> bool,
}

predicate_builder_lambda_true_builder_0 :: proc(o: rawptr) -> bool {
	return true
}

predicate_builder_new :: proc(initial: proc(o: rawptr) -> bool) -> ^Predicate_Builder {
	assert(initial != nil)
	pb := new(Predicate_Builder)
	pb.predicate = initial
	return pb
}

predicate_builder_build :: proc(self: ^Predicate_Builder) -> proc(o: rawptr) -> bool {
	return self.predicate
}
