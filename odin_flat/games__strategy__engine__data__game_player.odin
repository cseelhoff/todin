package game

import "core:fmt"
import "core:strings"

// games.strategy.engine.data.GamePlayer
//
// Java: `class GamePlayer extends NamedAttachable implements NamedUnitHolder`.
// Single inheritance → embed Named_Attachable as the parent. The
// NamedUnitHolder/UnitHolder interfaces contribute no fields. The harness
// access path `player.named.base.name` resolves through the chained
// `using` embeddings: Named_Attachable → Default_Named → Named.

Game_Player :: struct {
	using named_attachable: Named_Attachable,
	optional:             bool,
	can_be_disabled:      bool,
	default_type:         string,
	is_hidden:            bool,
	is_disabled:          bool,
	units_held:           ^Unit_Collection,
	resources:            ^Resource_Collection,
	production_frontier:  ^Production_Frontier,
	repair_frontier:      ^Repair_Frontier,
	technology_frontiers: ^Technology_Frontier_List,
	who_am_i:             string,
	tech_attachment:      ^Tech_Attachment,
}

// Java: @Nonnull @Override public GameData getData()
// Wraps super.getData() in Preconditions.checkNotNull(...).
game_player_get_data :: proc(self: ^Game_Player) -> ^Game_Data {
   return game_data_component_get_data_or_throw(&self.named_attachable.default_named.game_data_component)
}

// Java: public PlayerAttachment getPlayerAttachment()
// `(PlayerAttachment) getAttachment(Constants.PLAYER_ATTACHMENT_NAME)`.
// Constants.PLAYER_ATTACHMENT_NAME == "playerAttachment".
game_player_get_player_attachment :: proc(self: ^Game_Player) -> ^Player_Attachment {
	return cast(^Player_Attachment)named_attachable_get_attachment(&self.named_attachable, "playerAttachment")
}

// Java: public Type getPlayerType()
// Splits whoAmI on ':' (Splitter.on(':').splitToList) and constructs
// a new Type(tokens[0], tokens[1]).
game_player_get_player_type :: proc(self: ^Game_Player) -> Game_Player_Type {
	tokens := strings.split(self.who_am_i, ":")
	defer delete(tokens)
	return Game_Player_Type{id = tokens[0], name = tokens[1]}
}

// Java: public RulesAttachment getRulesAttachment()
// `(RulesAttachment) getAttachment(Constants.RULES_ATTACHMENT_NAME)`.
// Constants.RULES_ATTACHMENT_NAME == "rulesAttachment".
game_player_get_rules_attachment :: proc(self: ^Game_Player) -> ^Rules_Attachment {
	return cast(^Rules_Attachment)named_attachable_get_attachment(&self.named_attachable, "rulesAttachment")
}

// Java: public TechAttachment getTechAttachment()
// Lazily resolves techAttachment from the attachments map; if absent,
// constructs a fresh TechAttachment(Constants.TECH_ATTACHMENT_NAME, this,
// getData()) and caches it on the player. The Java constructor is not
// tracked as a separate proc in port.sqlite, so the equivalent
// DefaultAttachment field initialization is inlined here.
// Constants.TECH_ATTACHMENT_NAME == "techAttachment".
game_player_get_tech_attachment :: proc(self: ^Game_Player) -> ^Tech_Attachment {
	if self.tech_attachment == nil {
		self.tech_attachment = cast(^Tech_Attachment)named_attachable_get_attachment(&self.named_attachable, "techAttachment")
		if self.tech_attachment == nil {
			ta := new(Tech_Attachment)
			ta.name = "techAttachment"
			ta.attached_to = cast(^Attachable)self
			ta.game_data = game_player_get_data(self)
			self.tech_attachment = ta
		}
	}
	return self.tech_attachment
}

// Java: public TechnologyFrontierList getTechnologyFrontierList()
game_player_get_technology_frontier_list :: proc(self: ^Game_Player) -> ^Technology_Frontier_List {
	return self.technology_frontiers
}

// Java: @Getter private final ResourceCollection resources;
// Lombok-generated `public ResourceCollection getResources()`.
game_player_get_resources :: proc(self: ^Game_Player) -> ^Resource_Collection {
	return self.resources
}

// Java: @Override public String getType() { return UnitHolder.PLAYER; }
// UnitHolder.PLAYER == "P".
game_player_get_type :: proc(self: ^Game_Player) -> string {
	return "P"
}

// Java: @Override public UnitCollection getUnitCollection()
game_player_get_unit_collection :: proc(self: ^Game_Player) -> ^Unit_Collection {
	return self.units_held
}

// Java: public boolean isAi()
// Returns "AI".equalsIgnoreCase(getPlayerType().id).
game_player_is_ai :: proc(self: ^Game_Player) -> bool {
	t := game_player_get_player_type(self)
	return strings.equal_fold(t.id, "AI")
}

// Java: public boolean isHidden()
game_player_is_hidden :: proc(self: ^Game_Player) -> bool {
	return self.is_hidden
}

// Java: public boolean isNull() { return false; }
// The static NULL_GAME_PLAYER subclass override returning true is a
// deprecated save-game compatibility shim and is not part of the
// runtime call surface.
game_player_is_null :: proc(self: ^Game_Player) -> bool {
	return false
}

// Java: @Override public void notifyChanged() {}
game_player_notify_changed :: proc(self: ^Game_Player) {
}

// Java: public void setProductionFrontier(final ProductionFrontier frontier)
game_player_set_production_frontier :: proc(self: ^Game_Player, frontier: ^Production_Frontier) {
	self.production_frontier = frontier
}

// Java: public void setRepairFrontier(final RepairFrontier frontier)
game_player_set_repair_frontier :: proc(self: ^Game_Player, frontier: ^Repair_Frontier) {
	self.repair_frontier = frontier
}

// Java: private static List<String> tokenizeEncodedType(final String encodedType)
// Splitter.on(':').splitToList(encodedType). Caller owns the returned slice.
game_player_tokenize_encoded_type :: proc(encoded_type: string) -> []string {
	return strings.split(encoded_type, ":")
}

// Java: public void setWhoAmI(final String encodedType)
// Validates encodedType has exactly two ':'-separated tokens and that
// the first token is one of "AI"/"Human"/"null" (case-insensitive),
// mirroring Guava's Preconditions.checkArgument behaviour by panicking
// on violation.
game_player_set_who_am_i :: proc(self: ^Game_Player, encoded_type: string) {
	tokens := game_player_tokenize_encoded_type(encoded_type)
	defer delete(tokens)
	if len(tokens) != 2 {
		fmt.panicf("whoAmI '%s' must have two strings, separated by a colon", encoded_type)
	}
	type_id := tokens[0]
	if !(strings.equal_fold(type_id, "AI") ||
		   strings.equal_fold(type_id, "Human") ||
		   strings.equal_fold(type_id, "null")) {
		fmt.panicf("whoAmI '%s' first part must be, ai or human or null", encoded_type)
	}
	self.who_am_i = encoded_type
}

// Java: @Override public String toString() { return "PlayerId named: " + getName(); }
// Caller owns the returned string.
game_player_to_string :: proc(self: ^Game_Player) -> string {
   return strings.concatenate({"PlayerId named: ", default_named_get_name(&self.named_attachable.default_named)})
}

// Java: @Getter private RepairFrontier repairFrontier; → Lombok-generated
// `public RepairFrontier getRepairFrontier() { return this.repairFrontier; }`.
game_player_get_repair_frontier :: proc(self: ^Game_Player) -> ^Repair_Frontier {
	return self.repair_frontier
}

// Java: public boolean isDefaultTypeAi() { return DEFAULT_TYPE_AI.equals(defaultType); }
// DEFAULT_TYPE_AI == "AI". Java String.equals returns false for null receiver
// targets; here defaultType may be the empty string when unset, so a plain
// equality check matches the Java semantics.
game_player_is_default_type_ai :: proc(self: ^Game_Player) -> bool {
	return self.default_type == "AI"
}

// Java: public boolean getOptional() { return optional; }
game_player_get_optional :: proc(self: ^Game_Player) -> bool {
	return self.optional
}

// Java: public boolean getIsDisabled() { return isDisabled; }
game_player_get_is_disabled :: proc(self: ^Game_Player) -> bool {
	return self.is_disabled
}

// Java: public boolean isDefaultTypeDoesNothing() { return DEFAULT_TYPE_DOES_NOTHING.equals(defaultType); }
// DEFAULT_TYPE_DOES_NOTHING == "DoesNothing". Mirrors game_player_is_default_type_ai.
game_player_is_default_type_does_nothing :: proc(self: ^Game_Player) -> bool {
	return self.default_type == "DoesNothing"
}

// Java: @Getter private String whoAmI → public String getWhoAmI()
// Lombok-generated accessor; returns the encoded "<type>:<name>" string.
game_player_get_who_am_i :: proc(self: ^Game_Player) -> string {
	return self.who_am_i
}

// Java: public boolean getCanBeDisabled() { return canBeDisabled; }
game_player_get_can_be_disabled :: proc(self: ^Game_Player) -> bool {
	return self.can_be_disabled
}

// Java: public final boolean isAtWarWithAnyOfThesePlayers(Collection<GamePlayer> others)
// → getData().getRelationshipTracker().isAtWarWithAnyOfThesePlayers(this, others).
game_player_is_at_war_with_any_of_these_players :: proc(self: ^Game_Player, others: [dynamic]^Game_Player) -> bool {
	rt := game_data_get_relationship_tracker(game_player_get_data(self))
	return relationship_tracker_is_at_war_with_any_of_these_players(rt, self, others)
}

// Java: public final boolean isAlliedWithAnyOfThesePlayers(Collection<GamePlayer> others)
// → getData().getRelationshipTracker().isAlliedWithAnyOfThesePlayers(this, others).
game_player_is_allied_with_any_of_these_players :: proc(self: ^Game_Player, others: [dynamic]^Game_Player) -> bool {
	rt := game_data_get_relationship_tracker(game_player_get_data(self))
	return relationship_tracker_is_allied_with_any_of_these_players(rt, self, others)
}
