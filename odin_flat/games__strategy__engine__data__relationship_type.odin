package game

// games.strategy.engine.data.RelationshipType

Relationship_Type :: struct {
	using named_attachable: Named_Attachable,
}

// games.strategy.engine.data.RelationshipType#getRelationshipTypeAttachment()
//   public RelationshipTypeAttachment getRelationshipTypeAttachment() {
//       return RelationshipTypeAttachment.get(this);
//   }
relationship_type_get_relationship_type_attachment :: proc(self: ^Relationship_Type) -> ^Relationship_Type_Attachment {
	return relationship_type_attachment_get_1(self)
}
