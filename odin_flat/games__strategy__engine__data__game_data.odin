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

// games.strategy.engine.data.GameData#<init>()
//
// Java's implicit default constructor runs all in-line field initializers
// in declaration order:
//   alliances           = new AllianceTracker()
//   relationships       = new RelationshipTracker(this)
//   map                 = new GameMap(this)
//   playerList          = new PlayerList(this)
//   productionFrontierList = new ProductionFrontierList(this)
//   productionRuleList  = new ProductionRuleList(this)
//   repairFrontierList  = new RepairFrontierList(this)
//   repairRules         = new RepairRules(this)
//   resourceList        = new ResourceList(this)
//   sequence            = new GameSequence(this)
//   unitTypeList        = new UnitTypeList(this)
//   relationshipTypeList= new RelationshipTypeList(this)
//   properties          = new GameProperties(this)
//   unitsList           = new UnitsList()
//   technologyFrontier  = new TechnologyFrontier("allTechsForGame", this)
//   loader              = new TripleA()
//   territoryEffectList = new HashMap<>()
//   battleRecordsList   = new BattleRecordsList(this)
//   territoryListeners  = new CopyOnWriteArrayList<>()
//   dataChangeListeners = new CopyOnWriteArrayList<>()
//   delegates           = new HashMap<>()
//   gameHistory         = new History(this)
//   state               = new GameDataState(this)
//   attachmentOrderAndValues = new ArrayList<>()
//   gameDataEventListeners = new GameDataEventListeners()
//
// The single-threaded snapshot port drops the ReadWriteLock and transient
// flags Java initializes from defaults. AllianceTracker's no-arg form
// builds an empty alliances map; the Odin equivalent is
// alliance_tracker_new_empty. TripleA implements IGameLoader, so the
// concrete pointer is reinterpreted as ^I_Game_Loader (Triple_A embeds
// I_Game_Loader at offset 0, so the cast is layout-safe).
game_data_new :: proc() -> ^Game_Data {
	self := new(Game_Data)
	self.alliances = alliance_tracker_new_empty()
	self.relationships = relationship_tracker_new(self)
	self.game_map = game_map_new(self)
	self.player_list = player_list_new(self)
	self.production_frontier_list = production_frontier_list_new(self)
	self.production_rule_list = production_rule_list_new(self)
	self.repair_frontier_list = repair_frontier_list_new(self)
	self.repair_rules = repair_rules_new(self)
	self.resource_list = resource_list_new(self)
	self.sequence = game_sequence_new(self)
	self.unit_type_list = unit_type_list_new(self)
	self.relationship_type_list = relationship_type_list_new(self)
	self.properties = game_properties_new(self)
	self.units_list = make_Units_List()
	self.technology_frontier = technology_frontier_new("allTechsForGame", self)
	self.loader = cast(^I_Game_Loader)triple_a_new()
	self.territory_effect_list = make(map[string]^Territory_Effect)
	self.battle_records_list = battle_records_list_new(self)
	self.force_in_swing_event_thread = false
	self.territory_listeners = make([dynamic]^Territory_Listener)
	self.data_change_listeners = make([dynamic]^Game_Data_Change_Listener)
	self.delegates = make(map[string]^I_Delegate)
	self.game_history = history_new(self)
	self.state = game_data_state_new(self)
	self.attachment_order_and_values = make([dynamic]^Tuple(^I_Attachment, [dynamic]^Tuple(string, string)))
	listeners := new(Game_Data_Event_Listeners)
	listeners^ = make_Game_Data_Event_Listeners()
	self.game_data_event_listeners = listeners
	return self
}

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

// games.strategy.engine.data.GameData#addGameDataEventListener(GameDataEvent, Runnable)
//
// Java:
//   public void addGameDataEventListener(final GameDataEvent event, final Runnable listener) {
//     gameDataEventListeners.addListener(event, listener);
//   }
// Java Runnable lambdas often capture `this` and other locals; in Odin
// we model that by passing a context pointer alongside the callback.
// Callers that don't need any captured state pass `nil` for `ctx`.
game_data_add_game_data_event_listener :: proc(
	self: ^Game_Data,
	event: Game_Data_Event,
	callback: proc(ctx: rawptr),
	ctx: rawptr = nil,
) {
	game_data_event_listeners_add_listener(self.game_data_event_listeners, event, callback, ctx)
}

// games.strategy.engine.data.GameData#fireGameDataEvent(GameDataEvent)
//
// Java:
//   public void fireGameDataEvent(final GameDataEvent event) {
//     gameDataEventListeners.accept(event);
//   }
game_data_fire_game_data_event :: proc(self: ^Game_Data, event: Game_Data_Event) {
	game_data_event_listeners_accept(self.game_data_event_listeners, event)
}

// games.strategy.engine.data.GameData#setMapName(String)
//
// Java:
//   public void setMapName(final String mapName) {
//     properties.set(Constants.MAP_NAME, mapName);
//   }
// Constants.MAP_NAME is the literal "mapName". game_properties_set takes
// rawptr (Java Serializable shim); box the string on the heap so the
// property store owns a stable pointer to the value.
game_data_set_map_name :: proc(self: ^Game_Data, map_name: string) {
	boxed := new(string)
	boxed^ = map_name
	game_properties_set(self.properties, "mapName", rawptr(boxed))
}

// games.strategy.engine.data.GameData#lambda$notifyTerritoryUnitsChanged$2(Territory, TerritoryListener)
//
// Java: territoryListener -> territoryListener.unitsChanged(t)
// `t` is the captured Territory; `territory_listener` is the iterating var.
game_data_lambda_notify_territory_units_changed_2 :: proc(t: ^Territory, territory_listener: ^Territory_Listener) {
	territory_listener_units_changed(territory_listener, t)
}

// games.strategy.engine.data.GameData#lambda$notifyTerritoryAttachmentChanged$3(Territory, TerritoryListener)
//
// Java: territoryListener -> territoryListener.attachmentChanged(t)
game_data_lambda_notify_territory_attachment_changed_3 :: proc(t: ^Territory, territory_listener: ^Territory_Listener) {
	territory_listener_attachment_changed(territory_listener, t)
}

// games.strategy.engine.data.GameData#lambda$notifyTerritoryOwnerChanged$4(Territory, TerritoryListener)
//
// Java: territoryListener -> territoryListener.ownerChanged(t)
game_data_lambda_notify_territory_owner_changed_4 :: proc(t: ^Territory, territory_listener: ^Territory_Listener) {
	territory_listener_owner_changed(territory_listener, t)
}

// games.strategy.engine.data.GameData#lambda$preGameDisablePlayers$6(Predicate, GamePlayer)
//
// Java: p -> (p.getCanBeDisabled() && shouldDisablePlayer.test(p))
// The captured Predicate<GamePlayer> is modeled as a non-capturing
// `proc(^Game_Player) -> bool` here; the outer preGameDisablePlayers (layer 3)
// will adapt any closure-pair predicate before passing it in.
game_data_lambda_pre_game_disable_players_6 :: proc(should_disable_player: proc(^Game_Player) -> bool, p: ^Game_Player) -> bool {
	return game_player_get_can_be_disabled(p) && should_disable_player(p)
}

// games.strategy.engine.data.GameData#lambda$preGameDisablePlayers$7(Set, GamePlayer)
//
// Java:
//   p -> {
//     p.setIsDisabled(true);
//     playersWhoShouldBeRemoved.add(p);
//   }
// Set<GamePlayer> -> map[^Game_Player]struct{}. The setIsDisabled setter is
// a Lombok @Setter; we assign the field directly to mirror its body.
game_data_lambda_pre_game_disable_players_7 :: proc(players_who_should_be_removed: ^map[^Game_Player]struct {}, p: ^Game_Player) {
	p.is_disabled = true
	players_who_should_be_removed[p] = {}
}

// games.strategy.engine.data.GameData#lambda$performChange$8(Change, GameDataChangeListener)
//
// Java: listener -> listener.gameDataChanged(change)
// `change` is captured; `listener` is the iterating var.
game_data_lambda_perform_change_8 :: proc(change: ^Change, listener: ^Game_Data_Change_Listener) {
	game_data_change_listener_game_data_changed(listener, change)
}

// games.strategy.engine.data.GameData#lambda$getGameXmlPath$9(MapDescriptionYaml)
//
// Java: yaml -> yaml.getGameXmlPathByGameName(getGameName())
//
// `this` (Game_Data) is captured so the lambda can call getGameName();
// `yaml` is the value flowing through Optional.flatMap. The Java return
// type is Optional<Path>; in Odin we mirror that as (Path, bool).
game_data_lambda_get_game_xml_path_9 :: proc(
	self: ^Game_Data,
	yaml: ^Map_Description_Yaml,
) -> (
	Path,
	bool,
) {
	return map_description_yaml_get_game_xml_path_by_game_name(
		yaml,
		game_data_get_game_name(self),
	)
}

// games.strategy.engine.data.GameData#performChange(Change)
//
// Java:
//   public void performChange(final Change change) {
//     if (areChangesOnlyInSwingEventThread()) {
//       Util.ensureOnEventDispatchThread();
//     }
//     try (Unlocker ignored = acquireWriteLock()) {
//       change.perform(this);
//     }
//     dataChangeListeners.forEach(listener -> listener.gameDataChanged(change));
//     GameDataEvent.lookupEvent(change).ifPresent(this::fireGameDataEvent);
//   }
//
// The single-threaded snapshot port has no Swing event-dispatch thread
// and acquire_write_lock is a no-op, so the guard and try-with-resources
// collapse to a direct change_perform call. Game_Data embeds Game_State
// (line 15: `using game_state: Game_State`) so &self.game_state is the
// receiver Change.perform expects. dataChangeListeners.forEach maps to
// an explicit loop calling the lambda; lookupEvent's Optional becomes a
// (value, ok) tuple from game_data_event_lookup_event.
game_data_perform_change :: proc(self: ^Game_Data, change: ^Change) {
	if game_data_are_changes_only_in_swing_event_thread(self) {
		// Util.ensureOnEventDispatchThread() — no Swing thread in the
		// single-threaded snapshot port; the assertion is a no-op.
	}
	{
		_ = game_data_acquire_write_lock(self)
		change_perform(change, &self.game_state)
	}
	for listener in self.data_change_listeners {
		game_data_lambda_perform_change_8(change, listener)
	}
	if event, ok := game_data_event_lookup_event(change); ok {
		game_data_fire_game_data_event(self, event)
	}
}

// games.strategy.engine.data.GameData#fixUpNullPlayers()
//
// Java:
//   private void fixUpNullPlayers() {
//     GamePlayer nullPlayer = playerList.getNullPlayer();
//     for (Territory t : getMap().getTerritories()) {
//       if (t.getOwner().isNull() && !ObjectUtils.referenceEquals(t.getOwner(), nullPlayer)) {
//         t.setOwner(nullPlayer);
//       }
//     }
//     for (Unit u : getUnits()) {
//       if (u.getOwner().isNull() && !ObjectUtils.referenceEquals(u.getOwner(), nullPlayer)) {
//         u.setOwner(nullPlayer);
//       }
//     }
//   }
// ObjectUtils.referenceEquals is identity comparison; in Odin pointer
// equality (`!=`) is the direct equivalent.
game_data_fix_up_null_players :: proc(self: ^Game_Data) {
	null_player := player_list_get_null_player(self.player_list)
	for t in game_map_get_territories(game_data_get_map(self)) {
		owner := territory_get_owner(t)
		if game_player_is_null(owner) && owner != null_player {
			territory_set_owner(t, null_player)
		}
	}
	for u in units_list_iterator(game_data_get_units(self)) {
		owner := unit_get_owner(u)
		if game_player_is_null(owner) && owner != null_player {
			unit_set_owner(u, null_player)
		}
	}
}

// games.strategy.engine.data.GameData#getCurrentRound()
//
// Java:
//   public int getCurrentRound() {
//     try (GameData.Unlocker ignored = acquireReadLock()) {
//       return getSequence().getRound();
//     }
//   }
// The single-threaded port's acquire_read_lock is a no-op; mirror the
// try-with-resources call for fidelity then return the sequence round.
game_data_get_current_round :: proc(self: ^Game_Data) -> i32 {
	game_data_acquire_read_lock(self)
	return game_sequence_get_round(game_data_get_sequence(self))
}

// games.strategy.engine.data.GameData#getEndRoundDelegate()
//
// Java: return (EndRoundDelegate) getDelegate("endRound");
// Look up the "endRound" delegate and reinterpret the I_Delegate pointer
// as an End_Round_Delegate pointer, mirroring Java's downcast.
game_data_get_end_round_delegate :: proc(self: ^Game_Data) -> ^End_Round_Delegate {
	return cast(^End_Round_Delegate)game_data_get_delegate(self, "endRound")
}

// games.strategy.engine.data.GameData#getPoliticsDelegate()
//
// Java: return (PoliticsDelegate) getDelegate("politics");
// Look up the "politics" delegate and reinterpret the I_Delegate pointer
// as a Politics_Delegate pointer, mirroring Java's downcast.
game_data_get_politics_delegate :: proc(self: ^Game_Data) -> ^Politics_Delegate {
	return cast(^Politics_Delegate)game_data_get_delegate(self, "politics")
}

// games.strategy.engine.data.GameData#getMapName()
//
// Java:
//   public String getMapName() {
//     return String.valueOf(properties.get(Constants.MAP_NAME));
//   }
// Constants.MAP_NAME is the literal "mapName". String.valueOf(null) is
// "null", String.valueOf(s) is s.toString(); Property_Value carries
// typed primitives so we render the string variant directly and fall
// back to fmt.aprint for the rare non-string case (matches Java's
// Object.toString()), and emit "null" when the property is unset.
game_data_get_map_name :: proc(self: ^Game_Data) -> string {
	value := game_properties_get(self.properties, "mapName")
	if value == nil {
		return "null"
	}
	switch v in value {
	case string:
		return v
	case bool, i32, f64:
		return fmt.aprint(v)
	}
	return "null"
}

// games.strategy.engine.data.GameData#getUnitHolder(java.lang.String, java.lang.String)
//
// Java:
//   public UnitHolder getUnitHolder(final String name, final String type) {
//     switch (type) {
//       case UnitHolder.PLAYER:    return playerList.getPlayerId(name);
//       case UnitHolder.TERRITORY: return map.getTerritoryOrNull(name);
//       default: throw new IllegalStateException("Invalid type: " + type);
//     }
//   }
// UnitHolder.PLAYER = "P", UnitHolder.TERRITORY = "T". Unit_Holder is the
// empty interface stub; both Game_Player and Territory are returned to
// Java callers as UnitHolder, so we type-pun the concrete pointers to
// ^Unit_Holder (size-zero base, layout-safe).
game_data_get_unit_holder :: proc(self: ^Game_Data, name: string, type: string) -> ^Unit_Holder {
	switch type {
	case "P":
		return cast(^Unit_Holder)player_list_get_player_id(self.player_list, name)
	case "T":
		return cast(^Unit_Holder)game_map_get_territory_or_null(game_data_get_map(self), name)
	case:
		fmt.panicf("Invalid type: %s", type)
	}
	return nil
}

// games.strategy.engine.data.GameData#lambda$fixUpNullPlayersInDelegates$5(IDelegate)
//
// Java synthetic backing the lambda inside fixUpNullPlayersInDelegates:
//   delegate ->
//     ((BattleDelegate) delegate)
//         .getBattleTracker()
//         .fixUpNullPlayers(playerList.getNullPlayer())
// `self` (the enclosing GameData) is the captured outer reference for
// `playerList`. The body downcasts the I_Delegate to Battle_Delegate and
// applies the null-player fixup.
game_data_lambda_fix_up_null_players_in_delegates_5 :: proc(self: ^Game_Data, delegate: ^I_Delegate) {
	battle_delegate := cast(^Battle_Delegate)delegate
	battle_tracker_fix_up_null_players(
		battle_delegate_get_battle_tracker(battle_delegate),
		player_list_get_null_player(self.player_list),
	)
}
// games.strategy.engine.data.GameData#resetHistory()
//
// Java:
//   public void resetHistory() {
//     setGameHistory(new History(this));
//     GameStep step = getSequence().getStep();
//     final boolean oldForceInSwingEventThread = forceInSwingEventThread;
//     forceInSwingEventThread = false;
//     getGameHistory()
//         .getHistoryWriter()
//         .startNextStep(
//             step.getName(), step.getDelegateName(), step.getPlayerId(), step.getDisplayName());
//     forceInSwingEventThread = oldForceInSwingEventThread;
//   }
game_data_reset_history :: proc(self: ^Game_Data) {
        game_data_set_game_history(self, history_new(self))
        step := game_sequence_get_step(game_data_get_sequence(self))
        old_force_in_swing_event_thread := self.force_in_swing_event_thread
        self.force_in_swing_event_thread = false
        history_writer_start_next_step(
                history_get_history_writer(game_data_get_history(self)),
                game_step_get_name(step),
                game_step_get_delegate_name(step),
                game_step_get_player_id(step),
                game_step_get_display_name(step),
        )
        self.force_in_swing_event_thread = old_force_in_swing_event_thread
}