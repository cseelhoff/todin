# Deterministic-iteration policy & site tracker

## Goal

Java-Odin byte-equality of AI decisions requires that any map/set
iteration whose order influences AI output is iterated in a sort order
**both runtimes can trivially reproduce identically**.

We achieve this by wrapping impactful iteration sites — on **both** the
Java oracle and Odin port — with a sorted-iteration helper. The Java
side stops mirroring stock TripleA's `LinkedHashMap` JVM-hash ordering
in those spots, but the Odin port can finally match.

## Sort key conventions

| Map key type | Sort key | Java helper | Odin helper |
|---|---|---|---|
| `Territory` | `getName()` | `ProDeterminism.sortedTerritoryEntries(m)` | `pro_determinism_sorted_territory_keys(m)` |
| `Unit` | `(type.name, alreadyMoved)` + stable sort | `ProDeterminism.sortedUnitEntries(m)` | `pro_determinism_sorted_unit_keys(m)` |
| `GamePlayer` | `getName()` | `ProDeterminism.sortedPlayerEntries(m)` | `pro_determinism_sorted_player_keys(m)` |
| `UnitType` | `getName()` | `ProDeterminism.sortedUnitTypeEntries(m)` | `pro_determinism_sorted_unit_type_keys(m)` |

Unit ordering: deliberately property-based, NOT UUID — opaque keys
are hostile to debugging. Stable-sort preserves the underlying
collection's iteration order when all properties tie. If a future
divergence shows that's insufficient for a particular site, add a
territory-name tiebreak by passing a `Map<Unit, Territory>` to a
specialized overload.

## Workflow

1. Run r=2 DIGEST diff. The first divergence point identifies the
   step (e.g. `r=1 i=37 japaneseCombatMove` → divergence happened
   during the preceding `japanesePurchase`).
2. Inspect Java code for that step. Find map iterations whose order
   influences which-unit-where decisions (the impactful ones — pure
   logging or tally loops are skippable).
3. Wrap on **both** sides with the matching helper.
4. Re-run DIGEST. Divergence index should advance.
5. Add the site here under "Done".
6. Repeat until divergence reaches end-of-game.

## Sites — Done ✅

- `russianNonCombatMove` (r=1 i=15→16): fixed. Odin now matches Java
  byte-for-byte through i=20.

## Sites — In progress 🟡

- `japanesePurchase` (r=1 i=36→37, divergence visible at i=37
  japaneseCombatMove via PUs[Japanese]=1 Java vs 17 Odin). Japan's
  amphib loop returns nil → Odin buys 2 transports + 0 amphibs while
  Java buys 1 transport + 1 artillery + 1 infantry.

## Sites — Not yet investigated

(populated as new divergence points are localized)

## Skipped / not applicable

- Pure logging loops (`logAttackMoves`, `printMap`, etc.) — output
  text differs but no AI decisions affected.
- Tally / sum loops where iteration order doesn't change the result.

## Implementation files

- Java: `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/ProDeterminism.java`
- Odin: `odin_flat/games__strategy__triplea__ai__pro__util__pro_determinism.odin`
