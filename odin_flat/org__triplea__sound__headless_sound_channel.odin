package game

Headless_Sound_Channel :: struct {
	using i_sound: I_Sound,
}

headless_sound_channel_new :: proc() -> ^Headless_Sound_Channel {
	self := new(Headless_Sound_Channel)
	return self
}

headless_sound_channel_play_sound_for_all :: proc(self: ^Headless_Sound_Channel, sound: string, player: ^Game_Player) {
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
