package game

// Java owners covered by this file:
//   - games.strategy.engine.random.CryptoRandomSource

Crypto_Random_Source :: struct {
	using i_random_source: I_Random_Source,
	plain_random:          Plain_Random_Source,
	remote_player:         ^Game_Player,
	game:                  ^I_Game,
}
// Java owners covered by this file:
//   - games.strategy.engine.random.CryptoRandomSource

