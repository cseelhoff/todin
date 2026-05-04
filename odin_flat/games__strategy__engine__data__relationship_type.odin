package game

// games.strategy.engine.data.RelationshipType

Relationship_Type :: struct {
	using named_attachable: Named_Attachable,
}

// games.strategy.engine.data.RelationshipType#<init>(java.lang.String,games.strategy.engine.data.GameData)
//   public RelationshipType(final String name, final GameData data) {
//       super(name, data);
//   }
relationship_type_new :: proc(name: string, data: ^Game_Data) -> ^Relationship_Type {
	self := new(Relationship_Type)
	base := named_attachable_new(name, data)
	self.named_attachable = base^
	free(base)
	return self
}

// games.strategy.engine.data.RelationshipType#getRelationshipTypeAttachment()
//   public RelationshipTypeAttachment getRelationshipTypeAttachment() {
//       return RelationshipTypeAttachment.get(this);
//   }
relationship_type_get_relationship_type_attachment :: proc(self: ^Relationship_Type) -> ^Relationship_Type_Attachment {
	return relationship_type_attachment_get_1(self)
}
