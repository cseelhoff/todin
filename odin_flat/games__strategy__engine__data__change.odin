package game

// Discriminator for runtime instanceof-style checks on Change subtypes.
// Subtype constructors must set `parent.kind` to the corresponding value.
// Mirrors the I_Delegate.name retrofit pattern: empty Java interfaces /
// abstract bases get a tag field so Odin can recover Java's instanceof.
Change_Kind :: enum {
	Unknown,
	Composite_Change,
	Change_Attachment_Change,
	Object_Property_Change,
	Add_Battle_Records_Change,
	Add_Production_Rule,
	Add_Units,
	Change_Resource_Change,
	Owner_Change,
	Player_Owner_Change,
	Player_Who_Am_I_Change,
	Bombing_Unit_Damage_Change,
	Unit_Damage_Received_Change,
	Unit_Hits_Change,
	Attachment_Property_Reset,
	Attachment_Property_Reset_Undo,
	Relationship_Change,
	Remove_Battle_Records_Change,
	Remove_Units,
	Production_Frontier_Change,
	Remove_Production_Rule,
	Remove_Available_Tech,
	Generic_Tech_Change,
	Set_Property_Change,
	Add_Available_Tech,
	Change_Factory_1,
}

Change :: struct {
	kind: Change_Kind,
	// Java: public abstract Change invert();
	// Subtype constructors set this to the kind-specific invert proc.
	invert: proc(self: ^Change) -> ^Change,
	// Java: protected abstract void perform(GameState data);
	// Subtype constructors set this to the kind-specific perform proc.
	perform: proc(self: ^Change, data: ^Game_State),
}

// Java owners covered by this file:
//   - games.strategy.engine.data.Change

change_is_empty :: proc(self: ^Change) -> bool {
	return false
}

make_Change :: proc() -> Change {
	return Change{}
}


// Generic dispatch stubs over Change.kind. Real per-kind logic lives on
// the corresponding *_perform / *_invert procedures and will be wired in
// during Phase B. For now these unblock package-level compilation.
change_perform :: proc(self: ^Change, data: ^Game_State) {
	if self == nil { return }
	if self.perform != nil { self.perform(self, data) }
}
change_invert :: proc(self: ^Change) -> ^Change {
	if self == nil { return nil }
	if self.invert != nil { return self.invert(self) }
	return self
}
