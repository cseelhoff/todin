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
