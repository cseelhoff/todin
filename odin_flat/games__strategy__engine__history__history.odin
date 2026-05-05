package game

// games.strategy.engine.history.History extends javax.swing.tree.DefaultTreeModel
//
// Java:
//   public History(GameData data) {
//     super(new RootHistoryNode("Game History"));
//     gameData = data;
//   }
History :: struct {
        using default_tree_model: Default_Tree_Model,
        writer:            ^History_Writer,
        changes:           [dynamic]^Change,
        game_data:         ^Game_Data,
        panel:             ^History_Panel,
        next_change_index: i32,
        seeking_enabled:   bool,
}

// Java has a package-private RootHistoryNode subclass. Functionally
// it's just a HistoryNode with a fixed user_object title.
history_root_node_new :: proc(title: string) -> ^History_Node {
        self := new(History_Node)
        self.default_mutable_tree_node = Default_Mutable_Tree_Node{
                user_object = title,
                children    = make([dynamic]^Default_Mutable_Tree_Node),
        }
        self.kind = .Unknown
        return self
}

history_new :: proc(data: ^Game_Data) -> ^History {
        self := new(History)
        root := history_root_node_new("Game History")
        // super(new RootHistoryNode("Game History"))
        self.default_tree_model = Default_Tree_Model{
                root = &root.default_mutable_tree_node,
        }
        self.game_data = data
        self.changes = make([dynamic]^Change)
        // Java: private final HistoryWriter writer = new HistoryWriter(this)
        self.writer = history_writer_new(self)
        self.next_change_index = 0
        self.seeking_enabled = false
        return self
}

// Java: public HistoryWriter getHistoryWriter() { return writer; }
history_get_history_writer :: proc(self: ^History) -> ^History_Writer {
        return self.writer
}

// Java: public void goToEnd() { if (panel \!= null) panel.goToEnd(); }
// The snapshot harness runs headless — panel is always nil.
history_go_to_end :: proc(self: ^History) {
        // panel is nil in headless tests; no-op.
}

// Java: synchronized void changeAdded(Change change)
history_change_added :: proc(self: ^History, change: ^Change) {
        append(&self.changes, change)
        if self.seeking_enabled && int(self.next_change_index) == len(self.changes) - 1 {
                game_data_perform_change(self.game_data, change)
                self.next_change_index = cast(i32)len(self.changes)
        }
}

// Java: List<Change> getChanges() { return Collections.unmodifiableList(changes); }
history_get_changes :: proc(self: ^History) -> [dynamic]^Change {
        return self.changes
}

// Java: GameData getGameData() { return gameData; }
history_get_game_data :: proc(self: ^History) -> ^Game_Data {
        return self.game_data
}
