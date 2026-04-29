package game

// JDK shim: java.nio.channels.SocketChannel — opaque marker.
// The AI snapshot harness wires up Nio* helpers for setup-time
// reasons but never performs real socket I/O during the snapshot
// run, so an empty struct is sufficient.

Socket_Channel :: struct {}
