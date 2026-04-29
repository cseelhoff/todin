package game

// JDK shim: opaque marker for java.awt.Component. The AI snapshot
// harness does not run Swing UI; Component appears in struct fields
// (e.g. HeadedWatcherThreadMessaging.parent) only as compile-time
// wiring.
Component :: struct {}
