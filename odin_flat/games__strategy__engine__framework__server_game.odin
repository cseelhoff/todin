package game

import "core:fmt"
import "core:strings"

Server_Game :: struct {
	using abstract_game: Abstract_Game,
	random_stats:                       ^Random_Stats,
	random_source:                      ^I_Random_Source,
	delegate_random_source:             ^I_Random_Source,
	delegate_execution_manager:         ^Delegate_Execution_Manager,
	in_game_lobby_watcher:              ^In_Game_Lobby_Watcher_Wrapper,
	need_to_initialize:                 bool,
	launch_action:                      ^Launch_Action,
	delegate_autosaves_enabled:         bool,
	delegate_execution_stopped_latch:   ^Count_Down_Latch,
	delegate_execution_stopped:         bool,
	stop_game_on_delegate_execution_stop: bool,
}

server_game_is_game_sequence_running :: proc(self: ^Server_Game) -> bool {
	return !self.delegate_execution_stopped
}

server_game_is_or_are :: proc(self: ^Server_Game, player_name: string) -> string {
	if strings.has_suffix(player_name, "s") ||
	   strings.has_suffix(player_name, "ese") ||
	   strings.has_suffix(player_name, "ish") {
		return "are"
	}
	return "is"
}


server_game_set_random_source :: proc(self: ^Server_Game, random_source: ^I_Random_Source) {
        self.random_source = random_source
        self.delegate_random_source = nil
}

// games.strategy.engine.framework.ServerGame#getRemoteName(GamePlayer)
// Java: return new RemoteName(
//   "games.strategy.engine.framework.ServerGame.PLAYER_REMOTE." + gamePlayer.getName(),
//   Player.class);
SERVER_GAME_PLAYER_REMOTE :: "games.strategy.engine.framework.ServerGame.PLAYER_REMOTE."
SERVER_GAME_DELEGATE_REMOTE :: "games.strategy.engine.framework.ServerGame.DELEGATE_REMOTE."

server_game_get_remote_name_for_player :: proc(game_player: ^Game_Player) -> ^Remote_Name {
	return remote_name_new(
		strings.concatenate({SERVER_GAME_PLAYER_REMOTE, game_player.name}),
		class_new("games.strategy.engine.player.Player", "Player"),
	)
}

// games.strategy.engine.framework.ServerGame#getRemoteName(IDelegate)
// Java: return new RemoteName(
//   "games.strategy.engine.framework.ServerGame.DELEGATE_REMOTE." + delegate.getName(),
//   delegate.getRemoteType());
// Java's `Class<? extends IRemote>` becomes the Odin `typeid` returned by
// `i_delegate_get_remote_type`; format it via `%v` to recover the type
// name for the Remote_Name's clazz string carrier.
server_game_get_remote_name_for_delegate :: proc(delegate: ^I_Delegate) -> ^Remote_Name {
	type_id := i_delegate_get_remote_type(delegate)
	type_name := fmt.aprintf("%v", type_id)
	return remote_name_new(
		strings.concatenate({SERVER_GAME_DELEGATE_REMOTE, i_delegate_get_name(delegate)}),
		class_new(type_name, type_name),
	)
}

// games.strategy.engine.framework.ServerGame#lambda$addObserver$1(
//   IObserverWaitingToJoin blockingObserver, byte[] bytes,
//   CountDownLatch waitOnObserver, INode newNode)
// Java decompilation captures: (this, blockingObserver, bytes,
// waitOnObserver, newNode). The body sends the serialized game data to
// the joining observer and counts the latch down. Java's try/catch
// branch only logs on exceptions; in the single-threaded Odin shim the
// call cannot throw, so the catch arms are unreachable and omitted.
server_game_lambda_add_observer_1 :: proc(
	self: ^Server_Game,
	blocking_observer: ^I_Observer_Waiting_To_Join,
	bytes: []u8,
	wait_on_observer: ^Count_Down_Latch,
	new_node: ^I_Node,
) {
	_ = new_node
	i_observer_waiting_to_join_join_game(
		blocking_observer,
		bytes,
		player_manager_get_player_mapping(self.player_manager),
	)
	count_down_latch_count_down(wait_on_observer)
}

// games.strategy.engine.framework.ServerGame#shouldAutoSaveBeforeStart(IDelegate)
// Java: delegateAutosavesEnabled
//     && delegate.getClass().isAnnotationPresent(AutoSave.class)
//     && delegate.getClass().getAnnotation(AutoSave.class).beforeStepStart();
// Java reflection is replaced by an explicit `auto_save_annotation`
// pointer on I_Delegate, populated by concrete delegate constructors
// when the Java class is declared `@AutoSave(...)`. A nil annotation
// mirrors `isAnnotationPresent == false` and short-circuits to false.
server_game_should_auto_save_before_start :: proc(self: ^Server_Game, delegate: ^I_Delegate) -> bool {
	return self.delegate_autosaves_enabled &&
		delegate != nil &&
		delegate.auto_save_annotation != nil &&
		delegate.auto_save_annotation.before_step_start
}

// games.strategy.engine.framework.ServerGame#shouldAutoSaveAfterStart(IDelegate)
server_game_should_auto_save_after_start :: proc(self: ^Server_Game, delegate: ^I_Delegate) -> bool {
	return self.delegate_autosaves_enabled &&
		delegate != nil &&
		delegate.auto_save_annotation != nil &&
		delegate.auto_save_annotation.after_step_start
}

// games.strategy.engine.framework.ServerGame#shouldAutoSaveAfterEnd(IDelegate)
server_game_should_auto_save_after_end :: proc(self: ^Server_Game, delegate: ^I_Delegate) -> bool {
	return self.delegate_autosaves_enabled &&
		delegate != nil &&
		delegate.auto_save_annotation != nil &&
		delegate.auto_save_annotation.after_step_end
}

// games.strategy.engine.framework.ServerGame#getCurrentStep()
// Java: return gameData.getSequence().getStep();
server_game_get_current_step :: proc(self: ^Server_Game) -> ^Game_Step {
	return game_sequence_get_step(game_data_get_sequence(self.game_data))
}

// games.strategy.engine.framework.ServerGame#getGameModifiedBroadcaster()
// Java: return (IGameModifiedChannel)
//   messengers.getChannelBroadcaster(IGame.GAME_MODIFICATION_CHANNEL);
// IGame.GAME_MODIFICATION_CHANNEL is the RemoteName
//   ("games.strategy.engine.framework.IGame.GAME_MODIFICATION_CHANNEL",
//    IGameModifiedChannel.class).
SERVER_GAME_GAME_MODIFICATION_CHANNEL_NAME :: "games.strategy.engine.framework.IGame.GAME_MODIFICATION_CHANNEL"

server_game_get_game_modified_broadcaster :: proc(self: ^Server_Game) -> ^I_Game_Modified_Channel {
	rn := remote_name_new(
		SERVER_GAME_GAME_MODIFICATION_CHANNEL_NAME,
		class_new(
			"games.strategy.engine.framework.IGameModifiedChannel",
			"IGameModifiedChannel",
		),
	)
	return cast(^I_Game_Modified_Channel)messengers_get_channel_broadcaster(self.messengers, rn)
}

// games.strategy.engine.framework.ServerGame#importDiceStats(games.strategy.engine.history.HistoryNode)
// Java walks the history tree; for every EventChild whose rendering data
// is a DiceRoll it forwards the dice values to RandomStats keyed on the
// roller's GamePlayer (resolved via the player_name on the DiceRoll, or
// — when null — via DiceRoll.getPlayerNameFromAnnotation(node.getTitle())).
// Then it recurses into every child node.
server_game_import_dice_stats :: proc(self: ^Server_Game, node: ^History_Node) {
	if node == nil {
		return
	}
	if node.kind == .Event_Child {
		child_node := cast(^Event_Child)node
		if dice_roll, ok := child_node.rendering_data.(^Dice_Roll); ok {
			player_name := dice_roll_get_player_name(dice_roll)
			if player_name == "" {
				title, _ := default_mutable_tree_node_get_user_object(
					&child_node.history_node.default_mutable_tree_node,
				).(string)
				player_name = dice_roll_get_player_name_from_annotation(title)
			}
			game_player := player_list_get_player_id(
				game_data_get_player_list(self.game_data),
				player_name,
			)
			n := dice_roll_size(dice_roll)
			rolls := make([]i32, n)
			for i in 0 ..< n {
				rolls[i] = die_get_value(dice_roll_get_die(dice_roll, i))
			}
			random_stats_add_random(self.random_stats, rolls, game_player, .COMBAT)
		}
	}
	count := default_mutable_tree_node_get_child_count(&node.default_mutable_tree_node)
	for i in 0 ..< count {
		child := default_mutable_tree_node_get_child_at(&node.default_mutable_tree_node, i)
		server_game_import_dice_stats(self, cast(^History_Node)child)
	}
}

// Inline equivalent of games.strategy.engine.history.History#getLastNode():
// Java walks the DefaultTreeModel from the root, taking the last child at
// each level until reaching a leaf. The History tree only ever contains
// History_Node subclasses, so the final cast is safe.
@(private = "file")
server_game_history_get_last_node :: proc(history: ^History) -> ^History_Node {
	root := default_tree_model_get_root(&history.default_tree_model)
	node := root
	for default_mutable_tree_node_get_child_count(node) > 0 {
		n := default_mutable_tree_node_get_child_count(node)
		node = default_mutable_tree_node_get_child_at(node, n - 1)
	}
	return cast(^History_Node)node
}

// games.strategy.engine.framework.ServerGame#addChange(games.strategy.engine.data.Change)
// Java: getGameModifiedBroadcaster().gameDataChanged(change). Routing the
// change through the broadcast channel keeps every mutation on the same
// thread as the IGameModifiedChannel subscriber installed in the
// constructor.
server_game_add_change :: proc(self: ^Server_Game, change: ^Change) {
	i_game_modified_channel_game_data_changed(
		server_game_get_game_modified_broadcaster(self),
		change,
	)
}

// games.strategy.engine.framework.ServerGame#addDelegateMessenger(IDelegate)
// Java: skip delegates whose remoteType is null (no IRemote surface).
// Otherwise wrap the delegate via newInboundImplementation and register
// it on the messengers under the DELEGATE_REMOTE.<name> RemoteName.
server_game_add_delegate_messenger :: proc(self: ^Server_Game, delegate: ^I_Delegate) {
	remote_type := i_delegate_get_remote_type(delegate)
	if remote_type == nil {
		return
	}
	interfaces := []typeid{remote_type}
	wrapped := delegate_execution_manager_new_inbound_implementation(
		self.delegate_execution_manager,
		rawptr(delegate),
		interfaces,
	)
	descriptor := server_game_get_remote_name_for_delegate(delegate)
	messengers_register_remote(self.messengers, wrapped, descriptor)
}

// games.strategy.engine.framework.ServerGame#endStep()
// Java: enterDelegateExecution(); try { current.delegate.end() } finally
// { leaveDelegateExecution(); } current.incrementRunCount();
// The increment lives outside the try/finally, so the defer is scoped to
// the inner block.
server_game_end_step :: proc(self: ^Server_Game) {
	delegate_execution_manager_enter_delegate_execution(self.delegate_execution_manager)
	{
		defer delegate_execution_manager_leave_delegate_execution(self.delegate_execution_manager)
		i_delegate_end(game_step_get_delegate(server_game_get_current_step(self)))
	}
	game_step_increment_run_count(server_game_get_current_step(self))
}

// games.strategy.engine.framework.ServerGame#lambda$new$0(GameData)
// Java decompilation of the IServerRemote lambda installed in the
// constructor: () -> GameDataWriter.writeToBytes(data,
// delegateExecutionManager). The lambda captures `this` (for
// delegateExecutionManager) and `data`, and javac emits it as a private
// instance method taking the captured GameData argument.
server_game_lambda_new_0 :: proc(self: ^Server_Game, data: ^Game_Data) -> []u8 {
	return game_data_writer_write_to_bytes(data, self.delegate_execution_manager)
}

// games.strategy.engine.framework.ServerGame#notifyGameStepChanged(boolean)
// Java: read step name / delegate name / display name / round / player
// from the current step, fire the GAME_STEP_CHANGED event on game_data,
// then forward to the IGameModifiedChannel broadcaster.
server_game_notify_game_step_changed :: proc(self: ^Server_Game, loaded_from_saved_game: bool) {
	current_step := server_game_get_current_step(self)
	step_name := game_step_get_name(current_step)
	delegate_name := i_delegate_get_name(game_step_get_delegate(current_step))
	display_name := game_step_get_display_name(current_step)
	round := game_sequence_get_round(game_data_get_sequence(self.game_data))
	game_player := game_step_get_player_id(current_step)
	game_data_fire_game_data_event(self.game_data, .Game_Step_Changed)
	i_game_modified_channel_step_changed(
		server_game_get_game_modified_broadcaster(self),
		step_name,
		delegate_name,
		game_player,
		round,
		display_name,
		loaded_from_saved_game,
	)
}

// games.strategy.engine.framework.ServerGame#addPlayerTypesToGameData(
//   Collection<Player>, PlayerManager, IDelegateBridge)
// Java: on the very first step (no current step / player, or firstRun),
// flip firstRun off and bail. Otherwise (provided the latest history
// node is a Step / Event / EventChild) walk every local Player, write a
// "now being played by" history line, and emit a Player_Who_Am_I_Change
// for each player whose getWhoAmI() differs from the new value. Any
// names left over in `allPlayersString` after the local pass are remote
// human:client players; they get the same treatment with the literal
// "Human:Client" label. Finally, mark needToInitialize false and assert
// the working set is empty.
server_game_add_player_types_to_game_data :: proc(
	self:          ^Server_Game,
	local_players: [dynamic]^Player,
	all_players:   ^Player_Manager,
	bridge:        ^I_Delegate_Bridge,
) {
	data := i_delegate_bridge_get_data(bridge)
	cur_step := server_game_get_current_step(self)
	if cur_step == nil ||
	   game_step_get_player_id(cur_step) == nil ||
	   self.first_run {
		self.first_run = false
		return
	}
	cur_node := server_game_history_get_last_node(game_data_get_history(data))
	if cur_node.kind != .Step &&
	   cur_node.kind != .Event &&
	   cur_node.kind != .Event_Child {
		return
	}
	change := composite_change_new()
	all_players_string := player_manager_get_players(all_players)
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	i_delegate_history_writer_start_event(history_writer, "Game Loaded")

	for player in local_players {
		name := player_get_name(player)
		delete_key(&all_players_string, name)
		label := player_get_player_label(player)
		line := fmt.aprintf(
			"%s %s now being played by: %s",
			name,
			server_game_is_or_are(self, name),
			label,
		)
		history_writer_add_child_to_event(history_writer, line)
		p := player_list_get_player_id(game_data_get_player_list(data), name)
		who_kind := "Human"
		if player_is_ai(player) {
			who_kind = "AI"
		}
		new_who_am_i := fmt.aprintf("%s:%s", who_kind, label)
		if game_player_get_who_am_i(p) != new_who_am_i {
			composite_change_add(
				change,
				change_factory_change_player_who_am_i_change(p, new_who_am_i),
			)
		}
	}

	// Mirror Java's `Iterator.remove()` over the leftover names: copy
	// the remaining keys into a slice, then remove and process each.
	remaining := make([dynamic]string, 0, len(all_players_string))
	defer delete(remaining)
	for name in all_players_string {
		append(&remaining, name)
	}
	for name in remaining {
		delete_key(&all_players_string, name)
		line := fmt.aprintf(
			"%s %s now being played by: Human:Client",
			name,
			server_game_is_or_are(self, name),
		)
		history_writer_add_child_to_event(history_writer, line)
		p := player_list_get_player_id(game_data_get_player_list(data), name)
		new_who_am_i: string = "Human:Client"
		if game_player_get_who_am_i(p) != new_who_am_i {
			composite_change_add(
				change,
				change_factory_change_player_who_am_i_change(p, new_who_am_i),
			)
		}
	}

	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
	self.need_to_initialize = false
	if len(all_players_string) > 0 {
		panic("Not all Player Types (ai/human/client) could be added to game data.")
	}
}

// games.strategy.engine.framework.ServerGame#setupDelegateMessaging(GameData)
// Java: for (final IDelegate delegate : data.getDelegates()) {
//           addDelegateMessenger(delegate);
//       }
server_game_setup_delegate_messaging :: proc(self: ^Server_Game, data: ^Game_Data) {
	delegates := game_data_get_delegates(data)
	defer delete(delegates)
	for delegate in delegates {
		server_game_add_delegate_messenger(self, delegate)
	}
}

// games.strategy.engine.framework.ServerGame#startStep(boolean)
// Java: lazily wrap the random source with the delegate-execution outbound
// proxy on first use, build a fresh DefaultDelegateBridge that bundles the
// random/history/messenger plumbing, optionally seed player-type history
// (first run only), broadcast the GAME_STEP_CHANGED event, then enter
// delegate execution to run delegate.setDelegateBridgeAndPlayer + start
// inside the enter/leave try/finally.
server_game_start_step :: proc(self: ^Server_Game, step_is_restored_from_saved_game: bool) {
	if self.delegate_random_source == nil {
		interfaces := []typeid{typeid_of(I_Random_Source)}
		self.delegate_random_source = cast(^I_Random_Source)delegate_execution_manager_new_outbound_implementation(
			self.delegate_execution_manager,
			rawptr(self.random_source),
			interfaces,
		)
	}
	history_writer := delegate_history_writer_new(self.messengers.channel_messenger, self.game_data)
	bridge := make_Default_Delegate_Bridge(
		self.game_data,
		self,
		cast(^I_Delegate_History_Writer)history_writer,
		self.random_stats,
		self.delegate_execution_manager,
		self.client_network_bridge,
		self.delegate_random_source,
	)
	if self.need_to_initialize {
		local_players := make([dynamic]^Player, 0, len(self.game_players))
		defer delete(local_players)
		for _, player in self.game_players {
			append(&local_players, player)
		}
		server_game_add_player_types_to_game_data(
			self,
			local_players,
			self.player_manager,
			cast(^I_Delegate_Bridge)bridge,
		)
	}
	server_game_notify_game_step_changed(self, step_is_restored_from_saved_game)
	delegate_execution_manager_enter_delegate_execution(self.delegate_execution_manager)
	{
		defer delegate_execution_manager_leave_delegate_execution(self.delegate_execution_manager)
		delegate := game_step_get_delegate(server_game_get_current_step(self))
		i_delegate_set_delegate_bridge_and_player(
			delegate,
			cast(^I_Delegate_Bridge)bridge,
			self.client_network_bridge,
		)
		i_delegate_start(delegate)
	}
}

// games.strategy.engine.framework.ServerGame#waitForPlayerToFinishStep()
// Java: if the current step has no player or its delegate doesn't require
// user input, return early. Otherwise, look up the local Player by
// GamePlayer in gamePlayers; if found, invoke player.start(stepName) to
// drive the local turn. If not, resolve the remote node via
// playerManager and dispatch IGameStepAdvancer.startPlayerStep over the
// messenger using ClientGame's remote step-advancer name.
server_game_wait_for_player_to_finish_step :: proc(self: ^Server_Game) {
	game_player := game_step_get_player_id(server_game_get_current_step(self))
	if game_player == nil {
		return
	}
	if !i_delegate_delegate_currently_requires_user_input(
		game_step_get_delegate(server_game_get_current_step(self)),
	) {
		return
	}
	player, ok := self.game_players[game_player]
	if ok && player != nil {
		player_start(player, game_step_get_name(server_game_get_current_step(self)))
	} else {
		destination := player_manager_get_node(self.player_manager, game_player.name)
		advancer := cast(^I_Game_Step_Advancer)messengers_get_remote(
			self.messengers,
			client_game_get_remote_step_advancer_name(destination),
		)
		i_game_step_advancer_start_player_step(
			advancer,
			game_step_get_name(server_game_get_current_step(self)),
			game_player,
		)
	}
}
