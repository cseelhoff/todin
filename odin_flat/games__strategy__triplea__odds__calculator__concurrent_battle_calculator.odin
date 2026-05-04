package game

import "core:fmt"
import "core:time"

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

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#calculate(GamePlayer, GamePlayer, Territory, Collection<Unit>, Collection<Unit>, Collection<Unit>, Collection<TerritoryEffect>, boolean, int)
// Java wraps each worker call in a parallel stream, distributing run counts
// across `workers.size()` BattleCalculators and flat-mapping the resulting
// BattleResults lists. Under the single-threaded JDK shim, this collapses to
// a sequential loop over `self.workers`; the result aggregation, run-count
// distribution, and timing are preserved verbatim.
concurrent_battle_calculator_calculate :: proc(
	self: ^Concurrent_Battle_Calculator,
	attacker: ^Game_Player,
	defender: ^Game_Player,
	location: ^Territory,
	attacking: [dynamic]^Unit,
	defending: [dynamic]^Unit,
	bombarding: [dynamic]^Unit,
	territory_effects: [dynamic]^Territory_Effect,
	retreat_when_only_air_left: bool,
	run_count: i32,
) -> ^Aggregate_Results {
	concurrent_battle_calculator_wait_for_game_data_ready(self)
	// `synchronized (mutexCalcIsRunning)` is a no-op in the single-threaded shim.
	start := time.tick_now()
	if !self.is_data_set {
		// We could have attempted to set a new game data while the old one was
		// still being set, causing it to abort with null data. Mirror Java's
		// `new AggregateResults(0)` early-return.
		return aggregate_results_new_int(0)
	}
	run_count_distributor := run_count_distributor_new(run_count, i32(len(self.workers)))
	combined := make([dynamic]^Battle_Results)
	for worker in self.workers {
		worker_result := battle_calculator_calculate(
			worker,
			attacker,
			defender,
			location,
			attacking,
			defending,
			bombarding,
			territory_effects,
			retreat_when_only_air_left,
			run_count_distributor_next_run_count(run_count_distributor),
		)
		for r in worker_result.results {
			append(&combined, r)
		}
	}
	results := aggregate_results_new_list(combined)
	delete(combined)
	elapsed := time.tick_since(start)
	aggregate_results_set_time(results, i64(time.duration_milliseconds(elapsed)))
	return results
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#setGameData(GameData)
// Java:
//   cancelCurrentOperation.decrementAndGet();
//   cancel();
//   synchronized (mutexSetGameData) {
//     waitForGameDataReady();
//     latchWorkerThreadsCreation =
//         CompletableFuture.supplyAsync(() -> setGameDataInternal(data))
//             .exceptionally(throwable -> { log.error(...); return false; });
//     return latchWorkerThreadsCreation;
//   }
// Under the single-threaded JDK shim, `synchronized` is a no-op and
// `CompletableFuture.supplyAsync` runs the supplier synchronously. The
// exceptionally handler (`lambda$setGameData$1`) covers thrown errors; in
// the direct-synchronous shim a thrown error in `setGameDataInternal`
// would propagate via Odin's normal return paths, so we just invoke the
// supplier and wrap the boolean outcome in a freshly-completed future.
// Readers of the returned future (`waitForGameDataReady`) discard the
// payload, so we encode it as nil — same convention used by the
// constructor.
concurrent_battle_calculator_set_game_data :: proc(self: ^Concurrent_Battle_Calculator, data: ^Game_Data) -> ^Completable_Future {
	// cancel any current setting of data
	atomic_integer_decrement_and_get(self.cancel_current_operation)
	// cancel any existing calcing (it won't stop immediately, just quicker)
	concurrent_battle_calculator_cancel(self)
	// synchronized (mutex_set_game_data) — no-op in single-threaded shim.
	concurrent_battle_calculator_wait_for_game_data_ready(self)
	// supplyAsync(() -> setGameDataInternal(data)) — direct-synchronous in
	// the shim, so just invoke the supplier on the current thread. The
	// boolean result is discarded by every caller; we store a freshly
	// completed future so subsequent waitForGameDataReady() calls return
	// immediately.
	_ = concurrent_battle_calculator_set_game_data_internal(self, data)
	future := completable_future_new()
	completable_future_complete(future, nil)
	self.latch_worker_threads_creation = future
	return future
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#cancel()
// Java: forwards `cancel()` to every worker so an in-flight calculation can
// abort early. Faithfully translated under the single-threaded shim — there
// is no in-flight calculation to interrupt, but each worker still records
// the cancellation flag, matching the visible state changes Java performs.
concurrent_battle_calculator_cancel :: proc(self: ^Concurrent_Battle_Calculator) {
	for worker in self.workers {
		battle_calculator_cancel(worker)
	}
}

