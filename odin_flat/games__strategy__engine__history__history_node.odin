package game

// Java owners covered by this file:
//   - games.strategy.engine.history.HistoryNode
//
// Java extends javax.swing.tree.DefaultMutableTreeNode; per port
// instructions the Swing parent is not embedded. Only fields
// declared on HistoryNode itself are ported. The class declares
// no instance fields (only static constants); `title` is carried
// here because Java stores it in the parent's userObject which
// we are not embedding.

History_Node :: struct {
	title: string,
}

