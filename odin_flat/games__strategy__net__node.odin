package game

Node :: struct {
	using i_node: I_Node,
	name:    string,
	address: ^Inet_Address,
	port:    i32,
}
