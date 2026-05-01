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

