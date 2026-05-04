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

// games.strategy.engine.data.RelationshipTypeList#createDefaultRelationship(java.lang.String,java.lang.String,games.strategy.engine.data.GameData)
//   private void createDefaultRelationship(
//       final String relationshipTypeConstant,
//       final String relationshipArcheType,
//       final GameData data) throws GameParseException {
//     final RelationshipType relationshipType = new RelationshipType(relationshipTypeConstant, data);
//     final RelationshipTypeAttachment at =
//         new RelationshipTypeAttachment(
//             Constants.RELATIONSHIPTYPE_ATTACHMENT_NAME, relationshipType, data);
//     at.setArcheType(relationshipArcheType);
//     relationshipType.addAttachment(Constants.RELATIONSHIPTYPE_ATTACHMENT_NAME, at);
//     addRelationshipType(relationshipType);
//   }
//
// Java's `Constants.RELATIONSHIPTYPE_ATTACHMENT_NAME` is the literal
// `"relationshipTypeAttachment"`, used inline here to match the convention
// already established elsewhere in the port (e.g. the literal use in
// `relationship_type_attachment.odin` and `trigger_attachment.odin`).
//
// Java passes `relationshipType` (a `NamedAttachable`, which implements
// `Attachable`) as the `attachable` argument to the attachment constructor.
// The Odin port follows the existing convention from
// `game_parser_find_attachment` / `game_player.odin` of `cast(^Attachable)`
// on the `^Relationship_Type` to obtain the `Attachable` view stored in
// `Default_Attachment.attached_to`.
//
// Java's GameParseException (thrown by `setArcheType` for an invalid
// archetype) is replicated by `relationship_type_attachment_set_arche_type`'s
// `panicf`. Since this proc is only ever called with the WAR / ALLIED
// archetype constants (matching Java's caller) the panic path is unreachable,
// mirroring Java's "this should never happen" comment on the catch block.
relationship_type_list_create_default_relationship :: proc(
	self: ^Relationship_Type_List,
	relationship_type_constant: string,
	relationship_arche_type: string,
	data: ^Game_Data,
) {
	relationship_type := relationship_type_new(relationship_type_constant, data)
	at := relationship_type_attachment_new(
		"relationshipTypeAttachment",
		cast(^Attachable)relationship_type,
		data,
	)
	relationship_type_attachment_set_arche_type(at, relationship_arche_type)
	named_attachable_add_attachment(
		&relationship_type.named_attachable,
		"relationshipTypeAttachment",
		cast(^I_Attachment)at,
	)
	relationship_type_list_add_relationship_type(self, relationship_type)
}

// Mirrors Java RelationshipTypeList(GameData) constructor: seeds the list
// with the four default relationship types (SELF/ALLIED, NULL/WAR,
// DEFAULT_WAR/WAR, DEFAULT_ALLIED/ALLIED). The Java try/catch on
// GameParseException is unreachable in practice (only thrown for an
// invalid archetype, never passed here) — the Odin port simply omits the
// guard, matching the comment in `create_default_relationship`.
relationship_type_list_new :: proc(data: ^Game_Data) -> ^Relationship_Type_List {
	self := new(Relationship_Type_List)
	self.game_data_component = make_Game_Data_Component(data)
	self.relationship_types = make(map[string]^Relationship_Type)
	relationship_type_list_create_default_relationship(
		self,
		"self_relation",
		"allied",
		data,
	)
	relationship_type_list_create_default_relationship(
		self,
		"null_relation",
		"war",
		data,
	)
	relationship_type_list_create_default_relationship(
		self,
		"default_war_relation",
		"war",
		data,
	)
	relationship_type_list_create_default_relationship(
		self,
		"default_allied_relation",
		"allied",
		data,
	)
	return self
}
