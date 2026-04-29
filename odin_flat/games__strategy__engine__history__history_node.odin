package game

// games.strategy.engine.history.HistoryNode
// Abstract superclass for all nodes in the History tree view.
// Extends javax.swing.tree.DefaultMutableTreeNode (JDK shim).
// Java declares no instance fields (only static constants); the
// title is stored in the parent's userObject.

History_Node :: struct {
	using parent: Default_Mutable_Tree_Node,
}

