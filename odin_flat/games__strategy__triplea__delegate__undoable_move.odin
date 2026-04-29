package game

Undoable_Move :: struct {
	using parent: Abstract_Undoable_Move,
	reason_cant_undo: string,
	description: string,
	dependencies: map[^Undoable_Move]struct{},
	dependents: map[^Undoable_Move]struct{},
	conquered: map[^Territory]struct{},
	loaded: map[^Unit]struct{},
	unloaded: map[^Unit]struct{},
	route: ^Route,
}

