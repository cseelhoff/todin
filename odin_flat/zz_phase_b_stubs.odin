package game

// Phase-B stubs to unblock package-level compilation. Replaced with real
// ports as those entities/methods are dispatched.

game_map_get_distance_bipredicate :: proc(
        self: ^Game_Map,
        t1, t2: ^Territory,
        cond: proc(rawptr, ^Territory, ^Territory) -> bool,
        cond_ctx: rawptr,
) -> i32 {
        return 0
}

battle_tracker_fix_up_null_players :: proc(self: ^Battle_Tracker, null_player: ^Game_Player) {}
battle_delegate_get_battle_tracker :: proc(self: ^Battle_Delegate) -> ^Battle_Tracker { return self.battle_tracker }
player_list_get_null_player :: proc(self: ^Player_List) -> ^Game_Player { return self.null_player }
game_data_state_new :: proc(self: ^Game_Data) -> ^Game_Data_State { return nil }
game_data_fix_up_null_players :: proc(self: ^Game_Data) {}
