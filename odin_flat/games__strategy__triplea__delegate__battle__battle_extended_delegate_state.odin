package game

Battle_Extended_Delegate_State :: struct {
	super_state:                             rawptr,
	battle_tracker:                          ^Battle_Tracker,
	need_to_initialize:                      bool,
	need_to_scramble:                        bool,
	need_to_create_rockets:                  bool,
	need_to_kamikaze_suicide_attacks:        bool,
	need_to_clear_empty_air_battle_attacks:  bool,
	need_to_add_bombardment_sources:         bool,
	need_to_fire_rockets:                    bool,
	need_to_record_battle_statistics:        bool,
	need_to_check_defending_planes_can_land: bool,
	need_to_cleanup:                         bool,
	rocket_helper:                           ^Rockets_Fire_Helper,
	current_battle:                          ^I_Battle,
}

battle_extended_delegate_state_new :: proc() -> ^Battle_Extended_Delegate_State {
	self := new(Battle_Extended_Delegate_State)
	self.battle_tracker = battle_tracker_new()
	return self
}

