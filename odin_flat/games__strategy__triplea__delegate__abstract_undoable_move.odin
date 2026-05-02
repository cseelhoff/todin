package game

import "core:fmt"

// Java: games.strategy.triplea.delegate.AbstractUndoableMove (abstract class)
// Subclasses (UndoableMove, UndoablePlacement) embed this struct via `using` and
// populate the dispatch fields in their constructors.

Abstract_Undoable_Move :: struct {
        change: ^Composite_Change,
        index:  i32,
        units:  [dynamic]^Unit,
        // abstract dispatch — populated by concrete subclass _new procs.
        undo_specific:          proc(self: ^Abstract_Undoable_Move, bridge: ^I_Delegate_Bridge),
        get_description_object: proc(self: ^Abstract_Undoable_Move) -> ^Abstract_Move_Description,
        get_move_label:         proc(self: ^Abstract_Undoable_Move) -> string,
        get_end:                proc(self: ^Abstract_Undoable_Move) -> ^Territory,
}

abstract_undoable_move_new :: proc(change: ^Composite_Change, units: [dynamic]^Unit) -> ^Abstract_Undoable_Move {
        self := new(Abstract_Undoable_Move)
        self.change = change
        self.units = units
        return self
}

abstract_undoable_move_set_index :: proc(self: ^Abstract_Undoable_Move, index: i32) {
        self.index = index
}

abstract_undoable_move_get_index :: proc(self: ^Abstract_Undoable_Move) -> i32 {
        return self.index
}

abstract_undoable_move_get_units :: proc(self: ^Abstract_Undoable_Move) -> [dynamic]^Unit {
        return self.units
}

abstract_undoable_move_contains_unit :: proc(self: ^Abstract_Undoable_Move, unit: ^Unit) -> bool {
        for u in self.units {
                if u == unit {
                        return true
                }
        }
        return false
}

abstract_undoable_move_add_change :: proc(self: ^Abstract_Undoable_Move, change: ^Change) {
        composite_change_add(self.change, change)
}

// final void undo(IDelegateBridge delegateBridge)
abstract_undoable_move_undo :: proc(self: ^Abstract_Undoable_Move, delegate_bridge: ^I_Delegate_Bridge) {
        // delegateBridge.getHistoryWriter().startEvent(
        //   delegateBridge.getGamePlayer().getName() + " undo move " + (getIndex() + 1) + ".",
        //   getDescriptionObject());
        writer := i_delegate_bridge_get_history_writer(delegate_bridge)
        player := i_delegate_bridge_get_game_player(delegate_bridge)
        player_name := default_named_get_name(&player.named_attachable.default_named)
        event_name := fmt.aprintf("%s undo move %d.", player_name, self.index + 1)
        desc := self.get_description_object(self)
        i_delegate_history_writer_start_event(writer, event_name, rawptr(desc))

        // delegateBridge.addChange(change.invert());
        i_delegate_bridge_add_change(delegate_bridge, composite_change_invert(self.change))

        // undoSpecific(delegateBridge);
        self.undo_specific(self, delegate_bridge)
}
