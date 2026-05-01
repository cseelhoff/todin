package game

Map_Connection :: struct {
	t1: string,
	t2: string,
}

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Map$Connection

Map_Data_Connection :: struct {
	t1: string,
	t2: string,
}

map_connection_get_t1 :: proc(self: ^Map_Connection) -> string {
	return self.t1
}

map_connection_get_t2 :: proc(self: ^Map_Connection) -> string {
	return self.t2
}

