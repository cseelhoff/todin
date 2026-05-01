package game

Composite_Change :: struct {
	using change: Change,
	changes:      [dynamic]^Change,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.CompositeChange

composite_change_get_changes :: proc(self: ^Composite_Change) -> [dynamic]^Change {
	return self.changes
}

composite_change_perform :: proc(self: ^Composite_Change, data: ^Game_State) {
	for current in self.changes {
		change_perform(current, data)
	}
}

// Java: CompositeChange#invert()
// To invert a list of changes, invert each child in reverse order of the
// original list and wrap the result in a new CompositeChange.
composite_change_invert :: proc(self: ^Composite_Change) -> ^Change {
	result := new(Composite_Change)
	result.changes = make([dynamic]^Change)
	#reverse for child in self.changes {
		append(&result.changes, change_invert(child))
	}
	return &result.change
}

composite_change_is_empty :: proc(self: ^Composite_Change) -> bool {
	for child in self.changes {
		if !change_is_empty(child) {
			return false
		}
	}
	return true
}

// Java: public CompositeChange()
composite_change_new :: proc() -> ^Composite_Change {
	self := new(Composite_Change)
	self.change.kind = .Composite_Change
	self.changes = make([dynamic]^Change)
	return self
}

// Java: public CompositeChange(final List<Change> changes)
composite_change_new_from_list :: proc(changes: [dynamic]^Change) -> ^Composite_Change {
	self := new(Composite_Change)
	self.change.kind = .Composite_Change
	self.changes = make([dynamic]^Change, 0, len(changes))
	for c in changes {
		append(&self.changes, c)
	}
	return self
}

// Java: public void add(final Change... changes)
composite_change_add :: proc(self: ^Composite_Change, changes: ..^Change) {
	for change in changes {
		if !change_is_empty(change) {
			append(&self.changes, change)
		}
	}
}

