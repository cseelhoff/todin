package game

// JDK shim: java.lang.reflect.Method — minimal value carrier.
// The TripleA port does not actually use reflection at runtime. The few
// sites that reference java.lang.reflect.Method (RemoteInterfaceHelper,
// RemoteMethodCall lookup tables, WrappedInvocationHandler) only need
// to read a method's name, its declaring class, and an optional
// @RemoteActionCode value. No invocation is performed during the AI
// snapshot run.

Method :: struct {
        name:                   string,
        declaring_class:        ^Class,
        // @RemoteActionCode(int value) when present.
        remote_action_code:     i32,
        has_remote_action_code: bool,
}

method_new :: proc(name: string, declaring_class: ^Class) -> ^Method {
        m := new(Method)
        m.name = name
        m.declaring_class = declaring_class
        return m
}

method_get_name :: proc(self: ^Method) -> string {
        if self == nil {
                return ""
        }
        return self.name
}

method_get_declaring_class :: proc(self: ^Method) -> ^Class {
        if self == nil {
                return nil
        }
        return self.declaring_class
}

method_to_string :: proc(self: ^Method) -> string {
        if self == nil {
                return "<nil method>"
        }
        if self.declaring_class != nil {
                // simple "ClassName.methodName" form
                buf: [dynamic]u8
                for c in self.declaring_class.name {
                        append(&buf, u8(c))
                }
                append(&buf, '.')
                for c in self.name {
                        append(&buf, u8(c))
                }
                return string(buf[:])
        }
        return self.name
}

method_equals :: proc(self: ^Method, other: ^Method) -> bool {
        if self == other {
                return true
        }
        if self == nil || other == nil {
                return false
        }
        if self.name != other.name {
                return false
        }
        return class_equals(self.declaring_class, other.declaring_class)
}

// Java Method.getAnnotation(RemoteActionCode.class) → returns the
// @RemoteActionCode int value when the annotation is present.
// Callers translate the (value, present) pair back into a wrapper
// object on the Java side; here the caller checks `has` directly.
method_get_remote_action_code :: proc(self: ^Method) -> (value: i32, has: bool) {
        if self == nil {
                return 0, false
        }
        return self.remote_action_code, self.has_remote_action_code
}
