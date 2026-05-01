package game

Initialize_Owner_Initialize :: struct {
	territory_owners: [dynamic]^Initialize_Owner_Initialize_Territory_Owner,
}

initialize_owner_initialize_get_territory_owners :: proc(self: ^Initialize_Owner_Initialize) -> [dynamic]^Initialize_Owner_Initialize_Territory_Owner {
	return self.territory_owners
}
