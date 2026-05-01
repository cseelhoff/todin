package game

I_Battle_Battle_Type :: enum {
	NORMAL,
	AIR_BATTLE,
	AIR_RAID,
	BOMBING_RAID,
}

i_battle_battle_type_is_bombing_run :: proc(self: I_Battle_Battle_Type) -> bool {
	switch self {
	case .NORMAL:
		return false
	case .AIR_BATTLE:
		return false
	case .AIR_RAID:
		return true
	case .BOMBING_RAID:
		return true
	}
	return false
}

i_battle_battle_type_to_display_text :: proc(self: I_Battle_Battle_Type) -> string {
	switch self {
	case .NORMAL:
		return "Battle"
	case .AIR_BATTLE:
		return "Air Battle"
	case .AIR_RAID:
		return "Air Raid"
	case .BOMBING_RAID:
		return "Bombing Raid"
	}
	return ""
}

i_battle_battle_type_values :: proc() -> [dynamic]I_Battle_Battle_Type {
	result := make([dynamic]I_Battle_Battle_Type, 0, 4)
	append(&result, I_Battle_Battle_Type.NORMAL)
	append(&result, I_Battle_Battle_Type.AIR_BATTLE)
	append(&result, I_Battle_Battle_Type.AIR_RAID)
	append(&result, I_Battle_Battle_Type.BOMBING_RAID)
	return result
}

i_battle_battle_type_non_bombing_battle_types :: proc() -> [dynamic]I_Battle_Battle_Type {
	all := i_battle_battle_type_values()
	defer delete(all)
	result := make([dynamic]I_Battle_Battle_Type, 0, len(all))
	for bt in all {
		if !i_battle_battle_type_is_bombing_run(bt) {
			append(&result, bt)
		}
	}
	return result
}

i_battle_battle_type_bombing_battle_types :: proc() -> [dynamic]I_Battle_Battle_Type {
	all := i_battle_battle_type_values()
	defer delete(all)
	result := make([dynamic]I_Battle_Battle_Type, 0, len(all))
	for bt in all {
		if i_battle_battle_type_is_bombing_run(bt) {
			append(&result, bt)
		}
	}
	return result
}

