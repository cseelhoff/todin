package game

Alliance_Tracker_Serialization_Proxy :: struct {
	alliances: map[^Game_Player][dynamic]string,
}

// games.strategy.engine.data.AllianceTracker$SerializationProxy#<init>(AllianceTracker)
//
// Java copies the tracker's player → alliance-names multimap into an
// immutable copy. The Odin `Alliance_Tracker` stores the inverted mapping
// (alliance name → players), so we invert it back here.
make_Alliance_Tracker_Serialization_Proxy :: proc(
	tracker: ^Alliance_Tracker,
) -> ^Alliance_Tracker_Serialization_Proxy {
	result := new(Alliance_Tracker_Serialization_Proxy)
	result.alliances = make(map[^Game_Player][dynamic]string)
	for alliance_name, players in tracker.alliances {
		for player in players {
			if player not_in result.alliances {
				result.alliances[player] = make([dynamic]string)
			}
			names := &result.alliances[player]
			append(names, alliance_name)
		}
	}
	return result
}

// games.strategy.engine.data.AllianceTracker$SerializationProxy#readResolve()
//
// Java returns `new AllianceTracker(alliances)` directly. The Odin
// `Alliance_Tracker` stores the inverted mapping (alliance name →
// players), so we rebuild it from the proxy's player → alliance-names
// multimap.
alliance_tracker_serialization_proxy_read_resolve :: proc(
	self: ^Alliance_Tracker_Serialization_Proxy,
) -> ^Alliance_Tracker {
	result := new(Alliance_Tracker)
	result.alliances = make(map[string][dynamic]^Game_Player)
	for player, alliance_names in self.alliances {
		for alliance_name in alliance_names {
			if alliance_name not_in result.alliances {
				result.alliances[alliance_name] = make([dynamic]^Game_Player)
			}
			players := &result.alliances[alliance_name]
			append(players, player)
		}
	}
	return result
}

