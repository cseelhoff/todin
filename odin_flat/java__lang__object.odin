package game

// JDK shim: java.lang.Object — opaque marker.
// In Java this is the universal base class; the port only uses
// it as a synchronization monitor (`new Object()` for `synchronized`
// blocks). The AI snapshot harness is single-threaded, so a bare
// struct is sufficient.

Object :: struct {}
