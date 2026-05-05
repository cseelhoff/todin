package game

import "core:fmt"

// Java: games.strategy.engine.history.Step extends IndexedHistoryNode
//   Step(stepName, delegateName, player, changeStartIndex, displayName) {
//     super(displayName, changeStartIndex);
//     this.stepName = stepName;
//     this.delegateName = delegateName;
//     this.player = player;
//   }
Step :: struct {
	using indexed_history_node: Indexed_History_Node,
	player:        ^Game_Player, // @Nullable
	step_name:     string,
	delegate_name: string,
}

step_new :: proc(
	step_name: string,
	delegate_name: string,
	player: ^Game_Player,
	change_start_index: i32,
	display_name: string,
) -> ^Step {
	self := new(Step)
	self.indexed_history_node = Indexed_History_Node{
		change_start_index = change_start_index,
		change_stop_index  = -1,
	}
	self.indexed_history_node.history_node = History_Node{
		default_mutable_tree_node = Default_Mutable_Tree_Node{
			user_object = display_name,
			children    = make([dynamic]^Default_Mutable_Tree_Node),
		},
		kind = .Step,
	}
	self.step_name = step_name
	self.delegate_name = delegate_name
	self.player = player
	return self
}

// Java: public Optional<GamePlayer> getPlayerId() { return Optional.ofNullable(player); }
step_get_player_id :: proc(self: ^Step) -> ^Game_Player {
	return self.player
}

// Java: public GamePlayer getPlayerIdOrThrow()
step_get_player_id_or_throw :: proc(self: ^Step) -> ^Game_Player {
	if self.player == nil {
		fmt.panicf("No expected player for Step %s", self.step_name)
	}
	return self.player
}

// Java: @Getter String stepName
step_get_step_name :: proc(self: ^Step) -> string {
	return self.step_name
}

// Java: super.getTitle() — title was the displayName passed into super()
step_get_delegate_name :: proc(self: ^Step) -> string {
	return self.delegate_name
}

// Java: super.getTitle() returns the user_object string from DefaultMutableTreeNode
step_get_display_name :: proc(self: ^Step) -> string {
	if v, ok := self.indexed_history_node.history_node.default_mutable_tree_node.user_object.(string); ok {
		return v
	}
	return ""
}
