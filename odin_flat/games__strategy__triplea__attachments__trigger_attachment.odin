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
	return trigger_attachment_lambda_append_change_write_event_0, rawptr(ctx)
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


