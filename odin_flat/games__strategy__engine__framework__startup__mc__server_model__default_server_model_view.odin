package game

Server_Model_Default_Server_Model_View :: struct {
	this_0: ^Server_Model,
}

make_Server_Model_Default_Server_Model_View :: proc(this_0: ^Server_Model) -> ^Server_Model_Default_Server_Model_View {
	self := new(Server_Model_Default_Server_Model_View)
	self.this_0 = this_0
	return self
}
