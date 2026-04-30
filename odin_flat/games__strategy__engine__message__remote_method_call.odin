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

// Instance: getRemoteName()
remote_method_call_get_remote_name :: proc(self: ^Remote_Method_Call) -> string {
	return self.remote_name
}

// Instance: getMethodName()
remote_method_call_get_method_name :: proc(self: ^Remote_Method_Call) -> string {
	return self.method_name
}

// Instance: getArgs()
remote_method_call_get_args :: proc(self: ^Remote_Method_Call) -> []any {
	return self.args
}

// Static: classesToString(Class[], Object[]) -> String[]
// Java emits the class name, or null when args[i].getClass() == classes[i]
// (a serialization-size optimization that depends on reflection).
// The Odin port has no runtime "getClass" on `any`, so we always emit the
// declared class name; stringToClass will round-trip these correctly.
remote_method_call_classes_to_string :: proc(classes: []^Class, args: []any) -> []string {
	if args != nil && len(classes) != len(args) {
		panic("Classes and args arrays diff in length")
	}
	out := make([]string, len(classes))
	for i in 0 ..< len(classes) {
		if classes[i] == nil {
			out[i] = ""
		} else {
			out[i] = classes[i].name
		}
	}
	return out
}

// Static: stringToClass(String, Object) -> Class
// Java's branch for null string returns arg.getClass() via reflection.
// In the Odin port classes_to_string never emits an empty string for a
// non-nil class, so the null-string branch is unreachable on the round
// trip; we still handle it by returning nil so callers can detect the
// missing token.
remote_method_call_string_to_class :: proc(s: string, arg: any) -> ^Class {
	_ = arg
	if s == "" {
		return nil
	}
	switch s {
	case "int":
		return class_new("int", "int")
	case "short":
		return class_new("short", "short")
	case "byte":
		return class_new("byte", "byte")
	case "long":
		return class_new("long", "long")
	case "float":
		return class_new("float", "float")
	case "double":
		return class_new("double", "double")
	case "boolean":
		return class_new("boolean", "boolean")
	}
	// Java: Class.forName(s). The port has no class loader; carry the
	// fully-qualified name in a fresh shim Class so it can be printed
	// and compared.
	return class_new(s, s)
}
