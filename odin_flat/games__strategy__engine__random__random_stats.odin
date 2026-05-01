package game

// Java owners covered by this file:
//   - games.strategy.engine.random.RandomStats

Random_Stats :: struct {
	remote_messenger: ^I_Remote_Messenger,
	random_stats:     map[^Game_Player]^Integer_Map,
}

// IRandomStats.RANDOM_STATS_REMOTE_NAME (declared on the Java interface
// as a constant; reconstructed here per call — equality is by name string).
random_stats_remote_name :: proc() -> ^Remote_Name {
	return remote_name_new(
		"games.strategy.engine.random.RandomStats.RANDOM_STATS_REMOTE_NAME",
		class_new("games.strategy.engine.random.IRandomStats", "IRandomStats"),
	)
}

// public RandomStats(IRemoteMessenger remoteMessenger)
random_stats_new :: proc(remote_messenger: ^I_Remote_Messenger) -> ^Random_Stats {
	self := new(Random_Stats)
	self.remote_messenger = remote_messenger
	self.random_stats = make(map[^Game_Player]^Integer_Map)
	i_remote_messenger_register_remote(remote_messenger, self, random_stats_remote_name())
	return self
}

// public void shutDown()
random_stats_shut_down :: proc(self: ^Random_Stats) {
	i_remote_messenger_unregister_remote(self.remote_messenger, random_stats_remote_name())
}

// public synchronized void addRandom(int[] random, GamePlayer player, DiceType diceType)
random_stats_add_random :: proc(
	self: ^Random_Stats,
	random: []i32,
	player: ^Game_Player,
	dice_type: I_Random_Stats_Dice_Type,
) {
	im := self.random_stats[player]
	if im == nil {
		im = integer_map_new()
	}
	for element in random {
		integer_map_add(im, rawptr(uintptr(element + 1)), 1)
	}
	// Only record COMBAT under the player; everything else collapses to nil.
	key: ^Game_Player = nil
	if dice_type == .COMBAT {
		key = player
	}
	self.random_stats[key] = im
}

