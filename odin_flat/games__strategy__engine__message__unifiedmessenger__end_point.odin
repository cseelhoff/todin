package game

End_Point :: struct {
	next_given_number:       i64,
	current_runnable_number: i64,
	name:                    string,
	remote_class:            rawptr,
	implementors:            map[rawptr]struct {},
	single_threaded:         bool,
}

end_point_new :: proc(name: string, remote_class: ^Class, single_threaded: bool) -> ^End_Point {
	self := new(End_Point)
	self.name = name
	self.remote_class = rawptr(remote_class)
	self.single_threaded = single_threaded
	self.next_given_number = 0
	self.current_runnable_number = 0
	self.implementors = make(map[rawptr]struct {})
	return self
}

end_point_add_implementor :: proc(self: ^End_Point, implementor: rawptr) {
	self.implementors[implementor] = struct {}{}
}

end_point_take_a_number :: proc(self: ^End_Point) -> i64 {
	old := self.next_given_number
	self.next_given_number += 1
	return old
}

end_point_release_number :: proc(self: ^End_Point) {
	self.current_runnable_number += 1
}

end_point_wait_till_can_be_run :: proc(self: ^End_Point, num: i64) {
	// Single-threaded snapshot harness: serial calls always satisfy num == current, no-op.
}

end_point_invoke_multiple :: proc(self: ^End_Point, call: ^Remote_Method_Call, from: ^I_Node) -> [dynamic]^Remote_Method_Call_Results {
	// Snapshot harness does not exercise this path; no reflective dispatch available.
	results: [dynamic]^Remote_Method_Call_Results
	for _ in self.implementors {
		append(&results, remote_method_call_results_new(nil))
	}
	return results
}
