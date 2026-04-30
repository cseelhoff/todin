package game

Game_Player_Type :: struct {
	id:   string,
	name: string,
}

make_Game_Player_Type :: proc(name: string, ordinal: int) -> Game_Player_Type {
	_ = ordinal
	return Game_Player_Type{name = name}
}
