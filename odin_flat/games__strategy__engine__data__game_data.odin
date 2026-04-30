package game

import "core:fmt"
import "core:strings"

// games.strategy.engine.data.GameData
//
// Root of the game state. Every collection is owned by Game_Data and stored
// behind a pointer so other structs can reference Game_Data freely.

// Uuid: 16 raw bytes (Java UUID.toString() unhex'd by json_loader.string_to_uuid).
Uuid :: [16]u8

Game_Data :: struct {
	using game_state:               Game_State,
	game_name:                      string,
	game_version:                   ^Version,
	dice_sides:                     i32,
	force_in_swing_event_thread:    bool,
	alliances:                      ^Alliance_Tracker,
	relationships:                  ^Relationship_Tracker,
	game_map:                       ^Game_Map,
	player_list:                    ^Player_List,
	production_frontier_list:       ^Production_Frontier_List,
	production_rule_list:           ^Production_Rule_List,
	repair_frontier_list:           ^Repair_Frontier_List,
	repair_rules:                   ^Repair_Rules,
	resource_list:                  ^Resource_List,
	sequence:                       ^Game_Sequence,
	unit_type_list:                 ^Unit_Type_List,
	relationship_type_list:         ^Relationship_Type_List,
	properties:                     ^Game_Properties,
	units_list:                     ^Units_List,
	technology_frontier:            ^Technology_Frontier,
	loader:                         ^I_Game_Loader,
	territory_effect_list:          map[string]^Territory_Effect,
	battle_records_list:            ^Battle_Records_List,
	territory_listeners:            [dynamic]^Territory_Listener,
	data_change_listeners:          [dynamic]^Game_Data_Change_Listener,
	delegates:                      map[string]^I_Delegate,
	game_history:                   ^History,
	state:                          ^Game_Data_State,
	attachment_order_and_values:    [dynamic]^Tuple(^I_Attachment, [dynamic]^Tuple(string, string)),
	game_data_event_listeners:      ^Game_Data_Event_Listeners,
}

// Nested interface GameData.Unlocker (extends java.io.Closeable; no fields).
Unlocker :: struct {}

// games.strategy.engine.data.GameData#acquireWriteLock()
//
// Java acquires the write side of a ReentrantReadWriteLock and returns an
// Unlocker that releases it on close. The Odin port runs single-threaded
// (snapshot harness), so there is no underlying lock to take; the proc
// mirrors acquire_read_lock and returns an empty Unlocker value.
game_data_acquire_write_lock :: proc(self: ^Game_Data) -> Unlocker {
	return Unlocker{}
}

// games.strategy.engine.data.GameData#acquireReadLock()
//
// Java returns acquireLock(readWriteLock.readLock()), an Unlocker whose
// close() releases the read lock. The single-threaded port has no
// ReadWriteLock, so this is a no-op kept for API parity with Java callers.
game_data_acquire_read_lock :: proc(self: ^Game_Data) {
	_ = self
}

// games.strategy.engine.data.GameData#acquireLock(Lock)
//
// Java: private static Unlocker acquireLock(Lock lock) { lock.lock(); return lock::unlock; }
// Single-threaded snapshot harness: lock_lock is a no-op; return empty Unlocker.
game_data_acquire_lock :: proc(lock: ^Lock) -> Unlocker {
	lock_lock(lock)
	return Unlocker{}
}

// games.strategy.engine.data.GameData#getAllianceTracker()
//
// Java: returns the AllianceTracker stored in `alliances`. Simple getter.
game_data_get_alliance_tracker :: proc(self: ^Game_Data) -> ^Alliance_Tracker {
	return self.alliances
}

// games.strategy.engine.data.GameData#getRelationshipTracker()
//
// Java: public RelationshipTracker getRelationshipTracker() { return relationships; }
// Simple getter returning the tracker of current relationships between players.
game_data_get_relationship_tracker :: proc(self: ^Game_Data) -> ^Relationship_Tracker {
	return self.relationships
}

// games.strategy.engine.data.GameData#getRelationshipTypeList()
//
// Java: public RelationshipTypeList getRelationshipTypeList() { return relationshipTypeList; }
// Simple getter returning the list of relationship types defined in the game.
game_data_get_relationship_type_list :: proc(self: ^Game_Data) -> ^Relationship_Type_List {
	return self.relationship_type_list
}

// Returns whether we should throw an error if changes to this game data are
// made outside of the swing event thread.
game_data_are_changes_only_in_swing_event_thread :: proc(self: ^Game_Data) -> bool {
        return self.force_in_swing_event_thread
}

// games.strategy.engine.data.GameData#getBattleRecordsList()
//
// Java: public BattleRecordsList getBattleRecordsList() { return battleRecordsList; }
// Simple getter.
game_data_get_battle_records_list :: proc(self: ^Game_Data) -> ^Battle_Records_List {
	return self.battle_records_list
}

// games.strategy.engine.data.GameData#getProperties()
//
// Java: public GameProperties getProperties() { return properties; }
// Simple getter.
game_data_get_properties :: proc(self: ^Game_Data) -> ^Game_Properties {
	return self.properties
}

// games.strategy.engine.data.GameData#getProductionRuleList()
//
// Java: public ProductionRuleList getProductionRuleList() { return productionRuleList; }
// Simple getter.
game_data_get_production_rule_list :: proc(self: ^Game_Data) -> ^Production_Rule_List {
	return self.production_rule_list
}

// games.strategy.engine.data.GameData#getUnitTypeList()
//
// Java: public UnitTypeList getUnitTypeList() { return unitTypeList; }
// Simple getter.
game_data_get_unit_type_list :: proc(self: ^Game_Data) -> ^Unit_Type_List {
	return self.unit_type_list
}

// games.strategy.engine.data.GameData#getMap()
//
// Java: public GameMap getMap() { return map; }
// Simple getter. The Odin field is named `game_map` to avoid clashing with
// Odin's builtin `map` keyword.
game_data_get_map :: proc(self: ^Game_Data) -> ^Game_Map {
	return self.game_map
}

// games.strategy.engine.data.GameData#getProductionFrontierList()
//
// Java: public ProductionFrontierList getProductionFrontierList() { return productionFrontierList; }
// Simple getter.
game_data_get_production_frontier_list :: proc(self: ^Game_Data) -> ^Production_Frontier_List {
	return self.production_frontier_list
}

// games.strategy.engine.data.GameData#getRepairFrontierList()
//
// Java: public RepairFrontierList getRepairFrontierList() { return repairFrontierList; }
// Simple getter.
game_data_get_repair_frontier_list :: proc(self: ^Game_Data) -> ^Repair_Frontier_List {
	return self.repair_frontier_list
}

// games.strategy.engine.data.GameData#getRepairRules()
//
// Java: public RepairRules getRepairRules() { return repairRules; }
// Simple getter.
game_data_get_repair_rules :: proc(self: ^Game_Data) -> ^Repair_Rules {
	return self.repair_rules
}

// games.strategy.engine.data.GameData#getSequence()
//
// Java: public GameSequence getSequence() { return sequence; } Simple getter.
game_data_get_sequence :: proc(self: ^Game_Data) -> ^Game_Sequence {
	return self.sequence
}

// games.strategy.engine.data.GameData#getPlayerList()
//
// Java: public PlayerList getPlayerList() { return playerList; }
// Simple getter returning the list of Players in the game.
game_data_get_player_list :: proc(self: ^Game_Data) -> ^Player_List {
        return self.player_list
}

// games.strategy.engine.data.GameData#getUnits()
//
// Java: public UnitsList getUnits() { return unitsList; }
// Simple getter returning the collection of all units in the game.
game_data_get_units :: proc(self: ^Game_Data) -> ^Units_List {
        return self.units_list
}

// games.strategy.engine.data.GameData#getGameLoader()
//
// Java: `public IGameLoader getGameLoader() { return loader; }`. Simple
// getter exposing the IGameLoader instance (a TripleA in the JVM, modelled
// here as an empty `I_Game_Loader` placeholder) stored on Game_Data.
game_data_get_game_loader :: proc(self: ^Game_Data) -> ^I_Game_Loader {
        return self.loader
}

// games.strategy.engine.data.GameData#getDelegates()
//
// Java: public Collection<IDelegate> getDelegates() { return delegates.values(); }
// Returns the values of the delegates map. Odin equivalent collects the map's
// values into a [dynamic]^I_Delegate that mirrors Java's Collection<IDelegate>.
game_data_get_delegates :: proc(self: ^Game_Data) -> [dynamic]^I_Delegate {
	result: [dynamic]^I_Delegate
	for _, delegate in self.delegates {
		append(&result, delegate)
	}
	return result
}

// games.strategy.engine.data.GameData#getDelegateOptional(java.lang.String)
//
// Java: return Optional.ofNullable(delegates.get(name));
// Odin: map lookup returns the zero value (nil for ^I_Delegate) when the
// key is absent, which is the natural representation of Optional.empty().
game_data_get_delegate_optional :: proc(self: ^Game_Data, name: string) -> ^I_Delegate {
        delegate, ok := self.delegates[name]
        if !ok {
                return nil
        }
        return delegate
}

// games.strategy.engine.data.GameData#getDelegate(java.lang.String)
//
// Java:
//   public IDelegate getDelegate(final String name) {
//     return getDelegateOptional(name)
//

// games.strategy.engine.data.GameData#getBattleDelegate()
//
// Java: return (BattleDelegate) getDelegate("battle");
// Odin: look up the "battle" delegate and reinterpret the I_Delegate pointer
// as a Battle_Delegate pointer, mirroring Java's downcast.
game_data_get_battle_delegate :: proc(self: ^Game_Data) -> ^Battle_Delegate {
        return cast(^Battle_Delegate)game_data_get_delegate(self, "battle")
}

// games.strategy.engine.data.GameData#getMoveDelegate()
//
// Java: return (AbstractMoveDelegate) getDelegate("move");
// Odin: look up the "move" delegate and reinterpret the I_Delegate pointer
// as a Move_Delegate pointer. Move_Delegate embeds Abstract_Move_Delegate
// which embeds Abstract_Delegate (I_Delegate) at offset 0, so the cast is
// layout-safe and mirrors Java's downcast.
game_data_get_move_delegate :: proc(self: ^Game_Data) -> ^Move_Delegate {
        return cast(^Move_Delegate)game_data_get_delegate(self, "move")
}

// games.strategy.engine.data.GameData#getTechDelegate()
//
// Java: return (TechnologyDelegate) getDelegate("tech");
// Odin: look up the "tech" delegate and reinterpret the I_Delegate pointer
// as a Technology_Delegate pointer, mirroring Java's downcast.
game_data_get_tech_delegate :: proc(self: ^Game_Data) -> ^Technology_Delegate {
        return cast(^Technology_Delegate)game_data_get_delegate(self, "tech")
}

//         .orElseThrow(
//             () -> new IllegalStateException(
//                 name + " delegate not found in list: " + delegates.keySet()));
//   }
// games.strategy.engine.data.GameData#lambda$getDelegate$1(java.lang.String)
//
// Java synthetic method backing the orElseThrow supplier inside getDelegate:
//   () -> new IllegalStateException(
//             name + " delegate not found in list: " + delegates.keySet())
// Builds the IllegalStateException with the same message Java's
// AbstractMap.toString() format would emit for the key set ("[a, b, c]").
// game_data_get_delegate inlines this logic via fmt.panicf; this helper
// exists so the synthetic symbol is materialized in the Odin port.
game_data_lambda_get_delegate_1 :: proc(self: ^Game_Data, name: string) -> ^Exception {
	keys: [dynamic]string
	defer delete(keys)
	for key, _ in self.delegates {
		append(&keys, key)
	}
	joined := strings.join(keys[:], ", ")
	defer delete(joined)
	msg := fmt.aprintf("%s delegate not found in list: [%s]", name, joined)
	return exception_new(msg)
}

// Looks up the delegate by name; panics with the same message Java throws
// when the entry is missing (mirroring IllegalStateException via fmt.panicf).
game_data_get_delegate :: proc(self: ^Game_Data, name: string) -> ^I_Delegate {
	delegate := game_data_get_delegate_optional(self, name)
	if delegate == nil {
		keys: [dynamic]string
                for key, _ in self.delegates {
                        append(&keys, key)
                }
                joined := strings.join(keys[:], ", ")
                fmt.panicf("%s delegate not found in list: [%s]", name, joined)
        }
        return delegate
}

game_data_get_history :: proc(self: ^Game_Data) -> ^History {
        return self.game_history
}

// games.strategy.engine.data.GameData#setHistory(games.strategy.engine.history.History)
//
// Java: setGameHistory(history); — Lombok @Setter on the gameHistory field.
game_data_set_history :: proc(self: ^Game_Data, history: ^History) {
        self.game_history = history
}

// games.strategy.engine.data.GameData#getResourceList()
//
// Java: public ResourceList getResourceList() { return resourceList; }
// Simple getter. Returns the engine Resource_List (not the disambiguated
// Xml_Resource_List used by the XML parser).
game_data_get_resource_list :: proc(self: ^Game_Data) -> ^Resource_List {
        return self.resource_list
}

// games.strategy.engine.data.GameData#fixUpNullPlayersInDelegates()
//
// Java:
//   public void fixUpNullPlayersInDelegates() {
//     getDelegateOptional("battle")
//         .ifPresent(
//             delegate ->
//                 ((BattleDelegate) delegate)
//                     .getBattleTracker()
//                     .fixUpNullPlayers(playerList.getNullPlayer()));
//   }
// Odin: a nil result from get_delegate_optional represents Optional.empty(),
// so the body simply guards against nil and otherwise downcasts the
// I_Delegate pointer to ^Battle_Delegate (mirroring Java's cast) before
// invoking battle_tracker_fix_up_null_players with the player list's null
// player, exactly as the Java lambda does.
game_data_fix_up_null_players_in_delegates :: proc(self: ^Game_Data) {
        delegate := game_data_get_delegate_optional(self, "battle")
        if delegate != nil {
                battle_delegate := cast(^Battle_Delegate)delegate
                battle_tracker_fix_up_null_players(
                        battle_delegate_get_battle_tracker(battle_delegate),
                        player_list_get_null_player(self.player_list),
                )
        }
}

// games.strategy.engine.data.GameData#addDelegate(games.strategy.engine.delegate.IDelegate)
//
// Java: delegates.put(delegate.getName(), delegate);
// Inserts the delegate into the map keyed by its name. I_Delegate carries a
// `name` field (mirroring Java's getName()), so the lookup is direct.
game_data_add_delegate :: proc(self: ^Game_Data, delegate: ^I_Delegate) {
	self.delegates[delegate.name] = delegate
}

// games.strategy.engine.data.GameData#setDiceSides(int)
//
// Validating setter: accepts dice_sides in (0, 200], otherwise falls back to
// the default of 6, mirroring the Java implementation.
game_data_set_dice_sides :: proc(self: ^Game_Data, dice_sides: i32) {
        if dice_sides > 0 && dice_sides <= 200 {
                self.dice_sides = dice_sides
        } else {
                self.dice_sides = 6
        }
}

// games.strategy.engine.data.GameData#setGameName(java.lang.String)
//
// Java: this.gameName = gameName;
game_data_set_game_name :: proc(self: ^Game_Data, game_name: string) {
        self.game_name = game_name
}

// games.strategy.engine.data.GameData#getTechnologyFrontier()
//
// Java: public TechnologyFrontier getTechnologyFrontier() { return technologyFrontier; }
// Simple getter returning the aggregate "allTechsForGame" frontier.
game_data_get_technology_frontier :: proc(self: ^Game_Data) -> ^Technology_Frontier {
	return self.technology_frontier
}

// games.strategy.engine.data.GameData#getTechTracker()
//
// Java: public TechTracker getTechTracker() { return state.getTechTracker(); }
// Delegates to the Game_Data_State, which owns the Tech_Tracker.
game_data_get_tech_tracker :: proc(self: ^Game_Data) -> ^Tech_Tracker {
	return self.state.tech_tracker
}

// games.strategy.engine.data.GameData#notifyTerritoryUnitsChanged(Territory)
//
// Java: territoryListeners.forEach(territoryListener -> territoryListener.unitsChanged(t));
// Territory_Listener is an empty interface stub in odin_flat (only the Swing
// BottomBar implements it in Java; never registered in the AI snapshot path),
// so the slice is always empty here. The loop mirrors Java's forEach for
// fidelity; the body is a no-op because there is no callable dispatch field
// on the listener struct.
game_data_notify_territory_units_changed :: proc(self: ^Game_Data, territory: ^Territory) {
	for territory_listener in self.territory_listeners {
		_ = territory_listener
		_ = territory
	}
}

// games.strategy.engine.data.GameData#readObject(java.io.ObjectInputStream)
//
// Java body:
//   readWriteLock = new ReentrantReadWriteLock();
//   in.defaultReadObject();
//   gameDataEventListeners = new GameDataEventListeners();
//
// The Odin port is single-threaded and has no read_write_lock field
// (mirroring the no-op acquire_read_lock / acquire_write_lock procs).
// `Object_Input_Stream` is an opaque shim with no defaultReadObject
// semantics, so the only observable side effect is reinstating the
// event-listener container.
game_data_read_object :: proc(self: ^Game_Data, in_stream: ^Object_Input_Stream) {
	_ = in_stream
	self.game_data_event_listeners = new(Game_Data_Event_Listeners)
}

// games.strategy.engine.data.GameData#notifyTerritoryOwnerChanged(Territory)
//
// Java: territoryListeners.forEach(territoryListener -> territoryListener.ownerChanged(t));
// Iterates registered Territory_Listener pointers and dispatches owner_changed
// for the given territory. Territory_Listener is the empty interface stub
// (only Swing UI subclasses implement it; none are reachable in the AI/snapshot
// harness), so the body iterates the (always-empty in tests) listener list.
game_data_notify_territory_owner_changed :: proc(self: ^Game_Data, territory: ^Territory) {
	for territory_listener in self.territory_listeners {
		_ = territory_listener
		_ = territory
	}
}

// games.strategy.engine.data.GameData#postDeSerialize()
//
// Java:
//   public void postDeSerialize() {
//     state = new GameDataState(this);
//     territoryListeners = new CopyOnWriteArrayList<>();
//     dataChangeListeners = new CopyOnWriteArrayList<>();
//     delegates = new HashMap<>();
//     fixUpNullPlayers();
//   }
// Re-initializes the transient fields that Java's serialization skips and
// then patches up legacy save games via fix_up_null_players. The snapshot
// harness does not actually deserialize, but the body is mirrored exactly
// for fidelity with the Java engine.
game_data_post_de_serialize :: proc(self: ^Game_Data) {
	self.state = game_data_state_new(self)
	self.territory_listeners = make([dynamic]^Territory_Listener)
	self.data_change_listeners = make([dynamic]^Game_Data_Change_Listener)
	self.delegates = make(map[string]^I_Delegate)
	game_data_fix_up_null_players(self)
}

// games.strategy.engine.data.GameData#notifyTerritoryAttachmentChanged(Territory)
//
// Java: territoryListeners.forEach(territoryListener -> territoryListener.attachmentChanged(t));
// Territory_Listener is an empty interface stub in odin_flat (only the Swing
// BottomBar implements it in Java; never registered in the AI snapshot path),
// so the slice is always empty here. The loop mirrors Java's forEach for
// fidelity; the body is a no-op because there is no callable dispatch field
// on the listener struct.
game_data_notify_territory_attachment_changed :: proc(self: ^Game_Data, territory: ^Territory) {
	for territory_listener in self.territory_listeners {
		_ = territory_listener
		_ = territory
	}
}

// games.strategy.engine.data.GameData#setGameHistory(History)
// Lombok-generated @Setter for the `gameHistory` field.
game_data_set_game_history :: proc(self: ^Game_Data, history: ^History) {
	self.game_history = history
}

// games.strategy.engine.data.GameData#getAttachmentOrderAndValues()
// Lombok-generated @Getter for the `attachmentOrderAndValues` field, which
// records the parse order of <attachment> XML elements and their raw
// (option name, value) string pairs so the game can be re-saved in the
// same order it was loaded.
game_data_get_attachment_order_and_values :: proc(self: ^Game_Data) -> [dynamic]^Tuple(^I_Attachment, [dynamic]^Tuple(string, string)) {
	return self.attachment_order_and_values
}

// games.strategy.engine.data.GameData#getGameName()
// Lombok-generated @Getter for the `gameName` field.
game_data_get_game_name :: proc(self: ^Game_Data) -> string {
	return self.game_name
}

// games.strategy.engine.data.GameData#addToAttachmentOrderAndValues(Tuple)
// Java: attachmentOrderAndValues.add(attachmentAndValues);
game_data_add_to_attachment_order_and_values :: proc(self: ^Game_Data, tuple: ^Tuple(^I_Attachment, [dynamic]^Tuple(string, string))) {
        append(&self.attachment_order_and_values, tuple)
}

// games.strategy.engine.data.GameData#getGameHistory()
// Lombok-generated @Getter for the `gameHistory` field.
game_data_get_game_history :: proc(self: ^Game_Data) -> ^History {
	return self.game_history
}

// games.strategy.engine.data.GameData#setAttachmentOrderAndValues(List)
// Lombok-generated @Setter for the `attachmentOrderAndValues` field.
// Java assigns the supplied list directly: `this.attachmentOrderAndValues = attachmentOrderAndValues;`
game_data_set_attachment_order_and_values :: proc(self: ^Game_Data, list: [dynamic]^Tuple(^I_Attachment, [dynamic]^Tuple(string, string))) {
	self.attachment_order_and_values = list
}

// games.strategy.engine.data.GameData#getTerritoryEffectList()
// Java: return territoryEffectList;
game_data_get_territory_effect_list :: proc(self: ^Game_Data) -> map[string]^Territory_Effect {
	return self.territory_effect_list
}
