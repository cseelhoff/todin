package game

// games.strategy.engine.data.RelationshipTypeList

Relationship_Type_List :: struct {
	using game_data_component: Game_Data_Component,
	relationship_types: map[string]^Relationship_Type,
}

relationship_type_list_add_relationship_type :: proc(self: ^Relationship_Type_List, relationship_type: ^Relationship_Type) {
	self.relationship_types[relationship_type.name] = relationship_type
}

relationship_type_list_get_relationship_type :: proc(self: ^Relationship_Type_List, name: string) -> ^Relationship_Type {
	return self.relationship_types[name]
}

relationship_type_list_get_null_relation :: proc(self: ^Relationship_Type_List) -> ^Relationship_Type {
	return relationship_type_list_get_relationship_type(self, "null_relation")
}

relationship_type_list_get_self_relation :: proc(self: ^Relationship_Type_List) -> ^Relationship_Type {
	return relationship_type_list_get_relationship_type(self, "self_relation")
}

relationship_type_list_get_default_war_relationship :: proc(self: ^Relationship_Type_List) -> ^Relationship_Type {
	return relationship_type_list_get_relationship_type(self, "default_war_relation")
}

relationship_type_list_get_default_allied_relationship :: proc(self: ^Relationship_Type_List) -> ^Relationship_Type {
	return relationship_type_list_get_relationship_type(self, "default_allied_relation")
}

// Mirrors Java RelationshipTypeList#getAllRelationshipTypes(). Returns a
// freshly allocated dynamic array of every RelationshipType in the list,
// matching Java's Collection<RelationshipType> return (map.values()).
relationship_type_list_get_all_relationship_types :: proc(self: ^Relationship_Type_List) -> [dynamic]^Relationship_Type {
	list := make([dynamic]^Relationship_Type, 0, len(self.relationship_types))
	for _, rt in self.relationship_types {
		append(&list, rt)
	}
	return list
}
