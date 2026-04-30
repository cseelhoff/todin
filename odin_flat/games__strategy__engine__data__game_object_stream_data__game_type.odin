package game

Game_Object_Stream_Data_Game_Type :: enum {
	PLAYERID,
	UNITTYPE,
	TERRITORY,
	PRODUCTIONRULE,
	PRODUCTIONFRONTIER,
}

game_object_stream_data_game_type_values :: proc() -> []Game_Object_Stream_Data_Game_Type {
	return []Game_Object_Stream_Data_Game_Type{.PLAYERID, .UNITTYPE, .TERRITORY, .PRODUCTIONRULE, .PRODUCTIONFRONTIER}
}

game_object_stream_data_game_type_values_public :: proc() -> []Game_Object_Stream_Data_Game_Type {
	return game_object_stream_data_game_type_values()
}

make_Game_Object_Stream_Data_Game_Type :: proc(name: string, ordinal: int) -> Game_Object_Stream_Data_Game_Type {
	switch name {
	case "PLAYERID":           return .PLAYERID
	case "UNITTYPE":           return .UNITTYPE
	case "TERRITORY":          return .TERRITORY
	case "PRODUCTIONRULE":     return .PRODUCTIONRULE
	case "PRODUCTIONFRONTIER": return .PRODUCTIONFRONTIER
	}
	return .PLAYERID
}
