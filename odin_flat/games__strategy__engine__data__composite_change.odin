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

// Java: public CompositeChange(final Change... changes)
// Varargs overload: chains to the no-arg constructor and then funnels
// the variadic arguments through `add`, matching Java's behavior of
// filtering out empty children.
composite_change_new_from_varargs :: proc(changes: ..^Change) -> ^Composite_Change {
	self := composite_change_new()
	composite_change_add(self, ..changes)
	return self
}

// Java: public CompositeChange flatten()
// Recursively unwraps nested CompositeChange children: a non-composite
// child is kept as-is, while a composite child is flattened first and
// its children spliced in. The result is a fresh CompositeChange with
// no CompositeChange descendants.
composite_change_flatten :: proc(self: ^Composite_Change) -> ^Composite_Change {
	flat := make([dynamic]^Change)
	for child in self.changes {
		if child != nil && child.kind == .Composite_Change {
			inner := cast(^Composite_Change)child
			flattened := composite_change_flatten(inner)
			for c in flattened.changes {
				append(&flat, c)
			}
		} else {
			append(&flat, child)
		}
	}
	return composite_change_new_from_list(flat)
}

// Java: public void add(final Change... changes)
composite_change_add :: proc(self: ^Composite_Change, changes: ..^Change) {
	for change in changes {
		if !change_is_empty(change) {
			append(&self.changes, change)
		}
	}
}

