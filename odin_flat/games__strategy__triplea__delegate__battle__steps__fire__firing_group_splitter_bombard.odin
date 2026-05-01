package game

Firing_Group_Splitter_Bombard :: struct {
}

firing_group_splitter_bombard_new :: proc() -> ^Firing_Group_Splitter_Bombard {
	self := new(Firing_Group_Splitter_Bombard)
	return self
}

// Lombok @Value(staticConstructor = "of") on a class with no instance fields:
// generates a no-arg static factory that returns a new instance.
firing_group_splitter_bombard_of :: proc() -> ^Firing_Group_Splitter_Bombard {
	return firing_group_splitter_bombard_new()
}
