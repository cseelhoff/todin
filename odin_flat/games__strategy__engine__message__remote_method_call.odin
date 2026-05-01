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

// Static: stringsToClasses(String[], Object[]) -> Class[]
// Mirrors Java exactly: walks `strings` in order and translates each
// entry through `string_to_class`, threading the matching arg so the
// null-string optimization path can recover `arg.getClass()` when it
// fires. The Odin string_to_class returns nil for the empty-string
// sentinel since `any` carries no runtime "getClass"; round-tripping
// through classes_to_string never emits "" for a non-nil class so the
// nil result mirrors the Java unreachable branch faithfully.
remote_method_call_strings_to_classes :: proc(strings: []string, args: []any) -> []^Class {
	classes := make([]^Class, len(strings))
	for i in 0 ..< len(strings) {
		arg: any
		if args != nil && i < len(args) {
			arg = args[i]
		}
		classes[i] = remote_method_call_string_to_class(strings[i], arg)
	}
	return classes
}

// Instance: resolve(Class<?>) -> void
// After deserialization, methodName/argTypes carry no class context.
// Java looks the Method up by methodNumber on the supplied remoteType
// and rehydrates name + argTypes from it. The Odin
// `remote_interface_helper_get_method` shim returns nil because the
// snapshot run never dispatches a remote call through this lookup;
// when it returns nil we leave the call's fields untouched, matching
// the dormant nature of the call site. When a future shim populates
// the Method registry the code below performs the real rehydration.
remote_method_call_resolve :: proc(self: ^Remote_Method_Call, remote_type: ^Class) {
	if self.method_name != "" {
		return
	}
	method := remote_interface_helper_get_method(self.method_number, remote_type)
	if method == nil {
		return
	}
	self.method_name = method_get_name(method)
	self.arg_types = remote_method_call_classes_to_string(method.parameter_types, self.args)
}
