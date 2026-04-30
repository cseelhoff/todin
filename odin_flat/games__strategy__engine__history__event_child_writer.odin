package game

Event_Child_Writer :: struct {
	text:           string,
	rendering_data: rawptr,
}

event_child_writer_new :: proc(text: string, rendering_data: rawptr) -> ^Event_Child_Writer {
	self := new(Event_Child_Writer)
	self.text = text
	self.rendering_data = rendering_data
	return self
}
