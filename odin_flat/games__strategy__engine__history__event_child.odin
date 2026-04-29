package game

// Java owners covered by this file:
//   - games.strategy.engine.history.EventChild

Event_Child :: struct {
	using history_node: History_Node,
	using renderable:   Renderable,
	text:               string,
	rendering_data:     any,
}

