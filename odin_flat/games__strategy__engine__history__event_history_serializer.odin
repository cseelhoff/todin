package game

Event_History_Serializer :: struct {
	using serialization_writer: Serialization_Writer,
	event_name:     string,
	rendering_data: rawptr,
}

event_history_serializer_new :: proc(event_name: string, rendering_data: rawptr) -> ^Event_History_Serializer {
	self := new(Event_History_Serializer)
	self.event_name = event_name
	self.rendering_data = rendering_data
	return self
}
