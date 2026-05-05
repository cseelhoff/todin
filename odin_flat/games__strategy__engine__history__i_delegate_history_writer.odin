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

i_delegate_history_writer_start_event :: proc(
        self: ^I_Delegate_History_Writer,
        event_name: string,
        rendering_data: rawptr = nil,
) {
        self.start_event(self, event_name, rendering_data)
}

// games.strategy.engine.history.IDelegateHistoryWriter#addChildToEvent(java.lang.String)
// games.strategy.engine.history.IDelegateHistoryWriter#addChildToEvent(java.lang.String,java.lang.Object)
i_delegate_history_writer_add_child_to_event :: proc(
        self: ^I_Delegate_History_Writer,
        child: string,
        rendering_data: rawptr = nil,
) {
        self.add_child_to_event(self, child, rendering_data)
}
