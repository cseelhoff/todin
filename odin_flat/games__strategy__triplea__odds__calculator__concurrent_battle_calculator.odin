package game

Concurrent_Battle_Calculator :: struct {
	using i_battle_calculator: I_Battle_Calculator,
	workers: [dynamic]^Battle_Calculator,
	is_data_set: bool,
	cancel_current_operation: ^Atomic_Integer,
	latch_worker_threads_creation: ^Completable_Future,
	mutex_set_game_data: ^Object,
	mutex_calc_is_running: ^Object,
}
// Java owners covered by this file:
//   - games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator

