package game

Scramble_Logic :: struct {
	data:                                    ^Game_State,
	player:                                  ^Game_Player,
	territories_with_battles:                map[^Territory]struct{},
	battle_tracker:                          ^Battle_Tracker,
	// `Predicate<Unit> airbaseThatCanScramblePredicate` — Odin has no
	// closures, so we mirror the (proc, rawptr) calling convention used
	// throughout the matches module: a callable function pointer plus
	// an opaque context that carries captured state.
	airbase_that_can_scramble_predicate_fn:  proc(rawptr, ^Unit) -> bool,
	airbase_that_can_scramble_predicate_ctx: rawptr,
	// `Predicate<Territory> canScrambleFromPredicate`
	can_scramble_from_predicate_fn:          proc(rawptr, ^Territory) -> bool,
	can_scramble_from_predicate_ctx:         rawptr,
	max_scramble_distance:                   i32,
}

// AND-chained Unit predicate context. Each entry may be optionally
// negated (mirroring Java `predicate.negate()` calls).
Scramble_Logic_And_Pred_Unit_Entry :: struct {
	fn:     proc(rawptr, ^Unit) -> bool,
	ctx:    rawptr,
	negate: bool,
}

Scramble_Logic_And_Pred_Unit_Ctx :: struct {
	entries: [dynamic]Scramble_Logic_And_Pred_Unit_Entry,
}

scramble_logic_pred_unit_and_eval :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Scramble_Logic_And_Pred_Unit_Ctx)ctx_ptr
	for e in c.entries {
		r := e.fn(e.ctx, u)
		if e.negate {
			r = !r
		}
		if !r {
			return false
		}
	}
	return true
}

// Composite Territory predicate context for `canScrambleFromPredicate`.
// Java builds it via PredicateBuilder:
//   (water OR isEnemy(player))
//   AND territoryHasUnitsThatMatch(canScramble AND enemy AND notDisabled)
//   AND territoryHasUnitsThatMatch(airbaseThatCanScramblePredicate)
//   AND (scrambleFromIslandOnly ? territoryIsIsland : true)
Scramble_Logic_Can_Scramble_From_Ctx :: struct {
	water_fn:           proc(rawptr, ^Territory) -> bool,
	water_ctx:          rawptr,
	enemy_fn:           proc(rawptr, ^Territory) -> bool,
	enemy_ctx:          rawptr,
	has_scramblers_fn:  proc(rawptr, ^Territory) -> bool,
	has_scramblers_ctx: rawptr,
	has_airbases_fn:    proc(rawptr, ^Territory) -> bool,
	has_airbases_ctx:   rawptr,
	island_only:        bool,
	island_fn:          proc(rawptr, ^Territory) -> bool,
	island_ctx:         rawptr,
}

scramble_logic_pred_can_scramble_from_eval :: proc(ctx_ptr: rawptr, t: ^Territory) -> bool {
	c := cast(^Scramble_Logic_Can_Scramble_From_Ctx)ctx_ptr
	if !(c.water_fn(c.water_ctx, t) || c.enemy_fn(c.enemy_ctx, t)) {
		return false
	}
	if !c.has_scramblers_fn(c.has_scramblers_ctx, t) {
		return false
	}
	if !c.has_airbases_fn(c.has_airbases_ctx, t) {
		return false
	}
	if c.island_only && !c.island_fn(c.island_ctx, t) {
		return false
	}
	return true
}

// Java:
//   public ScrambleLogic(
//       final GameState data,
//       final GamePlayer player,
//       final Set<Territory> territoriesWithBattles,
//       final BattleTracker battleTracker) {
//     if (!Properties.getScrambleRulesInEffect(data.getProperties())) {
//       throw new IllegalStateException("Scrambling not supported");
//     }
//     ...
//     this.airbaseThatCanScramblePredicate =
//         Matches.unitIsEnemyOf(player)
//             .and(Matches.unitIsAirBase())
//             .and(Matches.unitIsNotDisabled())
//             .and(Matches.unitIsBeingTransported().negate());
//     this.canScrambleFromPredicate =
//         PredicateBuilder.of(Matches.territoryIsWater().or(Matches.isTerritoryEnemy(player)))
//             .and(Matches.territoryHasUnitsThatMatch(
//                 Matches.unitCanScramble()
//                     .and(Matches.unitIsEnemyOf(player))
//                     .and(Matches.unitIsNotDisabled())))
//             .and(Matches.territoryHasUnitsThatMatch(airbaseThatCanScramblePredicate))
//             .andIf(
//                 Properties.getScrambleFromIslandOnly(data.getProperties()),
//                 Matches.territoryIsIsland())
//             .build();
//     this.maxScrambleDistance = computeMaxScrambleDistance(data);
//   }
scramble_logic_new :: proc(
	data: ^Game_State,
	player: ^Game_Player,
	territories_with_battles: map[^Territory]struct{},
	battle_tracker: ^Battle_Tracker,
) -> ^Scramble_Logic {
	if !properties_get_scramble_rules_in_effect(game_state_get_properties(data)) {
		panic("Scrambling not supported")
	}
	self := new(Scramble_Logic)
	self.data = data
	self.player = player
	self.territories_with_battles = territories_with_battles
	self.battle_tracker = battle_tracker

	// airbaseThatCanScramblePredicate
	a_eo_fn, a_eo_ctx := matches_unit_is_enemy_of(player)
	a_ab_fn, a_ab_ctx := matches_unit_is_air_base()
	a_nd_fn, a_nd_ctx := matches_unit_is_not_disabled()
	a_bt_fn, a_bt_ctx := matches_unit_is_being_transported()
	airbase_ctx := new(Scramble_Logic_And_Pred_Unit_Ctx)
	airbase_ctx.entries = make([dynamic]Scramble_Logic_And_Pred_Unit_Entry, 0, 4)
	append(&airbase_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{a_eo_fn, a_eo_ctx, false})
	append(&airbase_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{a_ab_fn, a_ab_ctx, false})
	append(&airbase_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{a_nd_fn, a_nd_ctx, false})
	// `.negate()` on unitIsBeingTransported.
	append(&airbase_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{a_bt_fn, a_bt_ctx, true})
	self.airbase_that_can_scramble_predicate_fn = scramble_logic_pred_unit_and_eval
	self.airbase_that_can_scramble_predicate_ctx = rawptr(airbase_ctx)

	// canScrambleFromPredicate
	water_fn, water_ctx := matches_territory_is_water()
	enemy_fn, enemy_ctx := matches_is_territory_enemy(player)

	// Inner unit predicate: canScramble AND enemy AND notDisabled.
	cs_fn, cs_ctx := matches_unit_can_scramble()
	cs_eo_fn, cs_eo_ctx := matches_unit_is_enemy_of(player)
	cs_nd_fn, cs_nd_ctx := matches_unit_is_not_disabled()
	scrambler_unit_ctx := new(Scramble_Logic_And_Pred_Unit_Ctx)
	scrambler_unit_ctx.entries = make([dynamic]Scramble_Logic_And_Pred_Unit_Entry, 0, 3)
	append(&scrambler_unit_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{cs_fn, cs_ctx, false})
	append(&scrambler_unit_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{cs_eo_fn, cs_eo_ctx, false})
	append(&scrambler_unit_ctx.entries, Scramble_Logic_And_Pred_Unit_Entry{cs_nd_fn, cs_nd_ctx, false})
	has_scramblers_fn, has_scramblers_ctx := matches_territory_has_units_that_match(
		scramble_logic_pred_unit_and_eval,
		rawptr(scrambler_unit_ctx),
	)

	// Outer airbase-presence predicate uses the airbase predicate we
	// just built, faithful to Java referencing
	// `airbaseThatCanScramblePredicate` mid-construction.
	has_airbases_fn, has_airbases_ctx := matches_territory_has_units_that_match(
		self.airbase_that_can_scramble_predicate_fn,
		self.airbase_that_can_scramble_predicate_ctx,
	)

	island_only := properties_get_scramble_from_island_only(game_state_get_properties(data))
	island_fn, island_ctx := matches_territory_is_island()

	csf_ctx := new(Scramble_Logic_Can_Scramble_From_Ctx)
	csf_ctx.water_fn = water_fn
	csf_ctx.water_ctx = water_ctx
	csf_ctx.enemy_fn = enemy_fn
	csf_ctx.enemy_ctx = enemy_ctx
	csf_ctx.has_scramblers_fn = has_scramblers_fn
	csf_ctx.has_scramblers_ctx = has_scramblers_ctx
	csf_ctx.has_airbases_fn = has_airbases_fn
	csf_ctx.has_airbases_ctx = has_airbases_ctx
	csf_ctx.island_only = island_only
	csf_ctx.island_fn = island_fn
	csf_ctx.island_ctx = island_ctx

	self.can_scramble_from_predicate_fn = scramble_logic_pred_can_scramble_from_eval
	self.can_scramble_from_predicate_ctx = rawptr(csf_ctx)

	self.max_scramble_distance = scramble_logic_compute_max_scramble_distance(data)
	return self
}
// One file per Java class. Replace this header when the
// class's structs and procs are fully ported.
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.ScrambleLogic

scramble_logic_get_airbase_that_can_scramble_predicate :: proc(self: ^Scramble_Logic) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return self.airbase_that_can_scramble_predicate_fn, self.airbase_that_can_scramble_predicate_ctx
}

// private static int computeMaxScrambleDistance(final GameState data)
scramble_logic_compute_max_scramble_distance :: proc(data: ^Game_State) -> i32 {
	max_scramble_distance: i32 = 0
	for ut in unit_type_list_iterator(game_state_get_unit_type_list(data)) {
		ua := unit_type_get_unit_attachment(ut)
		if unit_attachment_can_scramble(ua) &&
		   max_scramble_distance < unit_attachment_get_max_scramble_distance(ua) {
			max_scramble_distance = unit_attachment_get_max_scramble_distance(ua)
		}
	}
	return max_scramble_distance
}

// public static int getMaxScrambleCount(final Collection<Unit> airbases)
scramble_logic_get_max_scramble_count :: proc(airbases: [dynamic]^Unit) -> i32 {
	is_air_base_fn, is_air_base_ctx := matches_unit_is_air_base()
	not_disabled_fn, not_disabled_ctx := matches_unit_is_not_disabled()
	if len(airbases) == 0 {
		panic("All units must be viable airbases")
	}
	for u in airbases {
		if !is_air_base_fn(is_air_base_ctx, u) || !not_disabled_fn(not_disabled_ctx, u) {
			panic("All units must be viable airbases")
		}
	}
	max_scrambled: i32 = 0
	for airbase in airbases {
		base_max := unit_get_max_scramble_count(airbase)
		if base_max == -1 {
			return max(i32)
		}
		max_scrambled += base_max
	}
	return max_scrambled
}

// Java:
//   public ScrambleLogic(
//       final GameState data,
//       final GamePlayer player,
//       final Set<Territory> territoriesWithBattles) {
//     this(data, player, territoriesWithBattles, new BattleTracker());
//   }
scramble_logic_new_with_battles :: proc(
	data: ^Game_State,
	player: ^Game_Player,
	territories_with_battles: map[^Territory]struct{},
) -> ^Scramble_Logic {
	return scramble_logic_new(data, player, territories_with_battles, battle_tracker_new())
}

// Java:
//   private Collection<Territory> getCanScrambleFromTerritories(final Territory battleTerr) {
//     return CollectionUtils.getMatches(
//         data.getMap().getNeighbors(battleTerr, maxScrambleDistance),
//         canScrambleFromPredicate);
//   }
scramble_logic_get_can_scramble_from_territories :: proc(
	self: ^Scramble_Logic,
	battle_terr: ^Territory,
) -> [dynamic]^Territory {
	neighbors := game_map_get_neighbors_distance(
		game_state_get_map(self.data),
		battle_terr,
		self.max_scramble_distance,
	)
	result := make([dynamic]^Territory, 0, len(neighbors))
	for t, _ in neighbors {
		if self.can_scramble_from_predicate_fn(self.can_scramble_from_predicate_ctx, t) {
			append(&result, t)
		}
	}
	return result
}

// Java:
//   public Map<Territory, Map<Territory, Tuple<Collection<Unit>, Collection<Unit>>>>
//       getUnitsThatCanScrambleByDestination() { ... }
scramble_logic_get_units_that_can_scramble_by_destination :: proc(
	self: ^Scramble_Logic,
) -> map[^Territory]map[^Territory]^Tuple([dynamic]^Unit, [dynamic]^Unit) {
	to_sea_only := properties_get_scramble_to_sea_only(game_state_get_properties(self.data))
	to_any_amphibious := properties_get_scramble_to_any_amphibious_assault(
		game_state_get_properties(self.data),
	)

	// Java:
	//   final Collection<Territory> territoriesWithBattlesWater =
	//       CollectionUtils.getMatches(territoriesWithBattles, Matches.territoryIsWater());
	//   final Collection<Territory> territoriesWithBattlesLand =
	//       CollectionUtils.getMatches(territoriesWithBattles, Matches.territoryIsLand());
	water_fn, water_ctx := matches_territory_is_water()
	land_fn, land_ctx := matches_territory_is_land()
	territories_with_battles_water: [dynamic]^Territory
	territories_with_battles_land: [dynamic]^Territory
	for t, _ in self.territories_with_battles {
		if water_fn(water_ctx, t) {
			append(&territories_with_battles_water, t)
		}
		if land_fn(land_ctx, t) {
			append(&territories_with_battles_land, t)
		}
	}

	// `Map<Territory, Set<Territory>> scrambleTerrs` — keys: where to
	// scramble TO, values: places we can scramble FROM.
	scramble_terrs: map[^Territory]map[^Territory]struct {}

	for battle_terr in territories_with_battles_water {
		can_scramble_from := scramble_logic_get_can_scramble_from_territories(self, battle_terr)
		if len(can_scramble_from) > 0 {
			inner: map[^Territory]struct {}
			for ft in can_scramble_from {
				inner[ft] = {}
			}
			scramble_terrs[battle_terr] = inner
		}
	}

	// Build a fast-lookup set of water-battle territories so we can do
	// `amphibFromTerrs.removeAll(territoriesWithBattlesWater)` cheaply.
	water_battle_set: map[^Territory]struct {}
	for w in territories_with_battles_water {
		water_battle_set[w] = {}
	}

	for battle_terr in territories_with_battles_land {
		if !to_sea_only {
			can_scramble_from := scramble_logic_get_can_scramble_from_territories(
				self,
				battle_terr,
			)
			if len(can_scramble_from) > 0 {
				inner: map[^Territory]struct {}
				for ft in can_scramble_from {
					inner[ft] = {}
				}
				scramble_terrs[battle_terr] = inner
			}
		}
		// Java:
		//   final IBattle battle = battleTracker.getPendingBattle(battleTerr, BattleType.NORMAL);
		battle := battle_tracker_get_pending_battle(self.battle_tracker, battle_terr, .NORMAL)
		if battle != nil && i_battle_is_amphibious(battle) {
			// Java guards with `battle instanceof DependentBattle`; the
			// existing Odin port (see matches.odin
			// `lambda_battle_is_amphibious_with_units_attacking_from_122`)
			// notes that any battle whose `isAmphibious()` returns true is a
			// DependentBattle subtype, so the unchecked cast is structurally
			// safe.
			db := cast(^Dependent_Battle)battle
			amphib_from_terrs := dependent_battle_get_amphibious_attack_territories(db)
			for amphib_from in amphib_from_terrs {
				if _, in_water := water_battle_set[amphib_from]; in_water {
					continue
				}
				if to_any_amphibious {
					// Java:
					//   scrambleTerrs.computeIfAbsent(amphibFrom, key -> new HashSet<>())
					//                .addAll(getCanScrambleFromTerritories(amphibFrom));
					territories := scramble_logic_get_can_scramble_from_territories(
						self,
						amphib_from,
					)
					inner: map[^Territory]struct {}
					if existing, ok := scramble_terrs[amphib_from]; ok {
						inner = existing
					} else {
						inner = make(map[^Territory]struct {})
					}
					for tt in territories {
						inner[tt] = {}
					}
					scramble_terrs[amphib_from] = inner
				} else if self.can_scramble_from_predicate_fn(
					self.can_scramble_from_predicate_ctx,
					battle_terr,
				) {
					// Java:
					//   scrambleTerrs.computeIfAbsent(amphibFrom, key -> new HashSet<>())
					//                .add(battleTerr);
					inner: map[^Territory]struct {}
					if existing, ok := scramble_terrs[amphib_from]; ok {
						inner = existing
					} else {
						inner = make(map[^Territory]struct {})
					}
					inner[battle_terr] = {}
					scramble_terrs[amphib_from] = inner
				}
			}
		}
	}

	// Java: `if (scrambleTerrs.isEmpty()) return Map.of();`
	if len(scramble_terrs) == 0 {
		return {}
	}

	// `Predicate<Unit> unitCanScramble = enemyOf(player) AND canScramble
	// AND notDisabled AND NOT wasScrambled`. Each `matches_*` factory
	// allocates internally, so we build them once outside the loops.
	ucs_eo_fn, ucs_eo_ctx := matches_unit_is_enemy_of(self.player)
	ucs_cs_fn, ucs_cs_ctx := matches_unit_can_scramble()
	ucs_nd_fn, ucs_nd_ctx := matches_unit_is_not_disabled()
	ucs_ws_fn, ucs_ws_ctx := matches_unit_was_scrambled()

	scramblers_by_territory: map[^Territory]map[^Territory]^Tuple(
		[dynamic]^Unit,
		[dynamic]^Unit,
	)

	for to, _ in scramble_terrs {
		scramblers: map[^Territory]^Tuple([dynamic]^Unit, [dynamic]^Unit)
		from_set := scramble_terrs[to]
		for from, _ in from_set {
			from_units := territory_get_unit_collection(from)
			// Java: `Collection<Unit> airbases =
			//   fromUnits.getMatches(airbaseThatCanScramblePredicate);`
			airbases: [dynamic]^Unit
			for u in from_units.units {
				if self.airbase_that_can_scramble_predicate_fn(
					self.airbase_that_can_scramble_predicate_ctx,
					u,
				) {
					append(&airbases, u)
				}
			}
			if scramble_logic_get_max_scramble_count(airbases) == 0 {
				continue
			}
			// Java:
			//   final Route toBattleRoute =
			//       data.getMap()
			//           .getRoute(from, to, Matches.territoryIsNotImpassable())
			//           .orElseThrow(() -> new IllegalStateException(...));
			// `game_map_get_route` takes a non-capturing
			// `proc(^Territory) -> bool`; `matches_territory_is_not_impassable`
			// is itself non-capturing (its rawptr ctx is unused), so a
			// trivial bare-proc wrapper is equivalent.
			to_battle_route := game_map_get_route(
				game_state_get_map(self.data),
				from,
				to,
				scramble_logic_route_is_not_impassable,
			)
			if to_battle_route == nil {
				panic("Route object should be found")
			}
			on_route_fn, on_route_ctx := matches_unit_can_scramble_on_route_distance(
				to_battle_route,
			)
			can_scramble_air: [dynamic]^Unit
			for u in from_units.units {
				if !ucs_eo_fn(ucs_eo_ctx, u) {
					continue
				}
				if !ucs_cs_fn(ucs_cs_ctx, u) {
					continue
				}
				if !ucs_nd_fn(ucs_nd_ctx, u) {
					continue
				}
				if ucs_ws_fn(ucs_ws_ctx, u) {
					// negated in Java: `unitWasScrambled().negate()`
					continue
				}
				if !on_route_fn(on_route_ctx, u) {
					continue
				}
				append(&can_scramble_air, u)
			}
			if len(can_scramble_air) > 0 {
				scramblers[from] = tuple_new(
					[dynamic]^Unit,
					[dynamic]^Unit,
					airbases,
					can_scramble_air,
				)
			}
		}
		if len(scramblers) == 0 {
			continue
		}
		scramblers_by_territory[to] = scramblers
	}
	return scramblers_by_territory
}

// Bare `proc(^Territory) -> bool` adapter for
// `matches_territory_is_not_impassable`, which is non-capturing and
// thus safe to invoke without its (unused) ctx. Used by
// `scramble_logic_get_units_that_can_scramble_by_destination` to feed
// `game_map_get_route`'s plain predicate parameter.
scramble_logic_route_is_not_impassable :: proc(t: ^Territory) -> bool {
	fn, ctx := matches_territory_is_not_impassable()
	return fn(ctx, t)
}

