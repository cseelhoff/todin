package game

// JDK shim: opaque marker for java.io.ObjectInputStream. The AI
// snapshot harness instantiates TripleA subclasses for compile-time
// wiring but does not perform real serialization during the snapshot
// run, so no semantics are required.
Object_Input_Stream :: struct {}
