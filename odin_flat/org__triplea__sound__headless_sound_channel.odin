package game

Headless_Sound_Channel :: struct {
	using i_sound: I_Sound,
}

headless_sound_channel_new :: proc() -> ^Headless_Sound_Channel {
	self := new(Headless_Sound_Channel)
	return self
}

// TEST-ONLY instrumentation for fixture-driven golden tests.
// Behaviour is unchanged when dbg_sound_capture_enabled=false (default).
// When enabled, the next play_sound_for_all call records its clip name
// and the player's name into package-level vars so a test can
// value-compare the exact clip selected by the SUT (e.g. SoundUtils#playBattleType).
dbg_sound_capture_enabled:    bool
dbg_sound_capture_last_clip:   string
dbg_sound_capture_last_player: string

headless_sound_channel_play_sound_for_all :: proc(self: ^Headless_Sound_Channel, sound: string, player: ^Game_Player) {
	// TEST-ONLY instrumentation: capture clip + player name when enabled.
	if dbg_sound_capture_enabled {
		dbg_sound_capture_last_clip = sound
		if player != nil {
			dbg_sound_capture_last_player = game_player_get_name(player)
		} else {
			dbg_sound_capture_last_player = ""
		}
	}
	// no-op: headless sound channel intentionally plays nothing
}


// Java: org.triplea.sound.HeadlessSoundChannel#playSoundToPlayers(String, Collection<GamePlayer>, Collection<GamePlayer>, boolean)
//   Empty body in Java (no-op headless impl).
headless_sound_channel_play_sound_to_players :: proc(
	self: ^Headless_Sound_Channel,
	clip_name: string,
	players_to_send_to: [dynamic]^Game_Player,
	but_not_these_players: [dynamic]^Game_Player,
	include_observers: bool,
) {
	// no-op
}
