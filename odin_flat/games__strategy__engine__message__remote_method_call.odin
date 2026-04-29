package game

// All the info necessary to describe a method call in one handy
// serializable package.
// Java owners covered by this file:
//   - games.strategy.engine.message.RemoteMethodCall

Remote_Method_Call :: struct {
	remote_name:   string,
	method_name:   string,
	args:          []any,
	// to save space, we don't serialize method name/types
	// instead we just serialize a number which can be translated into the correct method.
	method_number: i32,
	// stored as a []string so we can be serialized
	arg_types:     []string,
}
