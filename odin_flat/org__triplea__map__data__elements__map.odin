package game

// Java owners covered by this file:
//   - org.triplea.map.data.elements.Map

Map_Data_Map_Territory :: struct {
	name:  string,
	water: Maybe(bool),
}

Map_Data_Map_Connection :: struct {
	t1: string,
	t2: string,
}

Map_Data_Map :: struct {
	territories: [dynamic]Map_Data_Map_Territory,
	connections: [dynamic]Map_Data_Map_Connection,
}

