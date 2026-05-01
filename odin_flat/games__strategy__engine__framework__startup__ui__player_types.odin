package game

import "core:fmt"

@(private="file") _player_types_weak_ai: ^Player_Types_Type
@(private="file") _player_types_fast_ai: ^Player_Types_Type
@(private="file") _player_types_pro_ai: ^Player_Types_Type

player_types_weak_ai :: proc() -> ^Player_Types_Type {
	if _player_types_weak_ai == nil {
		_player_types_weak_ai = new(Player_Types_Type)
		_player_types_weak_ai.label = "Easy (AI)"
		_player_types_weak_ai.visible = true
	}
	return _player_types_weak_ai
}

player_types_fast_ai :: proc() -> ^Player_Types_Type {
	if _player_types_fast_ai == nil {
		_player_types_fast_ai = new(Player_Types_Type)
		_player_types_fast_ai.label = "Fast (AI)"
		_player_types_fast_ai.visible = true
	}
	return _player_types_fast_ai
}

player_types_pro_ai :: proc() -> ^Player_Types_Type {
	if _player_types_pro_ai == nil {
		_player_types_pro_ai = new(Player_Types_Type)
		_player_types_pro_ai.label = "Hard (AI)"
		_player_types_pro_ai.visible = true
	}
	return _player_types_pro_ai
}

Player_Types :: struct {
	player_types: [dynamic]^Player_Types_Type,
}

make_Player_Types :: proc(types: [dynamic]^Player_Types_Type) -> Player_Types {
	return Player_Types{player_types = types}
}

player_types_from_label :: proc(self: ^Player_Types, label: string) -> ^Player_Types_Type {
	for t in self.player_types {
		if t.label == label {
			return t
		}
	}
	panic("could not find PlayerType")
}

player_types_get_built_in_player_types :: proc() -> [dynamic]^Player_Types_Type {
	result: [dynamic]^Player_Types_Type
	append(&result, player_types_weak_ai())
	append(&result, player_types_fast_ai())
	append(&result, player_types_pro_ai())
	return result
}

player_types_get_player_types :: proc(self: ^Player_Types) -> [dynamic]^Player_Types_Type {
	return self.player_types
}

player_types_lambda_from_label_2 :: proc(label: string) {
	panic(fmt.tprintf("could not find PlayerType: %s", label))
}

player_types_lambda_get_available_player_labels_0 :: proc(size: i32) -> [dynamic]string {
	result: [dynamic]string
	resize(&result, int(size))
	return result
}

player_types_type_new_full :: proc(label: string, visible: bool) -> ^Player_Types_Type {
	t := new(Player_Types_Type)
	t.label = label
	t.visible = visible
	return t
}
