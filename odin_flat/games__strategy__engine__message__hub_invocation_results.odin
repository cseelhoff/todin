package game

Hub_Invocation_Results :: struct {
	using invocation_results: Invocation_Results,
}

hub_invocation_results_new :: proc(results: ^Remote_Method_Call_Results, method_call_id: Uuid) -> ^Hub_Invocation_Results {
	self := new(Hub_Invocation_Results)
	self.invocation_results = invocation_results_new(results, method_call_id)^
	return self
}
