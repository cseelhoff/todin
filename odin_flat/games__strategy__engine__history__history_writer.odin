package game

History_Writer :: struct {
	history: ^History,
	current: ^History_Node,
}

// Java owners covered by this file:
//   - games.strategy.engine.history.HistoryWriter

history_writer_new :: proc(history: ^History) -> ^History_Writer {
	self := new(History_Writer)
	self.history = history
	return self
}

history_writer_is_current_event :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Event
}

history_writer_is_current_round :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Round
}

history_writer_is_current_step :: proc(self: ^History_Writer) -> bool {
	return self.current != nil && self.current.kind == .Step
}

// games.strategy.engine.history.HistoryWriter#addToCurrent(HistoryNode)
//
// Java: history.insertNodeInto(newNode, current, current.getChildCount());
// followed by history.goToEnd(). DefaultTreeModel.insertNodeInto with
// index == childCount appends the child and notifies Swing tree
// listeners; the snapshot harness has no listeners, so the listener
// notification reduces to the parent/child link maintained by
// default_mutable_tree_node_add. assertCorrectThread() is the Swing
// EDT guard from Java; the headless port runs single-threaded.
history_writer_add_to_current :: proc(self: ^History_Writer, new_node: ^History_Node) {
	_ = game_data_acquire_write_lock(self.history.game_data)
	default_mutable_tree_node_add(
		&self.current.default_mutable_tree_node,
		&new_node.default_mutable_tree_node,
	)
	history_go_to_end(self.history)
}

// games.strategy.engine.history.HistoryWriter#closeCurrent()
//
// Mirrors Java exactly: when closing a Step that produced no children,
// drop the empty step from its parent and emit nodesWereRemoved (a
// Swing listener notification, no-op headless); record the change end
// index on the IndexedHistoryNode being closed; walk current up to
// its parent. The acquireWriteLock try-with-resources is preserved
// for fidelity (acquire is a no-op in single-threaded Odin).
history_writer_close_current :: proc(self: ^History_Writer) {
	old := self.current
	_ = game_data_acquire_write_lock(self.history.game_data)
	if history_writer_is_current_step(self) {
		parent := cast(^History_Node)default_mutable_tree_node_get_parent(
			&self.current.default_mutable_tree_node,
		)
		if default_mutable_tree_node_get_child_count(&self.current.default_mutable_tree_node) == 0 {
			index := default_mutable_tree_node_get_child_count(&parent.default_mutable_tree_node) - 1
			// parent.remove(current): drop the trailing empty step.
			ordered_remove(&parent.default_mutable_tree_node.children, int(index))
			self.current.default_mutable_tree_node.parent = nil
			// history.nodesWereRemoved(parent, [index], [current]) is a
			// DefaultTreeModel listener notification with no subscribers
			// in the snapshot harness.
		}
		// ((Step) current).setChangeEndIndex(history.getChanges().size())
		step_ihn := cast(^Indexed_History_Node)self.current
		step_ihn.change_stop_index = cast(i32)len(self.history.changes)
		self.current = parent
		return
	}
	self.current = cast(^History_Node)default_mutable_tree_node_get_parent(
		&self.current.default_mutable_tree_node,
	)
	// ((IndexedHistoryNode) old).setChangeEndIndex(history.getChanges().size())
	old_ihn := cast(^Indexed_History_Node)old
	old_ihn.change_stop_index = cast(i32)len(self.history.changes)
}

// games.strategy.engine.history.HistoryWriter#addToAndSetCurrent(HistoryNode)
//
// Java: addToCurrent(newNode); current = newNode;
history_writer_add_to_and_set_current :: proc(self: ^History_Writer, new_node: ^History_Node) {
	history_writer_add_to_current(self, new_node)
	self.current = new_node
}

// games.strategy.engine.history.HistoryWriter#startEvent(java.lang.String)
//
// Java: closes any open event, then attaches a fresh Event node as the
// new current. assertCorrectThread() is the Swing EDT guard from Java;
// the headless port runs single-threaded.
history_writer_start_event :: proc(self: ^History_Writer, event_name: string) {
	if history_writer_is_current_event(self) {
		history_writer_close_current(self)
	}
	event := event_new(event_name, cast(i32)len(self.history.changes))
	history_writer_add_to_and_set_current(self, cast(^History_Node)event)
}

// games.strategy.engine.history.HistoryWriter#startNextRound(int)
//
// Java: closes any open event/step/round, resets current to the tree
// root (a RootHistoryNode constructed by History's super(...) call,
// hence safely castable to ^History_Node), then attaches a new Round
// as the current node.
history_writer_start_next_round :: proc(self: ^History_Writer, round: i32) {
	if history_writer_is_current_event(self) {
		history_writer_close_current(self)
	}
	if history_writer_is_current_step(self) {
		history_writer_close_current(self)
	}
	if history_writer_is_current_round(self) {
		history_writer_close_current(self)
	}
	current_round := round_new(round, cast(i32)len(self.history.changes))
	self.current = cast(^History_Node)default_tree_model_get_root(
		&self.history.default_tree_model,
	)
	history_writer_add_to_and_set_current(self, cast(^History_Node)current_round)
}
