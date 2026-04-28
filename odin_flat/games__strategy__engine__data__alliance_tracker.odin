package game

// games.strategy.engine.data.AllianceTracker
//
// alliance-name → list of players in that alliance.

Alliance_Tracker :: struct {
	alliances: map[string][dynamic]^Game_Player,
}
