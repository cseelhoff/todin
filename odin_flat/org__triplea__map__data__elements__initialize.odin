package game

Initialize :: struct {
	owner_initialize:        ^Initialize_Owner_Initialize,
	unit_initialize:         ^Initialize_Unit_Initialize,
	resource_initialize:     ^Initialize_Resource_Initialize,
	relationship_initialize: ^Initialize_Relationship_Initialize,
}

initialize_get_owner_initialize :: proc(self: ^Initialize) -> ^Initialize_Owner_Initialize {
	return self.owner_initialize
}

initialize_get_unit_initialize :: proc(self: ^Initialize) -> ^Initialize_Unit_Initialize {
	return self.unit_initialize
}

initialize_get_resource_initialize :: proc(self: ^Initialize) -> ^Initialize_Resource_Initialize {
	return self.resource_initialize
}

initialize_get_relationship_initialize :: proc(self: ^Initialize) -> ^Initialize_Relationship_Initialize {
	return self.relationship_initialize
}

