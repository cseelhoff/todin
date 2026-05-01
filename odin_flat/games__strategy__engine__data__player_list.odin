package game

// games.strategy.engine.data.PlayerList
//
// Wrapper around the set of players in a game.

Player_List :: struct {
	using game_data_component: Game_Data_Component,
	players:      map[string]^Game_Player,
	null_player:  ^Game_Player,
}

// Java: public void addPlayerId(final GamePlayer player)
// Stores the player keyed by its name.
player_list_add_player_id :: proc(self: ^Player_List, player: ^Game_Player) {
	self.players[default_named_get_name(&player.named_attachable.default_named)] = player
}

// Java: private GamePlayer createNullPlayer(GameData data)
// Inlines `new GamePlayer("Neutral", true, false, null, false, data)` plus
// the anonymous-subclass `isNull() -> true` override. Game_Player has no
// dedicated is-null field; the runtime discriminator `Named_Kind.Game_Player`
// covers serialization, and the optional/canBeDisabled/isHidden flags
// mirror the Java ctor arguments byte-for-byte.
player_list_create_null_player :: proc(data: ^Game_Data) -> ^Game_Player {
	player := new(Game_Player)
	player.named_attachable.default_named.named.base.name = "Neutral"
	player.named_attachable.default_named.named.kind = .Game_Player
	player.named_attachable.default_named.game_data_component.game_data = data
	player.optional = true
	player.can_be_disabled = false
	player.default_type = ""
	player.is_hidden = false
	player.is_disabled = false

	units_held := new(Unit_Collection)
	units_held.game_data_component.game_data = data
	player.units_held = units_held

	resources := new(Resource_Collection)
	resources.game_data_component.game_data = data
	player.resources = resources

	tech_frontiers := new(Technology_Frontier_List)
	tech_frontiers.game_data_component.game_data = data
	player.technology_frontiers = tech_frontiers

	player.who_am_i = "null: no_one"
	return player
}

// Java: public @Nullable GamePlayer getPlayerId(final String name)
// Special-cases the null player by name, otherwise looks the player up
// in the name → player map. Returns nil for unknown names.
player_list_get_player_id :: proc(self: ^Player_List, name: string) -> ^Game_Player {
	if self.null_player != nil &&
	   default_named_get_name(&self.null_player.named_attachable.default_named) == name {
		return self.null_player
	}
	return self.players[name]
}

// Java: public List<GamePlayer> getPlayers()
// Returns `new ArrayList<>(players.values())` — a fresh copy of the
// player values. Caller owns the returned dynamic array.
player_list_get_players :: proc(self: ^Player_List) -> [dynamic]^Game_Player {
	out := make([dynamic]^Game_Player, 0, len(self.players))
	for _, player in self.players {
		append(&out, player)
	}
	return out
}

// Java: public Iterator<GamePlayer> iterator()
// "an iterator of a new ArrayList copy of the players." In Odin we
// surface the snapshot directly as a dynamic array — callers iterate
// it with `for p in player_list_iterator(self)`.
player_list_iterator :: proc(self: ^Player_List) -> [dynamic]^Game_Player {
	return player_list_get_players(self)
}

// Java: private void readObject(ObjectInputStream in)
// `in.defaultReadObject()` is the opaque JDK shim (no-op in the port).
// The post-read fixup creates the null player when an old save game
// deserialized a Player_List with a missing nullPlayer field.
player_list_read_object :: proc(self: ^Player_List, in_stream: ^Object_Input_Stream) {
	_ = in_stream
	if self.null_player == nil {
		self.null_player = player_list_create_null_player(
			game_data_component_get_data(&self.game_data_component),
		)
	}
}

// Java: public int size()
// Returns the number of players in the name → player map.
player_list_size :: proc(self: ^Player_List) -> i32 {
	return i32(len(self.players))
}

// Java: public Stream<GamePlayer> stream()
// Returns `players.values().stream()`. The Odin port surfaces the
// underlying dynamic-array snapshot of the player values; callers
// iterate it directly. Caller owns the returned dynamic array.
player_list_stream :: proc(self: ^Player_List) -> [dynamic]^Game_Player {
	return player_list_get_players(self)
}

// Java: public GamePlayer getNullPlayer() (Lombok @Getter)
// Returns the cached null player created in the Player_List constructor.
player_list_get_null_player :: proc(self: ^Player_List) -> ^Game_Player {
	return self.null_player
}

// Java: PlayerList.getPlayersThatMayBeDisabled lambda `p -> !p.getIsDisabled()`
// Second `.filter` predicate in the stream pipeline; keeps players whose
// `isDisabled` flag is false.
player_list_lambda_get_players_that_may_be_disabled_0 :: proc(p: ^Game_Player) -> bool {
	return !p.is_disabled
}
