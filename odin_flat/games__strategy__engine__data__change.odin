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
	if self.perform != nil {
		self.perform(self, data)
		return
	}
	// Constructors don't always wire the perform proc-field; dispatch
	// by kind so every Change subtype runs its concrete perform.
	switch self.kind {
	case .Unknown:
	case .Composite_Change:
		composite_change_perform(cast(^Composite_Change)self, data)
	case .Change_Attachment_Change:
		change_attachment_change_perform(cast(^Change_Attachment_Change)self, data)
	case .Object_Property_Change:
		object_property_change_perform(cast(^Object_Property_Change)self, data)
	case .Add_Battle_Records_Change:
		add_battle_records_change_perform(cast(^Add_Battle_Records_Change)self, data)
	case .Add_Production_Rule:
		add_production_rule_perform(cast(^Add_Production_Rule)self, data)
	case .Add_Units:
		add_units_perform(cast(^Add_Units)self, data)
	case .Change_Resource_Change:
		change_resource_change_perform(cast(^Change_Resource_Change)self, data)
	case .Owner_Change:
		owner_change_perform(cast(^Owner_Change)self, data)
	case .Player_Owner_Change:
		player_owner_change_perform(cast(^Player_Owner_Change)self, data)
	case .Player_Who_Am_I_Change:
		player_who_am_i_change_perform(cast(^Player_Who_Am_I_Change)self, data)
	case .Bombing_Unit_Damage_Change:
		bombing_unit_damage_change_perform(cast(^Bombing_Unit_Damage_Change)self, data)
	case .Unit_Damage_Received_Change:
		unit_damage_received_change_perform(cast(^Unit_Damage_Received_Change)self, data)
	case .Unit_Hits_Change:
	case .Attachment_Property_Reset:
	case .Attachment_Property_Reset_Undo:
	case .Relationship_Change:
	case .Remove_Battle_Records_Change:
	case .Remove_Units:
		remove_units_perform(cast(^Remove_Units)self, data)
	case .Production_Frontier_Change:
	case .Remove_Production_Rule:
	case .Remove_Available_Tech:
	case .Generic_Tech_Change:
	case .Set_Property_Change:
	case .Add_Available_Tech:
	case .Change_Factory_1:
		change_factory_1_perform(cast(^Change_Factory_1)self, data)
	}
}
change_invert :: proc(self: ^Change) -> ^Change {
	if self == nil { return nil }
	if self.invert != nil { return self.invert(self) }
	return self
}
