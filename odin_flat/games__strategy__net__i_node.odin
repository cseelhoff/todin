package game

// Ported from games.strategy.net.INode (Java interface)
// Phase A: TYPE only. Empty marker struct for compatibility with other
// structs that reference I_Node as a type.

I_Node :: struct {}

// games.strategy.net.INode#getPlayerName()
//
// Java (default method on the interface):
//   default UserName getPlayerName() { return UserName.of(getName()); }
//
// I_Node is an empty marker; the only concrete implementer is Node,
// which embeds I_Node at offset 0 via `using i_node: I_Node`, so the
// downcast (^Node)(self) safely reads Node.name at the same address.
i_node_get_player_name :: proc(self: ^I_Node) -> ^User_Name {
	return user_name_of((^Node)(self).name)
}
