package game

Invocation_In_Progress :: struct {
	waiting_on:  ^I_Node,
	method_call: ^Hub_Invoke,
	caller:      ^I_Node,
	results:     ^Remote_Method_Call_Results,
}
