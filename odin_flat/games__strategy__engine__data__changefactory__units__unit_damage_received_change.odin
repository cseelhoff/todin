package game

Unit_Damage_Received_Change :: struct {
	using change: Change,
	new_total_damage:      map[string]i32,
	old_total_damage:      map[string]i32,
	territories_to_notify: [dynamic]string,
}

