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

// games.strategy.engine.data.GameData#getMap()
//
// Java: public GameMap getMap() { return map; }
// Simple getter. The Odin field is named `game_map` to avoid clashing with
// Odin's builtin `map` keyword.
game_data_get_map :: proc(self: ^Game_Data) -> ^Game_Map {
	return self.game_map
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
/

// games.strategy.engine.data.GameData#getBattleDelegate()
//
// Java: return (BattleDelegate) getDelegate("battle");
// Odin: look up the "battle" delegate and reinterpret the I_Delegate pointer
// as a Battle_Delegate pointer, mirroring Java's downcast.
game_data_get_battle_delegate :: proc(self: ^Game_Data) -> ^Battle_Delegate {
        return cast(^Battle_Delegate)game_data_get_delegate(self, "battle")
}/         .orElseThrow(
//             () -> new IllegalStateException(
//                 name + " delegate not found in list: " + delegates.keySet()));
//   }
// Looks up the delegate by name; panics with the same message Java throws
// when the entry is missing (mirroring IllegalStateException via fmt.panicf).
game_data_get_delegate :: proc(self: ^Game_Data, name: string) -> ^I_Delegate {
	delegate := game_data_get_delegate_optional(self, name)
	if delegate == nil {
		keys: [dynamic]string
		defer delete(keys)
		for key, _ in self.delegates {
			append(&keys, key)
		}
		joined := strings.join(keys[:], ", ")
		defer delete(joined)
		fmt.panicf("%s delegate not found in list: [%s]", name, joined)
	}
	return delegate
}

// games.strategy.engine.data.GameData#getHistory()
//
// Java: return getGameHistory(); — Lombok @Getter on the gameHistory field.
game_data_get_history :: proc(self: ^Game_Data) -> ^History {
        return self.game_history
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
