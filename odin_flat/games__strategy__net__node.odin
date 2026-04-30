package game

Node :: struct {
	using i_node: I_Node,
	name:    string,
	address: ^Inet_Address,
	port:    i32,
}

node_new :: proc(name: string, address: ^Inet_Address, port: i32) -> ^Node {
	self := new(Node)
	self.name = name
	self.address = address
	self.port = port
	return self
}
