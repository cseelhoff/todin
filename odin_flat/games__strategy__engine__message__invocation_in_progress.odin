package game

import "core:fmt"

Invocation_In_Progress :: struct {
	waiting_on:  ^I_Node,
	method_call: ^Hub_Invoke,
	caller:      ^I_Node,
	results:     ^Remote_Method_Call_Results,
}

invocation_in_progress_new :: proc(
	waiting_on: ^I_Node,
	method_calls: ^Hub_Invoke,
	method_calls_from: ^I_Node,
) -> ^Invocation_In_Progress {
	self := new(Invocation_In_Progress)
	self.waiting_on = waiting_on
	self.method_call = method_calls
	self.caller = method_calls_from
	return self
}

invocation_in_progress_get_caller :: proc(self: ^Invocation_In_Progress) -> ^I_Node {
	return self.caller
}

invocation_in_progress_get_results :: proc(
	self: ^Invocation_In_Progress,
) -> ^Remote_Method_Call_Results {
	return self.results
}

invocation_in_progress_process :: proc(
	self: ^Invocation_In_Progress,
	hub_results: ^Hub_Invocation_Results,
	from: ^I_Node,
) {
	self.results = hub_results.results
	if from != self.waiting_on {
		panic(fmt.tprintf("Wrong node, expecting %p got %p", self.waiting_on, from))
	}
}

invocation_in_progress_should_send_results :: proc(self: ^Invocation_In_Progress) -> bool {
	return self.method_call.need_return_values
}
