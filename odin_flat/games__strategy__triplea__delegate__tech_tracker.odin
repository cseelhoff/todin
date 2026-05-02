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

