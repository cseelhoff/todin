package game

Server_Connection_Props_Builder :: struct {
	name:     string,
	port:     i32,
	password: [dynamic]rune,
}

make_Server_Connection_Props_Server_Connection_Props_Builder :: proc() -> Server_Connection_Props_Builder {
	return Server_Connection_Props_Builder{}
}

