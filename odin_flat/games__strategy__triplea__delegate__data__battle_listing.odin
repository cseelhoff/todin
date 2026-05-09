package game

import "core:slice"
import "core:strings"

Battle_Listing :: struct {
	battles_map: map[I_Battle_Battle_Type][dynamic]^Territory,
}

// games.strategy.triplea.delegate.data.BattleListing#<init>(java.util.Set)
//
// Java's input is `Set<IBattle>` (a HashSet, see BattleTracker.pendingBattles)
// whose iteration order depends on JVM-internal identity hashCodes — stable
// per-JVM but not portable. Odin's `map[^I_Battle]struct{}` randomizes per
// process. To make the AI's battle-resolution sequence reproducible across
// runs (so snapshot tests don't flake), we sort each per-BattleType territory
// bucket by territory name after construction. This is the same shape of fix
// applied to ProPurchaseUtils.randomizePurchaseOption (see scripts/patch_triplea.py
// `patch_pro_purchase_utils`). The matching Java patch sorts BattleListing's
// territories the same way; both sides agree on order.
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
	// Stable per-bucket sort by territory name for cross-run reproducibility.
	for bt in I_Battle_Battle_Type {
		territories, ok := self.battles_map[bt]
		if !ok {
			continue
		}
		slice.sort_by(territories[:], proc(a, b: ^Territory) -> bool {
			na := a != nil ? default_named_get_name(&a.named_attachable.default_named) : ""
			nb := b != nil ? default_named_get_name(&b.named_attachable.default_named) : ""
			return strings.compare(na, nb) < 0
		})
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

// games.strategy.triplea.delegate.data.BattleListing#lambda$new$0(IBattle)
//   Java: b -> !b.isEmpty()
battle_listing_lambda__new__0 :: proc(b: ^I_Battle) -> bool {
	return !i_battle_is_empty(b)
}

// games.strategy.triplea.delegate.data.BattleListing#lambda$new$1(IBattle)
//   Java forEach body capturing this.battlesMap.
battle_listing_lambda__new__1 :: proc(self: ^Battle_Listing, b: ^I_Battle) {
	bt := i_battle_get_battle_type(b)
	terr := i_battle_get_territory(b)
	territories, ok := self.battles_map[bt]
	if !ok {
		territories = make([dynamic]^Territory)
	}
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

// games.strategy.triplea.delegate.data.BattleListing#lambda$getNormalBattlesIncludingAirBattles$2(BattleType)
//   Java: b -> !b.isBombingRun()
battle_listing_lambda__get_normal_battles_including_air_battles__2 :: proc(b: I_Battle_Battle_Type) -> bool {
	return !i_battle_battle_type_is_bombing_run(b)
}

// games.strategy.triplea.delegate.data.BattleListing#getNormalBattlesIncludingAirBattles()
battle_listing_get_normal_battles_including_air_battles :: proc(self: ^Battle_Listing) -> map[^Territory]struct {} {
	return battle_listing_get_battles_with(self, battle_listing_lambda__get_normal_battles_including_air_battles__2)
}

// games.strategy.triplea.delegate.data.BattleListing#getStrategicBombingRaidsIncludingAirBattles()
battle_listing_get_strategic_bombing_raids_including_air_battles :: proc(self: ^Battle_Listing) -> map[^Territory]struct {} {
	return battle_listing_get_battles_with(self, i_battle_battle_type_is_bombing_run)
}
