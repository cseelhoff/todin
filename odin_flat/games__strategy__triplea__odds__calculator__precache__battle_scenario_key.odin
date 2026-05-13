package game

// Java: games.strategy.triplea.odds.calculator.precache.BattleScenarioKey
//
// Immutable, content-addressable identity for a battle simulation
// scenario. Two calls with the same scenario produce the same key;
// equal keys are safe to use as a SQLite primary key for memoised
// results. The cache key intentionally does NOT include the requested
// run count — a stored scenario with N simulations satisfies any
// subsequent request for <= N runs.

import "core:crypto/sha2"
import "core:encoding/hex"
import "core:slice"
import "core:strings"
import "core:fmt"

// Bumped together with any incompatible canonical-form / stored-result change.
BATTLE_SCENARIO_KEY_SCHEMA_VERSION :: 1

// Java: record BattleScenarioKey(...)
Battle_Scenario_Key :: struct {
	territory_name:           string,
	attacker_name:            string,
	defender_name:            string,
	attackers:                ^Unit_Composition,
	defenders:                ^Unit_Composition,
	bombarders:               ^Unit_Composition,
	territory_effect_names:   [dynamic]string,
	retreat_when_only_air_left: bool,
	game_data_fingerprint:    string,
	schema_version:           i32,
}

// Java: BattleScenarioKey.build(...)
battle_scenario_key_build :: proc(
	attacker:                 ^Game_Player,
	defender:                 ^Game_Player,
	location:                 ^Territory,
	attacking:                [dynamic]^Unit,
	defending:                [dynamic]^Unit,
	bombarding:               [dynamic]^Unit,
	territory_effects:        [dynamic]^Territory_Effect,
	retreat_when_only_air_left: bool,
	game_data:                ^Game_Data,
	allocator := context.allocator,
) -> ^Battle_Scenario_Key {
	self := new(Battle_Scenario_Key, allocator)
	self.territory_name = location == nil ? "?" : territory_get_name(location)
	self.attacker_name  = attacker == nil ? "<null>" : game_player_get_name(attacker)
	self.defender_name  = defender == nil ? "<null>" : game_player_get_name(defender)
	self.attackers      = unit_composition_from_units(attacking, allocator)
	self.defenders      = unit_composition_from_units(defending, allocator)
	self.bombarders     = unit_composition_from_units(bombarding, allocator)
	self.retreat_when_only_air_left = retreat_when_only_air_left
	self.game_data_fingerprint = game_data_fingerprint_compute(game_data, allocator)
	self.schema_version = BATTLE_SCENARIO_KEY_SCHEMA_VERSION

	self.territory_effect_names = make([dynamic]string, allocator)
	for te in territory_effects {
		if te == nil {
			append(&self.territory_effect_names, "?")
		} else {
			append(&self.territory_effect_names,
				default_named_get_name(&te.named_attachable.default_named))
		}
	}
	slice.sort(self.territory_effect_names[:])
	return self
}

// Java: BattleScenarioKey#toCanonicalString()
//   v=...\nterritory=...\nattacker=...\ndefender=...\n
//   retreatWhenOnlyAirLeft=...\neffects=a,b,c\n
//   attackers=...\ndefenders=...\nbombarders=...\ngame=...\n
battle_scenario_key_to_canonical_string :: proc(
	self: ^Battle_Scenario_Key, allocator := context.allocator,
) -> string {
	sb: strings.Builder
	strings.builder_init(&sb, allocator)

	fmt.sbprintf(&sb, "v=%d\n", self.schema_version)
	fmt.sbprintf(&sb, "territory=%s\n", self.territory_name)
	fmt.sbprintf(&sb, "attacker=%s\n",  self.attacker_name)
	fmt.sbprintf(&sb, "defender=%s\n",  self.defender_name)
	fmt.sbprintf(&sb, "retreatWhenOnlyAirLeft=%v\n", self.retreat_when_only_air_left)

	fmt.sbprintf(&sb, "effects=")
	for name, i in self.territory_effect_names {
		if i > 0 { strings.write_byte(&sb, ',') }
		strings.write_string(&sb, name)
	}
	strings.write_byte(&sb, '\n')

	atk := unit_composition_to_canonical_string(self.attackers, context.temp_allocator)
	def := unit_composition_to_canonical_string(self.defenders, context.temp_allocator)
	bom := unit_composition_to_canonical_string(self.bombarders, context.temp_allocator)
	fmt.sbprintf(&sb, "attackers=%s\n",  atk)
	fmt.sbprintf(&sb, "defenders=%s\n",  def)
	fmt.sbprintf(&sb, "bombarders=%s\n", bom)
	fmt.sbprintf(&sb, "game=%s\n", self.game_data_fingerprint)
	return strings.to_string(sb)
}

// Java: BattleScenarioKey#toCacheKey()
//   hex(SHA-256(toCanonicalString().getBytes(UTF-8)))
battle_scenario_key_to_cache_key :: proc(
	self: ^Battle_Scenario_Key, allocator := context.allocator,
) -> string {
	canonical := battle_scenario_key_to_canonical_string(self, context.temp_allocator)
	ctx: sha2.Context_256
	sha2.init_256(&ctx)
	sha2.update(&ctx, transmute([]byte)canonical)
	digest: [sha2.DIGEST_SIZE_256]byte
	sha2.final(&ctx, digest[:])
	encoded := hex.encode(digest[:], allocator)
	return string(encoded)
}
