package game

Battle_Listing :: struct {
	battles_map: map[I_Battle_Battle_Type][dynamic]^Territory,
}

// games.strategy.triplea.delegate.data.BattleListing#<init>(java.util.Set)
battle_listing_new :: proc(battles: map[^I_Battle]struct {}) -> ^Battle_Listing {
	self := new(Battle_Listing)
	self.battles_map = make(map[I_Battle_Battle_Type][dynamic]^Territory)
	for b in battles {
		if i_battle_is_empty(b) {
			continue
		}
		bt := i_battle_get_battle_type(b)
		terr := i_battle_get_territory(b)
		territories, ok := self.battles_map[bt]
		if !ok {
			territories = make([dynamic]^Territory)
		}
		// HashSet semantics: only add if not already present.
		already := false
		for t in territories {
			if t == terr {
				already = true
				break
			}
		}
		if !already {
			append(&territories, terr)
		}
		self.battles_map[bt] = territories
	}
	return self
}

// games.strategy.triplea.delegate.data.BattleListing#getBattlesMap
battle_listing_get_battles_map :: proc(self: ^Battle_Listing) -> map[I_Battle_Battle_Type][dynamic]^Territory {
	return self.battles_map
}

// games.strategy.triplea.delegate.data.BattleListing#getBattlesWith(java.util.function.Predicate)
battle_listing_get_battles_with :: proc(self: ^Battle_Listing, predicate: proc(I_Battle_Battle_Type) -> bool) -> map[^Territory]struct {} {
	territories := make(map[^Territory]struct {})
	for bt, terrs in self.battles_map {
		if predicate(bt) {
			for t in terrs {
				territories[t] = struct {}{}
			}
		}
	}
	return territories
}

// games.strategy.triplea.delegate.data.BattleListing#isEmpty
battle_listing_is_empty :: proc(self: ^Battle_Listing) -> bool {
	return len(self.battles_map) == 0
}
