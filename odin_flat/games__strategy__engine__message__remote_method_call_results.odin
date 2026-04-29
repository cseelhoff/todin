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

