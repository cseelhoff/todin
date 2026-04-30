package game

Player_Attachment :: struct {
	using default_attachment: Default_Attachment,
	vps:                                i32,
	capture_vps:                        i32,
	retain_capital_number:              i32,
	retain_capital_produce_number:      i32,
	give_unit_control:                  [dynamic]^Game_Player,
	give_unit_control_in_all_territories: bool,
	capture_unit_on_entering_by:        [dynamic]^Game_Player,
	share_technology:                   [dynamic]^Game_Player,
	help_pay_tech_cost:                 [dynamic]^Game_Player,
	destroys_pus:                       bool,
	immune_to_blockade:                 bool,
	suicide_attack_resources:           Integer_Map_Resource,
	suicide_attack_targets:             map[^Unit_Type]struct{},
	placement_limit:                    map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
	movement_limit:                     map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
	attacking_limit:                    map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{},
}
// Java owners covered by this file:
//   - games.strategy.triplea.attachments.PlayerAttachment

// Java: @Getter private int vps = 0; (Lombok-generated getVps())
player_attachment_get_vps :: proc(self: ^Player_Attachment) -> i32 {
	return self.vps
}

// Java: @Getter private int captureVps = 0; (Lombok-generated getCaptureVps())
player_attachment_get_capture_vps :: proc(self: ^Player_Attachment) -> i32 {
	return self.capture_vps
}

// Java: @Getter private int retainCapitalNumber = 1;
player_attachment_get_retain_capital_number :: proc(self: ^Player_Attachment) -> i32 {
	return self.retain_capital_number
}

// Java: int getRetainCapitalProduceNumber() { return retainCapitalProduceNumber; }
player_attachment_get_retain_capital_produce_number :: proc(self: ^Player_Attachment) -> i32 {
	return self.retain_capital_produce_number
}

// Java: public List<GamePlayer> getGiveUnitControl() { return getListProperty(giveUnitControl); }
// Odin: nil [dynamic] acts as the empty list, mirroring getListProperty's behaviour.
player_attachment_get_give_unit_control :: proc(self: ^Player_Attachment) -> [dynamic]^Game_Player {
	return self.give_unit_control
}

// Java: public boolean getGiveUnitControlInAllTerritories()
player_attachment_get_give_unit_control_in_all_territories :: proc(self: ^Player_Attachment) -> bool {
	return self.give_unit_control_in_all_territories
}

// Java: public List<GamePlayer> getCaptureUnitOnEnteringBy() { return getListProperty(captureUnitOnEnteringBy); }
player_attachment_get_capture_unit_on_entering_by :: proc(self: ^Player_Attachment) -> [dynamic]^Game_Player {
	return self.capture_unit_on_entering_by
}

// Java: public List<GamePlayer> getShareTechnology() { return getListProperty(shareTechnology); }
player_attachment_get_share_technology :: proc(self: ^Player_Attachment) -> [dynamic]^Game_Player {
	return self.share_technology
}

// Java: public List<GamePlayer> getHelpPayTechCost() { return getListProperty(helpPayTechCost); }
player_attachment_get_help_pay_tech_cost :: proc(self: ^Player_Attachment) -> [dynamic]^Game_Player {
	return self.help_pay_tech_cost
}

// Java: public boolean getDestroysPUs()
player_attachment_get_destroys_pus :: proc(self: ^Player_Attachment) -> bool {
	return self.destroys_pus
}

// Java: public boolean getImmuneToBlockade()
player_attachment_get_immune_to_blockade :: proc(self: ^Player_Attachment) -> bool {
	return self.immune_to_blockade
}

// Java: public IntegerMap<Resource> getSuicideAttackResources() { return getIntegerMapProperty(suicideAttackResources); }
// Odin: Integer_Map_Resource is a `map[^Resource]i32`; nil maps act as empty.
player_attachment_get_suicide_attack_resources :: proc(self: ^Player_Attachment) -> Integer_Map_Resource {
	return self.suicide_attack_resources
}

// Java: public Set<UnitType> getSuicideAttackTargets() { return getSetProperty(suicideAttackTargets); }
player_attachment_get_suicide_attack_targets :: proc(self: ^Player_Attachment) -> map[^Unit_Type]struct{} {
	return self.suicide_attack_targets
}

// Java: public Set<Triple<Integer, String, Set<UnitType>>> getPlacementLimit() { return getSetProperty(placementLimit); }
player_attachment_get_placement_limit :: proc(self: ^Player_Attachment) -> map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{} {
	return self.placement_limit
}

// Java: public Set<Triple<Integer, String, Set<UnitType>>> getMovementLimit() { return getSetProperty(movementLimit); }
player_attachment_get_movement_limit :: proc(self: ^Player_Attachment) -> map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{} {
	return self.movement_limit
}

// Java: public Set<Triple<Integer, String, Set<UnitType>>> getAttackingLimit() { return getSetProperty(attackingLimit); }
player_attachment_get_attacking_limit :: proc(self: ^Player_Attachment) -> map[^Triple(i32, string, map[^Unit_Type]struct{})]struct{} {
	return self.attacking_limit
}

// ---------------------------------------------------------------------------
// getPropertyOrEmpty inline lambdas:
//   lambda$getPropertyOrEmpty$1 -> () -> 0      (default IntSupplier for "vps")
//   lambda$getPropertyOrEmpty$3 -> () -> false  (default BooleanSupplier for
//                                                "giveUnitControlInAllTerritories")
// Both are non-capturing constant suppliers consumed by the layer-1 body of
// getPropertyOrEmpty.
// ---------------------------------------------------------------------------
player_attachment_lambda_get_property_or_empty_1 :: proc() -> i32 {
	return 0
}

player_attachment_lambda_get_property_or_empty_3 :: proc() -> bool {
	return false
}
