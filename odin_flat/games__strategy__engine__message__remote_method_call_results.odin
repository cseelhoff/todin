package game

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteMethodCallResults
//
// Java fields `Object returnValue` and `Throwable exception` cross the
// JDK boundary; both are kept as `rawptr`.

Remote_Method_Call_Results :: struct {
	return_value: rawptr,
	exception:    rawptr,
}

remote_method_call_results_new :: proc(return_value: rawptr) -> ^Remote_Method_Call_Results {
	self := new(Remote_Method_Call_Results)
	self.return_value = return_value
	self.exception = nil
	return self
}

remote_method_call_results_new_from_throwable :: proc(exception: rawptr) -> ^Remote_Method_Call_Results {
	self := new(Remote_Method_Call_Results)
	self.return_value = nil
	self.exception = exception
	return self
}

remote_method_call_results_get_exception :: proc(self: ^Remote_Method_Call_Results) -> rawptr {
	return self.exception
}

remote_method_call_results_get_r_val :: proc(self: ^Remote_Method_Call_Results) -> rawptr {
	return self.return_value
}

