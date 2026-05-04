package game

Tech_Tracker :: struct {
	data:  ^Game_Data,
	cache: map[^Tech_Tracker_Key]any,
}

// =====================================================================
// Method ports — TechTracker (layer 0).
//
// Naming convention: lambdas extracted by javac become standalone procs
// `tech_tracker_lambda_<method>_<n>` mirroring Java's `lambda$<method>$<n>`.
// Captured Java locals become explicit Odin proc parameters; functional
// interfaces (Supplier, BooleanSupplier, ToIntFunction, Function) are
// represented as Odin proc literals.
// =====================================================================

// Java: @AllArgsConstructor — TechTracker(GameData data).
// Allocates a new tracker with the given game data and an empty cache
// (Java initializes `cache = new ConcurrentHashMap<>();` at the field).
tech_tracker_new :: proc(data: ^Game_Data) -> ^Tech_Tracker {
	self := new(Tech_Tracker)
	self.data = data
	self.cache = make(map[^Tech_Tracker_Key]any)
	return self
}

// Java: public void clearCache() { cache.clear(); }
tech_tracker_clear_cache :: proc(self: ^Tech_Tracker) {
	clear(&self.cache)
}

// Java: lambda$getCached$17(Supplier, Key) — `key -> getter.get()` passed
// to `cache.computeIfAbsent(...)` inside the int-returning getCached
// overload. The Key parameter is unused; only the captured Supplier is
// invoked. Boxed Integer maps to Odin i32.
tech_tracker_lambda_get_cached_17 :: proc(getter: proc() -> i32, key: ^Tech_Tracker_Key) -> i32 {
	_ = key
	return getter()
}

// Java: lambda$getCached$18(BooleanSupplier, Key) — `key -> getter.getAsBoolean()`
// passed to `cache.computeIfAbsent(...)` inside the boolean-returning
// getCached overload.
tech_tracker_lambda_get_cached_18 :: proc(getter: proc() -> bool, key: ^Tech_Tracker_Key) -> bool {
	_ = key
	return getter()
}

// Java: lambda$getMinimumTerritoryValueForProductionBonus$13(int)
//   `i -> i != -1` — IntStream filter inside
//   getMinimumTerritoryValueForProductionBonus(GamePlayer).
tech_tracker_lambda_get_minimum_territory_value_for_production_bonus_13 :: proc(i: i32) -> bool {
	return i != -1
}

// Java: lambda$getUnitAbilitiesGained$20(UnitType, Map)
//   `m -> m.get(unitType)` — given a Map<UnitType, Set<String>> from a
//   TechAbilityAttachment.getUnitAbilitiesGained() call, look up the set
//   for the captured unitType. The captured Java local becomes the first
//   Odin parameter.
tech_tracker_lambda_get_unit_abilities_gained_20 :: proc(
	unit_type: ^Unit_Type,
	m: map[^Unit_Type]map[string]struct {},
) -> map[string]struct {} {
	return m[unit_type]
}

// Java: lambda$sumNumbers$21(String, TechAbilityAttachment)
//   `i -> i.getAttachedTo().toString().equals(attachmentType)` — predicate
//   in sumNumbers(...) selecting attachments whose owning TechAdvance
//   name matches the supplied attachmentType (e.g. TECH_NAME_ROCKETS).
//   The TechAbilityAttachment is always attached to a TechAdvance, whose
//   `toString()` resolves to its Named name; we read that name through
//   the embedded Default_Named chain on Tech_Advance.
tech_tracker_lambda_sum_numbers_21 :: proc(
	attachment_type: string,
	taa: ^Tech_Ability_Attachment,
) -> bool {
	if taa == nil || taa.attached_to == nil {
		return false
	}
	advance := cast(^Tech_Advance)taa.attached_to
	return advance.named_attachable.default_named.base.name == attachment_type
}

// Java: lambda$sumNumbers$22(int)  `i -> i > 0` — IntStream filter inside
// sumNumbers(...).
tech_tracker_lambda_sum_numbers_22 :: proc(i: i32) -> bool {
	return i > 0
}

// Java: static int sumIntegerMap(
//     Function<TechAbilityAttachment, IntegerMap<UnitType>> mapper,
//     UnitType ut, Collection<TechAdvance> techAdvances)
// Sum, across non-null attachments, of mapper(taa).getInt(ut).
// Integer_Map stores values keyed by rawptr, so the UnitType pointer is
// looked up directly with `[rawptr(ut)]` and missing keys read as zero.
tech_tracker_sum_integer_map :: proc(
	mapper: proc(taa: ^Tech_Ability_Attachment) -> ^Integer_Map,
	ut: ^Unit_Type,
	tech_advances: [dynamic]^Tech_Advance,
) -> i32 {
	total: i32 = 0
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		im := mapper(taa)
		if im == nil {
			continue
		}
		v, _ := im.map_values[rawptr(ut)]
		total += v
	}
	return total
}

// Java: @VisibleForTesting static int sumNumbers(
//     ToIntFunction<TechAbilityAttachment> mapper,
//     String attachmentType, Collection<TechAdvance> techAdvances)
// Stream pipeline:
//   techAdvances.stream()
//       .map(TechAbilityAttachment::get)
//       .filter(Objects::nonNull)
//       .filter(i -> i.getAttachedTo().toString().equals(attachmentType))
//       .mapToInt(mapper)
//       .filter(i -> i > 0)
//       .sum();
tech_tracker_sum_numbers :: proc(
	mapper: proc(taa: ^Tech_Ability_Attachment) -> i32,
	attachment_type: string,
	tech_advances: [dynamic]^Tech_Advance,
) -> i32 {
	total: i32 = 0
	for ta in tech_advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		if !tech_tracker_lambda_sum_numbers_21(attachment_type, taa) {
			continue
		}
		v := mapper(taa)
		if !tech_tracker_lambda_sum_numbers_22(v) {
			continue
		}
		total += v
	}
	return total
}

// Java: lambda$sumIntegerMap$19(UnitType, IntegerMap)
//   `m -> m.getInt(ut)` — IntStream mapper inside sumIntegerMap(...). The
//   captured Java local `ut` becomes the first Odin parameter; the stream
//   element (an IntegerMap<UnitType>) becomes the second. IntegerMap stores
//   values keyed by rawptr, so the UnitType pointer is widened directly.
tech_tracker_lambda_sum_integer_map_19 :: proc(ut: ^Unit_Type, m: ^Integer_Map) -> i32 {
	return integer_map_get_int(m, rawptr(ut))
}

// Java: private int getCached(GamePlayer, UnitType, String, Supplier<Integer>)
//   return (Integer) cache.computeIfAbsent(new Key(player, type, property),
//                                          key -> getter.get());
// Per llm-instructions.md the Java boxed Object return is represented as
// rawptr in Odin (Supplier<T> generic; integer callers box to ^i32 at the
// call site). Cache keys are heap-allocated Tech_Tracker_Key values whose
// `equals` collapses to component-wise comparison; we scan the map for a
// matching key (Java's @Value Key uses by-value equality, but the Odin
// cache map is keyed by ^Tech_Tracker_Key so we cannot rely on builtin
// hashing). On a miss, allocate a new key, invoke the getter, store, and
// return the produced value.
tech_tracker_get_cached :: proc(
	self: ^Tech_Tracker,
	player: ^Game_Player,
	type: ^Unit_Type,
	property: string,
	getter: proc() -> rawptr,
) -> rawptr {
	for k, v in self.cache {
		if k.player == player && k.unit_type == type && k.property == property {
			return v.(rawptr)
		}
	}
	key := new(Tech_Tracker_Key)
	tech_tracker_key_init(key, player, type, property)
	value := tech_tracker_lambda_get_cached_17_rawptr(getter, key)
	self.cache[key] = value
	return value
}

// Helper mirroring Java's `key -> getter.get()` for the rawptr Supplier
// flavor of getCached. The corresponding `proc() -> i32` flavor is the
// pre-existing tech_tracker_lambda_get_cached_17.
@(private = "file")
tech_tracker_lambda_get_cached_17_rawptr :: proc(
	getter: proc() -> rawptr,
	key: ^Tech_Tracker_Key,
) -> rawptr {
	_ = key
	return getter()
}

// Java: private boolean getCached(GamePlayer, UnitType, String, BooleanSupplier)
//   return (Boolean) cache.computeIfAbsent(new Key(player, type, property),
//                                          key -> getter.getAsBoolean());
// Same key-scan strategy as the Supplier overload; the cached value is a
// bool and the getter is a `proc() -> bool` literal (BooleanSupplier).
tech_tracker_get_cached_bool :: proc(
	self: ^Tech_Tracker,
	player: ^Game_Player,
	type: ^Unit_Type,
	property: string,
	getter: proc() -> bool,
) -> bool {
	for k, v in self.cache {
		if k.player == player && k.unit_type == type && k.property == property {
			return v.(bool)
		}
	}
	key := new(Tech_Tracker_Key)
	tech_tracker_key_init(key, player, type, property)
	value := tech_tracker_lambda_get_cached_18(getter, key)
	self.cache[key] = value
	return value
}

// Java: lambda$getCurrentTechAdvances$23(TechAttachment, TechAdvance)
//   `ta -> ta.hasTech(attachment)` — predicate inside
//   getCurrentTechAdvances(GamePlayer, TechnologyFrontier) selecting tech
//   advances the player has researched. The captured TechAttachment is
//   the first parameter; the stream element TechAdvance is second. The
//   polymorphic `hasTech` dispatch is provided by the orchestrator's
//   tech_advance_has_tech helper, which calls the per-subtype proc field
//   wired at Tech_Advance construction time.
tech_tracker_lambda_get_current_tech_advances_23 :: proc(
	attachment: ^Tech_Attachment,
	ta: ^Tech_Advance,
) -> bool {
	return tech_advance_has_tech(ta, attachment)
}

// Java: lambda$getFullyResearchedPlayerTechCategories$24(TechAttachment, TechAdvance)
//   `t -> t.hasTech(attachment)` — predicate passed to `allMatch` on each
//   TechnologyFrontier's techs inside getFullyResearchedPlayerTechCategories.
//   Identical shape to lambda 23; the distinct javac index is preserved.
tech_tracker_lambda_get_fully_researched_player_tech_categories_24 :: proc(
	attachment: ^Tech_Attachment,
	t: ^Tech_Advance,
) -> bool {
	return tech_advance_has_tech(t, attachment)
}

// =====================================================================
// Static-port bonus accessors.
//
// These methods are recorded in port.sqlite as static (no Tech_Tracker
// receiver) — the call sites in the AI test path treat them as pure
// functions of (GamePlayer[, UnitType]). The instance variant in Java
// caches results in a ConcurrentHashMap; the static port is faithful to
// the *real behavior* (the bonus values produced) but skips the cache,
// which is a pure performance optimization. Each method:
//   1. Resolves the player's currently-researched TechAdvances by
//      walking the player's TechnologyFrontier (via getData()) and
//      filtering with TechAdvance.hasTech(playerTechAttachment) —
//      exactly the inline expansion of Java's
//      `getCurrentTechAdvances(player)` instance helper.
//   2. Sums (or, for can*, ORs) the per-attachment value the Java
//      method-reference selects from each non-null TechAbilityAttachment.
// Lower-layer methods such as `getCurrentTechAdvances(GamePlayer)` and
// `getSumOfBonuses(...)` are at higher method_layers in the tracker and
// would otherwise require forward references; the per-method bodies
// inline the equivalent stream pipelines instead.
// =====================================================================

// Inline expansion of Java's instance `getCurrentTechAdvances(GamePlayer)`,
// which delegates to the static `getCurrentTechAdvances(GamePlayer,
// TechnologyFrontier)`. Both higher-layer procs are deliberately not
// referenced here — the body is exactly their composed behavior.
@(private = "file")
tech_tracker_static_current_tech_advances :: proc(
	player: ^Game_Player,
) -> [dynamic]^Tech_Advance {
	result := make([dynamic]^Tech_Advance, 0)
	if player == nil {
		return result
	}
	attachment := game_player_get_tech_attachment(player)
	data := game_player_get_data(player)
	if data == nil {
		return result
	}
	frontier := game_data_get_technology_frontier(data)
	all := tech_advance_get_tech_advances(frontier, player)
	defer delete(all)
	for ta in all {
		if tech_tracker_lambda_get_current_tech_advances_23(attachment, ta) {
			append(&result, ta)
		}
	}
	return result
}

// Java: public int getMovementBonus(GamePlayer player, UnitType type)
//   getCached(... () -> getSumOfBonuses(TAA::getMovementBonus, type, player))
// Static port: sumIntegerMap(TAA::getMovementBonus, type, currentTechAdvances).
tech_tracker_get_movement_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.movement_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.movement_bonus, rawptr(type))
	}
	return total
}

// Java: public int getAttackBonus(GamePlayer player, UnitType type)
tech_tracker_get_attack_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.attack_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.attack_bonus, rawptr(type))
	}
	return total
}

// Java: public int getAttackRollsBonus(GamePlayer player, UnitType type)
tech_tracker_get_attack_rolls_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.attack_rolls_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.attack_rolls_bonus, rawptr(type))
	}
	return total
}

// Java: public int getDefenseBonus(GamePlayer player, UnitType type)
tech_tracker_get_defense_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.defense_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.defense_bonus, rawptr(type))
	}
	return total
}

// Java: public int getDefenseRollsBonus(GamePlayer player, UnitType type)
tech_tracker_get_defense_rolls_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.defense_rolls_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.defense_rolls_bonus, rawptr(type))
	}
	return total
}

// Java: public int getRadarBonus(GamePlayer player, UnitType type)
tech_tracker_get_radar_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.radar_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.radar_bonus, rawptr(type))
	}
	return total
}

// Java: public int getRocketDiceNumber(GamePlayer player, UnitType type)
tech_tracker_get_rocket_dice_number :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.rocket_dice_number == nil {
			continue
		}
		total += integer_map_get_int(taa.rocket_dice_number, rawptr(type))
	}
	return total
}

// Java: public int getBombingBonus(GamePlayer player, UnitType type)
tech_tracker_get_bombing_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.bombing_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.bombing_bonus, rawptr(type))
	}
	return total
}

// Java: public int getProductionBonus(GamePlayer player, UnitType type)
tech_tracker_get_production_bonus :: proc(player: ^Game_Player, type: ^Unit_Type) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	total: i32 = 0
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil || taa.production_bonus == nil {
			continue
		}
		total += integer_map_get_int(taa.production_bonus, rawptr(type))
	}
	return total
}

// Java: public boolean canBlitz(GamePlayer player, UnitType type)
//   getUnitAbilitiesGained(ABILITY_CAN_BLITZ, type, player)
//   = currentTechAdvances.stream()
//        .map(TAA::get).filter(nonNull)
//        .map(TAA::getUnitAbilitiesGained)
//        .map(m -> m.get(type)).filter(nonNull)
//        .flatMap(Collection::stream)
//        .anyMatch(ABILITY_CAN_BLITZ::equals);
tech_tracker_can_blitz :: proc(player: ^Game_Player, type: ^Unit_Type) -> bool {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		set, ok := taa.unit_abilities_gained[type]
		if !ok {
			continue
		}
		if _, present := set[ABILITY_CAN_BLITZ]; present {
			return true
		}
	}
	return false
}

// Java: public boolean canBombard(GamePlayer player, UnitType type)
tech_tracker_can_bombard :: proc(player: ^Game_Player, type: ^Unit_Type) -> bool {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		set, ok := taa.unit_abilities_gained[type]
		if !ok {
			continue
		}
		if _, present := set[ABILITY_CAN_BOMBARD]; present {
			return true
		}
	}
	return false
}

// Java: public int getMinimumTerritoryValueForProductionBonus(GamePlayer player)
//   max(0, currentTechAdvances.stream()
//             .map(TAA::get).filter(nonNull)
//             .mapToInt(TAA::getMinimumTerritoryValueForProductionBonus)
//             .filter(i -> i != -1)
//             .min()
//             .orElse(-1));
tech_tracker_get_minimum_territory_value_for_production_bonus :: proc(
	player: ^Game_Player,
) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	min_val: i32 = -1
	have_any := false
	for ta in advances {
		taa := tech_ability_attachment_get(ta)
		if taa == nil {
			continue
		}
		v := taa.minimum_territory_value_for_production_bonus
		if !tech_tracker_lambda_get_minimum_territory_value_for_production_bonus_13(v) {
			continue
		}
		if !have_any || v < min_val {
			min_val = v
			have_any = true
		}
	}
	if !have_any {
		min_val = -1
	}
	if min_val < 0 {
		return 0
	}
	return min_val
}

// Java: public int getRocketNumberPerTerritory(GamePlayer player)
//   sumNumbers(TAA::getRocketNumberPerTerritory, TECH_NAME_ROCKETS,
//              currentTechAdvances).
// TECH_NAME_ROCKETS == "Rockets Advance" (Java TechAdvance constant).
tech_tracker_get_rocket_number_per_territory :: proc(player: ^Game_Player) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	mapper :: proc(taa: ^Tech_Ability_Attachment) -> i32 {
		return taa.rocket_number_per_territory
	}
	return tech_tracker_sum_numbers(mapper, "Rockets Advance", advances)
}

// Java: public int getRocketDistance(GamePlayer player)
//   sumNumbers(TAA::getRocketDistance, TECH_NAME_ROCKETS,
//              currentTechAdvances).
tech_tracker_get_rocket_distance :: proc(player: ^Game_Player) -> i32 {
	advances := tech_tracker_static_current_tech_advances(player)
	defer delete(advances)
	mapper :: proc(taa: ^Tech_Ability_Attachment) -> i32 {
		return taa.rocket_distance
	}
	return tech_tracker_sum_numbers(mapper, "Rockets Advance", advances)
}

// Java: public static Collection<TechAdvance> getCurrentTechAdvances(
//     GamePlayer gamePlayer, TechnologyFrontier technologyFrontier)
//   final TechAttachment attachment = gamePlayer.getTechAttachment();
//   return TechAdvance.getTechAdvances(technologyFrontier).stream()
//       .filter(ta -> ta.hasTech(attachment))
//       .collect(Collectors.toList());
// Mirrors the inline-expansion already used by the static bonus accessors
// (tech_tracker_static_current_tech_advances), but takes the frontier as
// an explicit parameter rather than reading it from data.
tech_tracker_get_current_tech_advances :: proc(
	game_player: ^Game_Player,
	technology_frontier: ^Technology_Frontier,
) -> [dynamic]^Tech_Advance {
	result := make([dynamic]^Tech_Advance, 0)
	if game_player == nil {
		return result
	}
	attachment := game_player_get_tech_attachment(game_player)
	all := tech_advance_get_tech_advances(technology_frontier, game_player)
	defer delete(all)
	for ta in all {
		if tech_tracker_lambda_get_current_tech_advances_23(attachment, ta) {
			append(&result, ta)
		}
	}
	return result
}

// Java: public static int getTechCost(GamePlayer player)
//   return player.getTechAttachment().getTechCost();
tech_tracker_get_tech_cost :: proc(player: ^Game_Player) -> i32 {
	return tech_attachment_get_tech_cost(game_player_get_tech_attachment(player))
}

// Java: public static boolean hasSuperSubs(GamePlayer player)
//   return player.getTechAttachment().getSuperSub();
tech_tracker_has_super_subs :: proc(player: ^Game_Player) -> bool {
	return tech_attachment_get_super_sub(game_player_get_tech_attachment(player))
}

// Java: public static boolean hasRocket(GamePlayer player)
//   return player.getTechAttachment().getRocket();
tech_tracker_has_rocket :: proc(player: ^Game_Player) -> bool {
	return tech_attachment_get_rocket(game_player_get_tech_attachment(player))
}

// Java: public static boolean hasImprovedArtillerySupport(GamePlayer player)
//   return player.getTechAttachment().getImprovedArtillerySupport();
tech_tracker_has_improved_artillery_support :: proc(player: ^Game_Player) -> bool {
	return tech_attachment_get_improved_artillery_support(
		game_player_get_tech_attachment(player),
	)
}

// Java: public static boolean hasParatroopers(GamePlayer player)
//   return player.getTechAttachment().getParatroopers();
tech_tracker_has_paratroopers :: proc(player: ^Game_Player) -> bool {
	return tech_attachment_get_paratroopers(game_player_get_tech_attachment(player))
}

// Java: private static Change createTechChange(
//     final TechAdvance advance, final GamePlayer player, final boolean value) {
//   final TechAttachment attachment = player.getTechAttachment();
//   if (advance instanceof GenericTechAdvance
//       && ((GenericTechAdvance) advance).getAdvance() == null) {
//     return ChangeFactory.genericTechChange(attachment, value, advance.getProperty());
//   }
//   return ChangeFactory.attachmentPropertyChange(
//       attachment, String.valueOf(value), advance.getProperty());
// }
// `instanceof GenericTechAdvance` is encoded by the `is_generic` discriminator
// flag on Tech_Advance (see tech_advance.odin); when true the pointer can be
// safely cast to ^Generic_Tech_Advance to read the wrapped advance. The
// String.valueOf(boolean) branch heap-allocates the literal "true"/"false"
// per the change_factory_attachment_property_change rawptr convention used
// throughout the port (cf. trigger_attachment.odin "uses" change emission).
tech_tracker_create_tech_change :: proc(
	advance: ^Tech_Advance,
	player: ^Game_Player,
	value: bool,
) -> ^Change {
	attachment := game_player_get_tech_attachment(player)
	if advance != nil && advance.is_generic {
		generic := cast(^Generic_Tech_Advance)advance
		if generic_tech_advance_get_advance(generic) == nil {
			return change_factory_generic_tech_change(
				attachment,
				value,
				tech_advance_get_property(advance),
			)
		}
	}
	new_value := new(string)
	new_value^ = value ? "true" : "false"
	return change_factory_attachment_property_change(
		cast(^I_Attachment)rawptr(attachment),
		rawptr(new_value),
		tech_advance_get_property(advance),
	)
}

// Java: private Collection<TechAdvance> getCurrentTechAdvances(GamePlayer player) {
//   return getCurrentTechAdvances(player, data.getTechnologyFrontier());
// }
// Instance overload that thunks to the static two-arg sibling already
// defined as tech_tracker_get_current_tech_advances. Suffix `_1` follows
// the project's arity-based overload-disambiguation convention
// (cf. territory_effect_attachment.odin).
tech_tracker_get_current_tech_advances_1 :: proc(
	self: ^Tech_Tracker,
	player: ^Game_Player,
) -> [dynamic]^Tech_Advance {
	return tech_tracker_get_current_tech_advances(
		player,
		game_data_get_technology_frontier(self.data),
	)
}

