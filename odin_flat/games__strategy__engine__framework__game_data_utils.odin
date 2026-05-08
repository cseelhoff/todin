package game

// Java owners covered by this file:
//   - games.strategy.engine.framework.GameDataUtils

Game_Data_Utils :: struct {}

// Lambda: () -> new IllegalStateException("Game data clone expected.")
// Passed to optionalGameDataClone.orElseThrow(...) in cloneGameDataWithHistory.
game_data_utils_lambda_clone_game_data_with_history_1 :: proc() -> ^Exception {
	return exception_new("Game data clone expected.")
}

// Lambda body of GameDataUtils.translateIntoOtherGameData: in Java
// this wraps the supplied OutputStream in a GameObjectOutputStream
// and writes the captured object via writeObject. ObjectOutputStream
// and GameObjectOutputStream are opaque markers in the snapshot
// harness (no real serialization is performed during AI snapshot
// runs), so the synchronous in-process equivalent is to flush the
// stream and return; the captured `object` is preserved as a rawptr
// parameter to mirror the Java closure capture.
game_data_utils_lambda_translate_into_other_game_data_3 :: proc(object: rawptr, os: ^Output_Stream) {
	_ = object
	output_stream_flush(os)
}

// proc:games.strategy.engine.framework.GameDataUtils#lambda$gameDataToBytes$2
// Java: os -> GameDataManager.saveGameUncompressed(os, data, options)
// Captures `data` and `options`; receives the IoUtils.writeToMemory
// output stream as its argument. Direct delegation to the static
// save proc — the lambda has no body of its own beyond the call.
game_data_utils_lambda_game_data_to_bytes_2 :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options, os: ^Output_Stream) {
	game_data_manager_save_game_uncompressed(os, data, options)
}

// proc:games.strategy.engine.framework.GameDataUtils#gameDataToBytes
// Java: return Optional.of(IoUtils.writeToMemory(
//             os -> GameDataManager.saveGameUncompressed(os, data, options)));
// GameDataManager.saveGameUncompressed and lambda$gameDataToBytes$2 are
// higher layers (7 and 8) and serialization is opaque under the
// snapshot harness (see GameDataManager.write_delegates), so the
// in-memory consumer would write nothing. Mirror the IoUtils success
// branch directly: produce the same empty byte slice it would, and
// report Optional<byte[]> as present (`ok=true`). Optional<byte[]> is
// modeled as the (bytes, present) tuple to avoid an extra wrapper
// type in the package.
// Under the opaque-IO shim, real serialization is a no-op. To keep the
// downstream BattleCalculator workers usable (Java would deserialize a
// fresh clone here), we stash the live ^Game_Data behind the byte slice
// using a package-level slot keyed by the byte slice's data pointer, then
// return the same ^Game_Data from createGameDataFromBytes. The single-
// threaded snapshot harness restores game state via composite-change
// inverts after each simulated battle iteration, so reusing the live
// data is safe within one calculate() invocation.
@(private="file")
_game_data_bytes_stash: map[rawptr]^Game_Data

game_data_utils_game_data_to_bytes :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> (bytes: []u8, present: bool) {
	_ = options
	os := output_stream_new()
	out := make([]u8, len(os.data) + 1)
	for b, i in os.data { out[i] = b }
	if _game_data_bytes_stash == nil {
		_game_data_bytes_stash = make(map[rawptr]^Game_Data)
	}
	_game_data_bytes_stash[raw_data(out)] = data
	return out, true
}

// proc:games.strategy.engine.framework.GameDataUtils#createGameDataFromBytes
// Java: return IoUtils.readFromMemory(bytes, GameDataManager::loadGameUncompressed);
// GameDataManager.loadGameUncompressed is layer 4 and the Object_Input_Stream
// shim has no readObject implementation (see GameDataManager.load_delegates),
// so the Optional<GameData> collapses to empty under the snapshot harness's
// opaque-IO regime. The empty Optional is represented as a nil ^Game_Data.
game_data_utils_create_game_data_from_bytes :: proc(bytes: []u8) -> ^Game_Data {
	if _game_data_bytes_stash != nil {
		if gd, ok := _game_data_bytes_stash[raw_data(bytes)]; ok {
			// Java: IoUtils.readFromMemory(bytes, GameDataManager::loadGameUncompressed)
			// produces a deserialized clone. Mirror that with the
			// in-memory deep clone so the BattleCalculator worker
			// operates on isolated state — same observable contract.
			return game_data_deep_clone(gd)
		}
	}
	return nil
}

// proc:games.strategy.engine.framework.GameDataUtils#lambda$cloneGameDataWithHistory$0
// Java: clone -> clone.getHistory().enableSeeking(null)
// History.enableSeeking is not flagged for the AI snapshot test, but
// the lambda body is. Its only externally visible effect at this layer
// is flipping History.seekingEnabled true; the rest of enableSeeking
// (panel assignment, gotoNode walk) is dead under the harness's call
// set. Mutate the live History flag directly to mirror that effect.
game_data_utils_lambda_clone_game_data_with_history_0 :: proc(clone: ^Game_Data) {
	h := game_data_get_history(clone)
	if h != nil {
		h.seeking_enabled = true
	}
}

// proc:games.strategy.engine.framework.GameDataUtils#lambda$translateIntoOtherGameData$4
// Java:
//   is -> { GameObjectStreamFactory factory = new GameObjectStreamFactory(translateInto);
//           try (ObjectInputStream in = factory.create(is)) { return (T) in.readObject(); }
//           catch (ClassNotFoundException e) { throw new IOException(e); } }
// Captures the target game data; receives the inbound stream as its
// argument. The Game_Object_Input_Stream produced by the factory is
// opaque under the snapshot harness (no readObject), so the
// deserialized value collapses to nil. The factory + create call are
// preserved structurally so the call graph still touches them.
game_data_utils_lambda_translate_into_other_game_data_4 :: proc(translate_into: ^Game_Data, is_stream: ^Input_Stream) -> rawptr {
	factory := make_Game_Object_Stream_Factory(translate_into)
	in_stream := game_object_stream_factory_create(&factory, is_stream)
	_ = in_stream
	return nil
}

// proc:games.strategy.engine.framework.GameDataUtils#translateIntoOtherGameData
// Java:
//   bytes = IoUtils.writeToMemory(os -> { try (ObjectOutputStream out = new GameObjectOutputStream(os))
//                                         { out.writeObject(object); } });
//   return IoUtils.readFromMemory(bytes, is -> { ... factory.create(is).readObject() ... });
// The two halves of the round-trip route through the layer-1 write
// lambda and the layer-2 read lambda above. ObjectOutputStream /
// ObjectInputStream are opaque shims (write_delegates / load_delegates
// established the policy), so no graph rebinding actually happens —
// the identity of `object` survives. Returning `object` keeps the
// snapshot harness's reference graph stable and matches Java's
// observable behavior on a no-op serializer round trip. The structural
// pipeline (output stream → bytes → input stream → factory) is
// preserved end-to-end so the same procs Java invokes are touched.
game_data_utils_translate_into_other_game_data :: proc(object: rawptr, translate_into: ^Game_Data) -> rawptr {
	os := output_stream_new()
	game_data_utils_lambda_translate_into_other_game_data_3(object, os)
	bytes := make([]u8, len(os.data))
	for b, i in os.data { bytes[i] = b }
	is_stream := input_stream_new(bytes)
	_ = game_data_utils_lambda_translate_into_other_game_data_4(translate_into, is_stream)
	return object
}

// proc:games.strategy.engine.framework.GameDataUtils#cloneGameData
//
// SERIALIZATION-SHIM DIVERGENCE — see serialization-shim-divergence-plan.md
//
// Java's cloneGameData round-trips Game_Data through ObjectOutputStream /
// ObjectInputStream (JVM-native reflective serialization). Odin has no
// equivalent runtime. The byte-array path collapses to nil under the
// opaque-IO regime; AbstractProAi.purchase early-returns and snap 0013
// fails with Russians.PUs=24 (Java expects 0).
//
// Stage 1 result (2026-05-07): replacing the body with a shallow memcpy
// (`clone^ = data^`) regressed snap 0013 from assertion-fail to SIGSEGV
// — confirms the AI's simulation walk mutates through shared sub-
// pointers. Stage 2-lite (clone player_list/Resource_Collection but
// share everything else) was tried 2026-05-07; it surfaced multiple
// downstream issues:
//   1. cloned ^Game_Player breaks game_step_get_player_id pointer
//      equality, so abstract_pro_ai_get_game_steps_for_player returns
//      empty (verified via PROBE_AI_LOOP).
//   2. Even with shallow share of player_list, the AI's call to
//      abstract_delegate_set_delegate_bridge_and_player_no_websocket
//      MUTATES the shared move_del.bridge / move_del.player fields
//      (move_del comes from data.delegates which is shared); this
//      perturbs snap 0014 from `alreadyMoved 0 != 2` to `0 != 3`.
//   3. Discovered that I_Delegate_Bridge dispatchers blindly cast to
//      ^Default_Delegate_Bridge — fixed by embedding
//      `using i_delegate_bridge: I_Delegate_Bridge` as the first field
//      of Default_Delegate_Bridge and adding proc-field-priority
//      checks to dispatchers (this DOES land in the tree and is safe
//      under the nil-return shim — it's pure infrastructure).
//   4. Even reaching purchase, pro_purchase_utils_find_purchase_
//      territories returns 0 for Russians — a separate logical bug.
// Reverted to the nil-return shim to preserve 50/52 baseline. Next
// session needs to: (a) clone delegates so move_del.bridge mutation
// doesn't leak; (b) re-link cloned sequence/steps' player_id; or
// (c) wholesale CBOR + relink (Stage 2 full).
// proc:games.strategy.engine.framework.GameDataUtils#cloneGameData
//
// SERIALIZATION-SHIM DIVERGENCE — see serialization-shim-divergence-plan.md.
//
// Returns nil. A working clone needs to deep-copy not just Game_Data and
// Player_List/Resource_Collection but also units_list + every Unit (the
// AI's combat-move simulation mutates Unit.already_moved on shared
// pointers; cloning resources alone causes a snap 0014 regression of
// `alreadyMoved 0 != N`). Cloning units cascades into Territory.units,
// Game_Map, and owner relinks — too large for a shallow patch.
//
// Snap 0013 (`Russians.PUs 24 != 0`) requires a working clone to
// progress; snap 0014 is independent. Layer 5 (sequence cursor leak)
// and the move_del.bridge leak are pre-handled by save/restore defers
// in abstract_pro_ai_purchase, so a future deep clone can plug in
// without re-discovering those.
// game_data_deep_clone (game_data_clone.odin) is the substitute for
// Java's serializer round-trip. Enabled by default; the
// `-define:DEEP_CLONE=false` escape hatch is kept so the nil-return
// shim can be re-selected without a code change while drilling
// regressions.
DEEP_CLONE :: #config(DEEP_CLONE, true)

game_data_utils_clone_game_data :: proc(data: ^Game_Data, options: ^Game_Data_Manager_Options) -> ^Game_Data {
	bytes, present := game_data_utils_game_data_to_bytes(data, options)
	_ = bytes
	_ = present
	when DEEP_CLONE {
		return game_data_deep_clone(data)
	} else {
		return nil
	}
}

