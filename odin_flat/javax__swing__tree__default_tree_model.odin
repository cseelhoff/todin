package game

// JDK shim: opaque marker for javax.swing.tree.DefaultTreeModel.
// History uses the tree model for in-memory bookkeeping; no Swing
// GUI runs in the AI snapshot harness.
Default_Tree_Model :: struct {
	root: ^Default_Mutable_Tree_Node,
}

default_tree_model_new :: proc(root: ^Default_Mutable_Tree_Node) -> ^Default_Tree_Model {
	m := new(Default_Tree_Model)
	m.root = root
	return m
}

default_tree_model_get_root :: proc(self: ^Default_Tree_Model) -> ^Default_Mutable_Tree_Node {
	return self.root
}
