package game

Initialize :: struct {
	owner_initialize:        ^Initialize_Owner_Initialize,
	unit_initialize:         ^Initialize_Unit_Initialize,
	resource_initialize:     ^Initialize_Resource_Initialize,
	relationship_initialize: ^Initialize_Relationship_Initialize,
}

Initialize_Owner_Initialize :: struct {
	territory_owners: [dynamic]^Initialize_Owner_Initialize_Territory_Owner,
}

Initialize_Owner_Initialize_Territory_Owner :: struct {
	territory: string,
	owner:     string,
}

Initialize_Unit_Initialize :: struct {
	unit_placements: [dynamic]^Initialize_Unit_Initialize_Unit_Placement,
	held_units:      [dynamic]^Initialize_Unit_Initialize_Held_Units,
}

Initialize_Unit_Initialize_Unit_Placement :: struct {
	unit_type:   string,
	territory:   string,
	quantity:    i32,
	owner:       string,
	hits_taken:  ^i32,
	unit_damage: ^i32,
}

Initialize_Unit_Initialize_Held_Units :: struct {
	unit_type: string,
	player:    string,
	quantity:  i32,
}

Initialize_Resource_Initialize :: struct {
	resources_given: [dynamic]^Initialize_Resource_Initialize_Resource_Given,
}

Initialize_Resource_Initialize_Resource_Given :: struct {
	player:   string,
	resource: string,
	quantity: i32,
}

Initialize_Relationship_Initialize :: struct {
	relationships: [dynamic]^Initialize_Relationship_Initialize_Relationship,
}

Initialize_Relationship_Initialize_Relationship :: struct {
	type:        string,
	round_value: i32,
	player1:     string,
	player2:     string,
}

