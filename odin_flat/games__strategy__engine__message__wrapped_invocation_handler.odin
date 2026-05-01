package game

import "core:fmt"

Wrapped_Invocation_Handler :: struct {
	delegate: rawptr,
}

wrapped_invocation_handler_new :: proc(delegate: rawptr) -> ^Wrapped_Invocation_Handler {
	assert(delegate != nil) // Java: checkNotNull(delegate)
	self := new(Wrapped_Invocation_Handler)
	self.delegate = delegate
	return self
}

// Java: shouldHandle returns true for the three Object methods routed
// to the delegate: equals(Object), hashCode(), toString().
wrapped_invocation_handler_should_handle :: proc(self: ^Wrapped_Invocation_Handler, method: ^Method, args: []rawptr) -> bool {
	if method == nil {
		return false
	}
	name := method_get_name(method)
	if name == "equals" && args != nil && len(args) == 1 {
		return true
	}
	if name == "hashCode" && args == nil {
		return true
	}
	if name == "toString" && args == nil {
		return true
	}
	return false
}

// Java: wrappedEquals(Object other). The original peeks through a
// java.lang.reflect.Proxy to compare the *delegates* of two wrapped
// handlers. The Odin port has no Proxy machinery, so `other` is
// interpreted as a pointer to another Wrapped_Invocation_Handler:
// equal when self == other, or when both delegates match.
wrapped_invocation_handler_wrapped_equals :: proc(self: ^Wrapped_Invocation_Handler, other: rawptr) -> bool {
	if other == rawptr(self) {
		return true
	}
	if other == nil {
		return false
	}
	other_wrapped := cast(^Wrapped_Invocation_Handler)other
	return other_wrapped.delegate == self.delegate
}

// Java: handle(Method, Object[]) routes the three Object methods to
// the delegate. Java returns Object (a boxed Boolean / Integer /
// String); the Odin port returns a rawptr to a freshly heap-allocated
// box, matching how Java would auto-box the primitive results. The
// caller (invoke) is responsible for interpreting the box according
// to the method name. delegate.hashCode()/toString() have no generic
// dispatch in Odin, so we use the delegate pointer itself — faithful
// to the wrapped_equals deviation already documented above. The
// proc panics on the impossible else branch, mirroring Java's
// IllegalStateException("how did we get here").
wrapped_invocation_handler_handle :: proc(self: ^Wrapped_Invocation_Handler, method: ^Method, args: []rawptr) -> rawptr {
	name := method_get_name(method)
	if name == "equals" && args != nil && len(args) == 1 {
		boxed := new(bool)
		boxed^ = wrapped_invocation_handler_wrapped_equals(self, args[0])
		return rawptr(boxed)
	} else if name == "hashCode" && args == nil {
		boxed := new(i32)
		boxed^ = i32(uintptr(self.delegate))
		return rawptr(boxed)
	} else if name == "toString" && args == nil {
		boxed := new(string)
		boxed^ = fmt.tprintf("%p", self.delegate)
		return rawptr(boxed)
	}
	panic("how did we get here")
}
