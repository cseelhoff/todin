package game

Select_Main_Battle_Casualties :: struct {
	select_function: ^Select_Main_Battle_Casualties_Select,
}

// Java: lambda$limitTransportsToSelect$0(GamePlayer)
// Source: alliedHitPlayer.computeIfAbsent(unit.getOwner(), (owner) -> new ArrayList<>())
select_main_battle_casualties_lambda_limit_transports_to_select_0 :: proc(owner: ^Game_Player) -> [dynamic]^Unit {
	return make([dynamic]^Unit)
}

// Java: SelectMainBattleCasualties() (no-args constructor, @NoArgsConstructor)
select_main_battle_casualties_new :: proc() -> ^Select_Main_Battle_Casualties {
	self := new(Select_Main_Battle_Casualties)
	self.select_function = select_main_battle_casualties_select_new()
	return self
}

// Java: List<Unit> limitTransportsToSelect(Collection<Unit>, int)
// Limit the number of transports to hitsLeftForTransports per ally.
select_main_battle_casualties_limit_transports_to_select :: proc(
	restricted_transports: [dynamic]^Unit,
	hits_left_for_transports: i32,
) -> [dynamic]^Unit {
	allied_hit_player := make(map[^Game_Player][dynamic]^Unit)
	defer {
		for _, list in allied_hit_player {
			delete(list)
		}
		delete(allied_hit_player)
	}
	for unit in restricted_transports {
		owner := unit_get_owner(unit)
		if _, ok := allied_hit_player[owner]; !ok {
			allied_hit_player[owner] = make([dynamic]^Unit)
		}
		bucket := &allied_hit_player[owner]
		append(bucket, unit)
	}
	transports_to_select := make([dynamic]^Unit)
	for _, units in allied_hit_player {
		count: i32 = 0
		for u in units {
			if count >= hits_left_for_transports {
				break
			}
			append(&transports_to_select, u)
			count += 1
		}
	}
	return transports_to_select
}

