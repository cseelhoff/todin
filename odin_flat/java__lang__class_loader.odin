package game

// JDK shim: java.lang.ClassLoader — opaque marker. The AI snapshot
// harness uses pre-loaded GameData and never resolves classpath
// resources, so getResourceAsStream simply returns nil ("resource not
// found"). Callers that wrap the result in Optional / orElseThrow
// will throw via the corresponding shim path.
Class_Loader :: struct {}

class_loader_get_resource_as_stream :: proc(self: ^Class_Loader, name: string) -> ^Input_Stream {
	_ = self
	_ = name
	return nil
}
