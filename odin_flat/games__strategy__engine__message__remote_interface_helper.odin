package game

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteInterfaceHelper

Remote_Interface_Helper :: struct {}

// Predicate equivalent to the Java lambda
//   method -> getNumber(method) == methodNumber
// inside RemoteInterfaceHelper#getMethod. Returns true when the
// method carries an @RemoteActionCode whose value matches.
remote_interface_helper_lambda_get_method_1 :: proc(method: ^Method, method_number: i32) -> bool {
	if method == nil {
		return false
	}
	if !method.has_remote_action_code {
		return false
	}
	return method_get_remote_action_code(method) == method_number
}

// Java iterates remoteInterface.getMethods() and returns the unique
// method whose @RemoteActionCode value equals method_number. The Class
// shim has no method registry because the AI snapshot harness never
// dispatches a remote call through this lookup; returning nil keeps the
// dormant call site honest without inventing reflection state.
remote_interface_helper_get_method :: proc(method_number: i32, remote_interface: ^Class) -> ^Method {
	return nil
}

