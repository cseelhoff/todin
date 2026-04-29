package game

// JDK shim: opaque marker for javax.swing.Action. The AI snapshot
// harness wires up chat-related interfaces for compile-time setup
// but does not invoke any Swing actions during the snapshot run.
Action :: struct {}
