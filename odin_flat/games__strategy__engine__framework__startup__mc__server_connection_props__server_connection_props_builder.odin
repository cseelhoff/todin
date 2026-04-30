package game

Server_Connection_Props_Builder :: struct {
	name:     string,
	port:     i32,
	password: [dynamic]rune,
}

make_Server_Connection_Props_Server_Connection_Props_Builder :: proc() -> Server_Connection_Props_Builder {
	return Server_Connection_Props_Builder{}
}

server_connection_props_builder_name :: proc(self: ^Server_Connection_Props_Builder, name: string) -> ^Server_Connection_Props_Builder {
	self.name = name
	return self
}

server_connection_props_builder_port :: proc(self: ^Server_Connection_Props_Builder, port: i32) -> ^Server_Connection_Props_Builder {
	self.port = port
	return self
}

server_connection_props_builder_password :: proc(self: ^Server_Connection_Props_Builder, password: []rune) -> ^Server_Connection_Props_Builder {
	clear(&self.password)
	for r in password {
		append(&self.password, r)
	}
	return self
}

