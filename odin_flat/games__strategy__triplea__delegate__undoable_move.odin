package game

import "core:fmt"

Undoable_Move :: struct {
	using abstract_undoable_move: Abstract_Undoable_Move,
	reason_cant_undo: string,
	description: string,
	dependencies: map[^Undoable_Move]struct{},
	dependents: map[^Undoable_Move]struct{},
	conquered: map[^Territory]struct{},
	loaded: map[^Unit]struct{},
	unloaded: map[^Unit]struct{},
	route: ^Route,
}

undoable_move_add_to_conquered :: proc(self: ^Undoable_Move, t: ^Territory) {
	self.conquered[t] = {}
}

undoable_move_get_route :: proc(self: ^Undoable_Move) -> ^Route {
	return self.route
}

undoable_move_load :: proc(self: ^Undoable_Move, transport: ^Unit) {
	self.loaded[transport] = {}
}

undoable_move_set_description :: proc(self: ^Undoable_Move, description: string) {
	self.description = description
}

undoable_move_to_string :: proc(self: ^Undoable_Move) -> string {
	return fmt.aprintf("UndoableMove index;%d description: %s", self.index, self.description)
}

undoable_move_unload :: proc(self: ^Undoable_Move, transport: ^Unit) {
	self.unloaded[transport] = {}
}

undoable_move_was_transport_unloaded :: proc(self: ^Undoable_Move, transport: ^Unit) -> bool {
	return transport in self.unloaded
}

