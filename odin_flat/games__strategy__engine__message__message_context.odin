package game

// Java owners covered by this file:
//   - games.strategy.engine.message.MessageContext
//
// Information useful on invocation of remote networked events.
// The Java original is a final class with a private constructor and only a
// thread-local static `sender` field; it has no instance state, so the type
// is modeled as a zero-sized marker struct.
Message_Context :: struct {}

// Java original uses a ThreadLocal<INode>. The AI snapshot harness is
// single-threaded, so model it as a package-level file-private global.
@(private="file")
message_context_sender: ^I_Node = nil

message_context_get_sender :: proc() -> ^I_Node {
	return message_context_sender
}

message_context_set_sender_node_for_thread :: proc(node: ^I_Node) {
	message_context_sender = node
}

