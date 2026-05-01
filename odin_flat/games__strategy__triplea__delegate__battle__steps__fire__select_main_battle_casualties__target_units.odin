package game

Select_Main_Battle_Casualties_Target_Units :: struct {
	combat_units:          [dynamic]^Unit,
	restricted_transports: [dynamic]^Unit,
}

select_main_battle_casualties_target_units_new :: proc(
	combat_units: [dynamic]^Unit,
	restricted_transports: [dynamic]^Unit,
) -> ^Select_Main_Battle_Casualties_Target_Units {
	self := new(Select_Main_Battle_Casualties_Target_Units)
	self.combat_units = combat_units
	self.restricted_transports = restricted_transports
	return self
}

select_main_battle_casualties_target_units_of :: proc(
	combat_units: [dynamic]^Unit,
	restricted_transports: [dynamic]^Unit,
) -> ^Select_Main_Battle_Casualties_Target_Units {
	return select_main_battle_casualties_target_units_new(combat_units, restricted_transports)
}
