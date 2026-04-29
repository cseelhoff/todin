package game

Game_Data_Event :: enum {
	Unit_Moved,
	Game_Step_Changed,
	Tech_Attachment_Changed,
}

// Java owners covered by this file:
//   - games.strategy.engine.data.GameDataEvent

// Java: GameDataEvent#hasMoveChange(Change)
// Recursively checks if `change` is or contains an ALREADY_MOVED
// ObjectPropertyChange (indicates a unit has moved).
game_data_event_has_move_change :: proc(change: ^Change) -> bool {
	if change == nil {
		return false
	}
	if change.kind == .Composite_Change {
		composite := cast(^Composite_Change)change
		for child in composite.changes {
			if game_data_event_has_move_change(child) {
				return true
			}
		}
	}
	if change.kind == .Object_Property_Change {
		opc := cast(^Object_Property_Change)change
		// Java: Unit.PropertyName.ALREADY_MOVED.toString() -> "ALREADY_MOVED"
		if opc.property == "ALREADY_MOVED" {
			return true
		}
	}
	return false
}

// Java: GameDataEvent#lookupEvent(Change) -> Optional<GameDataEvent>
// Modeled in Odin as (value, ok) to mirror Optional.
game_data_event_lookup_event :: proc(change: ^Change) -> (Game_Data_Event, bool) {
	if game_data_event_has_move_change(change) {
		return .Unit_Moved, true
	}
	if change != nil && change.kind == .Change_Attachment_Change {
		attachment_change := cast(^Change_Attachment_Change)change
		// Constants.TECH_ATTACHMENT_NAME == "techAttachment"
		if attachment_change.attachment_name == "techAttachment" {
			return .Tech_Attachment_Changed, true
		}
	}
	return .Unit_Moved, false
}

