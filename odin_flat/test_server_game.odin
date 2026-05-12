package game

import "core:math/rand"
import "core:fmt"
import "core:strings"
import "core:time"

// Harness-only wrapper used by the snapshot runner
// (`triplea/conversion/odin_tests/test_common/snapshot_runner.odin`).
// Mirrors the small subset of ServerGame state that the harness reads
// when wrapping a loaded ^Game_Data into a callable ServerGame instance
// for `server_game_run_next_step`. Field names match the harness's
// authoritative access pattern; do not rename without updating the
// harness via scripts/patch_triplea.py.
Test_Server_Game :: struct {
	data:                       ^Game_Data,
	game_over:                  bool,
	stop_on_delegate:           bool,
	delegate_autosaves_enabled: bool,
	need_to_initialize:         bool,
	first_run:                  bool,
	// RNG state captured from Java's snapshot run (before-meta.txt fields
	// `mt_state` and `math_random_seed`). When set, the harness seeds its
	// PlainRandomSource MersenneTwister and java_math_random LCG to these
	// values instead of unconditionally reseeding to 42 — required for
	// step-N dice/Math.random calls to match Java byte-for-byte (Java's
	// snapshot run accumulates RNG state across steps 1..N-1).
	//
	// mt_state layout (matches SnapshotHarness.dumpMersenneTwisterState):
	//   bytes 0..3    = mti (u32 LE)
	//   bytes 4..2499 = mt[0..624] (u32 LE each)
	// Total length = 2500 bytes when present, 0 (nil) otherwise.
	mt_state:           []u8,
	mt_state_present:   bool,
	math_random_seed:   i64,
	math_random_present: bool,

	// End-to-end "full game" mode. When max_rounds > 0 the harness runs
	// runNextStep in a loop until isGameOver or sequence.round > max_rounds
	// (mirrors Ww2v5JacocoRun.runFullGameDeterminismProbe). Defaults to 0
	// so existing snap tests still execute exactly one step.
	max_rounds:     int,
	steps_executed: int,

	// When non-empty, the full-game loop breaks immediately after a step
	// whose name equals this value completes. Used by oracle comparisons
	// scoped to a particular player's turn (e.g. "russianEndTurn").
	stop_after_step: string,
}

@(private = "file")
test_server_game_player_to_gp: map[^Player]^Game_Player

// Per-Player back-reference to the Pro_Ai instance bound to this
// nation. Required because Odin proc-fields can't capture closures,
// so the start-thunk has to look up its target via this parallel map.
// Populated below in test_server_game_run_next_step at the same
// time as test_server_game_player_to_gp.
@(private = "file")
test_server_game_player_to_ai: map[^Player]^Pro_Ai

@(private = "file")
test_server_game_player_is_ai_true :: proc(self: ^Player) -> bool {
	return true
}

@(private = "file")
test_server_game_player_label_hard_ai :: proc(self: ^Player) -> string {
	return "Hard (AI)"
}

@(private = "file")
test_server_game_player_get_gp :: proc(self: ^Player) -> ^Game_Player {
	return test_server_game_player_to_gp[self]
}

@(private = "file")
test_server_game_player_get_name_from_gp :: proc(self: ^Player) -> string {
	gp := test_server_game_player_to_gp[self]
	if gp == nil { return "" }
	return default_named_get_name(&gp.named_attachable.default_named)
}

// Player.retreat_query vtable thunk: dispatches to
// abstract_pro_ai_retreat_query on the bound Pro_Ai. Mirrors Java's
// AbstractProAi.retreatQuery being routed through the bridge's
// remote-player lookup. Without this wiring,
// `default_delegate_bridge_get_remote_player` returns a no-op
// singleton whose retreat_query field is nil, and air units cannot
// retreat from losing battles even when the AI would have chosen to
// (observed at WW2v5 r=1 i=14 russianBattle West Russia).
@(private = "file")
test_server_game_player_retreat_query :: proc(
	self: ^Player,
	battle_id: Uuid,
	submerge: bool,
	battle_site: ^Territory,
	possible_territories: [dynamic]^Territory,
	message: string,
) -> ^Territory {
	ai := test_server_game_player_to_ai[self]
	if ai == nil { return nil }
	return abstract_pro_ai_retreat_query(
		cast(^Abstract_Pro_Ai)ai,
		battle_id,
		submerge,
		battle_site,
		possible_territories,
		message,
	)
}

@(private = "file")
test_server_game_player_should_bomber_bomb :: proc(self: ^Player, territory: ^Territory) -> bool {
	ai := test_server_game_player_to_ai[self]
	if ai == nil { return false }
	return abstract_pro_ai_should_bomber_bomb(cast(^Abstract_Pro_Ai)ai, territory)
}

// Player.start vtable thunk: dispatches to abstract_ai_start on the
// bound Pro_Ai. Mirrors Java's `AbstractAi implements Player`
// dispatch via reflection. If no Pro_Ai is bound (e.g. the Neutral
// player skipped during construction), the thunk is a no-op so a
// stray dispatch can't crash mid-step.
@(private = "file")
test_server_game_player_start :: proc(self: ^Player, step_name: string) {
	ai := test_server_game_player_to_ai[self]
	if ai == nil { return }
	abstract_ai_start(cast(^Abstract_Ai)ai, step_name)
}

// Adapter for the snapshot harness. Each snapshot test wraps a loaded
// Game_Data in a Test_Server_Game and invokes this proc; the proc
// composes a minimal Server_Game from the harness's field set and
// dispatches to the canonical `server_game_run_next_step` so the
// snapshot exercises the real Java-port code path.
//
// The fields the harness owns are mapped 1:1 onto Server_Game; the
// remaining infrastructure (messengers, delegate execution manager,
// random source, random stats, player manager, history channel
// adapter) is wired here with stub-but-functional implementations
// that mirror what `server_game_new` would build at startup. The AI
// snapshot run is single-threaded and pinned to a fixed RNG seed,
// so the stub messengers/network layer is never exercised in a
// way that requires real I/O.
test_server_game_run_next_step :: proc(self: ^Test_Server_Game) {
	// Clear per-run parallel maps from any previous snapshot run
	// (snapshot_runner invokes this proc once per snapshot).
	clear(&test_server_game_player_to_gp)
	clear(&test_server_game_player_to_ai)
	default_delegate_bridge_clear_remote_player_registry()

	// Pin RNG seed for snapshot determinism (Java:
	// PlainRandomSource.fixedSeed = 42L).
	if plain_random_source_fixed_seed == nil {
		seed := new(i64)
		seed^ = 42
		plain_random_source_fixed_seed = seed
	}

	// Pin core:math/rand global state (matches Java's
	// java.lang.Math$RandomNumberGeneratorHolder.randomNumberGenerator
	// reseeded to 42 in Ww2v5JacocoRun#runWithSnapshots). The Pro AI uses
	// rand.float64() for weighted purchase picks
	// (pro_purchase_utils_randomize_purchase_option) and politics actions
	// (abstract_ai_political_actions, pro_politics_ai_*). Without this,
	// snap results vary per-run based on heap layout / context init,
	// since context.random_generator otherwise inherits whatever the
	// Odin test framework seeded it with (per-test random uniquifier).
	// Re-seeded per snapshot so each starts identically.
	rand.reset(42)

	// Bit-exact seed for the Java Math.random() shim. The Pro AI's
	// purchase weighted-pick + abstract_ai/political_ai paths used to
	// call core:math/rand which produces a different sequence than
	// java.util.Random(42). Seeding our java_math_random shim here
	// makes Math.random() call sites match the Java oracle exactly
	// (snap 0013 Russian armour vs. infantry mix).
	java_math_random_set_seed(42)
	// If the snapshot meta carried Java's accumulated math_random_seed
	// (from `math_random_seed: <hex>` in before-meta.txt), use that
	// instead of the bare 42 reseed. The harness loader fills
	// math_random_present when it parses the meta.
	if self.math_random_present {
		java_math_random_set_seed_raw(self.math_random_seed)
	}

	stub_messenger := new(I_Messenger)
	defer free(stub_messenger)
	messengers := messengers_new(stub_messenger)
	defer free(messengers)

	sg := new(Server_Game)
	defer free(sg)

	// AbstractGame init (mirrors abstract_game_new)
	sg.game_data = self.data
	sg.messengers = messengers
	sg.is_game_over = self.game_over
	sg.first_run = self.first_run

	// JSON loader doesn't backfill game_data_component on sub-objects;
	// patch the few that the run-step path dereferences.
	if seq := game_data_get_sequence(self.data); seq != nil {
		for step in seq.steps {
			step.game_data_component.game_data = self.data
		}
	}
	// Backfill game_data_component on Game_Players, Territories, and
	// Units so battle_delegate.start (and similar code paths that call
	// game_player_get_data / territory_get_data) can resolve the data
	// reference. Java code paths assume the parser sets this; the
	// snapshot JSON loader does not.
	for _, gp in self.data.player_list.players {
		gp.named_attachable.default_named.game_data_component.game_data = self.data
		// Each Game_Player needs a per-player technology_frontier_list
		// for tech_tracker_get_current_tech_advances; the snapshot JSON
		// only carries the master frontier, not per-player ones.
		if gp.technology_frontiers == nil {
			gp.technology_frontiers = technology_frontier_list_new(self.data)
		}
		// Each player owns a unit collection (held but not yet placed
		// units, e.g. just-purchased units awaiting Place). The JSON
		// loader doesn't deserialize this; harness creates an empty one
		// so abstract_place_delegate_currently_requires_user_input has
		// something to call .is_empty() on.
		if gp.units_held == nil {
			gp.units_held = unit_collection_new(cast(^Named_Unit_Holder)gp, self.data)
		}
	}
	if gm := game_data_get_map(self.data); gm != nil {
		for t in gm.territories {
			t.named_attachable.default_named.game_data_component.game_data = self.data
			for u in territory_get_units(t) {
				u.game_data_component.game_data = self.data
			}
		}
	}

	// Backfill game_data on UnitType.unit_attachment and on
	// RelationshipType.relationshipTypeAttachment. Battle delegate paths
	// (e.g. unit_attachment_get_attack_for_player) deref
	// default_attachment.game_data_component to call get_dice_sides.
	if self.data.unit_type_list != nil {
		for _, ut in self.data.unit_type_list.unit_types {
			if ut == nil { continue }
			ut.named_attachable.default_named.game_data_component.game_data = self.data
			if ut.unit_attachment != nil {
				ut.unit_attachment.default_attachment.game_data_component.game_data = self.data
			}
		}

		// Java's UnitAttachment.setArtillery / setArtillerySupportable
		// auto-inject UnitSupportAttachment rules at XML parse time
		// (see UnitAttachment.setArtillery in the .java source). The
		// snapshot JSON only persists the legacy bool fields, not the
		// derived UnitSupportAttachment, so AI purchase logic that
		// keys off `is_attack_support` (artillery's offensive support
		// flag) sees no support → infantry/artillery look equally
		// efficient → AI never picks artillery (snap 0013 buys 8
		// infantry instead of 4 infantry + 3 artillery).
		// Replay the same two-pass logic the XML parser does:
		//   1. addTarget for every type with artillerySupportable=true
		//      (creates a TempFirst attachment if no rule exists yet).
		//   2. addRule for every type with artillery=true (creates the
		//      real rule and absorbs the TempFirst targets).
		for _, ut in self.data.unit_type_list.unit_types {
			if ut == nil || ut.unit_attachment == nil { continue }
			if ut.unit_attachment.artillery_supportable {
				unit_support_attachment_add_target(ut, self.data)
			}
		}
		for _, ut in self.data.unit_type_list.unit_types {
			if ut == nil || ut.unit_attachment == nil { continue }
			if ut.unit_attachment.artillery {
				unit_support_attachment_add_rule(ut, self.data, false)
			}
		}
	}
	if self.data.relationship_type_list != nil {
		for _, rt in self.data.relationship_type_list.relationship_types {
			if rt == nil { continue }
			rt.named_attachable.default_named.game_data_component.game_data = self.data
			if rt.attachments != nil {
				if att, ok := rt.attachments["relationshipTypeAttachment"]; ok && att != nil {
					rta := cast(^Relationship_Type_Attachment)att
					rta.default_attachment.game_data_component.game_data = self.data
				}
			}
		}
	}

	// JSON loader skips infrastructure fields that game_data_new()
	// would populate (event listener bus, history, etc.). Rehydrate
	// the listener bus so notify_game_step_changed → fire_game_data_event
	// has a non-nil target.
	if self.data.game_data_event_listeners == nil {
		ls := new(Game_Data_Event_Listeners)
		ls^ = make_Game_Data_Event_Listeners()
		self.data.game_data_event_listeners = ls
	}

	// JSON loader also doesn't load the delegate list (delegates are
	// rule code, not snapshot state); register the WW2v5 delegate set
	// referenced by the snapshot game definitions so that
	// game_data_get_delegate(name) resolves the same way XML-loaded
	// games do.
	test_server_game_register_ww2v5_delegates(self.data)

	// JSON loader doesn't materialize battle_records_list (Java game-XML
	// init creates it via GameData ctor → battleRecordsList = new BRL(this)).
	// Battle delegate end path calls AddBattleRecordsChange.perform which
	// does &game_state.battle_records_list.battle_records — would deref nil.
	if self.data.battle_records_list == nil {
		self.data.battle_records_list = battle_records_list_new(self.data)
	}
	// JSON loader doesn't materialize game_data.state (Java GameData ctor
	// builds it via game_data_state_new → tech_tracker_new). The AI
	// purchase path calls game_data_get_tech_tracker → state.tech_tracker
	// → SIGSEGV on nil state. Provision both lazily here.
	if self.data.state == nil {
		self.data.state = game_data_state_new(self.data)
	}
	sg.vault = vault_new(messengers.channel_messenger)
	sg.game_players = make(map[^Game_Player]^Player)
	defer delete(sg.game_players)

	// Wire a "Hard AI" Player stub for every nation that appears as a
	// step.player in the snapshot sequence. ServerGame#start_step calls
	// add_player_types_to_game_data on the first non-init step (when
	// need_to_initialize=true), which writes whoAmI="AI:Hard (AI)" to
	// every Game_Player whose Player has is_ai=true and label="Hard (AI)".
	// Snapshots ≥0012 expect this; bid steps with max_run_count=0 are
	// skipped before start_step runs so they leave whoAmI untouched.
	for _, gp in self.data.player_list.players {
		if default_named_get_name(&gp.named_attachable.default_named) == "Neutral" {
			continue
		}
		ai := new(Player)
		ai.is_ai = test_server_game_player_is_ai_true
		ai.get_name = test_server_game_player_get_name_from_gp
		ai.get_player_label = test_server_game_player_label_hard_ai
		ai.get_game_player = test_server_game_player_get_gp
		// Wire .start so abstract_ai_start dispatches when the engine
		// invokes player_start during wait_for_player_to_finish_step.
		// Without this the AI's purchase / move / place calls never run
		// and PUs / unit moves silently flatline (snapshots 0013, 0014,
		// 0021, 0029 etc.). The Pro_Ai backing this thunk is built
		// below.
		ai.start = test_server_game_player_start
		ai.retreat_query = test_server_game_player_retreat_query
		ai.should_bomber_bomb = test_server_game_player_should_bomber_bomb
		// Stash the Game_Player pointer so the proc-fields can recover
		// it: I_Remote has no fields here, so reuse `name` slot is not
		// available — we rely on a parallel map below.
		sg.game_players[gp] = ai
		test_server_game_player_to_gp[ai] = gp
		// Register for retreat-query dispatch from inside MustFightBattle.
		// See comments on default_delegate_bridge_remote_player_registry
		// for why we use a global registry rather than the bridge's
		// `game.game_players` (sim-internal bridges have a different,
		// uninitialized Server_Game pointer).
		default_delegate_bridge_register_remote_player(gp, ai)
	}

	pm_map: map[string]^I_Node
	defer delete(pm_map)
	pm := make_Player_Manager(pm_map)
	sg.player_manager = new(Player_Manager)
	defer free(sg.player_manager)
	sg.player_manager^ = pm

	// ServerGame-specific init
	prs := plain_random_source_new()
	if self.mt_state_present && len(self.mt_state) == 4 + 4 * 624 {
		mersenne_twister_load_state(prs.random, self.mt_state)
	}
	sg.random_source = cast(^I_Random_Source)prs
	sg.delegate_random_source = nil
	dem := new(Delegate_Execution_Manager)
	dem^ = make_Delegate_Execution_Manager()
	sg.delegate_execution_manager = dem
	defer free(dem)
	sg.delegate_autosaves_enabled = self.delegate_autosaves_enabled
	sg.need_to_initialize = self.need_to_initialize
	sg.delegate_execution_stopped = self.stop_on_delegate
	sg.stop_game_on_delegate_execution_stop = false
	sg.delegate_execution_stopped_latch = count_down_latch_new(1)

	if game_data_get_history(self.data) == nil {
		hist := history_new(self.data)
		game_data_set_history(self.data, hist)
	}
	// Plant a synthetic Step history node so the .Step/.Event/.Event_Child
	// gate inside server_game_add_player_types_to_game_data passes. In a
	// real game this would be the previous step's node; for snapshot
	// tests there's no prior step, but the gate still needs to clear so
	// whoAmI gets stamped on every Game_Player.
	{
		hist := game_data_get_history(self.data)
		root := default_tree_model_get_root(&hist.default_tree_model)
		if default_mutable_tree_node_get_child_count(root) == 0 {
			step_node := new(History_Node)
			step_node.default_mutable_tree_node = Default_Mutable_Tree_Node{
				user_object = "synthetic-prior-step",
				children    = make([dynamic]^Default_Mutable_Tree_Node),
			}
			step_node.kind = .Step
			default_mutable_tree_node_add(root, &step_node.default_mutable_tree_node)
			// Seed History_Writer.current so start_event has a valid
			// parent to attach the synthesized "Game Loaded" event to.
			hist.writer.current = step_node
		}
	}
	gmc := new(Server_Game_Game_Modified_Channel_Adapter)
	defer free(gmc)
	gmc.target = sg
	gmc.history_writer = game_data_get_history(self.data).writer
	gmc.game_data_changed             = sg_gmc_game_data_changed
	gmc.start_history_event           = sg_gmc_start_history_event
	gmc.start_history_event_with_data = sg_gmc_start_history_event_with_data
	gmc.add_child_to_event            = sg_gmc_add_child_to_event
	gmc.step_changed                  = sg_gmc_step_changed
	gmc.shut_down                     = sg_gmc_shut_down
	sg.game_modified_channel = cast(^I_Game_Modified_Channel)gmc
	messengers_register_channel_subscriber(
		messengers,
		rawptr(gmc),
		remote_name_new(
			"games.strategy.engine.framework.IGame.GAME_MODIFICATION_CHANNEL",
			class_new(
				"games.strategy.engine.framework.IGameModifiedChannel",
				"IGameModifiedChannel",
			),
		),
	)

	sg.random_stats = random_stats_new(messengers.remote_messenger)

	// Register every WW2v5 delegate as its `IDelegate` remote on the
	// unified messenger. PlayerBridge#getRemoteDelegate fetches the
	// current delegate by remote name; without this registration the
	// remote_messenger fast-path can't find a local implementor, so
	// it falls back to the UIH proxy and the
	// `cast(^Battle_Delegate)i_remote` in abstract_ai_battle reads
	// garbage fields (concretely: nil battle_tracker → SIGSEGV at
	// snapshot 0015). Java ServerGame's ctor calls this; the harness
	// constructs Server_Game manually, so we replay the call here.
	server_game_setup_delegate_messaging(sg, self.data)

	// L35 wiring: after Server_Game is fully populated (data, messengers,
	// listener bus, delegates), construct one Pro_Ai per AI nation and
	// bind it to the Player stub via test_server_game_player_to_ai +
	// abstract_base_player_initialize(pro, bridge, gp). The bridge is
	// built from an I_Game shim wrapping sg; PlayerBridge registers a
	// GAME_STEP_CHANGED listener on the shared event bus, so when
	// server_game_start_step fires notify_game_step_changed the
	// bridge's step_name updates and abstract_base_player_start's poll
	// loop short-circuits immediately (verified by
	// test_abstract_base_player_start_short_circuits_when_bridge_matches).
	{
		i_game_shim := abstract_game_as_i_game(&sg.abstract_game)
		// Don't free i_game_shim: the listener registered by
		// player_bridge_new captures it for the run-step lifetime.
		for gp, ai in sg.game_players {
			pro := pro_ai_new(
				default_named_get_name(&gp.named_attachable.default_named),
				"Hard (AI)",
			)
			bridge := player_bridge_new(i_game_shim)
			abstract_base_player_initialize(
				&pro.abstract_base_player,
				bridge,
				gp,
			)
			test_server_game_player_to_ai[ai] = pro
		}
	}

	when DIGEST { test_full_game_digest_emit(self.data) }
	server_game_run_next_step(sg)

	// If max_rounds > 0, this is the end-to-end "full game" test mode:
	// keep running next steps until either the game ends or the round
	// counter passes max_rounds. Mirrors Java's
	// Ww2v5JacocoRun.runFullGameDeterminismProbe loop:
	//   while (!game.isGameOver()) {
	//     if (game.getData().getSequence().getRound() > maxRounds) break;
	//     game.runNextStep();
	//   }
	if self.max_rounds > 0 {
		step_count: int = 1  // we already ran one above
		for !sg.is_game_over {
			seq := game_data_get_sequence(self.data)
			if seq != nil && int(seq.round) > self.max_rounds {
				break
			}
			step_name := ""
			player_name := "-"
			r_now: i32 = -1
			i_now: i32 = -1
			if seq != nil {
				r_now = seq.round
				i_now = seq.current_index
				if int(seq.current_index) < len(seq.steps) {
					if step := seq.steps[seq.current_index]; step != nil {
						step_name = step.name
						if step.player != nil {
							player_name = default_named_get_name(&step.player.named_attachable.default_named)
						}
					}
				}
			}
			when DIGEST { test_full_game_digest_emit(self.data) }
			before_snap: Step_Snapshot
			when STEP_REPORT {
				before_snap = test_step_report_snapshot(self.data)
			}
			own_snap: Owner_Snapshot
			own_active := false
			when NARRATE {
				is_combat_step := strings.has_suffix(step_name, "Combat") ||
					strings.has_suffix(step_name, "CombatMove") ||
					strings.has_suffix(step_name, "Battle")
				if is_combat_step {
					own_snap = narrate_ownership_snapshot(self.data)
					own_active = true
				}
			}
			t0 := time.now()
			server_game_run_next_step(sg)
			dt := time.since(t0)
			when STEP_REPORT {
				test_step_report_emit(self.data, &before_snap, r_now, i_now, step_name, player_name)
				test_step_report_destroy(&before_snap)
			}
			when NARRATE {
				if own_active {
					narrate_ownership_delta(self.data, &own_snap, step_name)
					narrate_ownership_destroy(&own_snap)
				}
			}
			if dt > 1 * time.Second {
				fmt.printf("[step %d] round=%d %s took %v\n",
					step_count, seq.round if seq != nil else -1,
					step_name, dt)
			}
			step_count += 1
			if self.stop_after_step != "" && step_name == self.stop_after_step {
				break
			}
			// Guard against infinite loops if a delegate fails to advance.
			if step_count > 100000 {
				break
			}
		}
		self.steps_executed = step_count
	}

	// Reflect any state changes back so the harness's diff sees them.
	self.game_over = sg.is_game_over
	self.first_run = sg.first_run
	self.need_to_initialize = sg.need_to_initialize
}

// Mirrors the <delegate> entries in WW2v5_1942_2nd.xml. Builds each
// delegate via the standard XmlGameElementMapper factory map and adds
// it to the GameData delegate list under the same name the snapshot
// step records reference (e.g. "initDelegate", "battle", "move", …).
test_server_game_register_ww2v5_delegates :: proc(data: ^Game_Data) {
	if len(game_data_get_delegates(data)) > 0 {
		return
	}
	mapper := xml_game_element_mapper_new()
	defer free(mapper)

	entries := [?]struct{ name, display, java_class: string }{
		{"initDelegate",    "Initializing Delegates", "InitializationDelegate"},
		{"tech",            "Research Technology",    "TechnologyDelegate"},
		{"tech_activation", "Activate Technology",    "TechActivationDelegate"},
		{"battle",          "Combat",                 "BattleDelegate"},
		{"move",            "Combat Move",            "MoveDelegate"},
		{"place",           "Place Units",            "PlaceDelegate"},
		{"purchase",        "Purchase Units",         "PurchaseDelegate"},
		{"endTurn",         "Turn Complete",          "EndTurnDelegate"},
		{"endRound",        "Round Complete",         "EndRoundDelegate"},
		{"placeBid",        "Bid Placement",          "BidPlaceDelegate"},
		{"bid",             "Bid Purchase",           "BidPurchaseDelegate"},
		{"politicsDelegate","Politics",               "PoliticsDelegate"},
		{"nonCombatMove",   "Non Combat Move",        "MoveDelegate"},
	}
	for e in entries {
		delegate := xml_game_element_mapper_new_delegate(mapper, e.java_class)
		if delegate == nil {
			continue
		}
		i_delegate_initialize(delegate, e.name, e.display)
		game_data_add_delegate(data, delegate)
	}
}

