package game

Client_Setting :: struct {
	using game_setting: Game_Setting,
	type: typeid,
	name: string,
	default_value: rawptr,
	listeners: [dynamic]proc(^Game_Setting),
}

