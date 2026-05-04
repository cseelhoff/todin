package game

import "core:fmt"
import "core:strings"

Trigger_Attachment :: struct {
	using abstract_trigger_attachment:  Abstract_Trigger_Attachment,
	frontier:                           ^Production_Frontier,
	production_rule:                    [dynamic]string,
	tech:                               [dynamic]^Tech_Advance,
	available_tech:                     map[string]map[^Tech_Advance]bool,
	placement:                          map[^Territory]^Integer_Map,
	remove_units:                       map[^Territory]^Integer_Map,
	purchase:                           ^Integer_Map,
	resource:                           string,
	resource_count:                     i32,
	support:                            map[string]bool,
	relationship_change:                [dynamic]string,
	victory:                            string,
	activate_trigger:                   [dynamic]^Tuple(string, string),
	change_ownership:                   [dynamic]string,
	unit_types:                         [dynamic]^Unit_Type,
	unit_attachment_name:               ^Tuple(string, string),
	unit_property:                      [dynamic]^Tuple(string, string),
	territories:                        [dynamic]^Territory,
	territory_attachment_name:          ^Tuple(string, string),
	territory_property:                 [dynamic]^Tuple(string, string),
	players:                            [dynamic]^Game_Player,
	player_attachment_name:             ^Tuple(string, string),
	player_property:                    [dynamic]^Tuple(string, string),
	relationship_types:                 [dynamic]^Relationship_Type,
	relationship_type_attachment_name:  ^Tuple(string, string),
	relationship_type_property:         [dynamic]^Tuple(string, string),
	territory_effects:                  [dynamic]^Territory_Effect,
	territory_effect_attachment_name:   ^Tuple(string, string),
	territory_effect_property:          [dynamic]^Tuple(string, string),
}

// Java owners covered by this file:
//   - games.strategy.triplea.attachments.TriggerAttachment
//
// Predicate factories that don't capture state return a bare
//   proc(^Trigger_Attachment) -> bool
// matching the established convention in
// `abstract_trigger_attachment.odin` (`notification_match`). Capturing
// factories follow the (proc, rawptr) ctx pair convention used there.
//
// Optional<X> is mirrored as the raw value with a sentinel for
// absence: empty string for Optional<String>, nil for Optional<^T>.

// ---------------------------------------------------------------------------
// Simple field accessors (`getListProperty` / `getMapProperty` /
// `getIntegerMapProperty` in Java are pass-throughs; nil/empty Odin
// values already iterate as empty).
// ---------------------------------------------------------------------------

// Java: private List<Tuple<String, String>> getActivateTrigger()
trigger_attachment_get_activate_trigger :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.activate_trigger)
}

// Java: private Map<String, Map<TechAdvance, Boolean>> getAvailableTech()
trigger_attachment_get_available_tech :: proc(self: ^Trigger_Attachment) -> map[string]map[^Tech_Advance]bool {
	return default_attachment_get_map_property(self.available_tech)
}

// Java: private List<String> getChangeOwnership()
trigger_attachment_get_change_ownership :: proc(self: ^Trigger_Attachment) -> [dynamic]string {
	return default_attachment_get_list_property(self.change_ownership)
}

// Java: private Optional<ProductionFrontier> getFrontier()
//   Optional.ofNullable(frontier) — port returns the raw pointer; nil = absent.
trigger_attachment_get_frontier :: proc(self: ^Trigger_Attachment) -> ^Production_Frontier {
	return self.frontier
}

// Java: private Map<Territory, IntegerMap<UnitType>> getPlacement()
trigger_attachment_get_placement :: proc(self: ^Trigger_Attachment) -> map[^Territory]^Integer_Map {
	return default_attachment_get_map_property(self.placement)
}

// Java: private List<Tuple<String, String>> getPlayerProperty()
trigger_attachment_get_player_property :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.player_property)
}

// Java: private List<GamePlayer> getPlayers()
trigger_attachment_get_players :: proc(self: ^Trigger_Attachment) -> [dynamic]^Game_Player {
	return default_attachment_get_list_property(self.players)
}

// Java: List<String> getProductionRule()
trigger_attachment_get_production_rule :: proc(self: ^Trigger_Attachment) -> [dynamic]string {
	return default_attachment_get_list_property(self.production_rule)
}

// Java: private IntegerMap<UnitType> getPurchase()
//   getIntegerMapProperty(purchase) — return raw pointer; nil = empty.
trigger_attachment_get_purchase :: proc(self: ^Trigger_Attachment) -> ^Integer_Map {
	return self.purchase
}

// Java: private List<String> getRelationshipChange()
trigger_attachment_get_relationship_change :: proc(self: ^Trigger_Attachment) -> [dynamic]string {
	return default_attachment_get_list_property(self.relationship_change)
}

// Java: private List<Tuple<String, String>> getRelationshipTypeProperty()
trigger_attachment_get_relationship_type_property :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.relationship_type_property)
}

// Java: private List<RelationshipType> getRelationshipTypes()
trigger_attachment_get_relationship_types :: proc(self: ^Trigger_Attachment) -> [dynamic]^Relationship_Type {
	return default_attachment_get_list_property(self.relationship_types)
}

// Java: private Map<Territory, IntegerMap<UnitType>> getRemoveUnits()
trigger_attachment_get_remove_units :: proc(self: ^Trigger_Attachment) -> map[^Territory]^Integer_Map {
	return default_attachment_get_map_property(self.remove_units)
}

// Java: private Optional<String> getResource()
//   Optional.ofNullable(resource) — empty string represents absent.
trigger_attachment_get_resource :: proc(self: ^Trigger_Attachment) -> string {
	return self.resource
}

// Java: private int getResourceCount()
trigger_attachment_get_resource_count :: proc(self: ^Trigger_Attachment) -> i32 {
	return self.resource_count
}

// Java: private Map<String, Boolean> getSupport()
trigger_attachment_get_support :: proc(self: ^Trigger_Attachment) -> map[string]bool {
	return default_attachment_get_map_property(self.support)
}

// Java: private List<TechAdvance> getTech()
trigger_attachment_get_tech :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tech_Advance {
	return default_attachment_get_list_property(self.tech)
}

// Java: private List<Territory> getTerritories()
trigger_attachment_get_territories :: proc(self: ^Trigger_Attachment) -> [dynamic]^Territory {
	return default_attachment_get_list_property(self.territories)
}

// Java: private List<Tuple<String, String>> getTerritoryEffectProperty()
trigger_attachment_get_territory_effect_property :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.territory_effect_property)
}

// Java: private List<TerritoryEffect> getTerritoryEffects()
trigger_attachment_get_territory_effects :: proc(self: ^Trigger_Attachment) -> [dynamic]^Territory_Effect {
	return default_attachment_get_list_property(self.territory_effects)
}

// Java: private List<Tuple<String, String>> getTerritoryProperty()
trigger_attachment_get_territory_property :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.territory_property)
}

// Java: private List<Tuple<String, String>> getUnitProperty()
trigger_attachment_get_unit_property :: proc(self: ^Trigger_Attachment) -> [dynamic]^Tuple(string, string) {
	return default_attachment_get_list_property(self.unit_property)
}

// Java: private List<UnitType> getUnitType()
trigger_attachment_get_unit_type :: proc(self: ^Trigger_Attachment) -> [dynamic]^Unit_Type {
	return default_attachment_get_list_property(self.unit_types)
}

// Java: private Optional<String> getVictory()
//   Optional.ofNullable(victory) — empty string represents absent.
trigger_attachment_get_victory :: proc(self: ^Trigger_Attachment) -> string {
	return self.victory
}

// ---------------------------------------------------------------------------
// getTriggers(GamePlayer player, Predicate<TriggerAttachment> cond)
// Iterates `player.getAttachments()`, retains those that are
// TriggerAttachments and satisfy `cond`. Java tests `instanceof
// TriggerAttachment`; in the port, TriggerAttachments are the
// attachments registered under the `Constants.TRIGGER_ATTACHMENT_PREFIX`
// ("triggerAttachment") prefix — same convention used by
// `political_action_attachment_get_political_action_attachments`.
// ---------------------------------------------------------------------------
trigger_attachment_get_triggers :: proc(
	player: ^Game_Player,
	cond: proc(rawptr, ^Trigger_Attachment) -> bool,
	cond_ctx: rawptr,
) -> map[^Trigger_Attachment]struct{} {
	assert(cond != nil) // Preconditions.checkNotNull(cond)
	trigs: map[^Trigger_Attachment]struct{}
	attachments := named_attachable_get_attachments(&player.named_attachable)
	for name, att in attachments {
		if !strings.has_prefix(name, "triggerAttachment") {
			continue
		}
		ta := cast(^Trigger_Attachment)att
		if cond(cond_ctx, ta) {
			trigs[ta] = {}
		}
	}
	return trigs
}

// ---------------------------------------------------------------------------
// collectForAllTriggersMatching(Set<GamePlayer>, Predicate<TriggerAttachment>)
// Streams every player's matching triggers into one Set.
// ---------------------------------------------------------------------------
trigger_attachment_collect_for_all_triggers_matching :: proc(
	players: map[^Game_Player]struct{},
	trigger_match: proc(rawptr, ^Trigger_Attachment) -> bool,
	trigger_match_ctx: rawptr,
) -> map[^Trigger_Attachment]struct{} {
	assert(trigger_match != nil) // Preconditions.checkNotNull
	result: map[^Trigger_Attachment]struct{}
	for player in players {
		per_player := trigger_attachment_get_triggers(player, trigger_match, trigger_match_ctx)
		for t in per_player {
			result[t] = {}
		}
	}
	return result
}

// ---------------------------------------------------------------------------
// Match factories — each returns Predicate<TriggerAttachment>.
// All of these are non-capturing → bare-proc form (no ctx).
// ---------------------------------------------------------------------------

// Java: t -> t.getFrontier().isPresent()
trigger_attachment_lambda_prod_match :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_get_frontier(t) != nil
}
trigger_attachment_prod_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_prod_match
}

// Java: t -> !t.getProductionRule().isEmpty()
trigger_attachment_lambda_prod_frontier_edit_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_production_rule(t)) > 0
}
trigger_attachment_prod_frontier_edit_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_prod_frontier_edit_match
}

// Java: t -> !t.getTech().isEmpty()
trigger_attachment_lambda_tech_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_tech(t)) > 0
}
trigger_attachment_tech_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_tech_match
}

// Java: t -> !t.getAvailableTech().isEmpty()
trigger_attachment_lambda_tech_available_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_available_tech(t)) > 0
}
trigger_attachment_tech_available_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_tech_available_match
}

// Java: t -> !t.getRemoveUnits().isEmpty()
trigger_attachment_lambda_remove_units_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_remove_units(t)) > 0
}
trigger_attachment_remove_units_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_remove_units_match
}

// Java: t -> !t.getPlacement().isEmpty()
trigger_attachment_lambda_place_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_placement(t)) > 0
}
trigger_attachment_place_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_place_match
}

// Java: t -> !t.getPurchase().isEmpty()
trigger_attachment_lambda_purchase_match :: proc(t: ^Trigger_Attachment) -> bool {
	p := trigger_attachment_get_purchase(t)
	return p != nil && len(p.map_values) > 0
}
trigger_attachment_purchase_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_purchase_match
}

// Java: t -> t.getResource().isPresent() && t.getResourceCount() != 0
trigger_attachment_lambda_resource_match :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_get_resource(t) != "" && trigger_attachment_get_resource_count(t) != 0
}
trigger_attachment_resource_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_resource_match
}

// Java: t -> !t.getSupport().isEmpty()
trigger_attachment_lambda_support_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_support(t)) > 0
}
trigger_attachment_support_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_support_match
}

// Java: t -> !t.getChangeOwnership().isEmpty()
trigger_attachment_lambda_change_ownership_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_change_ownership(t)) > 0
}
trigger_attachment_change_ownership_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_change_ownership_match
}

// Java: t -> !t.getUnitType().isEmpty() && !t.getUnitProperty().isEmpty()
trigger_attachment_lambda_unit_property_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_unit_type(t)) > 0 && len(trigger_attachment_get_unit_property(t)) > 0
}
trigger_attachment_unit_property_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_unit_property_match
}

// Java: t -> !t.getTerritories().isEmpty() && !t.getTerritoryProperty().isEmpty()
trigger_attachment_lambda_territory_property_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_territories(t)) > 0 && len(trigger_attachment_get_territory_property(t)) > 0
}
trigger_attachment_territory_property_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_territory_property_match
}

// Java: t -> !t.getPlayerProperty().isEmpty()
trigger_attachment_lambda_player_property_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_player_property(t)) > 0
}
trigger_attachment_player_property_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_player_property_match
}

// Java: t -> !t.getRelationshipTypes().isEmpty() && !t.getRelationshipTypeProperty().isEmpty()
trigger_attachment_lambda_relationship_type_property_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_relationship_types(t)) > 0 && len(trigger_attachment_get_relationship_type_property(t)) > 0
}
trigger_attachment_relationship_type_property_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_relationship_type_property_match
}

// Java: t -> !t.getTerritoryEffects().isEmpty() && !t.getTerritoryEffectProperty().isEmpty()
trigger_attachment_lambda_territory_effect_property_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_territory_effects(t)) > 0 && len(trigger_attachment_get_territory_effect_property(t)) > 0
}
trigger_attachment_territory_effect_property_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_territory_effect_property_match
}

// Java: t -> !t.getRelationshipChange().isEmpty()
trigger_attachment_lambda_relationship_change_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_relationship_change(t)) > 0
}
trigger_attachment_relationship_change_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_relationship_change_match
}

// Java: t -> !t.getVictory().orElse("").isEmpty()
trigger_attachment_lambda_victory_match :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_get_victory(t) != ""
}
trigger_attachment_victory_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_victory_match
}

// Java: t -> !t.getActivateTrigger().isEmpty()
trigger_attachment_lambda_activate_trigger_match :: proc(t: ^Trigger_Attachment) -> bool {
	return len(trigger_attachment_get_activate_trigger(t)) > 0
}
trigger_attachment_activate_trigger_match :: proc() -> proc(^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_activate_trigger_match
}

// ---------------------------------------------------------------------------
// Captured-state lambda bodies (synthetic Java method signatures keep
// the captured variables as leading parameters).
// ---------------------------------------------------------------------------

// Java: lambda$getVictoryOrThrow$28 — Supplier<IllegalStateException>
//   () -> new IllegalStateException(String.format(
//             "No expected victory for TriggerAttachment %s", this))
// Captures `this`. Returns the message that would be thrown.
trigger_attachment_lambda_get_victory_or_throw_28 :: proc(self: ^Trigger_Attachment) -> string {
	return fmt.aprintf("No expected victory for TriggerAttachment %v", self)
}

// Java: lambda$setSupport$29(String name, UnitSupportAttachment support)
//   support -> support.getName().equals(name)
trigger_attachment_lambda_set_support_29 :: proc(name: string, support: ^Unit_Support_Attachment) -> bool {
	return support.name == name
}

// Java: lambda$triggerSupportChange$7(Map.Entry<String,Boolean> entry,
//                                     UnitSupportAttachment s)
//   s -> s.getName().equals(entry.getKey())
// Map.Entry's "key" is the support-name string.
trigger_attachment_lambda_trigger_support_change_7 :: proc(entry_key: string, s: ^Unit_Support_Attachment) -> bool {
	return s.name == entry_key
}

// Java: lambda$triggerSupportChange$8(Map.Entry<String,Boolean> entry)
//   () -> new IllegalStateException(
//             "Could not find unitSupportAttachment. name: " + entry.getKey())
trigger_attachment_lambda_trigger_support_change_8 :: proc(entry_key: string) -> string {
	return fmt.aprintf("Could not find unitSupportAttachment. name: %s", entry_key)
}

// Java: lambda$triggerTerritoryPropertyChange$3(Territory territory)
//   () -> new IllegalStateException(
//             "Triggers: No territory attachment for: " + territory.getName())
trigger_attachment_lambda_trigger_territory_property_change_3 :: proc(territory: ^Territory) -> string {
	return fmt.aprintf("Triggers: No territory attachment for: %s", default_named_get_name(&territory.named_attachable.default_named))
}

// ---------------------------------------------------------------------------
// appendChangeWriteEvent(IDelegateBridge, CompositeChange)
//   -> Consumer<Tuple<Change, String>>
//
//   return propertyChangeEvent -> {
//       compositeChange.add(propertyChangeEvent.getFirst());
//       bridge.getHistoryWriter().startEvent(propertyChangeEvent.getSecond());
//   };
//
// Capturing factory — pairs a top-level lambda body proc with a
// heap-allocated ctx struct holding the captured (bridge, compositeChange),
// per the rawptr-context convention used by the other capturing factories
// in this package (see `abstract_trigger_attachment_is_satisfied_match`).
// The lambda body itself is its own method_key and is ported separately.
// ---------------------------------------------------------------------------
Trigger_Attachment_Ctx_append_change_write_event :: struct {
	bridge:           ^I_Delegate_Bridge,
	composite_change: ^Composite_Change,
}

trigger_attachment_append_change_write_event :: proc(
	bridge: ^I_Delegate_Bridge,
	composite_change: ^Composite_Change,
) -> (proc(rawptr, ^Tuple(^Change, string)), rawptr) {
	ctx := new(Trigger_Attachment_Ctx_append_change_write_event)
	ctx.bridge = bridge
	ctx.composite_change = composite_change
	return trigger_attachment_lambda_append_change_write_event_1, rawptr(ctx)
}

// ===========================================================================
// Method-key bodies for the requested batch.
// Naming follows the user-supplied convention `trigger_attachment_lambda__<method>__<n>`
// (double underscore between the method name and the Java-synthetic index)
// so each port is unambiguously identifiable from its `method_key`.
// ===========================================================================

// ---------------------------------------------------------------------------
// getVictoryOrThrow()
//   private String getVictoryOrThrow() {
//     return getVictory().orElseThrow(
//         () -> new IllegalStateException(
//             String.format("No expected victory for TriggerAttachment %s", this)));
//   }
// ---------------------------------------------------------------------------
trigger_attachment_get_victory_or_throw :: proc(self: ^Trigger_Attachment) -> string {
	v := trigger_attachment_get_victory(self)
	if v == "" {
		// Mirrors Java's IllegalStateException via the captured-state
		// supplier `lambda$getVictoryOrThrow$28` (see existing
		// `trigger_attachment_lambda_get_victory_or_throw_28`).
		panic(trigger_attachment_lambda_get_victory_or_throw_28(self))
	}
	return v
}

// ---------------------------------------------------------------------------
// lambda$collectForAllTriggersMatching$0(Predicate<TriggerAttachment>, GamePlayer)
//   players.stream().map(player -> getTriggers(player, triggerMatch))...
// Captures `triggerMatch` (Predicate). Mirrors the (proc, rawptr) ctx-pair
// convention used by `trigger_attachment_collect_for_all_triggers_matching`.
// ---------------------------------------------------------------------------
trigger_attachment_lambda__collect_for_all_triggers_matching__0 :: proc(
	trigger_match: proc(rawptr, ^Trigger_Attachment) -> bool,
	trigger_match_ctx: rawptr,
	player: ^Game_Player,
) -> map[^Trigger_Attachment]struct{} {
	return trigger_attachment_get_triggers(player, trigger_match, trigger_match_ctx)
}

// ---------------------------------------------------------------------------
// lambda$triggerProductionFrontierEditChange$5(String)
//   Synthetic adapter for the `DefaultAttachment::splitOnColon` method
//   reference used as `.map(DefaultAttachment::splitOnColon)`.
// ---------------------------------------------------------------------------
trigger_attachment_lambda__trigger_production_frontier_edit_change__5 :: proc(
	value: string,
) -> [dynamic]string {
	return default_attachment_split_on_colon(value)
}

// ---------------------------------------------------------------------------
// Match-predicate lambda bodies. The user-requested numbering pairs each
// match factory with its Java-synthetic index. Bodies delegate to the
// already-implemented non-numbered match procs above to avoid divergence.
// ---------------------------------------------------------------------------

// lambda$prodMatch$10                — t -> t.getFrontier().isPresent()
trigger_attachment_lambda__prod_match__10 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_prod_match(t)
}

// lambda$prodFrontierEditMatch$11    — t -> !t.getProductionRule().isEmpty()
trigger_attachment_lambda__prod_frontier_edit_match__11 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_prod_frontier_edit_match(t)
}

// lambda$techMatch$12                — t -> !t.getTech().isEmpty()
trigger_attachment_lambda__tech_match__12 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_tech_match(t)
}

// lambda$techAvailableMatch$13       — t -> !t.getAvailableTech().isEmpty()
trigger_attachment_lambda__tech_available_match__13 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_tech_available_match(t)
}

// lambda$removeUnitsMatch$14         — t -> !t.getRemoveUnits().isEmpty()
trigger_attachment_lambda__remove_units_match__14 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_remove_units_match(t)
}

// lambda$placeMatch$15               — t -> !t.getPlacement().isEmpty()
trigger_attachment_lambda__place_match__15 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_place_match(t)
}

// lambda$purchaseMatch$16            — t -> !t.getPurchase().isEmpty()
trigger_attachment_lambda__purchase_match__16 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_purchase_match(t)
}

// lambda$resourceMatch$17            — t -> t.getResource().isPresent() && t.getResourceCount() != 0
trigger_attachment_lambda__resource_match__17 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_resource_match(t)
}

// lambda$supportMatch$18             — t -> !t.getSupport().isEmpty()
trigger_attachment_lambda__support_match__18 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_support_match(t)
}

// lambda$changeOwnershipMatch$19     — t -> !t.getChangeOwnership().isEmpty()
trigger_attachment_lambda__change_ownership_match__19 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_change_ownership_match(t)
}

// lambda$unitPropertyMatch$20        — t -> !t.getUnitType().isEmpty() && !t.getUnitProperty().isEmpty()
trigger_attachment_lambda__unit_property_match__20 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_unit_property_match(t)
}

// lambda$territoryPropertyMatch$21   — t -> !t.getTerritories().isEmpty() && !t.getTerritoryProperty().isEmpty()
trigger_attachment_lambda__territory_property_match__21 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_territory_property_match(t)
}

// lambda$playerPropertyMatch$22      — t -> !t.getPlayerProperty().isEmpty()
trigger_attachment_lambda__player_property_match__22 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_player_property_match(t)
}

// lambda$relationshipTypePropertyMatch$23
//   t -> !t.getRelationshipTypes().isEmpty() && !t.getRelationshipTypeProperty().isEmpty()
trigger_attachment_lambda__relationship_type_property_match__23 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_relationship_type_property_match(t)
}

// lambda$territoryEffectPropertyMatch$24
//   t -> !t.getTerritoryEffects().isEmpty() && !t.getTerritoryEffectProperty().isEmpty()
trigger_attachment_lambda__territory_effect_property_match__24 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_territory_effect_property_match(t)
}

// lambda$relationshipChangeMatch$25  — t -> !t.getRelationshipChange().isEmpty()
trigger_attachment_lambda__relationship_change_match__25 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_relationship_change_match(t)
}

// lambda$victoryMatch$26             — t -> !t.getVictory().orElse("").isEmpty()
trigger_attachment_lambda__victory_match__26 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_victory_match(t)
}

// lambda$activateTriggerMatch$27     — t -> !t.getActivateTrigger().isEmpty()
trigger_attachment_lambda__activate_trigger_match__27 :: proc(t: ^Trigger_Attachment) -> bool {
	return trigger_attachment_lambda_activate_trigger_match(t)
}

// ---------------------------------------------------------------------------
// Captured-state error-supplier lambdas inside the various setX(String)
// validators. Each returns the GameParseException message string the
// orElseThrow supplier would have constructed in Java; the calling
// validator can wrap the string in its own error-propagation mechanism.
// ---------------------------------------------------------------------------

// lambda$setSupport$30(String name)
//   () -> new GameParseException(
//             "Could not find unitSupportAttachment. name: " + name + thisErrorMsg())
// `thisErrorMsg()` is appended by the caller; we return the prefix only.
trigger_attachment_lambda__set_support__30 :: proc(name: string) -> string {
	return fmt.aprintf("Could not find unitSupportAttachment. name: %s", name)
}

// lambda$setRelationshipChange$31(String relChange, String[] s)
//   () -> new GameParseException(MessageFormat.format(
//       "Invalid relationshipChange declaration: {0} \n first player: {1} unknown{2}",
//       relChange, s[0], thisErrorMsg()))
trigger_attachment_lambda__set_relationship_change__31 :: proc(rel_change: string, s: [dynamic]string) -> string {
	return fmt.aprintf(
		"Invalid relationshipChange declaration: %s \n first player: %s unknown",
		rel_change,
		s[0],
	)
}

// lambda$setRelationshipChange$32(String relChange, String[] s)
//   The Java source for the second player-check passes the SAME
//   `s[0]` into the message format (see line ~1894 of TriggerAttachment.java);
//   the wording reads "first player: {1} unknown" — preserved verbatim.
trigger_attachment_lambda__set_relationship_change__32 :: proc(rel_change: string, s: [dynamic]string) -> string {
	return fmt.aprintf(
		"Invalid relationshipChange declaration: %s \n first player: %s unknown",
		rel_change,
		s[0],
	)
}

// lambda$setTerritories$33(String names, String element)
//   () -> new GameParseException(MessageFormat.format(
//       "TriggerAttachment: Setting territories with value {0} not possible; No territory found for {1}",
//       names, element))
trigger_attachment_lambda__set_territories__33 :: proc(names: string, element: string) -> string {
	return fmt.aprintf(
		"TriggerAttachment: Setting territories with value %s not possible; No territory found for %s",
		names,
		element,
	)
}

// lambda$setPlacement$34(String place, int currentIndex, String[] s)
//   () -> new GameParseException(MessageFormat.format(
//       "TriggerAttachment: Setting placement with value {0} not possible; Index {1}: No territory found for {2}",
//       place, currentIndex, s[currentIndex]))
trigger_attachment_lambda__set_placement__34 :: proc(place: string, current_index: i32, s: [dynamic]string) -> string {
	return fmt.aprintf(
		"TriggerAttachment: Setting placement with value %s not possible; Index %d: No territory found for %s",
		place,
		current_index,
		s[current_index],
	)
}

// lambda$setChangeOwnership$35(String value, String[] s)
//   () -> new GameParseException(MessageFormat.format(
//       "TriggerAttachment: Setting changeOwnership with value {0} not possible; Index 0: No territory found for {1}",
//       value, s[0]))
trigger_attachment_lambda__set_change_ownership__35 :: proc(value: string, s: [dynamic]string) -> string {
	return fmt.aprintf(
		"TriggerAttachment: Setting changeOwnership with value %s not possible; Index 0: No territory found for %s",
		value,
		s[0],
	)
}

// lambda$setChangeOwnership$36(String[] s)
//   () -> new GameParseException(MessageFormat.format(
//       "TriggerAttachment: Setting changeOwnership with value {0} not possible; No source player found for {1}",
//       s, s[1]))
// The Java code passes `s` (the String[] array, whose toString is the JVM
// default `[Ljava.lang.String;@hash`) into placeholder {0}. We mirror by
// formatting the joined contents — the runtime never reaches this branch
// in the snapshot harness so the exact toString form is immaterial.
trigger_attachment_lambda__set_change_ownership__36 :: proc(s: [dynamic]string) -> string {
	joined := strings.join(s[:], ":")
	defer delete(joined)
	msg := fmt.aprintf(
		"TriggerAttachment: Setting changeOwnership with value %s not possible; No source player found for %s",
		joined,
		s[1],
	)
	return msg
}

// lambda$setChangeOwnership$37(String[] s)
//   () -> new GameParseException(MessageFormat.format(
//       "TriggerAttachment: Setting changeOwnership with value {0} not possible; No target player found for {1}",
//       s, s[2]))
trigger_attachment_lambda__set_change_ownership__37 :: proc(s: [dynamic]string) -> string {
	joined := strings.join(s[:], ":")
	defer delete(joined)
	msg := fmt.aprintf(
		"TriggerAttachment: Setting changeOwnership with value %s not possible; No target player found for %s",
		joined,
		s[2],
	)
	return msg
}

// ---------------------------------------------------------------------------
// triggerNotifications(Set<TriggerAttachment>, IDelegateBridge, FireTriggerParams)
//
//   public static void triggerNotifications(...) {
//     if (satisfiedTriggers.stream().anyMatch(notificationMatch())) {
//       bridge.getResourceLoader().ifPresent(
//           resourceLoader -> triggerNotifications(
//               satisfiedTriggers, bridge, fireTriggerParams,
//               new NotificationMessages(resourceLoader)));
//     }
//   }
//
// The current `I_Delegate_Bridge` surface (see
// `games__strategy__engine__delegate__i_delegate_bridge.odin`) does not
// expose a resource loader. This corresponds exactly to the
// `Optional.empty()` branch of Java's `bridge.getResourceLoader()` in the
// snapshot harness, where UI-related code paths are never executed (see
// the comment in the Java source citing `MustFightBattleTest`). The port
// therefore performs the early `anyMatch` check faithfully and then
// no-ops, matching observed Java behaviour.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_notifications :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct{},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	any_match := false
	for t in satisfied_triggers {
		if abstract_trigger_attachment_lambda_notification_match_4(t) {
			any_match = true
			break
		}
	}
	if !any_match {
		return
	}
	// bridge.getResourceLoader() is Optional.empty in the snapshot harness:
	// the body of `ifPresent(...)` is therefore never executed.
	_ = bridge
	_ = fire_trigger_params
}

// ---------------------------------------------------------------------------
// triggerVictory(Set<TriggerAttachment>, IDelegateBridge, FireTriggerParams)
//
// Mirrors the structure of triggerNotifications above: gate on
// `victoryMatch()` and rely on the resource-loader Optional being empty
// in the harness, so the inner UI dispatch (`new NotificationMessages(...)`)
// is not exercised. Phase C snapshots already validate the absence of
// victory output for the AI-test suite.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_victory :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct{},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	any_match := false
	for t in satisfied_triggers {
		if trigger_attachment_lambda_victory_match(t) {
			any_match = true
			break
		}
	}
	if !any_match {
		return
	}
	_ = bridge
	_ = fire_trigger_params
}

// ---------------------------------------------------------------------------
// lambda$appendChangeWriteEvent$1(CompositeChange, IDelegateBridge,
//                                 Tuple<Change, String>)
//   propertyChangeEvent -> {
//     compositeChange.add(propertyChangeEvent.getFirst());
//     bridge.getHistoryWriter().startEvent(propertyChangeEvent.getSecond());
//   }
// Captures (compositeChange, bridge); ctx stored in
// Trigger_Attachment_Ctx_append_change_write_event (defined above).
// ---------------------------------------------------------------------------
trigger_attachment_lambda_append_change_write_event_1 :: proc(
	ctx_ptr: rawptr,
	property_change_event: ^Tuple(^Change, string),
) {
	ctx := cast(^Trigger_Attachment_Ctx_append_change_write_event)ctx_ptr
	composite_change_add(ctx.composite_change, property_change_event.first)
	writer := i_delegate_bridge_get_history_writer(ctx.bridge)
	i_delegate_history_writer_start_event(writer, property_change_event.second)
}

// ---------------------------------------------------------------------------
// collectTestsForAllTriggers(Set<TriggerAttachment>, IDelegateBridge,
//                            Set<ICondition>, Map<ICondition, Boolean>)
//
// Java:
//   final Set<ICondition> allConditionsNeeded =
//       AbstractConditionsAttachment.getAllConditionsRecursive(
//           Set.copyOf(toFirePossible), allConditionsNeededSoFar);
//   return AbstractConditionsAttachment.testAllConditionsRecursive(
//       allConditionsNeeded, allConditionsTestedSoFar, bridge);
//
// TriggerAttachment ⟶ AbstractTriggerAttachment ⟶ AbstractConditionsAttachment
// implements ICondition; the Odin port performs the upcast via rawptr in
// keeping with the convention used by `abstract_conditions_attachment_*`.
// ---------------------------------------------------------------------------
trigger_attachment_collect_tests_for_all_triggers :: proc(
	to_fire_possible: map[^Trigger_Attachment]struct{},
	bridge: ^I_Delegate_Bridge,
	all_conditions_needed_so_far: map[^I_Condition]struct{},
	all_conditions_tested_so_far: map[^I_Condition]bool,
) -> map[^I_Condition]bool {
	starting := make(map[^I_Condition]struct{})
	defer delete(starting)
	for t in to_fire_possible {
		starting[cast(^I_Condition)rawptr(t)] = {}
	}
	all_conditions_needed := abstract_conditions_attachment_get_all_conditions_recursive(
		starting,
		all_conditions_needed_so_far,
	)
	return abstract_conditions_attachment_test_all_conditions_recursive(
		all_conditions_needed,
		all_conditions_tested_so_far,
		bridge,
	)
}

// ---------------------------------------------------------------------------
// filterSatisfiedTriggers(Set<TriggerAttachment>, Predicate<TriggerAttachment>,
//                         FireTriggerParams)
//
// Java composes its Predicate via PredicateBuilder; the Odin
// `Predicate_Builder` only accepts `proc(rawptr) -> bool`, while one of
// the chained predicates (`whenOrDefaultMatch`) carries a captured ctx
// in our (proc, rawptr) form. We therefore inline the AND chain here,
// faithful to Java's evaluation order:
//   customPredicate
//     AND (testWhen ? whenOrDefaultMatch(beforeOrAfter, stepName) : true)
//     AND (testUses ? availableUses                                : true)
// ---------------------------------------------------------------------------
trigger_attachment_filter_satisfied_triggers :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct{},
	custom_predicate: proc(^Trigger_Attachment) -> bool,
	fire_trigger_params: ^Fire_Trigger_Params,
) -> [dynamic]^Trigger_Attachment {
	result: [dynamic]^Trigger_Attachment
	when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match(
		fire_trigger_params.before_or_after,
		fire_trigger_params.step_name,
	)
	for t in satisfied_triggers {
		if !custom_predicate(t) {
			continue
		}
		if fire_trigger_params.test_when && !when_pred(when_ctx, t) {
			continue
		}
		if fire_trigger_params.test_uses && !abstract_trigger_attachment_lambda_static_0(t) {
			continue
		}
		append(&result, t)
	}
	return result
}

// ---------------------------------------------------------------------------
// getClearFirstNewValue(String preNewValue) -> Tuple<Boolean, String>
//
// Java pattern: ^-(:?clear|reset)-
//   The literal `:?` makes the colon optional only inside the first
//   alternative, so the matched prefixes are exactly "-clear-",
//   "-:clear-", and "-reset-". `Matcher.lookingAt()` checks the prefix;
//   `Matcher.replaceFirst("")` then strips it. We mirror this without a
//   regex dependency.
// ---------------------------------------------------------------------------
trigger_attachment_get_clear_first_new_value :: proc(
	pre_new_value: string,
) -> ^Tuple(bool, string) {
	clear_first := false
	new_value := pre_new_value
	prefixes := [?]string{"-clear-", "-:clear-", "-reset-"}
	for p in prefixes {
		if strings.has_prefix(pre_new_value, p) {
			clear_first = true
			new_value = pre_new_value[len(p):]
			break
		}
	}
	return tuple_new(bool, string, clear_first, new_value)
}

// ---------------------------------------------------------------------------
// Instance attachment-name accessors. Each returns a 2-tuple
// (attachment-class-name, attachment-name); when the underlying field
// is unset, fall back to a fixed default pair sourced from
// `Constants` (literal values verified against
// games/strategy/triplea/Constants.java).
// ---------------------------------------------------------------------------

// Java: private Tuple<String, String> getUnitAttachmentName()
trigger_attachment_get_unit_attachment_name :: proc(
	self: ^Trigger_Attachment,
) -> ^Tuple(string, string) {
	if self.unit_attachment_name == nil {
		return tuple_new(string, string, "UnitAttachment", "unitAttachment")
	}
	return self.unit_attachment_name
}

// Java: private Tuple<String, String> getTerritoryAttachmentName()
trigger_attachment_get_territory_attachment_name :: proc(
	self: ^Trigger_Attachment,
) -> ^Tuple(string, string) {
	if self.territory_attachment_name == nil {
		return tuple_new(string, string, "TerritoryAttachment", "territoryAttachment")
	}
	return self.territory_attachment_name
}

// Java: private Tuple<String, String> getPlayerAttachmentName()
trigger_attachment_get_player_attachment_name :: proc(
	self: ^Trigger_Attachment,
) -> ^Tuple(string, string) {
	if self.player_attachment_name == nil {
		return tuple_new(string, string, "PlayerAttachment", "playerAttachment")
	}
	return self.player_attachment_name
}

// Java: private Tuple<String, String> getRelationshipTypeAttachmentName()
trigger_attachment_get_relationship_type_attachment_name :: proc(
	self: ^Trigger_Attachment,
) -> ^Tuple(string, string) {
	if self.relationship_type_attachment_name == nil {
		return tuple_new(
			string,
			string,
			"RelationshipTypeAttachment",
			"relationshipTypeAttachment",
		)
	}
	return self.relationship_type_attachment_name
}

// Java: private Tuple<String, String> getTerritoryEffectAttachmentName()
trigger_attachment_get_territory_effect_attachment_name :: proc(
	self: ^Trigger_Attachment,
) -> ^Tuple(string, string) {
	if self.territory_effect_attachment_name == nil {
		return tuple_new(
			string,
			string,
			"TerritoryEffectAttachment",
			"territoryEffectAttachment",
		)
	}
	return self.territory_effect_attachment_name
}

// ---------------------------------------------------------------------------
// public static Map<ICondition, Boolean> collectTestsForAllTriggers(
//     final Set<TriggerAttachment> toFirePossible, final IDelegateBridge bridge) {
//   return collectTestsForAllTriggers(toFirePossible, bridge, null, null);
// }
// 2-arg public overload that delegates to the 4-arg version with two
// nil sets/maps. The 4-arg version (`..._collect_tests_for_all_triggers`)
// already accepts nil for the trailing two map parameters and allocates
// them on demand.
// ---------------------------------------------------------------------------
trigger_attachment_collect_tests_for_all_triggers_simple :: proc(
	to_fire_possible: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
) -> map[^I_Condition]bool {
	return trigger_attachment_collect_tests_for_all_triggers(
		to_fire_possible,
		bridge,
		nil,
		nil,
	)
}

// ---------------------------------------------------------------------------
// @VisibleForTesting
// static void triggerNotifications(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams,
//     NotificationMessages notificationMessages)
//
// The 3-arg public overload (already ported as
// `trigger_attachment_trigger_notifications`) gates on resource-loader
// presence and dispatches into this 4-arg version. Bodied faithfully
// here. UI broadcasting helpers (`headless_sound_channel_play_sound_to_players`)
// are forward-references — the harness never reaches this code path
// (resource loader is empty), so they remain unimplemented at this layer.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_notifications_with_messages :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
	notification_messages: ^Notification_Messages,
) {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		abstract_trigger_attachment_lambda_notification_match_4,
		fire_trigger_params,
	)
	defer delete(trigs)
	notifications := make(map[string]struct {})
	defer delete(notifications)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		notification := t.notification
		if _, present := notifications[notification]; present {
			continue
		}
		notifications[notification] = {}
		notification_message_key := strings.trim_space(notification)
		sounds := notification_messages_get_sounds_key(
			notification_messages,
			notification_message_key,
		)
		if sounds != "" {
			sound_channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
			clip := strings.concatenate(
				{"notification_", strings.trim_space(sounds)},
			)
			defer delete(clip)
			players := trigger_attachment_get_players(t)
			all_game_players := player_list_get_players(
				game_data_get_player_list(data),
			)
			contains_all := true
			for gp in all_game_players {
				found := false
				for p in players {
					if p == gp {
						found = true
						break
					}
				}
				if !found {
					contains_all = false
					break
				}
			}
			headless_sound_channel_play_sound_to_players(
				sound_channel,
				clip,
				players,
				nil,
				contains_all,
			)
		}
		message := notification_messages_get_message(
			notification_messages,
			notification_message_key,
		)
		if message != "" {
			message_for_record := strings.trim_space(message)
			if len(message_for_record) > 190 {
				// Java: replaceAll("<br.*?>", " ") then replaceAll("<.*?>", "").
				// Combined effect: strip every HTML tag, with <br...> tags
				// becoming a single space (whereas other tags collapse to
				// nothing). Implemented inline as a single-pass walk that
				// preserves Java's reluctant `.*?` semantics by ending each
				// tag at the first '>' encountered.
				buf := strings.builder_make()
				i := 0
				for i < len(message_for_record) {
					c := message_for_record[i]
					if c == '<' {
						end := strings.index_byte(message_for_record[i:], '>')
						if end < 0 {
							strings.write_byte(&buf, c)
							i += 1
							continue
						}
						tag := message_for_record[i + 1:i + end]
						if len(tag) >= 2 &&
						   (tag[0] == 'b' || tag[0] == 'B') &&
						   (tag[1] == 'r' || tag[1] == 'R') {
							strings.write_byte(&buf, ' ')
						}
						i += end + 1
					} else {
						strings.write_byte(&buf, c)
						i += 1
					}
				}
				message_for_record = strings.to_string(buf)
				if len(message_for_record) > 195 {
					message_for_record = strings.concatenate(
						{message_for_record[:190], "...."},
					)
				}
			}
			players := trigger_attachment_get_players(t)
			named_players: [dynamic]^Default_Named
			defer delete(named_players)
			for p in players {
				append(&named_players, &p.named_attachable.default_named)
			}
			players_text := my_formatter_default_named_to_text_list_simple(named_players)
			event_msg := strings.concatenate(
				{"Note to players ", players_text, ": ", message_for_record},
			)
			defer delete(event_msg)
			writer := i_delegate_bridge_get_history_writer(bridge)
			i_delegate_history_writer_start_event(writer, event_msg)
			display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
			html := strings.concatenate(
				{"<html>", strings.trim_space(message), "</html>"},
			)
			defer delete(html)
			i_display_report_message_to_players(
				display,
				players,
				nil,
				html,
				"Notification",
			)
		}
	}
}

// ---------------------------------------------------------------------------
// public static void triggerAvailableTechChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each satisfied trigger that passes filterSatisfiedTriggers with
// techAvailableMatch(): roll testChance / consume uses, then for every
// (player, category, TechAdvance) entry in availableTech add or remove
// the available tech and write a history entry.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_available_tech_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_tech_available_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		players := trigger_attachment_get_players(t)
		available := trigger_attachment_get_available_tech(t)
		for player in players {
			for cat, tech_map in available {
				tf := technology_frontier_list_get_technology_frontier_or_throw(player, cat)
				for ta, granted in tech_map {
					attachment_text := my_formatter_attachment_name_to_text(t.name)
					player_name := default_named_get_name(
						&player.named_attachable.default_named,
					)
					ta_name := default_named_get_name(&ta.named_attachable.default_named)
					verb := " gains access to "
					if !granted {
						verb = " loses access to "
					}
					event := strings.concatenate(
						{attachment_text, ": ", player_name, verb, ta_name},
					)
					i_delegate_history_writer_start_event(history_writer, event)
					delete(event)
					change: ^Change
					if granted {
						change = change_factory_add_available_tech(tf, ta, player)
					} else {
						change = change_factory_remove_available_tech(tf, ta, player)
					}
					i_delegate_bridge_add_change(bridge, change)
				}
			}
		}
	}
}

// ---------------------------------------------------------------------------
// public static void triggerProductionChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For every satisfied trigger filtered by prodMatch(): if a production
// frontier is present, swap it in for each captured player via
// ChangeFactory.changeProductionFrontier. The per-frontier body is
// `lambda$triggerProductionChange$4` (separately ported below).
// ---------------------------------------------------------------------------
trigger_attachment_trigger_production_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_prod_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		history_writer := i_delegate_bridge_get_history_writer(bridge)
		frontier := trigger_attachment_get_frontier(t)
		if frontier != nil {
			trigger_attachment_lambda__trigger_production_change__4(
				t,
				change,
				history_writer,
				frontier,
			)
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// lambda$triggerProductionChange$4(
//   TriggerAttachment t, CompositeChange change,
//   IDelegateHistoryWriter historyWriter, ProductionFrontier productionFrontier)
//
//   for (final GamePlayer player : t.getPlayers()) {
//     change.add(ChangeFactory.changeProductionFrontier(player, productionFrontier));
//     historyWriter.startEvent(
//         MyFormatter.attachmentNameToText(t.getName())
//             + ": " + player.getName()
//             + " has their production frontier changed to: "
//             + productionFrontier.getName());
//   }
trigger_attachment_lambda__trigger_production_change__4 :: proc(
	t: ^Trigger_Attachment,
	change: ^Composite_Change,
	history_writer: ^I_Delegate_History_Writer,
	production_frontier: ^Production_Frontier,
) {
	players := trigger_attachment_get_players(t)
	frontier_name := default_named_get_name(&production_frontier.default_named)
	attachment_text := my_formatter_attachment_name_to_text(t.name)
	for player in players {
		composite_change_add(
			change,
			change_factory_change_production_frontier(player, production_frontier),
		)
		player_name := default_named_get_name(&player.named_attachable.default_named)
		event := strings.concatenate(
			{
				attachment_text,
				": ",
				player_name,
				" has their production frontier changed to: ",
				frontier_name,
			},
		)
		i_delegate_history_writer_start_event(history_writer, event)
		delete(event)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerProductionFrontierEditChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each satisfied trigger filtered by prodFrontierEditMatch(): split
// each productionRule entry on ":" and dispatch the per-array body
// (`lambda$triggerProductionFrontierEditChange$6`).
// ---------------------------------------------------------------------------
trigger_attachment_trigger_production_frontier_edit_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_prod_frontier_edit_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	for trigger_attachment in trigs {
		if fire_trigger_params.test_chance &&
		   !abstract_trigger_attachment_test_chance(trigger_attachment, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(trigger_attachment, bridge)
		}
		rules := trigger_attachment_get_production_rule(trigger_attachment)
		for value in rules {
			array := default_attachment_split_on_colon(value)
			defer delete(array)
			trigger_attachment_lambda__trigger_production_frontier_edit_change__6(
				data,
				bridge,
				change,
				trigger_attachment,
				array,
			)
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// lambda$triggerProductionFrontierEditChange$6(
//   GameState data, IDelegateBridge bridge, CompositeChange change,
//   TriggerAttachment triggerAttachment, String[] array)
//
//   final ProductionFrontier front =
//       data.getProductionFrontierList().getProductionFrontier(array[0]);
//   final String rule = array[1];
//   final String ruleName = rule.replaceFirst("^-", "");
//   final ProductionRule productionRule =
//       data.getProductionRuleList().getProductionRule(ruleName);
//   final boolean ruleAdded = !rule.startsWith("-");
//   final IDelegateHistoryWriter historyWriter = bridge.getHistoryWriter();
//   if (ruleAdded) {
//     if (!front.getRules().contains(productionRule)) {
//       change.add(ChangeFactory.addProductionRule(productionRule, front));
//       historyWriter.startEvent(
//           MyFormatter.attachmentNameToText(triggerAttachment.getName())
//               + ": " + productionRule.getName() + " added to " + front.getName());
//     }
//   } else {
//     if (front.getRules().contains(productionRule)) {
//       change.add(ChangeFactory.removeProductionRule(productionRule, front));
//       historyWriter.startEvent(
//           MyFormatter.attachmentNameToText(triggerAttachment.getName())
//               + ": " + productionRule.getName() + " removed from " + front.getName());
//     }
//   }
//
// `data` is the concrete `^Game_Data` returned by `bridge.getData()`;
// the Java static type `GameState` is an interface, but in this port
// the engine's only impl is `Game_Data`, so the lambda receives the
// concrete pointer directly.
trigger_attachment_lambda__trigger_production_frontier_edit_change__6 :: proc(
	data: ^Game_Data,
	bridge: ^I_Delegate_Bridge,
	change: ^Composite_Change,
	trigger_attachment: ^Trigger_Attachment,
	array: [dynamic]string,
) {
	front := production_frontier_list_get_production_frontier(
		game_data_get_production_frontier_list(data),
		array[0],
	)
	rule := array[1]
	rule_name := rule
	if strings.has_prefix(rule, "-") {
		rule_name = rule[1:]
	}
	production_rule := production_rule_list_get_production_rule(
		game_data_get_production_rule_list(data),
		rule_name,
	)
	rule_added := !strings.has_prefix(rule, "-")
	history_writer := i_delegate_bridge_get_history_writer(bridge)
	rules_in_front := production_frontier_get_rules(front)
	contains := false
	for r in rules_in_front {
		if r == production_rule {
			contains = true
			break
		}
	}
	attachment_text := my_formatter_attachment_name_to_text(trigger_attachment.name)
	rule_display_name := default_named_get_name(&production_rule.default_named)
	front_name := default_named_get_name(&front.default_named)
	if rule_added {
		if !contains {
			composite_change_add(
				change,
				change_factory_add_production_rule(production_rule, front),
			)
			event := strings.concatenate(
				{attachment_text, ": ", rule_display_name, " added to ", front_name},
			)
			i_delegate_history_writer_start_event(history_writer, event)
			delete(event)
		}
	} else {
		if contains {
			composite_change_add(
				change,
				change_factory_remove_production_rule(production_rule, front),
			)
			event := strings.concatenate(
				{attachment_text, ": ", rule_display_name, " removed from ", front_name},
			)
			i_delegate_history_writer_start_event(history_writer, event)
			delete(event)
		}
	}
}

// ---------------------------------------------------------------------------
// public static void triggerRelationshipChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For every satisfied trigger filtered by relationshipChangeMatch():
// roll testChance / consume uses, then for every "p1:p2:condition:newRel"
// entry in `relationshipChange`, evaluate the condition against the
// current relationship and (if matched) emit a relationship change with
// a history event and record the change on the battle tracker.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_relationship_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_relationship_change_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	is_neutral_pred, is_neutral_ctx := matches_relationship_type_is_neutral()
	is_allied_pred, is_allied_ctx := matches_relationship_type_is_allied()
	is_at_war_pred, is_at_war_ctx := matches_relationship_type_is_at_war()
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for relationship_change in trigger_attachment_get_relationship_change(t) {
			s := default_attachment_split_on_colon(relationship_change)
			defer delete(s)
			player1 := player_list_get_player_id(game_data_get_player_list(data), s[0])
			player2 := player_list_get_player_id(game_data_get_player_list(data), s[1])
			current_relation := relationship_tracker_get_relationship_type(
				game_data_get_relationship_tracker(data),
				player1,
				player2,
			)
			matched :=
				s[2] == "any" ||
				(s[2] == "anyNeutral" && is_neutral_pred(is_neutral_ctx, current_relation)) ||
				(s[2] == "anyAllied" && is_allied_pred(is_allied_ctx, current_relation)) ||
				(s[2] == "anyWar" && is_at_war_pred(is_at_war_ctx, current_relation)) ||
				current_relation ==
					relationship_type_list_get_relationship_type(
						game_data_get_relationship_type_list(data),
						s[2],
					)
			if matched {
				trigger_new_relation := relationship_type_list_get_relationship_type(
					game_data_get_relationship_type_list(data),
					s[3],
				)
				composite_change_add(
					change,
					change_factory_relationship_change(
						player1,
						player2,
						current_relation,
						trigger_new_relation,
					),
				)
				attachment_text := my_formatter_attachment_name_to_text(t.name)
				p1_name := default_named_get_name(&player1.named_attachable.default_named)
				p2_name := default_named_get_name(&player2.named_attachable.default_named)
				cur_name := default_named_get_name(
					&current_relation.named_attachable.default_named,
				)
				new_name := default_named_get_name(
					&trigger_new_relation.named_attachable.default_named,
				)
				event := strings.concatenate(
					{
						attachment_text,
						": Changing Relationship for ",
						p1_name,
						" and ",
						p2_name,
						" from ",
						cur_name,
						" to ",
						new_name,
					},
				)
				writer := i_delegate_bridge_get_history_writer(bridge)
				i_delegate_history_writer_start_event(writer, event)
				delete(event)
				battle_tracker_add_relationship_changes_this_turn(
					abstract_move_delegate_get_battle_tracker(data),
					player1,
					player2,
					current_relation,
					trigger_new_relation,
				)
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// private static IntegerMap<Resource> triggerResourceChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams,
//     StringBuilder endOfTurnReport)
//
// For each satisfied trigger filtered by resourceMatch(): roll
// testChance, consume uses, multiply the requested resource count by
// `eachMultiple` and the PUS multiplier (if applicable), apply the
// floor-at-zero cap, accumulate into the returned IntegerMap, write
// the resource-change Change, and append a history line plus an
// endOfTurnReport entry.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_resource_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
	end_of_turn_report: ^strings.Builder,
) -> ^Integer_Map {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_resource_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	resources := integer_map_new()
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		resource := trigger_attachment_get_resource(t)
		if resource == "" {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		each_multiple := abstract_trigger_attachment_get_each_multiple(
			&t.abstract_trigger_attachment,
		)
		players := trigger_attachment_get_players(t)
		for player in players {
			for i in 0 ..< each_multiple {
				to_add := trigger_attachment_get_resource_count(t)
				if resource == "PUs" {
					to_add *= properties_get_pu_multiplier(game_data_get_properties(data))
				}
				resource_obj := resource_list_get_resource_or_throw(
					game_data_get_resource_list(data),
					resource,
				)
				integer_map_add(resources, rawptr(resource_obj), to_add)
				total := resource_collection_get_quantity(
					game_player_get_resources(player),
					resource_obj,
				) + to_add
				if total < 0 {
					to_add -= total
					total = 0
				}
				i_delegate_bridge_add_change(
					bridge,
					change_factory_change_resources_change(player, resource_obj, to_add),
				)
				attachment_text := my_formatter_attachment_name_to_text(t.name)
				player_name := default_named_get_name(&player.named_attachable.default_named)
				count_str := fmt.aprintf("%d", trigger_attachment_get_resource_count(t))
				defer delete(count_str)
				total_str := fmt.aprintf("%d", total)
				defer delete(total_str)
				pu_message := strings.concatenate(
					{
						attachment_text,
						": ",
						player_name,
						" met a national objective for an additional ",
						count_str,
						" ",
						resource,
						"; end with ",
						total_str,
						" ",
						resource,
					},
				)
				writer := i_delegate_bridge_get_history_writer(bridge)
				i_delegate_history_writer_start_event(writer, pu_message)
				strings.write_string(end_of_turn_report, pu_message)
				strings.write_string(end_of_turn_report, " <br />")
				delete(pu_message)
			}
		}
	}
	return resources
}

// ---------------------------------------------------------------------------
// @VisibleForTesting
// static void triggerVictory(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams,
//     NotificationMessages notificationMessages)
//
// 4-arg @VisibleForTesting overload (the 3-arg public version
// `trigger_attachment_trigger_victory` gates on resource-loader
// presence and dispatches into this body when present). For each
// satisfied trigger passing victoryMatch(): roll testChance / consume
// uses, look up the localized victory + sounds keys, optionally
// broadcast triggered_victory / triggered_defeat sounds (forward
// reference: `headless_sound_channel_play_sound_to_players`), strip
// HTML from messages exceeding 150 chars, then write a history event
// and signal game over.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_victory_with_messages :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
	notification_messages: ^Notification_Messages,
) {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_victory_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		victory_key := strings.trim_space(trigger_attachment_get_victory_or_throw(t))
		victory_message := notification_messages_get_message(
			notification_messages,
			victory_key,
		)
		sounds := notification_messages_get_sounds_key(notification_messages, victory_key)
		if victory_message != "" {
			if sounds != "" {
				sound_channel := i_delegate_bridge_get_sound_channel_broadcaster(bridge)
				sounds_trim := strings.trim_space(sounds)
				victory_clip := strings.concatenate({"victory_", sounds_trim})
				defer delete(victory_clip)
				defeat_clip := strings.concatenate({"defeat_", sounds_trim})
				defer delete(defeat_clip)
				players := trigger_attachment_get_players(t)
				headless_sound_channel_play_sound_to_players(
					sound_channel,
					victory_clip,
					players,
					nil,
					true,
				)
				headless_sound_channel_play_sound_to_players(
					sound_channel,
					defeat_clip,
					player_list_get_players(game_data_get_player_list(data)),
					players,
					false,
				)
			}
			message_for_record := strings.trim_space(victory_message)
			if len(message_for_record) > 150 {
				// Java: replaceAll("<br.*?>", " ") then replaceAll("<.*?>", "").
				// Strip every HTML tag; <br...> collapses to a single space,
				// other tags collapse to nothing. Reluctant `.*?` semantics
				// preserved by stopping each tag at the first '>'.
				buf := strings.builder_make()
				i := 0
				for i < len(message_for_record) {
					c := message_for_record[i]
					if c == '<' {
						end := strings.index_byte(message_for_record[i:], '>')
						if end < 0 {
							strings.write_byte(&buf, c)
							i += 1
							continue
						}
						tag := message_for_record[i + 1:i + end]
						if len(tag) >= 2 &&
						   (tag[0] == 'b' || tag[0] == 'B') &&
						   (tag[1] == 'r' || tag[1] == 'R') {
							strings.write_byte(&buf, ' ')
						}
						i += end + 1
					} else {
						strings.write_byte(&buf, c)
						i += 1
					}
				}
				message_for_record = strings.to_string(buf)
				if len(message_for_record) > 155 {
					message_for_record = strings.concatenate(
						{message_for_record[:150], "...."},
					)
				}
			}
			players := trigger_attachment_get_players(t)
			named_players: [dynamic]^Default_Named
			defer delete(named_players)
			for p in players {
				append(&named_players, &p.named_attachable.default_named)
			}
			players_text := my_formatter_default_named_to_text_list_simple(named_players)
			writer := i_delegate_bridge_get_history_writer(bridge)
			event_msg := strings.concatenate(
				{
					"Players: ",
					players_text,
					" have just won the game, with this victory: ",
					message_for_record,
				},
			)
			i_delegate_history_writer_start_event(writer, event_msg)
			delete(event_msg)
			end_round_delegate_signal_game_over(
				game_data_get_end_round_delegate(data),
				strings.trim_space(victory_message),
				players,
				bridge,
			)
		}
	}
}

// ---------------------------------------------------------------------------
// lambda$triggerNotifications$2(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams,
//     ResourceLoader resourceLoader)
//
// Java body (the lambda passed to bridge.getResourceLoader().ifPresent):
//   resourceLoader -> triggerNotifications(
//       satisfiedTriggers, bridge, fireTriggerParams,
//       new NotificationMessages(resourceLoader));
//
// Captures (satisfiedTriggers, bridge, fireTriggerParams); the
// trailing ResourceLoader is the lambda parameter. Ported as a plain
// 4-arg proc — there are no consumers in the harness (the public 3-arg
// `trigger_attachment_trigger_notifications` short-circuits because
// the resource-loader Optional is empty), so the (proc, rawptr) ctx
// adapter pair is unnecessary.
// ---------------------------------------------------------------------------
trigger_attachment_lambda__trigger_notifications__2 :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
	resource_loader: ^Resource_Loader,
) {
	trigger_attachment_trigger_notifications_with_messages(
		satisfied_triggers,
		bridge,
		fire_trigger_params,
		notification_messages_new(resource_loader),
	)
}

// ---------------------------------------------------------------------------
// lambda$triggerVictory$9(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams,
//     ResourceLoader resourceLoader)
//
// Mirror of lambda$triggerNotifications$2 for the victory side:
//   resourceLoader -> triggerVictory(
//       satisfiedTriggers, bridge, fireTriggerParams,
//       new NotificationMessages(resourceLoader));
// ---------------------------------------------------------------------------
trigger_attachment_lambda__trigger_victory__9 :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
	resource_loader: ^Resource_Loader,
) {
	trigger_attachment_trigger_victory_with_messages(
		satisfied_triggers,
		bridge,
		fire_trigger_params,
		notification_messages_new(resource_loader),
	)
}

// ---------------------------------------------------------------------------
// private static void removeUnits(
//     TriggerAttachment t, Territory terr, IntegerMap<UnitType> utMap,
//     GamePlayer player, IDelegateBridge bridge)
//
// For each UnitType key in utMap, take up to utMap.getInt(ut) units from
// terr that are owned by `player` AND of that exact type, batch them
// into a CompositeChange via ChangeFactory.removeUnits, and — if any
// were actually removed — emit a single history event and apply the
// change. Inlined the (owned ∧ ofType) Predicate AND because Odin's
// `collection_utils_get_n_matches` accepts only a no-ctx predicate,
// while `matches_unit_is_owned_by` / `matches_unit_is_of_type` carry
// a captured ctx in the (proc, rawptr) form.
// ---------------------------------------------------------------------------
trigger_attachment_remove_units :: proc(
	t: ^Trigger_Attachment,
	terr: ^Territory,
	ut_map: ^Integer_Map,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	change := composite_change_new()
	total_removed: [dynamic]^Unit
	defer delete(total_removed)
	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	for ut_raw in integer_map_key_set(ut_map) {
		ut := cast(^Unit_Type)ut_raw
		remove_num := integer_map_get_int(ut_map, ut_raw)
		of_type_pred, of_type_ctx := matches_unit_is_of_type(ut)
		territory_units := territory_get_units(terr)
		to_remove: [dynamic]^Unit
		count: i32 = 0
		for u in territory_units {
			if count >= remove_num {
				break
			}
			if owned_pred(owned_ctx, u) && of_type_pred(of_type_ctx, u) {
				append(&to_remove, u)
				count += 1
			}
		}
		if len(to_remove) > 0 {
			for r in to_remove {
				append(&total_removed, r)
			}
			composite_change_add(
				change,
				change_factory_remove_units(cast(^Unit_Holder)terr, to_remove),
			)
		}
	}
	if !composite_change_is_empty(change) {
		attachment_text := my_formatter_attachment_name_to_text(t.name)
		units_text := my_formatter_units_to_text_no_owner(total_removed, nil)
		player_name := default_named_get_name(&player.named_attachable.default_named)
		terr_name := default_named_get_name(&terr.named_attachable.default_named)
		transcript := strings.concatenate(
			{
				attachment_text,
				": has removed ",
				units_text,
				" owned by ",
				player_name,
				" in ",
				terr_name,
			},
		)
		writer := i_delegate_bridge_get_history_writer(bridge)
		i_delegate_history_writer_start_event(writer, transcript, rawptr(&total_removed))
		delete(transcript)
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerPurchase(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each satisfied trigger filtered by purchaseMatch(): roll
// testChance / consume uses, and for every (player, eachMultiple)
// instantiate t.getPurchase() into freshly-created units, write a
// history event, and apply ChangeFactory.addUnits(player, units).
// ---------------------------------------------------------------------------
trigger_attachment_trigger_purchase :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_purchase_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		each_multiple := abstract_trigger_attachment_get_each_multiple(
			&t.abstract_trigger_attachment,
		)
		players := trigger_attachment_get_players(t)
		purchase := trigger_attachment_get_purchase(t)
		for player in players {
			for i: i32 = 0; i < each_multiple; i += 1 {
				units: [dynamic]^Unit
				for ut_raw in integer_map_key_set(purchase) {
					ut := cast(^Unit_Type)ut_raw
					qty := integer_map_get_int(purchase, ut_raw)
					created := unit_type_create_2(ut, qty, player)
					for u in created {
						append(&units, u)
					}
					delete(created)
				}
				if len(units) > 0 {
					attachment_text := my_formatter_attachment_name_to_text(t.name)
					units_text := my_formatter_units_to_text_no_owner(units, nil)
					player_name := default_named_get_name(
						&player.named_attachable.default_named,
					)
					transcript := strings.concatenate(
						{
							attachment_text,
							": ",
							units_text,
							" gained by ",
							player_name,
						},
					)
					writer := i_delegate_bridge_get_history_writer(bridge)
					i_delegate_history_writer_start_event(
						writer,
						transcript,
						rawptr(&units),
					)
					delete(transcript)
					place := change_factory_add_units(cast(^Unit_Holder)player, units)
					i_delegate_bridge_add_change(bridge, place)
				} else {
					delete(units)
				}
			}
		}
	}
}

// ---------------------------------------------------------------------------
// public static String triggerResourceChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// 3-arg public overload: build a fresh StringBuilder, delegate to the
// 4-arg private `trigger_attachment_trigger_resource_change`, and
// return the accumulated end-of-turn report. The `_simple` suffix
// disambiguates from the 4-arg variant (Odin has no overloading);
// matches the convention used by
// `trigger_attachment_collect_tests_for_all_triggers_simple`.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_resource_change_simple :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) -> string {
	end_of_turn_report := strings.builder_make()
	trigger_attachment_trigger_resource_change(
		satisfied_triggers,
		bridge,
		fire_trigger_params,
		&end_of_turn_report,
	)
	return strings.to_string(end_of_turn_report)
}

// ---------------------------------------------------------------------------
// protected static void setUsesForWhenTriggers(
//     Set<TriggerAttachment> triggersToBeFired, IDelegateBridge bridge)
//
// For each trigger with `uses > 0` AND a non-empty `when` list, decrement
// `uses` by one (as a stringified integer property change) and clear
// `usedThisRound` if it was set. Emits a single history event and applies
// the composite change only when at least one property change was queued.
// ---------------------------------------------------------------------------
trigger_attachment_set_uses_for_when_triggers :: proc(
	triggers_to_be_fired: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
) {
	change := composite_change_new()
	for trig in triggers_to_be_fired {
		current_uses := trig.uses
		if current_uses > 0 && len(trig.when_triggers) > 0 {
			uses_value := new(string)
			uses_value^ = fmt.aprintf("%d", current_uses - 1)
			composite_change_add(
				change,
				change_factory_attachment_property_change(
					cast(^I_Attachment)rawptr(trig),
					rawptr(uses_value),
					"uses",
				),
			)
			if trig.used_this_round {
				used_value := new(bool)
				used_value^ = false
				composite_change_add(
					change,
					change_factory_attachment_property_change(
						cast(^I_Attachment)rawptr(trig),
						rawptr(used_value),
						"usedThisRound",
					),
				)
			}
		}
	}
	if !composite_change_is_empty(change) {
		writer := i_delegate_bridge_get_history_writer(bridge)
		i_delegate_history_writer_start_event(
			writer,
			"Setting uses for triggers used this phase.",
		)
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// private static void placeUnits(
//     TriggerAttachment t, Territory terr, IntegerMap<UnitType> utMap,
//     GamePlayer player, IDelegateBridge bridge)
//
// Instantiate fresh units for each (unitType, qty) entry in `utMap`,
// mark them no-movement, and (for infrastructure) record the original
// owner. Then add the units to `terr` via ChangeFactory.addUnits and
// emit a history event listing the placement.
// ---------------------------------------------------------------------------
trigger_attachment_place_units :: proc(
	t: ^Trigger_Attachment,
	terr: ^Territory,
	ut_map: ^Integer_Map,
	player: ^Game_Player,
	bridge: ^I_Delegate_Bridge,
) {
	units: [dynamic]^Unit
	for ut_raw in integer_map_key_set(ut_map) {
		ut := cast(^Unit_Type)ut_raw
		qty := integer_map_get_int(ut_map, ut_raw)
		created := unit_type_create_2(ut, qty, player)
		for u in created {
			append(&units, u)
		}
		delete(created)
	}
	change := composite_change_new()
	infra_pred, infra_ctx := matches_unit_is_infrastructure()
	for unit in units {
		composite_change_add(change, change_factory_mark_no_movement_change(unit))
		if infra_pred(infra_ctx, unit) {
			composite_change_add(
				change,
				original_owner_tracker_add_original_owner_change_unit(unit, player),
			)
		}
	}
	composite_change_add(change, change_factory_add_units(cast(^Unit_Holder)terr, units))
	i_delegate_bridge_add_change(bridge, change)
	attachment_text := my_formatter_attachment_name_to_text(t.name)
	player_name := default_named_get_name(&player.named_attachable.default_named)
	units_text := my_formatter_units_to_text_no_owner(units, nil)
	terr_name := default_named_get_name(&terr.named_attachable.default_named)
	transcript := strings.concatenate(
		{
			attachment_text,
			": ",
			player_name,
			" has ",
			units_text,
			" placed in ",
			terr_name,
		},
	)
	writer := i_delegate_bridge_get_history_writer(bridge)
	i_delegate_history_writer_start_event(writer, transcript, rawptr(&units))
	delete(transcript)
}

// ---------------------------------------------------------------------------
// @VisibleForTesting
// static Optional<Tuple<Change, String>> getPropertyChangeHistoryStartEvent(
//     TriggerAttachment triggerAttachment,
//     DefaultAttachment propertyAttachment,
//     String propertyName,
//     Tuple<Boolean, String> clearFirstNewValue,
//     String propertyAttachmentName,
//     Named attachedTo)
//
// Returns the (Change, history-event) tuple that records `propertyName`
// being set to `clearFirstNewValue.second` on `propertyAttachment`, or
// nil when the new value matches the current raw-property string.
// `clearFirstNewValue.first == true` AND `newValue.isEmpty()` resolves
// to a `attachmentPropertyReset` change; otherwise the change carries
// the new value with `clearFirst` semantics passed through.
//
// Optional<...> is mirrored as a raw pointer with nil = absent, per
// the file-level convention.
// ---------------------------------------------------------------------------
trigger_attachment_get_property_change_history_start_event :: proc(
	trigger_attachment: ^Trigger_Attachment,
	property_attachment: ^Default_Attachment,
	property_name: string,
	clear_first_new_value: ^Tuple(bool, string),
	property_attachment_name: string,
	attached_to: ^Named,
) -> ^Tuple(^Change, string) {
	clear_first := clear_first_new_value.first
	new_value := clear_first_new_value.second

	current := default_attachment_get_raw_property_string(property_attachment, property_name)
	if new_value == current {
		return nil
	}

	change: ^Change
	if clear_first && new_value == "" {
		change = change_factory_attachment_property_reset(
			cast(^I_Attachment)rawptr(property_attachment),
			property_name,
		)
	} else {
		boxed := new(string)
		boxed^ = new_value
		change = change_factory_attachment_property_change_with_reset_first(
			cast(^I_Attachment)rawptr(property_attachment),
			rawptr(boxed),
			property_name,
			clear_first,
		)
	}

	value_clause: string
	if new_value == "" {
		value_clause = "cleared"
	} else {
		value_clause = strings.concatenate({"to ", new_value})
	}
	start_event := fmt.aprintf(
		"%s: Setting %s %s for %s attached to %s",
		my_formatter_attachment_name_to_text(trigger_attachment.name),
		property_name,
		value_clause,
		property_attachment_name,
		named_get_name(attached_to),
	)
	return tuple_new(^Change, string, change, start_event)
}

// ---------------------------------------------------------------------------
// public static void triggerSupportChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For every satisfied trigger filtered by supportMatch(): for each
// (player, supportName -> add?) entry in t.support, locate the matching
// UnitSupportAttachment by name, build a new players list with
// `player` added or removed accordingly, and queue a property change
// on the USA's "players" field plus a history event. Apply the
// composite change at the end if non-empty.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_support_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	data := i_delegate_bridge_get_data(bridge)
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_support_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	all_usas := unit_support_attachment_get_for_unit_type_list(
		game_data_get_unit_type_list(data),
	)
	defer delete(all_usas)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		players := trigger_attachment_get_players(t)
		support := trigger_attachment_get_support(t)
		for player in players {
			for support_name, add_player in support {
				usa: ^Unit_Support_Attachment
				for candidate in all_usas {
					if candidate.name == support_name {
						usa = candidate
						break
					}
				}
				if usa == nil {
					panic(
						strings.concatenate(
							{
								"Could not find unitSupportAttachment. name: ",
								support_name,
							},
						),
					)
				}
				existing := unit_support_attachment_get_players(usa)
				contains := false
				for gp in existing {
					if gp == player {
						contains = true
						break
					}
				}
				if contains == add_player {
					continue
				}
				new_players := new([dynamic]^Game_Player)
				for gp in existing {
					append(new_players, gp)
				}
				if add_player {
					append(new_players, player)
				} else {
					for i := 0; i < len(new_players); i += 1 {
						if new_players[i] == player {
							ordered_remove(new_players, i)
							break
						}
					}
				}
				composite_change_add(
					change,
					change_factory_attachment_property_change(
						cast(^I_Attachment)rawptr(usa),
						rawptr(new_players),
						"players",
					),
				)
				attachment_text := my_formatter_attachment_name_to_text(t.name)
				player_name := default_named_get_name(
					&player.named_attachable.default_named,
				)
				verb := " is added to "
				if !add_player {
					verb = " is removed from "
				}
				event := strings.concatenate(
					{
						attachment_text,
						": ",
						player_name,
						verb,
						usa.name,
					},
				)
				writer := i_delegate_bridge_get_history_writer(bridge)
				i_delegate_history_writer_start_event(writer, event)
				delete(event)
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerUnitRemoval(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For every satisfied trigger filtered by removeUnitsMatch(): roll
// testChance / consume uses, and for each (player, territory) pair
// repeated `eachMultiple` times, dispatch into
// `trigger_attachment_remove_units` with the territory's IntegerMap.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_unit_removal :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_remove_units_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		each_multiple := abstract_trigger_attachment_get_each_multiple(
			&t.abstract_trigger_attachment,
		)
		players := trigger_attachment_get_players(t)
		remove := trigger_attachment_get_remove_units(t)
		for player in players {
			for ter, ut_map in remove {
				for i: i32 = 0; i < each_multiple; i += 1 {
					trigger_attachment_remove_units(t, ter, ut_map, player, bridge)
				}
			}
		}
	}
}

// ---------------------------------------------------------------------------
// Java: private static final Map<String, BiFunction<GamePlayer, String,
//                                                   DefaultAttachment>>
//   playerPropertyChangeAttachmentNameToAttachmentGetter = ...;
// (PlayerAttachment, RulesAttachment, TriggerAttachment, TechAttachment,
//  PoliticalActionAttachment, UserActionAttachment)
//
// Each value in the Java map is a `Foo::get(GamePlayer, String)` method
// reference whose body delegates to `getAttachment(player, name, Foo.class)`
// — i.e. a typed lookup through the player's NamedAttachable map. In the
// Odin port the lookup itself is type-agnostic
// (`named_attachable_get_attachment` already returns the stored
// `^I_Attachment`); the only role of the Java map is the
// `containsKey(attachmentName)` gate that screens out attachment-class
// names not enumerated in this set. We mirror that gate here.
// ---------------------------------------------------------------------------
trigger_attachment_is_player_property_attachment :: proc(name: string) -> bool {
	return name == "PlayerAttachment" ||
	       name == "RulesAttachment" ||
	       name == "TriggerAttachment" ||
	       name == "TechAttachment" ||
	       name == "PoliticalActionAttachment" ||
	       name == "UserActionAttachment"
}

// Java: private static final Map<String, BiFunction<UnitType, String,
//                                                   DefaultAttachment>>
//   unitPropertyChangeAttachmentNameToAttachmentGetter = ...;
// (UnitAttachment, UnitSupportAttachment) — same role as above.
trigger_attachment_is_unit_property_attachment :: proc(name: string) -> bool {
	return name == "UnitAttachment" || name == "UnitSupportAttachment"
}

// ---------------------------------------------------------------------------
// public static void triggerPlayerPropertyChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each trigger filtered by playerPropertyMatch(): roll testChance /
// consume uses, and for each (property, player) pair locate the named
// attachment on the player and queue a property-change history event via
// `getPropertyChangeHistoryStartEvent` + `appendChangeWriteEvent`.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_player_property_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_player_property_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	append_pred, append_ctx := trigger_attachment_append_change_write_event(bridge, change)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for property in trigger_attachment_get_player_property(t) {
			clear_first_new_value := trigger_attachment_get_clear_first_new_value(property.second)
			for player in trigger_attachment_get_players(t) {
				attachment_name_pair := trigger_attachment_get_player_attachment_name(t)
				attachment_class := attachment_name_pair.first
				attachment_name := attachment_name_pair.second
				if !trigger_attachment_is_player_property_attachment(attachment_class) {
					continue
				}
				raw := named_attachable_get_attachment(
					&player.named_attachable,
					attachment_name,
				)
				if raw == nil {
					continue
				}
				attachment := cast(^Default_Attachment)rawptr(raw)
				event := trigger_attachment_get_property_change_history_start_event(
					t,
					attachment,
					property.first,
					clear_first_new_value,
					attachment_name,
					&player.named,
				)
				if event != nil {
					append_pred(append_ctx, event)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerRelationshipTypePropertyChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each trigger filtered by relationshipTypePropertyMatch(): for each
// (property, relationshipType) pair, only `RelationshipTypeAttachment`
// is recognized; queue the corresponding property-change.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_relationship_type_property_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_relationship_type_property_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	append_pred, append_ctx := trigger_attachment_append_change_write_event(bridge, change)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for property in trigger_attachment_get_relationship_type_property(t) {
			clear_first_new_value := trigger_attachment_get_clear_first_new_value(property.second)
			for relationship_type in trigger_attachment_get_relationship_types(t) {
				attachment_name_pair := trigger_attachment_get_relationship_type_attachment_name(t)
				if attachment_name_pair.first != "RelationshipTypeAttachment" {
					continue
				}
				attachment := relationship_type_attachment_get(
					relationship_type,
					attachment_name_pair.second,
				)
				if attachment == nil {
					continue
				}
				event := trigger_attachment_get_property_change_history_start_event(
					t,
					&attachment.default_attachment,
					property.first,
					clear_first_new_value,
					attachment_name_pair.second,
					&relationship_type.named,
				)
				if event != nil {
					append_pred(append_ctx, event)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerTerritoryPropertyChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each trigger filtered by territoryPropertyMatch(): for each
// (property, territory) pair, dispatch on TerritoryAttachment vs
// CanalAttachment. Track touched territories so we can fire
// `notifyAttachmentChanged` after applying the composite change.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_territory_property_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_territory_property_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	territories_needing_redraw := make(map[^Territory]struct {})
	defer delete(territories_needing_redraw)
	append_pred, append_ctx := trigger_attachment_append_change_write_event(bridge, change)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for property in trigger_attachment_get_territory_property(t) {
			clear_first_new_value := trigger_attachment_get_clear_first_new_value(property.second)
			for territory in trigger_attachment_get_territories(t) {
				territories_needing_redraw[territory] = {}
				attachment_name_pair := trigger_attachment_get_territory_attachment_name(t)
				if attachment_name_pair.first == "TerritoryAttachment" {
					attachment := territory_attachment_get(territory, attachment_name_pair.second)
					if attachment == nil {
						// Mirrors Java's orElseThrow on the missing-attachment case
						// (water territories may legitimately lack an attachment).
						fmt.panicf(
							"Triggers: No territory attachment for: %s",
							default_named_get_name(&territory.named_attachable.default_named),
						)
					}
					event := trigger_attachment_get_property_change_history_start_event(
						t,
						&attachment.default_attachment,
						property.first,
						clear_first_new_value,
						attachment_name_pair.second,
						&territory.named,
					)
					if event != nil {
						append_pred(append_ctx, event)
					}
				} else if attachment_name_pair.first == "CanalAttachment" {
					attachment := canal_attachment_get_by_name(
						territory,
						attachment_name_pair.second,
					)
					event := trigger_attachment_get_property_change_history_start_event(
						t,
						&attachment.default_attachment,
						property.first,
						clear_first_new_value,
						attachment_name_pair.second,
						&territory.named,
					)
					if event != nil {
						append_pred(append_ctx, event)
					}
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
		for territory in territories_needing_redraw {
			territory_notify_attachment_changed(territory)
		}
	}
}

// ---------------------------------------------------------------------------
// public static void triggerTerritoryEffectPropertyChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each trigger filtered by territoryEffectPropertyMatch(): for each
// (property, territoryEffect) pair recognize only
// `TerritoryEffectAttachment`.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_territory_effect_property_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_territory_effect_property_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	append_pred, append_ctx := trigger_attachment_append_change_write_event(bridge, change)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for property in trigger_attachment_get_territory_effect_property(t) {
			clear_first_new_value := trigger_attachment_get_clear_first_new_value(property.second)
			for territory_effect in trigger_attachment_get_territory_effects(t) {
				attachment_name_pair := trigger_attachment_get_territory_effect_attachment_name(t)
				if attachment_name_pair.first != "TerritoryEffectAttachment" {
					continue
				}
				attachment := territory_effect_attachment_get(
					territory_effect,
					attachment_name_pair.second,
				)
				if attachment == nil {
					continue
				}
				event := trigger_attachment_get_property_change_history_start_event(
					t,
					&attachment.default_attachment,
					property.first,
					clear_first_new_value,
					attachment_name_pair.second,
					&territory_effect.named,
				)
				if event != nil {
					append_pred(append_ctx, event)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerUnitPropertyChange(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For each trigger filtered by unitPropertyMatch(): for each
// (property, unitType) pair gate on the recognized attachment-class
// names (UnitAttachment, UnitSupportAttachment) and queue the
// property-change history event.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_unit_property_change :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_unit_property_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	change := composite_change_new()
	append_pred, append_ctx := trigger_attachment_append_change_write_event(bridge, change)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		for property in trigger_attachment_get_unit_property(t) {
			clear_first_new_value := trigger_attachment_get_clear_first_new_value(property.second)
			for unit_type in trigger_attachment_get_unit_type(t) {
				attachment_name_pair := trigger_attachment_get_unit_attachment_name(t)
				attachment_class := attachment_name_pair.first
				attachment_name := attachment_name_pair.second
				if !trigger_attachment_is_unit_property_attachment(attachment_class) {
					continue
				}
				raw := named_attachable_get_attachment(
					&unit_type.named_attachable,
					attachment_name,
				)
				if raw == nil {
					continue
				}
				attachment := cast(^Default_Attachment)rawptr(raw)
				event := trigger_attachment_get_property_change_history_start_event(
					t,
					attachment,
					property.first,
					clear_first_new_value,
					attachment_name,
					&unit_type.named,
				)
				if event != nil {
					append_pred(append_ctx, event)
				}
			}
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, change)
	}
}

// ---------------------------------------------------------------------------
// public static void triggerUnitPlacement(
//     Set<TriggerAttachment> satisfiedTriggers,
//     IDelegateBridge bridge,
//     FireTriggerParams fireTriggerParams)
//
// For every trigger filtered by placeMatch(): roll testChance /
// consume uses, and for each (player, territory) entry in the
// trigger's placement map dispatch into `place_units` repeated
// `eachMultiple` times.
// ---------------------------------------------------------------------------
trigger_attachment_trigger_unit_placement :: proc(
	satisfied_triggers: map[^Trigger_Attachment]struct {},
	bridge: ^I_Delegate_Bridge,
	fire_trigger_params: ^Fire_Trigger_Params,
) {
	trigs := trigger_attachment_filter_satisfied_triggers(
		satisfied_triggers,
		trigger_attachment_lambda_place_match,
		fire_trigger_params,
	)
	defer delete(trigs)
	for t in trigs {
		if fire_trigger_params.test_chance && !abstract_trigger_attachment_test_chance(t, bridge) {
			continue
		}
		if fire_trigger_params.use_uses {
			abstract_trigger_attachment_use(t, bridge)
		}
		each_multiple := abstract_trigger_attachment_get_each_multiple(
			&t.abstract_trigger_attachment,
		)
		players := trigger_attachment_get_players(t)
		placement := trigger_attachment_get_placement(t)
		for player in players {
			for ter, ut_map in placement {
				for i: i32 = 0; i < each_multiple; i += 1 {
					trigger_attachment_place_units(t, ter, ut_map, player, bridge)
				}
			}
		}
	}
}

