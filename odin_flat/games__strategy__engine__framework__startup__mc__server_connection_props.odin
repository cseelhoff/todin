package game

Server_Connection_Props :: struct {
	name:     string,
	port:     i32,
	password: [dynamic]rune,
}

make_Server_Connection_Props :: proc(name: string, port: i32, password: []rune) -> Server_Connection_Props {
	pw: [dynamic]rune
	for r in password {
		append(&pw, r)
	}
	return Server_Connection_Props{
		name = name,
		port = port,
		password = pw,
	}
}

server_connection_props_get_name :: proc(self: ^Server_Connection_Props) -> string {
	return self.name
}

server_connection_props_get_port :: proc(self: ^Server_Connection_Props) -> i32 {
	return self.port
}

