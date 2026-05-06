package game

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
}

@(private = "file")
test_server_game_player_to_gp: map[^Player]^Game_Player

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
	// Pin RNG seed for snapshot determinism (Java:
	// PlainRandomSource.fixedSeed = 42L).
	if plain_random_source_fixed_seed == nil {
		seed := new(i64)
		seed^ = 42
		plain_random_source_fixed_seed = seed
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
		// Stash the Game_Player pointer so the proc-fields can recover
		// it: I_Remote has no fields here, so reuse `name` slot is not
		// available — we rely on a parallel map below.
		sg.game_players[gp] = ai
		test_server_game_player_to_gp[ai] = gp
	}

	pm_map: map[string]^I_Node
	defer delete(pm_map)
	pm := make_Player_Manager(pm_map)
	sg.player_manager = new(Player_Manager)
	defer free(sg.player_manager)
	sg.player_manager^ = pm

	// ServerGame-specific init
	sg.random_source = cast(^I_Random_Source)plain_random_source_new()
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

	server_game_run_next_step(sg)

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

