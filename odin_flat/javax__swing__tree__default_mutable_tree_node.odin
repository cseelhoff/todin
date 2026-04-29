package game

// JDK shim: opaque marker for javax.swing.tree.DefaultMutableTreeNode.
// History tracking uses the tree structure for in-memory bookkeeping;
// no Swing GUI runs in the AI snapshot harness.
Default_Mutable_Tree_Node :: struct {
	user_object: any,
	parent:      ^Default_Mutable_Tree_Node,
	children:    [dynamic]^Default_Mutable_Tree_Node,
}

default_mutable_tree_node_new :: proc(user_object: any) -> ^Default_Mutable_Tree_Node {
	n := new(Default_Mutable_Tree_Node)
	n.user_object = user_object
	n.children = make([dynamic]^Default_Mutable_Tree_Node)
	return n
}

default_mutable_tree_node_add :: proc(self: ^Default_Mutable_Tree_Node, child: ^Default_Mutable_Tree_Node) {
	child.parent = self
	append(&self.children, child)
}

default_mutable_tree_node_get_user_object :: proc(self: ^Default_Mutable_Tree_Node) -> any {
	return self.user_object
}

default_mutable_tree_node_get_child_count :: proc(self: ^Default_Mutable_Tree_Node) -> i32 {
	return cast(i32)len(self.children)
}

default_mutable_tree_node_get_child_at :: proc(self: ^Default_Mutable_Tree_Node, i: i32) -> ^Default_Mutable_Tree_Node {
	return self.children[i]
}

default_mutable_tree_node_get_parent :: proc(self: ^Default_Mutable_Tree_Node) -> ^Default_Mutable_Tree_Node {
	return self.parent
}
