package game

// games.strategy.engine.data.AllianceTracker
//
// alliance-name → list of players in that alliance.

Alliance_Tracker :: struct {
	alliances: map[string][dynamic]^Game_Player,
}

// AllianceTracker.getAllies(GamePlayer): returns the set of all players who
// share at least one alliance with `player`.
alliance_tracker_get_allies :: proc(
	self: ^Alliance_Tracker,
	player: ^Game_Player,
) -> map[^Game_Player]struct {} {
	allies: map[^Game_Player]struct {}
	for _, members in self.alliances {
		in_alliance := false
		for m in members {
			if m == player {
				in_alliance = true
				break
			}
		}
		if !in_alliance {
			continue
		}
		for m in members {
			allies[m] = {}
		}
	}
	return allies
}

// Synthetic lambda body from
// AllianceTracker#getPlayersInAlliance: e -> e.getValue().equals(allianceName).
// getPlayersInAlliance is inlined elsewhere against the inverted
// alliance_name → players map, so this proc just mirrors the predicate.
alliance_tracker_lambda_get_players_in_alliance_0 :: proc(
	alliance: string,
	entry_key: ^Game_Player,
	entry_value: string,
) -> bool {
	_ = entry_key
	return entry_value == alliance
}

// Returns a set of all the games alliances, this will return an empty set if
// you aren't using alliances. Mirrors Java `Set<String> getAlliances()`.
alliance_tracker_get_alliances :: proc(self: ^Alliance_Tracker) -> map[string]struct {} {
	result: map[string]struct {}
	for alliance_name in self.alliances {
		result[alliance_name] = {}
	}
	return result
}

// Adds player to the alliance specified by alliance.
alliance_tracker_add_to_alliance :: proc(self: ^Alliance_Tracker, player: ^Game_Player, alliance: string) {
	if alliance not_in self.alliances {
		self.alliances[alliance] = make([dynamic]^Game_Player)
	}
	members := &self.alliances[alliance]
	append(members, player)
}

// Returns the players that are members of the alliance specified by
// allianceName. Mirrors Java
// `Set<GamePlayer> getPlayersInAlliance(String allianceName)`.
//
// The Java implementation streams the underlying Multimap entries and filters
// with `e -> e.getValue().equals(allianceName)` (lambda$getPlayersInAlliance$0,
// inlined here). The Odin port stores the multimap inverted (alliance-name →
// players), so iterating the entries and matching the value reduces to a
// direct lookup of the alliance key.
alliance_tracker_get_players_in_alliance :: proc(
	self: ^Alliance_Tracker,
	alliance: string,
) -> map[^Game_Player]struct {} {
	result: map[^Game_Player]struct {}
	for alliance_name, members in self.alliances {
		// Inlined lambda$getPlayersInAlliance$0: e.getValue().equals(allianceName).
		if alliance_name != alliance {
			continue
		}
		for player in members {
			result[player] = {}
		}
	}
	return result
}

// AllianceTracker.writeReplace(): returns a SerializationProxy snapshotting
// the current player → alliance-names multimap. The Odin tracker stores
// alliance-name → players, so the proxy is built by inverting the map.
alliance_tracker_write_replace :: proc(self: ^Alliance_Tracker) -> ^Alliance_Tracker_Serialization_Proxy {
	proxy := new(Alliance_Tracker_Serialization_Proxy)
	proxy.alliances = make(map[^Game_Player][dynamic]string)
	for alliance_name, members in self.alliances {
		for player in members {
			if player not_in proxy.alliances {
				proxy.alliances[player] = make([dynamic]string)
			}
			names := &proxy.alliances[player]
			append(names, alliance_name)
		}
	}
	return proxy
}

// AllianceTracker.getAlliancesPlayerIsIn(GamePlayer): returns the alliance
// names `player` belongs to, or `Set.of(player.getName())` if the player is
// in no alliance. The Java code returns the live `alliances.get(player)`
// Collection<String> from the Multimap; we materialize an equivalent
// `[dynamic]string` because the Odin tracker stores the inverted
// alliance-name → players map.
alliance_tracker_get_alliances_player_is_in :: proc(
	self: ^Alliance_Tracker,
	player: ^Game_Player,
) -> [dynamic]string {
	result := make([dynamic]string)
	for alliance_name, members in self.alliances {
		for m in members {
			if m == player {
				append(&result, alliance_name)
				break
			}
		}
	}
	if len(result) == 0 {
		append(&result, player.named.base.name)
	}
	return result
}

// AllianceTracker(Multimap<GamePlayer, String>): construct from a
// player → alliance-names multimap. The Odin tracker stores the inverted
// alliance-name → players map, so we invert the entries on construction.
alliance_tracker_new :: proc(alliances: ^Multimap(^Game_Player, string)) -> ^Alliance_Tracker {
	self := new(Alliance_Tracker)
	self.alliances = make(map[string][dynamic]^Game_Player)
	if alliances != nil {
		for player, names in alliances.entries {
			for alliance_name in names {
				if alliance_name not_in self.alliances {
					self.alliances[alliance_name] = make([dynamic]^Game_Player)
				}
				members := &self.alliances[alliance_name]
				append(members, player)
			}
		}
	}
	return self
}

// AllianceTracker(): no-arg constructor delegating to
// `this(HashMultimap.create())`. The Odin tracker stores the inverted
// alliance-name → players map, so an empty HashMultimap maps to an empty
// alliances map here.
alliance_tracker_new_empty :: proc() -> ^Alliance_Tracker {
	self := new(Alliance_Tracker)
	self.alliances = make(map[string][dynamic]^Game_Player)
	return self
}
