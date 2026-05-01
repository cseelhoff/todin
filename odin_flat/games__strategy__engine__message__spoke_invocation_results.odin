package game

Spoke_Invocation_Results :: struct {
	using invocation_results: Invocation_Results,
}

spoke_invocation_results_new :: proc(results: ^Remote_Method_Call_Results, method_call_id: Uuid) -> ^Spoke_Invocation_Results {
	self := new(Spoke_Invocation_Results)
	self.invocation_results = invocation_results_new(results, method_call_id)^
	return self
}
