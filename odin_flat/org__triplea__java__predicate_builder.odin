package game

// Predicate_Builder — chained predicate composition. Java's
// `PredicateBuilder<T>.and(p)` / `.or(p)` mutate the underlying predicate
// to a closure over (this.predicate, p). Odin's bare `proc` type cannot
// capture environment, so we represent the composition as an op chain
// that `build()` flattens via a thunk reading a heap-allocated context.
//
// The contract callers see is unchanged: `predicate_builder_build(self)`
// returns a `(proc(rawptr) -> bool, rawptr)` pair following the
// rawptr+ctx convention from llm-instructions.md. The 3 procs marked
// done in earlier batches (new, build, lambda_true_builder_0) are
// re-implemented here against the new shape; the 2 previously blocked
// procs (and, or) are now expressible.

Predicate_Builder_Op_Kind :: enum {
	Initial,
	And,
	Or,
}

Predicate_Builder_Op :: struct {
	kind: Predicate_Builder_Op_Kind,
	pred: proc(o: rawptr) -> bool,
}

Predicate_Builder :: struct {
	chain: [dynamic]Predicate_Builder_Op,
}

predicate_builder_new :: proc(initial: proc(o: rawptr) -> bool) -> ^Predicate_Builder {
	assert(initial != nil)
	pb := new(Predicate_Builder)
	pb.chain = make([dynamic]Predicate_Builder_Op, 0, 1)
	append(&pb.chain, Predicate_Builder_Op{kind = .Initial, pred = initial})
	return pb
}

predicate_builder_lambda_true_builder_0 :: proc(o: rawptr) -> bool {
	return true
}

predicate_builder_and :: proc(self: ^Predicate_Builder, p: proc(o: rawptr) -> bool) -> ^Predicate_Builder {
	assert(p != nil)
	append(&self.chain, Predicate_Builder_Op{kind = .And, pred = p})
	return self
}

predicate_builder_or :: proc(self: ^Predicate_Builder, p: proc(o: rawptr) -> bool) -> ^Predicate_Builder {
	assert(p != nil)
	append(&self.chain, Predicate_Builder_Op{kind = .Or, pred = p})
	return self
}

_predicate_builder_eval :: proc(ctx: rawptr, o: rawptr) -> bool {
	self := cast(^Predicate_Builder)ctx
	if len(self.chain) == 0 {
		return true
	}
	acc := self.chain[0].pred(o)
	for i in 1 ..< len(self.chain) {
		op := self.chain[i]
		if op.kind == .And {
			acc = acc && op.pred(o)
		} else {
			acc = acc || op.pred(o)
		}
	}
	return acc
}

predicate_builder_build :: proc(self: ^Predicate_Builder) -> (proc(ctx: rawptr, o: rawptr) -> bool, rawptr) {
	return _predicate_builder_eval, rawptr(self)
}
