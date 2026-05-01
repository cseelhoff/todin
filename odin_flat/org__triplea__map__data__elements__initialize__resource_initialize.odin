package game

Initialize_Resource_Initialize :: struct {
	resources_given: [dynamic]^Initialize_Resource_Initialize_Resource_Given,
}

initialize_resource_initialize_get_resources_given :: proc(self: ^Initialize_Resource_Initialize) -> [dynamic]^Initialize_Resource_Initialize_Resource_Given {
	return self.resources_given
}

