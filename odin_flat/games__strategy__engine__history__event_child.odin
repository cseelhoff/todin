package game

// Java owners covered by this file:
//   - games.strategy.engine.history.EventChild

Event_Child :: struct {
	using history_node: History_Node,
	using renderable:   Renderable,
	text:               string,
	rendering_data:     any,
}

// games.strategy.engine.history.EventChild#<init>(java.lang.String,java.lang.Object)
//
// Java: super(text); this.text = text; this.renderingData = renderingData;
// Mirrors Event/Round/Step constructors: initialise the embedded
// History_Node (DefaultMutableTreeNode userObject = text, kind tag
// = .Event_Child) and stash both fields. `rendering_data` is `any`
// to mirror Java's `Object`; callers ferrying a raw pointer wrap
// it with `any{data = ptr, id = nil}`.
event_child_new :: proc(text: string, rendering_data: any) -> ^Event_Child {
	self := new(Event_Child)
	self.history_node = History_Node{
		default_mutable_tree_node = Default_Mutable_Tree_Node{
			user_object = text,
			children    = make([dynamic]^Default_Mutable_Tree_Node),
		},
		kind = .Event_Child,
	}
	self.text = text
	self.rendering_data = rendering_data
	return self
}

