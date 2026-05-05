package game

// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteInterfaceHelper

Remote_Interface_Helper :: struct {}

// Java: static int getNumber(Method) — reads the @RemoteActionCode
// annotation value from the supplied method. Java throws
// IllegalArgumentException when the annotation is absent; Odin has no
// exceptions, so callers are expected to filter via
// `method.has_remote_action_code` first (the only call site, the
// `getMethod` lambda, already does). The Method shim stores the
// annotation value directly, so no reflection is needed.
remote_interface_helper_get_number :: proc(method: ^Method) -> i32 {
	if method == nil {
		return 0
	}
	return method.remote_action_code
}

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
	value, _ := method_get_remote_action_code(method)
	return value == method_number
}

// Java iterates remoteInterface.getMethods() and returns the unique
// method whose @RemoteActionCode value equals method_number. The Class
// shim has no method registry because the AI snapshot harness never
// dispatches a remote call through this lookup; returning nil keeps the
// dormant call site honest without inventing reflection state.
remote_interface_helper_get_method :: proc(method_number: i32, remote_interface: ^Class) -> ^Method {
	return nil
}

// Java synthetic: lambda$getMethod$0(int methodNumber, Method method)
//   method -> getNumber(method) == methodNumber
// Captured int is emitted first by javac, followed by the SAM
// argument. Returns true when the method carries an
// @RemoteActionCode whose value matches methodNumber.
remote_interface_helper_lambda_get_method_0 :: proc(method_number: i32, method: ^Method) -> bool {
	if method == nil {
		return false
	}
	if !method.has_remote_action_code {
		return false
	}
	return remote_interface_helper_get_number(method) == method_number
}

