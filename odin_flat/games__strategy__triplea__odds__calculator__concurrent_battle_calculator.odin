package game

import "core:fmt"

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

// MAX_THREADS in Java = Runtime.getRuntime().availableProcessors(). Under the
// single-threaded JDK shim, the AI snapshot harness runs serially, so this
// constant is fixed at 1.
@(private = "file")
CONCURRENT_BATTLE_CALCULATOR_MAX_THREADS :: 1

// Closure-capture context for `lambda$createWorkers$2`: the lambda body
// `j -> new BattleCalculator(serializedData)` captures the serialized game
// data byte array from the enclosing `createWorkers` frame.
Concurrent_Battle_Calculator_Lambda_Create_Workers_2_Ctx :: struct {
	serialized_data: []u8,
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#<init>()
concurrent_battle_calculator_new :: proc() -> ^Concurrent_Battle_Calculator {
	self := new(Concurrent_Battle_Calculator)
	self.workers = make([dynamic]^Battle_Calculator)
	self.is_data_set = false
	self.cancel_current_operation = atomic_integer_new(0)
	// CompletableFuture.completedFuture(false): an already-completed future
	// whose payload is Boolean.FALSE. Our shim stores `rawptr`, so we encode
	// FALSE as a nil payload (the only readers of this future are
	// waitForGameDataReady's `.get()`, which discards the value).
	self.latch_worker_threads_creation = completable_future_new()
	completable_future_complete(self.latch_worker_threads_creation, nil)
	self.mutex_set_game_data = new(Object)
	self.mutex_calc_is_running = new(Object)
	return self
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#getThreadsToUse(long, long)
// Java guards the heavy memory-introspection path with
// `if (timeToCopyInMillis > 20000 || MAX_THREADS == 1) return 1;`. Because
// the Odin shim hard-codes MAX_THREADS = 1 (single-threaded harness), the
// guard is always taken and the function unconditionally returns 1. The
// remaining Java branches are unreachable under this configuration and
// therefore have no observable behavior to translate.
concurrent_battle_calculator_get_threads_to_use :: proc(time_to_copy_in_millis: i64, memory_used_before_copy: i64) -> i32 {
	_ = memory_used_before_copy
	if time_to_copy_in_millis > 20000 || CONCURRENT_BATTLE_CALCULATOR_MAX_THREADS == 1 {
		return 1
	}
	return CONCURRENT_BATTLE_CALCULATOR_MAX_THREADS
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#lambda$createWorkers$2(int)
// Java body: `j -> new BattleCalculator(serializedData)`. The captured
// `serializedData` is supplied via the rawptr ctx convention.
concurrent_battle_calculator_lambda_create_workers_2 :: proc(ctx: rawptr, j: i32) -> ^Battle_Calculator {
	_ = j
	cap_ctx := cast(^Concurrent_Battle_Calculator_Lambda_Create_Workers_2_Ctx)ctx
	return battle_calculator_new(cap_ctx.serialized_data)
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#lambda$setGameData$1(Throwable)
// Java body: `throwable -> { log.error("Error while trying to set GameData", throwable); return false; }`.
concurrent_battle_calculator_lambda_set_game_data_1 :: proc(throwable: ^Throwable) -> bool {
	if throwable != nil {
		fmt.eprintln("Error while trying to set GameData:", throwable.message)
	} else {
		fmt.eprintln("Error while trying to set GameData")
	}
	return false
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#waitForGameDataReady()
concurrent_battle_calculator_wait_for_game_data_ready :: proc(self: ^Concurrent_Battle_Calculator) {
	// `synchronized (mutexSetGameData)` is a no-op in the single-threaded
	// shim. The body simply waits for the latch (i.e. the most recent
	// setGameData CompletableFuture) to complete. In the shim,
	// completable_future_get returns immediately because every future is
	// resolved synchronously at creation; the InterruptedException /
	// ExecutionException branches in Java are unreachable here.
	_ = completable_future_get(self.latch_worker_threads_creation)
}

