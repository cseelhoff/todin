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

// Closure-capture context for `lambda$setGameData$0`: the Supplier body
// `() -> setGameDataInternal(data)` captures the enclosing instance
// (`this`) and the `data` argument from `setGameData`'s frame.
Concurrent_Battle_Calculator_Lambda_Set_Game_Data_0_Ctx :: struct {
	self: ^Concurrent_Battle_Calculator,
	data: ^Game_Data,
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#lambda$setGameData$0(GameData)
// Java body (Supplier<Boolean>): `() -> setGameDataInternal(data)`. The
// captured `this` and `data` are supplied via the rawptr ctx convention.
concurrent_battle_calculator_lambda_set_game_data_0 :: proc(ctx: rawptr) -> bool {
	cap_ctx := cast(^Concurrent_Battle_Calculator_Lambda_Set_Game_Data_0_Ctx)ctx
	return concurrent_battle_calculator_set_game_data_internal(cap_ctx.self, cap_ctx.data)
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

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#lambda$createWorkers$3(byte[], int)
// Java body: `j -> new BattleCalculator(serializedData)`. The captured
// `serializedData` byte[] is supplied via the rawptr ctx convention (same
// ctx struct as `lambda$createWorkers$2`); the int parameter `j` is the
// IntStream index and is unused by the body.
concurrent_battle_calculator_lambda_create_workers_3 :: proc(ctx: rawptr, j: i32) -> ^Battle_Calculator {
	_ = j
	cap_ctx := cast(^Concurrent_Battle_Calculator_Lambda_Create_Workers_2_Ctx)ctx
	return battle_calculator_new(cap_ctx.serialized_data)
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#createWorkers(GameData)
// Java:
//   workers.clear();
//   if (data != null && cancelCurrentOperation.get() >= 0) {
//     final long startTime = System.currentTimeMillis();
//     final long startMemory = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
//     final byte[] serializedData;
//     try (GameData.Unlocker ignored = data.acquireWriteLock()) {
//       serializedData = GameDataUtils.gameDataToBytes(
//             data, GameDataManager.Options.forBattleCalculator()).orElse(null);
//       if (serializedData == null) return false;
//     }
//     if (cancelCurrentOperation.get() >= 0) {
//       workers.add(new BattleCalculator(serializedData));
//       int threadsToUse = getThreadsToUse(System.currentTimeMillis() - startTime, startMemory);
//       workers.addAll(IntStream.range(1, threadsToUse).parallel()
//           .filter(j -> cancelCurrentOperation.get() >= 0)
//           .mapToObj(j -> new BattleCalculator(serializedData))
//           .collect(Collectors.toList()));
//     }
//   }
//   if (cancelCurrentOperation.get() < 0 || data == null) {
//     workers.clear();
//     return false;
//   }
//   return true;
//
// Under the single-threaded JDK shim, `acquireWriteLock` returns an empty
// Unlocker (no real lock to release) and `getThreadsToUse` always returns
// 1, so the IntStream.range(1, 1) loop is empty and only the first
// BattleCalculator is created. We still execute the timing call and the
// cancel-check branches so that visible state (workers list, return
// value) matches Java's behaviour bit-for-bit.
concurrent_battle_calculator_create_workers :: proc(self: ^Concurrent_Battle_Calculator, data: ^Game_Data) -> bool {
	clear(&self.workers)
	if data != nil && atomic_integer_get(self.cancel_current_operation) >= 0 {
		// see how long 1 copy takes (some games can get REALLY big)
		start_tick := time.tick_now()
		start_memory: i64 = 0
		serialized_data: []u8
		{
			// try (GameData.Unlocker ignored = data.acquireWriteLock())
			ignored := game_data_acquire_write_lock(data)
			_ = ignored
			bytes, present := game_data_utils_game_data_to_bytes(
				data,
				game_data_manager_options_for_battle_calculator(),
			)
			if !present {
				return false
			}
			serialized_data = bytes
		}
		if atomic_integer_get(self.cancel_current_operation) >= 0 {
			// Create the first battle calc on the current thread to measure the
			// end-to-end copy time.
			append(&self.workers, battle_calculator_new(serialized_data))
			elapsed := time.tick_since(start_tick)
			threads_to_use := concurrent_battle_calculator_get_threads_to_use(
				i64(time.duration_milliseconds(elapsed)),
				start_memory,
			)
			// Now, create the remaining ones (sequentially under the
			// single-threaded shim). IntStream.range(1, threads_to_use) with
			// the parallel filter `cancelCurrentOperation.get() >= 0`.
			cap_ctx := new(Concurrent_Battle_Calculator_Lambda_Create_Workers_2_Ctx)
			cap_ctx.serialized_data = serialized_data
			for j: i32 = 1; j < threads_to_use; j += 1 {
				if atomic_integer_get(self.cancel_current_operation) < 0 {
					continue
				}
				append(&self.workers, concurrent_battle_calculator_lambda_create_workers_3(rawptr(cap_ctx), j))
			}
		}
	}
	if atomic_integer_get(self.cancel_current_operation) < 0 || data == nil {
		// we could have cancelled while setting data, so clear the workers
		// again if so
		clear(&self.workers)
		return false
	}
	// should make sure that all workers have their game data set before
	// we can call calculate and other things
	return true
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#setGameDataInternal(GameData)
// Java:
//   private boolean setGameDataInternal(@Nullable final GameData data) {
//     synchronized (mutexCalcIsRunning) {
//       cancel();
//       cancelCurrentOperation.incrementAndGet();
//       isDataSet = createWorkers(data);
//       return isDataSet;
//     }
//   }
// `synchronized (mutexCalcIsRunning)` is a no-op in the single-threaded shim.
concurrent_battle_calculator_set_game_data_internal :: proc(self: ^Concurrent_Battle_Calculator, data: ^Game_Data) -> bool {
	concurrent_battle_calculator_cancel(self)
	atomic_integer_increment_and_get(self.cancel_current_operation)
	self.is_data_set = concurrent_battle_calculator_create_workers(self, data)
	return self.is_data_set
}

// games.strategy.triplea.odds.calculator.ConcurrentBattleCalculator#lambda$calculate$4(GamePlayer, GamePlayer, Territory, Collection<Unit>, Collection<Unit>, Collection<Unit>, Collection<TerritoryEffect>, boolean, RunCountDistributor, BattleCalculator)
// Java body (parallelStream map lambda):
//   worker -> worker.calculate(
//       attacker, defender, location, attacking, defending, bombarding,
//       territoryEffects, retreatWhenOnlyAirLeft, runCountDistributor.nextRunCount())
// The lambda captures the eight calculate() parameters plus the
// RunCountDistributor; `worker` is the per-element BattleCalculator from
// the parallel stream. Translated as a static-style proc taking all
// captures as explicit arguments (the calculate() inlining above does the
// equivalent work directly, so this proc is the verbatim lambda body
// kept for fidelity with the Java surface).
concurrent_battle_calculator_lambda_calculate_4 :: proc(
	attacker: ^Game_Player,
	defender: ^Game_Player,
	location: ^Territory,
	attacking: [dynamic]^Unit,
	defending: [dynamic]^Unit,
	bombarding: [dynamic]^Unit,
	territory_effects: [dynamic]^Territory_Effect,
	retreat_when_only_air_left: bool,
	run_count_distributor: ^Run_Count_Distributor,
	worker: ^Battle_Calculator,
) -> ^Aggregate_Results {
	return battle_calculator_calculate(
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
}

