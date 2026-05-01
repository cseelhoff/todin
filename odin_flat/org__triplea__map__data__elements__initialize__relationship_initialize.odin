package game

Initialize_Relationship_Initialize :: struct {
	relationships: [dynamic]^Initialize_Relationship_Initialize_Relationship,
}

initialize_relationship_initialize_get_relationships :: proc(self: ^Initialize_Relationship_Initialize) -> [dynamic]^Initialize_Relationship_Initialize_Relationship {
	return self.relationships
}

