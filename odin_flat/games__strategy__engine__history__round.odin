package game

import "core:fmt"

// Java: games.strategy.engine.history.Round extends IndexedHistoryNode
//   Round(int round, int changeStartIndex) {
//     super("Round: " + round, changeStartIndex);
//     roundNo = round;
//   }
Round :: struct {
	using indexed_history_node: Indexed_History_Node,
	round_no: i32,
}

round_new :: proc(round: i32, change_start_index: i32) -> ^Round {
	self := new(Round)
	title := fmt.aprintf("Round: %d", round)
	self.indexed_history_node = Indexed_History_Node{
		change_start_index = change_start_index,
		change_stop_index  = -1,
	}
	self.indexed_history_node.history_node = History_Node{
		default_mutable_tree_node = Default_Mutable_Tree_Node{
			user_object = title,
			children    = make([dynamic]^Default_Mutable_Tree_Node),
		},
		kind = .Round,
	}
	self.round_no = round
	return self
}

// Java: public int getRoundNo() { return roundNo; }  (Lombok @Getter)
round_get_round_no :: proc(self: ^Round) -> i32 {
	return self.round_no
}
