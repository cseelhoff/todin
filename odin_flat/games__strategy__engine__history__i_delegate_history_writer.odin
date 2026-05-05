package game

// Java: games.strategy.engine.history.IDelegateHistoryWriter (interface)
// Modelled as a vtable struct. The two startEvent overloads collapse into
// a single dispatch field with an optional rendering-data parameter.

I_Delegate_History_Writer :: struct {
        concrete:           rawptr,
        start_event:        proc(self: ^I_Delegate_History_Writer, event_name: string, rendering_data: rawptr),
        add_child_to_event: proc(self: ^I_Delegate_History_Writer, child: string, rendering_data: rawptr),
}

// Java owners covered by this file:
//   - games.strategy.engine.history.IDelegateHistoryWriter

// NOTE: The bridge stores history_writer as ^I_Delegate_History_Writer but
// the only concrete supplied at runtime is ^Delegate_History_Writer (which
// does not embed the interface vtable). Reading proc-fields off such a
// transmuted pointer returns garbage memory. Until proper vtable wiring is
// in place, all dispatchers bypass the proc-fields and direct-dispatch to
// the Delegate_History_Writer concrete.

i_delegate_history_writer_start_event :: proc(
	self: ^I_Delegate_History_Writer,
	event_name: string,
	rendering_data: rawptr = nil,
) {
	if self == nil { return }
	dhw := cast(^Delegate_History_Writer)self
	if rendering_data == nil {
		delegate_history_writer_start_event(dhw, event_name)
	} else {
		delegate_history_writer_start_event_with_data(dhw, event_name, rendering_data)
	}
}

// games.strategy.engine.history.IDelegateHistoryWriter#addChildToEvent(java.lang.String)
// games.strategy.engine.history.IDelegateHistoryWriter#addChildToEvent(java.lang.String,java.lang.Object)
i_delegate_history_writer_add_child_to_event :: proc(
	self: ^I_Delegate_History_Writer,
	child: string,
	rendering_data: rawptr = nil,
) {
	if self == nil { return }
	dhw := cast(^Delegate_History_Writer)self
	if rendering_data == nil {
		delegate_history_writer_add_child_to_event(dhw, child)
	} else {
		delegate_history_writer_add_child_to_event_with_data(dhw, child, rendering_data)
	}
}
