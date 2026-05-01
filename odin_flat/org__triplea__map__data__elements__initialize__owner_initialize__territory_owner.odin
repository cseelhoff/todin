package game

Initialize_Owner_Initialize_Territory_Owner :: struct {
	territory: string,
	owner:     string,
}

initialize_owner_initialize_territory_owner_get_owner :: proc(self: ^Initialize_Owner_Initialize_Territory_Owner) -> string {
	return self.owner
}

initialize_owner_initialize_territory_owner_get_territory :: proc(self: ^Initialize_Owner_Initialize_Territory_Owner) -> string {
	return self.territory
}

