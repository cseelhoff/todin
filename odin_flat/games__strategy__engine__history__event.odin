package game

// Java: games.strategy.engine.history.Event extends IndexedHistoryNode implements Renderable
//   Event(String description, int changeStartIndex) {
//     super(description, changeStartIndex);
//     this.description = description;
//   }
Event :: struct {
	using indexed_history_node: Indexed_History_Node,
	description:  string,
	rendering_data: any,
}

event_new :: proc(description: string, change_start_index: i32) -> ^Event {
	self := new(Event)
	self.indexed_history_node = Indexed_History_Node{
		change_start_index = change_start_index,
		change_stop_index  = -1,
	}
	self.indexed_history_node.history_node = History_Node{
		default_mutable_tree_node = Default_Mutable_Tree_Node{
			user_object = description,
			children    = make([dynamic]^Default_Mutable_Tree_Node),
		},
		kind = .Event,
	}
	self.description = description
	return self
}

// Java: public Object getRenderingData() { return renderingData; }
event_get_rendering_data :: proc(self: ^Event) -> any {
	return self.rendering_data
}

// Java: public void setRenderingData(Object o) { this.renderingData = o; }
event_set_rendering_data :: proc(self: ^Event, rendering_data: any) {
	self.rendering_data = rendering_data
}

// Java: public String getDescription() { return description; }  (Lombok @Getter)
event_get_description :: proc(self: ^Event) -> string {
	return self.description
}
