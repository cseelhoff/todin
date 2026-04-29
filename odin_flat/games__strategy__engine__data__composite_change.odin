package game

Composite_Change :: struct {
	using parent: Change,
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
	return &result.parent
}

composite_change_is_empty :: proc(self: ^Composite_Change) -> bool {
	for child in self.changes {
		if !change_is_empty(child) {
			return false
		}
	}
	return true
}

