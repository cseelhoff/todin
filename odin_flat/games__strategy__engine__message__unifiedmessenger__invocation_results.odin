package game

Invocation_Results :: struct {
	results:        ^Remote_Method_Call_Results,
	method_call_id: Uuid,
}
// Java owners covered by this file:
//   - games.strategy.engine.message.unifiedmessenger.InvocationResults

invocation_results_new :: proc(results: ^Remote_Method_Call_Results, method_call_id: Uuid) -> ^Invocation_Results {
	assert(results != nil)
	self := new(Invocation_Results)
	self.results = results
	self.method_call_id = method_call_id
	return self
}

