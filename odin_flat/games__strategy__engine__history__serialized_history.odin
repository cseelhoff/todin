package game

// games.strategy.engine.history.SerializedHistory
//
// Java DefaultTreeModel is not Serializable across JDK versions, so
// History.writeReplace() emits one of these objects: a flat list of
// SerializationWriter records that can rebuild the tree on the
// receiving side. readResolve() reverses that: build a fresh History
// and re-apply each writer.
//
// Java SerializationWriter is an empty marker interface in Odin
// (`Serialization_Writer :: struct {}`), so the writers slice cannot
// itself carry a runtime tag. We tag each appended record by wrapping
// it in `Sh_Tagged_Writer` (which embeds Serialization_Writer at
// offset 0, size 0) and cast the wrapper pointer to
// `^Serialization_Writer`. read_resolve casts the pointer back to
// recover the discriminator and payload.

Serialized_History :: struct {
	writers:   [dynamic]^Serialization_Writer,
	game_data: ^Game_Data,
}

Sh_Writer_Kind :: enum {
	Change,
	Event_Child,
	Round,
	Step,
	Event,
}

Sh_Tagged_Writer :: struct {
	using sw:           Serialization_Writer,
	kind:               Sh_Writer_Kind,
	// Change payload
	change:             ^Change,
	// EventChildWriter payload
	ec_text:            string,
	ec_rendering_data:  rawptr,
	// Round payload
	round_no:           i32,
	// Step payload
	step_name:          string,
	delegate_name:      string,
	step_player:        ^Game_Player,
	display_name:       string,
	// Event payload
	event_description:  string,
	event_rendering:    rawptr,
}

@(private="file")
sh_append_change :: proc(self: ^Serialized_History, c: ^Change) {
	w := new(Sh_Tagged_Writer)
	w.kind = .Change
	w.change = c
	append(&self.writers, cast(^Serialization_Writer)w)
}

@(private="file")
sh_append_node_writer :: proc(self: ^Serialized_History, node: ^History_Node) {
	w := new(Sh_Tagged_Writer)
	switch node.kind {
	case .Event_Child:
		ec := cast(^Event_Child)node
		w.kind = .Event_Child
		w.ec_text = ec.text
		// rendering_data is `any` on Event_Child; SerializedHistory
		// only ferries it through to a fresh EventChild on resolve,
		// so we keep it as the underlying data pointer.
		w.ec_rendering_data = ec.rendering_data.data
	case .Round:
		// Round/Step/Event Odin structs are blank in Phase A (not
		// reached by the AI snapshot harness, so their per-subtype
		// fields are unavailable). Tag the slot with the kind so a
		// future Phase A pass can fill in the payload without
		// changing the SerializedHistory shape.
		w.kind = .Round
	case .Step:
		w.kind = .Step
	case .Event:
		w.kind = .Event
	case .Unknown:
		// Defensive: unknown discriminator means the node was never
		// initialized; fall through with an Event slot, which is the
		// neutral leaf-style writer.
		w.kind = .Event
	}
	append(&self.writers, cast(^Serialization_Writer)w)
}

@(private="file")
sh_walk_preorder_visit :: proc(self: ^Serialized_History, node: ^Default_Mutable_Tree_Node, changes: []^Change, change_index: ^i32) {
	hn := cast(^History_Node)node
	// Java: `if (node instanceof IndexedHistoryNode indexedHistoryNode)`.
	// Round / Step / Event are the IndexedHistoryNode subtypes;
	// Event_Child is the only HistoryNode subtype that is NOT
	// indexed (matches Java's class hierarchy).
	if hn.kind == .Round || hn.kind == .Step || hn.kind == .Event {
		ihn := cast(^Indexed_History_Node)node
		for change_index^ < ihn.change_start_index && change_index^ < cast(i32)len(changes) {
			sh_append_change(self, changes[change_index^])
			change_index^ += 1
		}
	}
	sh_append_node_writer(self, hn)

	for child in node.children {
		sh_walk_preorder_visit(self, child, changes, change_index)
	}
}

serialized_history_new :: proc(history: ^History, data: ^Game_Data, changes: [dynamic]^Change) -> ^Serialized_History {
	self := new(Serialized_History)
	self.game_data = data
	self.writers = make([dynamic]^Serialization_Writer)

	root := default_tree_model_get_root(&history.default_tree_model)
	change_index: i32 = 0
	changes_slice := changes[:]

	// Java's DefaultMutableTreeNode.preorderEnumeration() yields
	// the receiver first, then recursively yields each child's
	// preorder. SerializedHistory's loop drops that first element
	// (the root) before processing, so we recurse over the root's
	// children directly.
	for child in root.children {
		sh_walk_preorder_visit(self, child, changes_slice, &change_index)
	}

	// Java: drain remaining changes after the last node.
	for change_index < cast(i32)len(changes_slice) {
		sh_append_change(self, changes_slice[change_index])
		change_index += 1
	}
	return self
}

// Java: public Object readResolve(). Returns a fully rebuilt History.
serialized_history_read_resolve :: proc(self: ^Serialized_History) -> ^History {
	history := history_new(self.game_data)
	hw := history_get_history_writer(history)
	for sw in self.writers {
		tw := cast(^Sh_Tagged_Writer)sw
		switch tw.kind {
		case .Change:
			// ChangeSerializationWriter.write(historyWriter):
			//   historyWriter.addChange(change)
			history_writer_add_change(hw, tw.change)
		case .Event_Child:
			// EventChildWriter.write(historyWriter):
			//   historyWriter.addChildToEvent(new EventChild(text, renderingData))
			child := event_child_new(tw.ec_text, any{data = tw.ec_rendering_data, id = nil})
			history_writer_add_child_to_event(hw, child)
		case .Round:
			// RoundHistorySerializer.write(historyWriter):
			//   historyWriter.startNextRound(roundNo)
			history_writer_start_next_round(hw, tw.round_no)
		case .Step:
			// StepHistorySerializer.write(historyWriter):
			//   historyWriter.startNextStep(stepName, delegateName, player, displayName)
			history_writer_start_next_step(hw, tw.step_name, tw.delegate_name, tw.step_player, tw.display_name)
		case .Event:
			// EventHistorySerializer.write(historyWriter):
			//   historyWriter.startEvent(eventName);
			//   if (renderingData != null) writer.setRenderingData(renderingData);
			history_writer_start_event(hw, tw.event_description)
			if tw.event_rendering != nil {
				history_writer_set_rendering_data(hw, any{data = tw.event_rendering, id = nil})
			}
		}
	}
	return history
}
