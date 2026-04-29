package game

Event_Child_Writer :: struct {
	using serialization_writer: Serialization_Writer,
	text:                       string,
	rendering_data:             any,
}

// Java owners covered by this file:
//   - games.strategy.engine.history.EventChildWriter

