package game

// games.strategy.engine.history.HistoryNode
// Abstract superclass for all nodes in the History tree view.
// Extends javax.swing.tree.DefaultMutableTreeNode (JDK shim).
// Java declares no instance fields (only static constants); the
// title is stored in the parent's userObject.

// Discriminator used to recover Java `instanceof` checks against
// History_Node subtypes (Round, Step, Event, Event_Child, ...).
// Subtype constructors must set `kind` to the corresponding value.
History_Node_Kind :: enum {
	Unknown,
	Round,
	Step,
	Event,
	Event_Child,
}

History_Node :: struct {
	using default_mutable_tree_node: Default_Mutable_Tree_Node,
	kind: History_Node_Kind,
}

