package game

// Java owners covered by this file:
//   - games.strategy.engine.random.RandomStats

Random_Stats :: struct {
	remote_messenger: ^I_Remote_Messenger,
	random_stats:     map[^Game_Player]^Integer_Map,
}

