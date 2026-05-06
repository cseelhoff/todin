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

// Java: public GamePlayer(String name, boolean optional, boolean canBeDisabled,
//                        String defaultType, boolean isHidden, GameData data)
//   super(name, data);
//   this.optional = optional; this.canBeDisabled = canBeDisabled;
//   this.defaultType = defaultType; this.isHidden = isHidden;
//   unitsHeld = new UnitCollection(this, data);
//   resources = new ResourceCollection(data);
//   technologyFrontiers = new TechnologyFrontierList(data);
// Java field initializer `whoAmI = "null: " + "no_one"` is mirrored here.
game_player_new :: proc(
	name: string,
	optional: bool,
	can_be_disabled: bool,
	default_type: string,
	hidden: bool,
	game_data: ^Game_Data,
) -> ^Game_Player {
	self := new(Game_Player)
	parent := named_attachable_new(name, game_data)
	self.named_attachable = parent^
	free(parent)
	self.optional = optional
	self.can_be_disabled = can_be_disabled
	self.default_type = default_type
	self.is_hidden = hidden
	self.is_disabled = false
	self.units_held = unit_collection_new(cast(^Named_Unit_Holder)self, game_data)
	self.resources = resource_collection_new(game_data)
	self.technology_frontiers = technology_frontier_list_new(game_data)
	self.who_am_i = "null: no_one"
	self.named_attachable.default_named.named.kind = .Game_Player
	self.named_attachable.default_named.named.get_name = game_player_v_get_name
	return self
}

game_player_v_get_name :: proc(self: ^Named) -> string {
	return game_player_get_name(cast(^Game_Player)self)
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
	if self == nil {
		return true
	}
	// Java's PlayerList.createNullPlayer constructs an anonymous subclass
	// whose `isNull()` returns true; the canonical name of that singleton
	// is "Neutral". The Odin port doesn't carry an explicit isNull flag
	// (see player_list_create_null_player), so identify the null player by
	// its canonical name.
	return default_named_get_name(&self.named_attachable.default_named) == "Neutral"
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

// Java: public final boolean isAllied(GamePlayer other)
// → getData().getRelationshipTracker().isAllied(this, other).
game_player_is_allied :: proc(self: ^Game_Player, other: ^Game_Player) -> bool {
	rt := game_data_get_relationship_tracker(game_player_get_data(self))
	return relationship_tracker_is_allied(rt, self, other)
}

// Java: public final boolean isAtWar(GamePlayer other)
// → getData().getRelationshipTracker().isAtWar(this, other).
game_player_is_at_war :: proc(self: ^Game_Player, other: ^Game_Player) -> bool {
	rt := game_data_get_relationship_tracker(game_player_get_data(self))
	return relationship_tracker_is_at_war(rt, self, other)
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

// Java: public boolean amNotDeadYet()
// "If I have no units with movement and I own zero factories or have no
// owned land, then I am basically dead, and therefore should not
// participate in things like politics."
//
// Java composes Predicate<Unit> via .and(...) and feeds it to
// territory.anyUnitsMatch(...). The Odin matchers return a
// (proc(rawptr, ^Unit) -> bool, rawptr) pair, so we evaluate the
// composed conjunction inline by walking each territory's unit
// collection and short-circuiting per the Java semantics.
game_player_am_not_dead_yet :: proc(self: ^Game_Player) -> bool {
	territories := game_map_get_territories(game_data_get_map(game_player_get_data(self)))
	defer delete(territories)

	owned_p, owned_c := matches_unit_is_owned_by(self)
	atk_p, atk_c := matches_unit_has_attack_value_of_at_least(1)
	mov_p, mov_c := matches_unit_can_move()
	land_p, land_c := matches_unit_is_land()
	prod_p, prod_c := matches_unit_can_produce_units()

	for t in territories {
		uc := territory_get_unit_collection(t)
		if uc != nil {
			for u in uc.units {
				if owned_p(owned_c, u) && atk_p(atk_c, u) && mov_p(mov_c, u) && land_p(land_c, u) {
					return true
				}
			}
			if territory_is_owned_by(t, self) {
				for u in uc.units {
					if owned_p(owned_c, u) && prod_p(prod_c, u) {
						return true
					}
				}
			}
		}
	}
	return false
}

// Java: games.strategy.engine.data.GamePlayer#getName()
//   Inherited from DefaultNamed via NamedAttachable. Forwarder so
//   callers that hold a ^Game_Player can read the name without
//   reaching through the embed chain explicitly.
game_player_get_name :: proc(self: ^Game_Player) -> string {
	return default_named_get_name(&self.named_attachable.default_named)
}
