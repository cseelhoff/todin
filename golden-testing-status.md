# Golden-testing status — TripleA Java→Odin port (Phase C)

> **Living document.** The orchestrator (driven by
> [`golden-testing-prompt.md`](./golden-testing-prompt.md)) reads
> this at session start and rewrites the four mutable sections at
> session end. Hand-edit only the "Failing snaps" table and "Notes"
> if you (the human) need to redirect.

---

## Last action

2026-06-04 (iter 71 — DRILLED the snap-0038 fighter air-move divergence. Added
gated `AIR_PROBE`/`CSL` probes to `pro_combat_move_ai_determine_units_to_attack_with`
(air block) and `can_air_safely_land_after_attack`. FINDING: every divergent
fighter choice is a TIE among win%=100 candidates broken by priority-iteration
ORDER + land-safety. The FIC fighter is the lever — Yunnan & Burma are BOTH
dist=1/win=100/land-safe; Odin's priority order `[Anhwei;Yunnan;Burma]` picks
Yunnan, but Java expects Burma (tally: Yunnan Exp=0, Burma Exp=1). EXONERATED
this pass: `can_air_safely_land_after_attack` is line-by-line faithful
[`ProCombatMoveAi.java:2115`]; the territory iteration order is faithful too —
`tryToAttackTerritories` [`ProCombatMoveAi.java:1374`] rebuilds the value set as
a `LinkedHashSet` in `prioritizedTerritories` order, so `sorted_territory_keys_by_priority`
matches. ⟹ ROOT is UPSTREAM: the attack-territory PRIORITY order of Yunnan vs
Burma. New bottom row = `ProCombatMoveAi#prioritizeAttackOptions`. Probes are
compile-gated (off by default); iter-69 markNoMovement guard untouched.)

## Last action (prev iter 70)

2026-06-04 (iter 70 — FULL-SUITE REGRESSION CHECK on the iter-69 markNoMovement
guard: **90 PASS / 14 FAIL** (was 89/104 at iter-62 baseline). FAIL set:
`0025 0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0090 0097 0100`.
Delta vs baseline: newly GREEN `0089`, `0092`; newly RED `0025`. A/B-tested the
0025 regression by building `/tmp/snaprun_iter68` with the 3 guards reverted —
**0025 PASSES on iter-68, FAILS on iter-69**, so the guard caused it. HOWEVER
the guard is a verified-faithful port: all 3 MovePerformer sites call the
guarded `markNoMovementChange(Set.of(unit))` Collection overload
[`MovePerformer.java:366,379,474`; `ChangeFactory.java:215-225`]. So 0025's new
germanPlace divergence (Germany +1 artillery/−1 infantry; Italy −1 artillery/+1
infantry, all Moves=0) is a LATENT already_moved divergence the faithful guard
now EXPOSES → DECISION: KEEP the guard (net 89→90), log 0025 as a new RED to
drill. iter-69 source restored from `/tmp/move_performer.iter69.bak`; 3 guards
verified present.)

## Last action (prev iter 69)

2026-06-04 (iter 69 — ROOT CAUSE FOUND + FIXED the amphib-unload movement
accounting bug. The SFE cargo accounting divergence is RESOLVED: infantry &
artillery now land with already_moved=4 matching Java. Snap 0038 is still RED
but ONLY on 4 fighter rows now — a separate air-move destination divergence
[30 Sea Zone / Burma / Yunnan] that is independent of the cargo root cause.)

**ROOT CAUSE (Java ground truth via JPROBE_0038 in MovePerformer):** Java's
`ChangeFactory.markNoMovementChange(Collection<Unit>)` overload (used at ALL
MovePerformer call sites via `markNoMovementChange(Set.of(unit))`) GUARDS each
reset with `if (unit.getMovementLeft().compareTo(BigDecimal.ZERO) >= 0)`. An
amphib-unloaded cargo unit has already over-accumulated movement during the
load + sea legs (already_moved=3 > maxMovement=1 ⟹ movementLeft = -2 < 0), so
Java SKIPS the reset, leaving already_moved=3; then `markMovementChange` adds
the unload route cost (1) ⟹ already_moved=4. Odin's 3 MovePerformer call sites
called the UNGUARDED single-unit `change_factory_mark_no_movement_change(unit)`,
which always sets already_moved = maxMovementAllowed+1 = 2, then +1 ⟹ 3.

Probe data (oracle, snap 0038): `MTM-UNLOAD-NOMOVE unit=infantry ...
alreadyMovedAfterNoMove=3` (Java did NOT reset to 2), then `MMC ... moved=1
alreadyMovedBefore=3 sum=4`. Odin without the guard produced
`alreadyMovedAfterNoMove=2` → `sum=3`.

**FIX (faithful port, 1 file — odin_flat/.../move_performer.odin):** Added the
`unit_get_movement_left(unit) >= 0` guard at the 3 single-unit
`change_factory_mark_no_movement_change` call sites that mirror Java's
`markNoMovementChange(Set.of(unit))`:
- `move_performer_mark_movement_change` conquered/empty-neutral land block (~657)
- `move_performer_mark_movement_change` subs-end-with-enemy-destroyer block (~680)
- `move_performer_mark_transports_movement` unload-leg noMovement (~871)
The existing `change_factory_mark_no_movement_change_collection` already had the
guard; these 3 sites were the only ones bypassing it. (Other call sites in
trigger_attachment / move_delegate / rockets_fire_helper use the single-unit
proc but are NOT amphib-unload paths; left unchanged for now — they mirror Java
single-unit semantics where applicable. Re-audit if a future snap implicates
them.)

**Result (FILTER_SNAP=0038):** SFE infantry/artillery rows GONE (cargo now
already_moved=4 ✓). Remaining RED = 4 fighter rows only:
`30 Sea Zone fighter Moves=1 Exp=1 Act=0`, `Burma fighter Moves=1 Exp=1 Act=0`,
`Burma fighter Moves=2 Exp=1 Act=2`, `Yunnan fighter Moves=1 Exp=0 Act=1`.

**NOT yet verified:** full snap suite (run batch to confirm no regression from
the markNoMovement guard). The fighter rows are the next descent target (iter
70) — an independent air-move destination divergence.

**What I changed (faithful port of Java's LinkedHashSet-from-HashSet order):**
- `ProTransport.transportMap` value in Java is a `LinkedHashSet` populated by
  `linkedHashSet.addAll(loadFromTerritories)` where `loadFromTerritories` is a
  plain `HashSet` (ProTerritoryManager.findAmphibMoveOptions). So the load-from
  iteration order = the accumulated first-seen order across the multiple
  `addTerritories` calls, each call iterating its own HashSet in JVM bucket
  order. Odin was instead sorting the FINAL set ALPHABETICALLY
  (`pro_determinism_sorted_territory_keys`), which broke the armour/artillery
  cargo tie the wrong way.
- `pro_transport.odin`: added a parallel `transport_map_order:
  map[^Territory][dynamic]^Territory` to `Pro_Transport` (insertion-ordered
  load-from list per unload territory), a getter
  `pro_transport_get_transport_map_order`, and changed
  `pro_transport_add_territories` to take an ORDERED slice and accumulate it
  with LinkedHashSet dedup semantics (first-seen position wins). The plain
  `transport_map` map is kept ONLY for membership/`in` checks.
- `pro_territory_manager.odin` `find_amphib_move_options`: before each
  `add_territories` call, sort that call's `load_from_territories` into Java
  HashSet bucket order via `java_hashmap_sort_territories_by_bucket(...,
  java_hashmap_capacity_for_size(len))`, then pass the ordered slice. (A SINGLE
  bucket-sort of the final set is NOT enough — proven: it gave
  `Manchuria,Kwangtung,Kiangsu,Japan` vs Java's accumulated
  `Kwangtung;Kiangsu;Japan;Manchuria`. Per-call accumulation is required.)
- `pro_combat_move_ai.odin` (amphib commit ~line 2254): read the ordered list
  `pro_transport_get_transport_map_order(inner_pt)[t]` and call the ordered
  variant `..._get_units_to_transport_from_ordered_territories_4` instead of the
  alphabetical map variant.
- `pro_transport_utils.odin` lines ~711 and ~1283: replaced the leftover
  alphabetical `pro_determinism_sorted_territory_keys` with the Java bucket-order
  sort (fallback path for non-combat callers; combat now uses the ordered list).

**Result (FILTER_SNAP=0038, /tmp/snaprun_0038planN, /tmp/snap0038_planN.log):**
- BEFORE iter-68: SFE = {infantry, armour} (wrong type).
- AFTER iter-68: `AMPHIB ... to=Soviet Far East ... types=[infantry,artillery]`
  — TYPE FIXED. The Manchuria/Kiangsu leftover-infantry divergence rows are
  GONE (source territories now match Java).
- REMAINING divergence (snap still RED): in the AFTER tally, "Moves" =
  `already_moved`:
  `Soviet Far East artillery Moves=4 Expected=1 Actual=0` /
  `Moves=3 Expected=0 Actual=1`, same for infantry — i.e. Odin's amphib cargo
  lands with already_moved=3, Java's with already_moved=4. Plus 3 fighter rows
  (30 Sea Zone, Burma, Yunnan) where Odin's fighters used one LESS move than
  Java's. These look like an amphib-unload / transport-route movement-accounting
  divergence (transport route length 3 vs 4), NOT a cargo-selection issue.

**Build recipe note (cd gets stripped by the shell wrapper):** build with
ABSOLUTE paths and no leading `cd` — `odin build
/home/caleb/todin/triplea/conversion/odin_tests/server_game_run_next_step
-collection:flat=/home/caleb/todin/odin_flat
-collection:test_common=/home/caleb/todin/triplea/conversion/odin_tests/test_common
-build-mode:test -define:PLAN=true -out:/tmp/snaprun_0038planN -no-bounds-check
-o:minimal`. Run inside a subshell so the cwd sticks: `( cd
/home/caleb/todin/triplea && export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
FILTER_SNAP=0038 LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && timeout 360
/tmp/snaprun_0038planN > /tmp/snap0038_planN.log 2>&1 )`.

**NOT yet verified:** the full snap suite (this change touches all amphib
planning). Re-run the batch to confirm no regressions once 0038 is fully green.

## Last action (prev iter 68)

(iter 68 — APPLIED THE STRUCTURAL FIX for the cargo load-from territory order.
SFE cargo TYPE fixed [artillery+infantry, was armour] AND source-territory diff
gone. Details above were superseded by the iter-69 cargo accounting fix; the
remaining divergence after iter-68 was the already_moved=3-vs-4 bug, now fixed.)

## Last action (prev iter 67)

**Got the Java oracle running.** `JAVA_HOME=/nix/store/c3pl7bqrx3d2rc3dh98z6yaj0mv1p52g-openjdk-21.0.10+7`,
then `cd triplea && ./gradlew --no-daemon --quiet :game-app:smoke-testing:test
--tests "*Ww2v5JacocoRun.runWithSnapshots"`. Added temporary `System.out`/file
probes (`jprobe` → `/tmp/jprobe_0038.txt`) in `ProCombatMoveAi` (amphib commit,
transport order, committed attackMap) and `ProTransportUtils`
(getUnitsToTransportFromTerritories gather+cargo). **All Java probes have been
REVERTED** (`git checkout` on the two files) — tree is clean.

**Java round-1 (snap 0038) GROUND TRUTH (JPROBE_COMMIT):**
`Soviet Far East=[infantry,artillery]  Alaska=[infantry,artillery]` — Java
loads ARTILLERY onto BOTH transports (two different artilleries; the map has
many Japanese artilleries — Japan, Kwangtung, Philippine Islands, etc.).
Odin gets `Alaska=[infantry,artillery]` but `SFE=[infantry,armour]`.

**The cargo SELECTION is FAITHFUL (re-confirmed).** Java round-2 probe
`terrs=Japan;Kwangtung;Soviet Far East gather=armour,artillery,... cargo=infantry,armour`
proves Java ALSO picks armour when Japan's artillery is ignored AND armour
leads the gather. So the comparator/sort/select match.

**ROOT CAUSE — territory iteration order breaks the armour/artillery tie.**
armour & artillery tie on transportCost AND on decreasing-attack, so the
STABLE cargo sort preserves the gather (territory-iteration) order. For the
SFE load set `{Japan, Kiangsu, Kwangtung, Manchuria}`:
- Java iterates it as `Kwangtung;Kiangsu;Japan;Manchuria` (Kwangtung FIRST →
  Kwangtung's artillery leads → cargo=artillery). This order is Java's
  `ProTransport.transportMap` value = a **LinkedHashSet** (INSERTION order
  from `ProTerritoryManager.findAmphibMoveOptions`), NOT sorted.
- Odin sorts it ALPHABETICALLY via `pro_determinism_sorted_territory_keys`
  (`pro_transport_utils.odin:722`) → `Japan;Kiangsu;Kwangtung;Manchuria`
  (Japan FIRST). With Japan's artillery ignored, Japan yields armour which
  leads → cargo=armour. **This is the user's "sort by name is a red flag"
  anti-pattern.**

**FIX (iter-68, structural):** `ProTransport.transportMap` value in Java is
`LinkedHashSet<Territory>` (`ProTransport.java:14`, populated via
`computeIfAbsent(...).addAll(loadFromTerritories)`). Odin currently stores it
as an unordered `map[^Territory]struct{}` and sorts by name at use. To port
faithfully: (1) make Odin's transport load-from set an INSERTION-ORDERED
structure (ordered list/set), (2) ensure `find_amphib_move_options`
(pro_territory_manager.odin) inserts load-from territories in Java's order,
(3) DELETE the alphabetical `pro_determinism_sorted_territory_keys` sort in
`get_units_to_transport_from_territories` so the insertion order is used.
Verify Java's insertion order against `findAmphibMoveOptions` (it iterates
`myUnitTerritories` then within-territory transports/neighbors).

Probe binary/logs: Java probes reverted; Odin probe binary
`/tmp/snaprun_0038plan5` (CARGO_PRE) still valid.

## Last action (prev iter 66)

2026-06-03 (iter 66 — NAMED the divergent commit with Java GROUND TRUTH:
Odin spuriously plans a 60 Sea Zone → ALASKA amphib that Java never makes,
consuming Japan's artillery before the SFE transport commits.

**Java after.json GROUND TRUTH (decisive).** Parsed
`snapshots/0038/after.json`: **Alaska = AMERICAN** (never attacked; its 60
SZ transport STAYS in 60 SZ with its battleship+destroyer escort, no cargo
loaded). **Soviet Far East = Japanese {artillery, infantry}**; the 61 SZ
transport moved to 63 SZ to unload. So Java's 60 SZ transport never moves.

**Odin AMPHIB probe (plan5).** Odin commits TWO amphibs:
`60 SZ → Alaska unloadFrom=64 SZ units=[infantry,artillery]` AND
`61 SZ → Soviet Far East unloadFrom=63 SZ units=[infantry,armour]`. Alaska
(attackValue 8.0) is processed BEFORE SFE (attackValue 0.1) in the
priority-ordered amphib loop, so the Alaska transport grabs Japan's
artillery first → when SFE's cargo is selected the artillery is already in
the ignore set → SFE gets armour. (Alaska is later dropped — the final
state has Alaska American, matching Java, with NO Alaska divergence — but
the SFE armour cargo was already locked in.)

**Reachability is LEGITIMATE, not a connectivity bug.** From before.json
neighbours: 60 SZ→64 SZ dist=2, 64 SZ→Alaska dist=1, so the transport CAN
load at Japan, move 60→63→64 (2), and unload Alaska. Java could attack
Alaska too — it just doesn't. So the divergence is NOT spurious sea-route
reachability.

**The amphib loop + cargo path are FAITHFUL (re-confirmed line-by-line
vs Java `ProCombatMoveAi` lines 1700-1800).** The `tryToAttackTerritories`
reset clears all attack_map entries each call (no stale persistence); the
unit-assignment loops iterate SORTED keys
(`sorted_unit_keys_by_move_options`, `sorted_territory_keys_by_priority`),
already hardened against pointer order; the amphib outer loop iterates the
`transport_map_list` LIST and the inner loop iterates
`prioritized_territories` (both faithful); the unload destination uses
`java_hashmap_bucket_for_string`. So the leak is NOT in layer 27's body.

**Localised to layer 28 = `determineTerritoriesToAttack`.** Its loop grows
`numToAttack` over the priority-ordered list, re-running
`tryToAttackTerritories` on `subList(0,numToAttack)` each step, and KEEPS a
territory only if its attack is "successful"
(`areSuccessful`: NOT (estimate<strengthEstimate AND (winPct<minWin OR
!hasLandUnitRemaining))). DUA_REMOVE_DECIDE shows Odin keeps Alaska with
**win%=100, hasLandRem=true, removed=false**. For Java to leave Alaska
American, Java must evaluate Alaska's attack as UNSUCCESSFUL (low win% or
weak strength estimate) and REMOVE it. ⇒ The real divergence is Odin
computing Alaska win%=100 / keeping it where Java removes it — either Odin
over-assigns attackers to Alaska or the battle-result estimation differs
(possible shared root with battle-resolution reds 0031/0074).

Files touched: none (investigation only; probes from iter-64/65 reused).
Probe binary `/tmp/snaprun_0038plan5`; log `/tmp/snap0038_plan5.log`.

## Last action (prev iter 65)

2026-06-03 (iter 65 — EXONERATED the cargo-selection code (layer 26) and
re-localised snap 0038 to the amphib COMMIT ORDER that fills the
already-attacked ignore set; NO logic fix — the faithful fix needs the
specific prior commit identified first).

**Corrected the transportCost facts (iter-64 assumed both cost 1 — WRONG).**
From `before.json` unitTypes: infantry transportCost=**2**, artillery=**3**,
armour=**3**, transport transportCapacity=**5**. So the cargo sort
(`transportCost asc, then decreasing-attack`) puts the four infantries
(cost 2) FIRST, then artillery+armour (cost 3) which TIE at
effective-attack 3. selectUnitsToTransportFromList loads inf+inf (cost 4),
then the replace-last branch swaps the weakest selected (an infantry) for
the strongest cost-≤3 remaining → artillery (Java) giving {infantry,
artillery} cost 5. For Odin to pick armour, armour must precede artillery
in the gather.

**CARGO_PRE probe PROVES the cargo code is FAITHFUL.** Added a
`when PLAN_PROBE` probe in
`get_units_to_transport_from_ordered_territories` printing the load-from
territory list + the pre-sort gather order. For `loadFrom=[Japan]` the
gather is CONSISTENTLY `[inf,inf,inf,inf,artillery,armour]` (artillery
before armour, matching `before.json`'s Japan order). armour only ever
precedes artillery in calls where **Japan's artillery is already in the
ignore set** (`ignored=2`): then Japan contributes only armour and the
nearest remaining artillery comes from Kwangtung (sorts AFTER Japan
alphabetically) → armour-before-artillery → armour selected. ⇒ The
divergence is NOT in the cargo comparator/sort/select (all faithful) but
in **whether Japan's artillery is consumed by a prior commit before the
SFE transport's cargo is selected**.

**Verified the obvious ordering inputs are all FAITHFUL insertion-ordered
lists** (so the pointer-layout leak is NOT in them): `game_map.territories`
(the snapshot serializer writes `map.getTerritories()` List order; the
JSON loader appends in array order), `pro_data.my_unit_territories`
(filtered from `game_map.territories` in order), `transport_map_list`
(built by iterating `my_unit_territories` then within-territory
`territory_get_matches` = `unit_collection.units` order),
`unit_collection.units` (JSON array order). `prioritized_territories`
uses an alphabetic pre-sort then a STABLE value-desc sort. None of these
is the leak.

**Remaining suspect = the COMMIT-ORDER iteration that adds Japan's
artillery to `attack_map` (hence the ignore set) before the SFE transport
commits.** The ignore set = `pro_transport_utils_get_moved_units(
already_moved_units, attack_map)` — a SET, so its own iteration order is
irrelevant; what matters is which moves are already in `attack_map`. That
is decided by the outer attack/amphib processing loop in
`tryToAttackTerritories` / `determineUnitsToAttackWith`. Next iter must
instrument, at the SFE-transport commit, whether Japan's artillery is in
`already_attacked_units_dyn` and which `attack_map` territory holds it —
that names the divergent prior commit (likely a land attack FROM Japan or
another amphib that Java does not make, or makes in a different order).

Files touched: `pro_transport_utils.odin` (+CARGO_PRE probe + freed the
support map in CARGO_CMP; all gated `when PLAN_PROBE`). Probe binary:
`/tmp/snaprun_0038plan5`; log `/tmp/snap0038_plan5.log`. (Prior iter-64
entry below.)

## Last action (prev iter 64)

2026-06-03 (iter 64 — DROVE snap 0038's cargo divergence down to its
ROOT and uncovered a broader pointer-order determinism bug; NO logic
fix yet — fixing now would be guessing at WHICH pointer-keyed iteration
to reorder).

**Ground truth (from the snapshot JSON, not probes).** Parsed
`snapshots/0038/{before,after}.json`. Java's `after.json`:
**Alaska stays AMERICAN — NOT attacked**; the 60 SZ transport STAYS
home; exactly ONE amphib assault happens: 61 SZ transport → 63 SZ →
unloads `{artillery, infantry}` into **Soviet Far East** (now Japanese).
Cargo pool = **Japan** territory (`{infantry×4, artillery×1, armour×1}`,
all alreadyMoved=0; before.json lists **artillery BEFORE armour**).
⇒ **Alaska was a RED HERRING**: the iter-63 `AMPHIB to=Alaska` lines
were a NON-FINAL planning iteration; the final plan attacks only SFE in
BOTH Java and Odin (Alaska is NOT in the divergence tally).

**The real divergence is pure cargo selection for the SFE transport:**
Odin loads `{armour, infantry m3}` where Java loads `{artillery,
infantry m4}`.

**Root cause of the armour-vs-artillery choice (proven by CARGO_CMP
probe).** Added a `when PLAN_PROBE` probe in
`pro_transport_utils_get_units_to_transport_from_ordered_territories`
(after the sort) printing each unit's `base+support=effective` attack.
Output: `artillery(base=2+sup=1=3)` and `armour(base=3+sup=0=3)` — they
**TIE at effective-attack 3** (Odin DOES apply artillery's offensive
support bonus; comparator + stable insertion sort are FAITHFUL). The tie
is broken by the order units sit in the load-from territory's unit
collection (`territory_get_matches` iterates `unit_collection.units`,
an insertion-ordered list). The probe shows Japan's order is
INCONSISTENT across calls — some lines `…artillery,armour`, others
`…armour,artillery` — i.e. the tie-break order is not faithfully Java's
stable `List`/`HashSet` order.

**BIGGER FINDING — pointer-layout determinism bug.** Built
`/tmp/snaprun_0038plan4` (`-define:PLAN=true` + CARGO_CMP probe). Ran the
SAME binary twice (`/tmp/div_A.txt` vs `/tmp/div_B.txt`): **IDENTICAL**
12-line divergence ⇒ deterministic WITHIN a binary. BUT iter-63's
`plan3` build (`-define:PLAN -define:AMPHIB_TRACE`, no cargo probe) gave
a **1-territory** divergence (SFE only), whereas the logically-equivalent
`plan4` build gives an **8-territory** divergence (fighters→Burma/Yunnan/
30 SZ, Japan armour & infantry counts, Kiangsu, Kwangtung, SFE). Same
game logic, different builds ⇒ **the Pro combat-move planner's outcome
is sensitive to binary MEMORY LAYOUT — it depends on pointer-hash map/set
iteration order, not on a Java-faithful key ordering.** The SFE
armour/artillery tie (and the fighter destinations, etc.) are downstream
symptoms of pointer-order-dependent iteration. The existing
`pro_determinism_sorted_territory_keys` / `java_hashmap_bucket_for_string`
mitigations cover SOME sites but not all of them in the combat-move path.

Files touched: `pro_transport_utils.odin` (+CARGO_CMP probe, gated
`when PLAN_PROBE`; harmless). Probe binaries: `/tmp/snaprun_0038plan4`.
Logs: `/tmp/snap0038_plan4.log`, `/tmp/snap0038_run{A,B}.log`,
`/tmp/div_{A,B}.txt`. Hard rule reminder: the eventual fix must be a
faithful port (replicate Java's HashSet/HashMap iteration order via the
bucket helper / stable key sort) — NOT an invented tie-break, NOT a
sort-by-pointer. (Prior iter-63 entry below.)

## Last action (prev iter 63)

2026-06-03 (iter 63 — LOCALISED snap 0038's cargo divergence to the
amphib transport→destination assignment in `ProCombatMoveAi#tryToAttackTerritories`;
NO code change — evidence only, a fix now would be guessing).
**The cargo SORT is FAITHFUL** (`ProTransportUtils.getUnitsToTransportFromTerritories`
4-arg → content comparator `transportCost asc, then decreasing attack`,
NO uuid — verified Java↔Odin line-for-line, incl. the
`selectUnitsToTransportFromList` replace-last-unit branch). Built a
PLAN/AMPHIB_TRACE probe binary (`/tmp/snaprun_0038plan`, defines
`-define:PLAN=true -define:AMPHIB_TRACE=true`; **linker needs
`LIBRARY_PATH`/`LD_LIBRARY_PATH` to include
`/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib` for
`-lsqlite3`**) and ran `FILTER_SNAP=0038` (`/tmp/snap0038_plan.log`).
**Decisive probe evidence:** Odin commits TWO Japanese amphib attacks —
`AMPHIB to=Alaska unloadFrom=64 Sea Zone units=2 types=[infantry,artillery]`
and `AMPHIB to=Soviet Far East unloadFrom=63 Sea Zone units=2 types=[infantry,armour]`.
The prioritised territory values are **Alaska=8.0000** vs **Soviet Far
East=1.6000** (raw pre-sort order had SFE idx=4 BEFORE Alaska idx=7;
after value-desc prioritisation Alaska sorts FIRST). So the FIRST
transport processed targets the higher-value Alaska and grabs the best
cargo (the lone Japan artillery, cost 1, attack 2); the SECOND
transport is left with only armour for SFE. **But the snapshot's ONLY
divergence is Soviet Far East** (`armour≠artillery`, `infantry m3≠m4`);
**Alaska is NOT flagged** — and since Japan holds exactly ONE artillery,
Java CANNOT have artillery in both Alaska and SFE. ⇒ **In Java the
artillery ends up in SFE, meaning Java does NOT consume the artillery on
an Alaska amphib assault.** The bug is therefore that Odin plans/commits
an Alaska amphib attack (or pairs a transport with Alaska) that Java does
not — wasting the artillery on the higher-value target and demoting SFE
to armour. NEW BOTTOM ROW = layer 27 `tryToAttackTerritories` (the
transport→destination amphib loop + the upstream amphib-target
enumeration/`removeTerritoriesWhereTransportsAreExposed` filtering).
Next iter must add a per-transport probe (transport identity, home sea
zone, ordered reachable amphib targets, chosen dest, cargo,
already-attacked set) and run BOTH the Odin binary AND a Java
`-Dpro.ncm.trace.dump` smoke run to see whether Java even enumerates an
Alaska amphib attack for these two transports. (Prior iter-62 entry
below.)

2026-06-01 (iter 62 — ROOT CAUSE FOUND + FIXED for snap 0038's
amphib-conquest failure; territory now conquered, snap advanced to a
deeper unit-selection divergence) — **the `transported_by` /
`unloaded_to` / `originated_from` reference-typed unit property
changes were silently corrupting the transport pointer.** Drilled the
trace from symptom (`Soviet Far East.owner: 'Russians' != 'Japanese'`)
down 4 layers via gated `AMPHIB_TRACE`/`PLAN` probes:
enumeration (AMPHIB_SFE: SFE IS enumerated, 2 amphib units) → selection
(PRIO0-6: survives, value 1.6, units=2) → routing (AMPHIB_RT/BATCH:
correct unload batch 63 Sea Zone→Soviet Far East) → **execution**: the
load move `60 Sea Zone → 63 Sea Zone` failed `'Unit must stay with its
transport while moving'`. MP_LOAD_POST proved the bug: applying the
load change set `transported_by` to a DIFFERENT pointer than passed
(`transporter=0xDA5790` but `now_tb=0xCCF3088`).
**ROOT CAUSE:** the `.Transported_By` / `.Unloaded_To` /
`.Originated_From` setters in
`unit_lambda_get_property_or_empty_0` (unit.odin) dereferenced the
incoming `rawptr` as a heap-boxed pointer-to-pointer
(`(cast(^^Unit)v)^`), but ALL ~10 call sites (transport_tracker,
unit_utils, battle_delegate, abstract_battle) pass the raw `^Unit` /
`^Territory` reference (or `nil`) directly — matching Java's
`ChangeFactory.unitPropertyChange(unit, transport, …)`. So the setter
read the transport struct's first 8 bytes
(its `game_data_component`) as the transported_by value → garbage.
**FIX (faithful, 1 file):** changed the three reference-typed
getter/setter pairs in
`odin_flat/games__strategy__engine__data__unit.odin` to use the
unboxed convention the call sites actually use — setter
`cast(^Unit)v` / `cast(^Territory)v`, getter
`rawptr(unit_get_…())`. Verified: snap 0038 now conquers Soviet Far
East (owner = Japanese ✓).
**FULL-SUITE IMPACT: 91→89 green (net −2).** The fix is a correct
faithful port (the old setter `(cast(^^Unit)v)^` would NULL-DEREF on
the nil-clear paths and read garbage on loads; all ~10 call sites pass
raw `^Unit`/`^Territory` or `nil`). All `transported_by` CONSUMERS use
the direct `unit_get_transported_by` accessor (not the generic
getter), so the getter change is inert. The −2 is the Pro AI's what-if
SIMULATIONS now correctly tracking transports, which shifts unit
valuations and EXPOSES the same downstream cargo-SELECTION divergence
in 2 more snaps:
  - **0032 britishNonCombatMove** (was green): NCM infantry now lands
    in Eastern Canada instead of Alaska.
  - **0089 japanesePurchase r2** (was green): buys `{1 armour, 8 inf}`
    vs Java's `{10 inf}` (board eval shifted by corrected simulation).
**0038 + 0032 + 0089 are now a CLUSTER** rooted in the same
unit-SELECTION / movement-accounting bug; fixing that (iter-63) should
recover all three AND keep 0038's conquest. Decision: KEEP the boxing
fix (correct + prerequisite for amphib assaults). **Remaining
divergence for 0038**: AI sent `armour(moves=4) +
infantry(moves=3)` but Java expects `artillery(moves=4) +
infantry(moves=4)` — wrong cargo units chosen, almost
certainly a sort-by-id where the directive mandates a sort by
(unit_type, owner, territory, moves_remaining, hp_remaining, …).
Probes are gated behind `-define:AMPHIB_TRACE`/`-define:PLAN` (default
build excludes them) and can stay. (Prior iter-61 entry below.)

2026-06-01 (iter 61 — characterized all 13 remaining RED snaps and
seeded a fresh descent on snap 0038) — ran each red snap
`FILTER_SNAP=NNNN` and captured the first-divergence line. Picked
**0038 (japaneseCombatMove)** as the next target: its symptom is the
cleanest single field — `Soviet Far East.owner: 'Russians' !=
'Japanese'` — Odin fails to amphibiously conquer the undefended Soviet
Far East. Verified the inputs are ALL present in `before.json`
(Japanese transports in 60/61 Sea Zone, infantry+artillery cargo in
Japan, empty Russian target reachable via 63 Sea Zone), so this is a
genuine `ProCombatMoveAi` amphibious-assault port divergence, NOT a
harness-state gap. Seeded the trace table with the entry proc
`ProCombatMoveAi#doMove` (layer 29). No code change this iter —
characterization + seeding only. (Prior iter-60 entry below.)

2026-06 (iter 60 — ROOT CAUSE FOUND + FIXED; **87→91 PASS, no
regressions**) — **layer 29f: the snapshot harness never serialized
`BattleTracker.conquered`, so Odin's loaded battle tracker was empty
and `was_conquered("Ukraine S.S.R.")` returned `false` where Java
(in-engine, having just conquered Ukraine in round-1 combat) returns
`true`.** That single missing bit cascaded exactly as iter 57–59
localized: Java's
`airCanLandOnThisAlliedNonConqueredLandTerritory(Ukraine)=false` ⇒
`findAirMoveOptions` adds NO air ⇒ Ukraine `maxN=5`; Odin's `=true` ⇒
adds the 14 Sea Zone bomber + 2 Ukraine fighters ⇒ `maxN=8`, which
over-counts the defender set and inverts the can-hold verdict. The
iter-59 "+3 infantry cantMove" was a red herring (Java's
`DEFROSTER round=1` also produces a `cantMoveN=4 {inf3}` row). The
ports (`unitCanBeMovedAndIsOwnedAir`, `territoryCanLandAirUnits`,
`airCanLandOnThisAlliedNonConqueredLandTerritory`) are all faithful —
the divergence was purely the empty tracker.
**FIX (faithful, 4 code files + snapshot regen):**
1. `GameStateJsonSerializer.java` — added `serializeBattleTracker()`
   emitting `{"conquered":[territoryName,…]}` via
   `AbstractMoveDelegate.getBattleTracker(data).getConquered()`.
2. `odin_flat/test_server_game.odin` — new
   `Test_Server_Game.conquered_territory_names` field; after
   `register_ww2v5_delegates`, replays each name into the freshly
   registered battle delegate's tracker via
   `battle_tracker_add_to_conquered`.
3. `test_common/json_loader.odin` — new
   `load_conquered_territory_names()` reader.
4. `test_common/snapshot_runner.odin` — wires the loader into the
   per-snap setup before `run_proc`.
   (NOTE: the `test_common` files exist in TWO trees — the canonical
   `templates/odin_test_common/` and the compiled
   `conversion/odin_tests/test_common/`; both were edited.)
Regenerated all 104 snapshots from the patched Java
(`*Ww2v5JacocoRun.runWithSnapshots` → `process_snapshots.py`);
snap 0024's `before.json` now carries
`battleTracker.conquered=["Belorussia","Ukraine S.S.R."]`. Full
parallel run: **91/104 PASS** (was 87). Newly green: **0024, 0076,
0077, 0089**. No previously-green snap regressed. Old snaps preserved
at `…/snapshots.bak.iter60.<ts>/`. Layers 29c–29f RESOLVED.
(Prior iter-59 entry below.)

2026-06-01 (iter 59 — JAVA↔ODIN defender-ROSTER DIFF on snap 0024 via
`JAVA_DEFROSTER` probe in `determineIfMoveTerritoriesCanBeHeld()`;
probe added both sides, no logic change) — **identifies EXACTLY which
units Odin over-assigns to Ukraine's defender set (layer 29d).** Dumped
owner/type tallies of the three source sets (`getMaxUnits`,
`getMaxAmphibUnits`, `getCantMoveUnits`) for Ukraine S.S.R. on the
German NCM turn. Diff on snap 0024 (reconciled by the `cantMove` size
that matches iter-58's `minDefSize`):
- **Java:** maxUnits=5 {armour4, arty1}; amphib=2 {armour1, inf1};
  cantMove=1 {armour1}. → defSize 8.
- **Odin:** maxUnits=8 {armour4, arty1, **fighter2, bomber1**};
  amphib=2 {armour1, inf1}; cantMove=4 {armour1, **inf3**}. → defSize
  14.
- `maxAmphibUnits` MATCHES. TWO over-assignments: (1) Odin's
  `maxUnits` has **+2 fighter +1 bomber** (air); (2) Odin's
  `cantMoveUnits` has **+3 infantry**. Together = the +6 defenders
  that flip the can-hold verdict.
Producer = `ProTerritoryManager.populateDefenseOptions` →
`findDefendOptions` (`:650`) → `findAirMoveOptions` (`:929`) for the
air over-assign; the infantry `cantMoveUnits` over-assign is set
outside `ProTerritoryManager` (TBD — likely `ProNonCombatMoveAi`
move-gen / `findDefenders`). No logic change — instrumentation only.
(Prior iter-58 entry below.)

2026-06-01 (iter 58 — JAVA↔ODIN canHold DIFF on snap 0024 via
`JAVA_CANHOLD`/`JAVA_CANHOLD3` probes in
`determineIfMoveTerritoriesCanBeHeld()`; probes added both sides, no
logic change) — **EXONERATES the `isCanHold` decision logic itself and
localizes the divergence one layer deeper to the defend-map DEFENDER
UNIT SETS for Ukraine S.S.R. (new layer 29d).** Iter 57 had pinned the
armour split to the can-hold flag being INVERTED for Ukraine/Finland
(layer 29c). Iter 58 found the producer is NOT
`ProTerritoryManager.populateDefenseOptions` but
`ProNonCombatMoveAi.determineIfMoveTerritoriesCanBeHeld()`
(`:417`, writes `patd.setCanHold(false)`). Added a post-loop
`JAVA_CANHOLD` verdict probe + a `JAVA_CANHOLD3` branch-3-inputs probe
(both gated `pro.ncm.trace.dump`, Germans, {Ukraine,Finland,
Belorussia}) with faithful Odin mirrors. Diff on the snap-0024 German
NCM (Ukraine row, `minTuvSwing=6.000` identical both sides):
- **Java `isCanHold=FALSE`**: `minDefSize=1 defSize=8
  resTuvSwing=14.000 holdValue=4.625 extraUnitValue=37.000
  branch3=false`.
- **Odin `isCanHold=TRUE`**: `minDefSize=4 defSize=14
  resTuvSwing=−15.000 holdValue=8.625 extraUnitValue=69.000
  branch3=true`.
- Finland + Belorussia: both sides `isCanHold=TRUE` (match).
ROOT: the branch-3 verdict flips purely because Odin's **defender unit
set for Ukraine is bigger** (def=14 vs Java 8; minDef=4 vs 1). With 14
defenders Odin's max-defender battle wins (resTuvSwing −15) so the
"max defenders hold" branch fires ⇒ can-hold; Java with 8 defenders
loses (resTuvSwing +14) ⇒ can't-hold. The `isCanHold` decision math is
faithful; the divergent INPUT is `patd.getMaxUnits() +
getMaxAmphibUnits() + getCantMoveUnits()` for Ukraine — **new bottom
layer 29d = defend-map defender-set population (`populateDefenseOptions`
move-generation over-assigns ~6 defenders to Ukraine in Odin)**. No
logic change this iter — instrumentation only. (Prior iter-57 entry
below.)

2026-06-01 (iter 57 — JAVA↔ODIN VALUE DIFF on snap 0024 via
`JAVA_TVAL`/`JAVA_TVAL2` probes; probes added both sides, no logic
change) — **EXONERATES `capitalOrFactoryValue` and localizes the
divergence two layers down to the defend-map `isCanHold` flag (new
layer 29c).** Method: added a gated `JAVA_TVAL` probe in Java
`ProTerritoryValueUtils#findLandValue` (behind `-Dpro.ncm.trace.dump`)
and a mirror in Odin, decomposing the territory value into
`nearbyEnemyValue`, `landMassSize`, `capitalOrFactoryValue`, the
sorted caps list, and (enriched) the per-territory `nbe` breakdown.
Diff on the matching German-NCM game state:
- **`capitalOrFactoryValue` is BYTE-IDENTICAL** (Belorussia 39.734,
  Ukraine 47.640) — iter-57's prime suspect is EXONERATED.
- The ONLY divergent term is **`nearbyEnemyValue` for Belorussia:
  Java 6.250 vs Odin 5.500 (Δ0.75)**. Ukraine's value matches.
- `nbe` breakdown shows the set differs: Java's Belorussia nbe
  INCLUDES `Ukraine S.S.R.` (d1, contrib 1.0) and EXCLUDES `Finland`;
  Odin INCLUDES `Finland` (d2, contrib 0.25) and EXCLUDES Ukraine.
A second probe `JAVA_TVAL2` (owner, isEnemyRaw, inCantBeHeld,
inToAttack, dist) on the matching owner=Germans state proved the
mechanism is **`territoriesThatCantBeHeld` (cantHold) set membership**:
  - Java: Ukraine S.S.R. `inCantBeHeld=true` (counted), Finland
    `inCantBeHeld=false` (not counted).
  - Odin: Finland `inCantBeHeld=true` (counted), Ukraine
    `inCantBeHeld=false` (not counted) — **INVERTED**.
Both are owner=Germans / `isEnemyRaw=false` so they only enter
`nearbyEnemyValue` via the `territoriesThatCantBeHeld::contains`
branch of `ProMatches.territoryIsEnemyOrCantBeHeld`. Tracing the
producer: `territoryManager.getCantHoldTerritories()`
(`ProTerritoryManager.java:333`) returns every defend-map territory
whose `isCanHold()==false`. So **NEW BOTTOM ROW = layer 29c: the
`isCanHold` flag on the defend-territory-map differs — Java marks
Ukraine S.S.R. as can't-hold and Finland as can-hold; Odin inverts
this.** That flips `territoriesThatCantBeHeld` → flips Belorussia's
`nearbyEnemyValue` → flips the Belorussia/Ukraine territory value →
drives the armour split. iter-58 must instrument the defend-map
`isCanHold` assignment (in `populateDefenseOptions` /
`ProTerritoryManager` populate path) for Ukraine S.S.R. + Finland and
diff Java↔Odin. Probes left in place (Java behind
`-Dpro.ncm.trace.dump`, Odin behind `-define:ARMOUR_TRACE`).

---

2026-06-01 (iter 56 — ARMOUR_TRACE landloop probes on snap 0024; Odin
probes added, no logic change) — **EXONERATES layer 29a
(moveUnitsToBestTerritories assignment loop) and refocuses on the
territory VALUE calc (layer 29b, `ProTerritoryValueUtils#findLandValue`).**
Added `landloop_terr` (per-territory value+canHold), `landloop_unit`
(candidate dests in iteration order), `landloop_eval` (per-candidate
value/needAmphib + running max) and `landloop_chosen` (final dest)
probes inside the Odin land-assignment loop, rebuilt the lean
`/tmp/snaprun_0024trace` binary, ran `FILTER_SNAP=0024`. RESULT: the
assignment loop is FAITHFUL — it correctly picks the higher-valued
territory. Odin's own values are **Belorussia=44.112 (canHold=true),
Ukraine S.S.R.=53.609 (canHold=true)** so Ukraine legitimately wins
given those inputs. Crucially `phase=after_defend` already shows
Ukraine=armour4/bomber1/fighter2 and Belorussia=empty, proving the
armour split is decided in the DEFEND phase from the territory VALUE,
not in this leftover loop. The `TVAL` probe decomposes the value:
`value = nearbyEnemyValue·landMass/maxLandMass + capitalOrFactoryValue`
— Ukraine `6.5·45/49 + 47.640 = 53.609`, Belorussia
`5.5·39/49 + 39.734 = 44.112`. The dominant differing term is
`capitalOrFactoryValue` (Ukraine 47.640 vs Belorussia 39.734), a
discounted (÷2^i) sum over the sorted nearby enemy capitals/factories.
If Java computes Belorussia ≥ Ukraine, the defend phase fills
Belorussia first → the expected 5-armour. NEW BOTTOM ROW = layer 29b
`ProTerritoryValueUtils#findLandValue`. Checkpointed because the next
step is a Java-instrumented value diff (needs a full smoke run) — best
started fresh. Probes left in place (gated by `-define:ARMOUR_TRACE`).

---

2026-06-01 (iter 55 — JAVA-GROUND-TRUTH DIFF on snap 0024; probes
added both sides, no logic change) — **OVERTURNS iter 54. Confirmed
Belorussia's `minBattleResult` is BYTE-IDENTICAL Java↔Odin, so the
min-result is NOT the divergence and the entire defend-prioritization
path (layers 27 + 28) is EXONERATED.** Method: added a gated
`JAVA_MINRES` probe in Java `populateDefenseOptions` (right after
`patd.setMinBattleResult`, behind `-Dpro.ncm.trace.dump=true`) and a
mirror `ARMOUR_TRACE minres` probe in Odin at the same site
(`pro_non_combat_move_ai.odin` ~957). Ran the full Java smoke test
(`-Dpro.ncm.trace.dump=true`) and the lean Odin `FILTER_SNAP=0024`
binary. For the decisive German-NCM-turn invocation BOTH compute:
`t=Belorussia atk={Russians/armour=3,fighter=2} (5) minDef={Germans/armour=1,infantry=2} (3) tuvSwing=0.000 winPct=100.0 rounds=1.0`
and `t=Ukraine S.S.R. atk=10 minDef=4 tuvSwing=6.000`. Since Java's
filter predicate `isNotFactoryAndShouldHold = !hasFactory &&
(tuvSwing<=0 || !hasLandRem)` ALSO fires on Belorussia's 0.000,
**Java removes Belorussia from the defend list too** — exactly like
Odin. Then captured the FULL per-region divergence (not just
Belorussia): the whole German NCM distribution is redistributed
across THREE adjacent-territory pairs —
Belorussia(5→1)↔Ukraine(1→5+bomber+2fighter),
Finland(bomber+2fighter+3inf→1inf)↔Norway(0→2fighter+2inf),
Libya(armour+arty+3fighter+2inf→1inf)↔Algeria(1inf→armour+arty+fighter+2inf).
This is a SYSTEMIC `moveUnitsToBestTerritories` destination-assignment
divergence (layer 29a), NOT a min-result, NOT a sort, NOT the
defend-filter. Refocus the trace there. Checkpointed because the next
step is a Java↔Odin line diff of the `moveUnitsToBestTerritories`
assignment loop + its prioritized-list ordering — best started
fresh.**

---

2026-06-01 (iter 54 — DRILL on snap 0024 with FRESH ARMOUR_TRACE
data; no code change this pass) — **Descended
`moveUnitsToBestTerritories` → `prioritizeDefendOptions` and got
fresh probe output on the iter-52 board that OVERTURNS the stale
iter-12 conclusion. iter-12 said "Belorussia never appears in
prioritized_territories"; the iter-52 regen changed the board and
now `belo_in_move_map=true belo_in_prio_pre_filter=true` —
Belorussia IS present. It is REMOVED at the filter loop because
`isNotFactoryAndShouldHold` fires: Belorussia's
`minResult.tuvSwing = 0.00 ≤ 0` (so the AI thinks it can already
hold and isn't worth defending), while Ukraine S.S.R. survives
(`tuvSwing = 6.00`). The 5 German armour then default to Ukraine
S.S.R. The decisive lever is Belorussia's `minBattleResult`
TUV-swing — an odds-calculator / min-result divergence, NOT a sort
and NOT the prioritize filter logic itself. Appended trace row
(layer 27) at the `getMinBattleResult`/populate-defense step that
sets `patd.minBattleResult` for Belorussia. Checkpointed because
the next step is a full Java↔Odin diff of the min-defender battle
result for Belorussia (odds calc) — best started fresh.**

---

2026-05-29 (iter 53 — DIAGNOSTIC PASS on snap 0024, the lone iter-52
regression; no code change this pass) — **Descended snap 0024
(germanNonCombatMove) → `moveUnitsToBestTerritories`. Established it is
a TERRITORY-SELECTION divergence (Java sends German armour→Belorussia,
Odin→Ukraine S.S.R.; units redistributed, not lost), NOT a unit
tie-order issue. Proof: both Java `sortUnitMoveOptions` and Odin
`pro_sort_move_options_utils_sorted_unit_keys_by_move_options` sort by
`(moveCount, unitValue, typeName)` with NO UUID (Odin already honours
the directive) — and a fungible-unit tie can't change per-territory
counts by greedy symmetry. So the next drill targets the territory
priority / best-destination ranking inside `moveUnitsToBestTerritories`
(Odin `pro_non_combat_move_ai.odin:1499`), line-by-line vs the Java
`ProNonCombatMoveAi#moveUnitsToBestTerritories`. Checkpointed here
because a proper fix needs a full Java↔Odin diff of that 2000-line
proc plus a snapshot regen — best started fresh.**

---

2026-05-29 (iter 52 — SORT-AT-ITERATION refactor LANDED → **87/104
PASS**, +6 over the 81/104 baseline) — **Executed the forced design
from the iter-51 decisive finding. Discovered the repo already had the
correct TRACKED `ProDeterminism.java` (content comparator mirroring
Odin's `pro_determinism_unit_property_less` EXACTLY — type, owner,
hits, alreadyMoved, wasAmphibious, submerged, transported-presence,
unloaded-count, unloadedTo-name; UUID DELIBERATELY removed) with NEW
`*WithLocation` variants (location tiebreak via a
`Function<Unit,Territory>` locator). The iter-49
`ProDeterministicOrder.java` (TreeMap/TreeSet UUID factories) was the
wrong parallel approach → DELETED.**

Concretely: (1) reverted all 6 data-class field types back to
identity-keyed LinkedHashMap/HashMap/LinkedHashSet (ProData,
ProMyMoveOptions, ProOtherMoveOptions, ProTransport, ProTerritory) —
preserves multiplicity, dodges the mutable-TreeMap NPE; (2) deleted
`ProDeterministicOrder.java`; (3) wired content sort-at-iteration in
`ProPurchaseAi.java` via two private helpers — `orderedUnits(coll)` =
`ProDeterminism.sortedUnitsWithLocation(coll, u ->
proData.getUnitTerritoryMap().get(u))` and
`orderedEnemyAttackers(maxUnits, maxAmphib)` (sorted maxUnits first,
amphib appended, LinkedHashSet dedup) — applied at the 5
odds-calculator-feeding sites (calculateBattleResults /
estimateDefendBattleResults attacker collections built from
getMaxUnits()+getMaxAmphibUnits(), bombard arg getMaxBombardUnits()).
Logging/`.stream().anyMatch()`/`estimateStrengthDifference` sites left
alone (order-independent). This mirrors Odin's 8 `_with_loc` sort
sites — all of which live in `pro_purchase_ai.odin`. game-core
compiled clean.

Regenerated all 104 snapshots (Java green run, no NPE this time —
identity maps), installed via `process_snapshots.py`, rebuilt lean
Odin binary `/tmp/snaprun_iter52`, ran the 104-snap parallel batch
(`/tmp/iter52_results/`). **Result: 87/104 PASS.** Newly GREEN (7,
were RED at iter-49/50): 0021 0022 0025 0029 0032 0073 0091. One
regression: 0024 (was green; now a real German-unit move/placement
divergence — Algeria/Belorussia/Finland tallies differ). Still RED
(16): 0031 0037 0038 0040 0048 0065 0074 0075 0076 0077 0084 0089
0090 0092 0097 0100. 0037 = genuine divergence
(`players.Japanese.resources[PUs]: 16 != 1`) that also ran past the
300 s timeout (exit 124).

The user directive "stop sorting by UUID" is now STRUCTURALLY
satisfied: UUID factories deleted, content sort-at-iteration wired on
both runtimes. Only `ProDeterminism.java` (+81/-17) remains changed vs
HEAD in the pro/ tree; the 5 data-class files are reverted to
original.

---

2026-05-29 (iter 51 — DECISIVE FINDING: content-keyed TreeMap is
BROKEN for mutable Unit keys) — **Implemented `UNIT_BY_CONTENT` (a
serializable content comparator mirroring Odin's
`pro_determinism_unit_property_less` field order EXACTLY: type, owner,
hits, alreadyMoved, wasAmphibious, submerged, transported-presence,
unloaded-count, unloadedTo-name; UUID only as final uniqueness
tiebreak) and pointed the `unitMap()/unitSet()` factories at it. Java
compiled. Snapshot regen then FAILED with
`NullPointerException: …Territory.getName() because unitTerritory is
null` at `ProSimulateTurnUtils.transferUnit:275` ← a TreeMap lookup
returned null. ROOT CAUSE: Units are MUTABLE (alreadyMoved, hits,
transportedBy, wasAmphibious, unloadedTo all change mid-turn). A
TreeMap requires its comparator stable over a key's lifetime; mutating
a unit while it is a content-keyed entry corrupts the tree ordering
invariant → get/containsKey/iteration silently fail. The iter-49 UUID
comparator worked ONLY because `Unit.getId()` is immutable.**

DECISIVE CONSEQUENCE: the "keep TreeMap, swap to a content comparator"
shortcut is IMPOSSIBLE. The ONLY correct content-ordering approach is
the original iter-51 plan: revert unit-keyed maps to identity-keyed
(LinkedHashMap/HashMap/LinkedHashSet) and SORT-AT-ITERATION with
`UNIT_BY_CONTENT` — exactly how the Odin side already works (Odin's
`pro_determinism.odin` already sorts by content, not UUID; the file
even documents "UUID is deliberately NOT used"). So the real iter-49
divergence was: Java sorted by UUID while Odin already sorted by
content.

To avoid leaving a broken build, RESTORED the factories to the
immutable-safe `UNIT_BY_UUID` (known-good iter-49 state; regen works;
81/104 holds; on-disk snapshots untouched — regen failed before
writing, backup at `…/snapshots.iter49_backup/`). `UNIT_BY_CONTENT` +
its javadoc'd mutable-TreeMap warning are retained in
`ProDeterministicOrder.java`, ready for the sort-at-iteration refactor.

---

2026-05-29 (iter 50 DONE → iter 51 STRATEGY CORRECTION) —
**Completed the full 104-snap Odin batch (81/104 PASS; 23 RED, all
AI move/purchase snaps — see Snap status). Then the user issued a
governing directive that supersedes the iter-49/50 UUID approach:
"any sorts by id are a red flag … replace with a sort focused on
unit type, owner, territory, moves remaining, hp remaining + ship/
bombard/transport attributes … our snapshot comparison treats ids as
arbitrary." The snapshot comparator confirms this — it keys units by
`{type, owner, already_moved, unit_damage}` and ignores UUIDs.**

Consequence: iter-49's `UNIT_BY_UUID` comparator AND its TreeMap/
TreeSet field-type changes are WRONG. A content comparator returns 0
for content-identical units, so it cannot key a TreeMap/TreeSet
without collapsing duplicate units — and a UUID tiebreak is barred.
The iter-51 plan (see Next action) REVERTS the field types to
LinkedHashMap/HashMap/LinkedHashSet and switches to stable
sort-at-iteration by a new pure-content comparator `UNIT_BY_CONTENT`,
mirrored in Java and Odin, then regenerates all 104 snapshots.
Awaiting user confirmation on two specifics (see Notes / blockers).

---

2026-05-29 (iter 50 — full Odin batch characterisation) —
**Ran the full 104-snap Odin batch against the iter-49 regenerated
snapshots to characterise which snaps now fail before applying the
Odin sort-at-iteration. Strong interim result: of the ~61 snaps that
have completed so far, ~54 PASS. Engine/deterministic snaps pass; the
failures are concentrated in AI move/purchase snaps with "unit tally
divergence" — exactly the iter-50 Odin sort-at-iteration target.**

Method bug caught + fixed: the first batch attempt ran the lean
binary from the wrong CWD, so the relative snapshot path
(`conversion/odin_tests/server_game_run_next_step/snapshots`) didn't
resolve → every test was vacuously "successful" ("No snapshots
found"). Re-ran with an explicit `cd /home/caleb/todin/triplea`
inside each `xargs` worker. Lean binary built via **`odin build`**
(NOT `odin test`, which rejects `-build-mode:test`):
`odin build conversion/odin_tests/server_game_run_next_step
-build-mode:test -out:/tmp/snaprun_iter50 -no-bounds-check -o:minimal`.
The runner reads `FILTER_SNAP` from the ENV at runtime
(`snapshot_runner.odin:41 os.get_env`), so per-snap parallel runs work.

Interim batch facts (`/tmp/iter50_results/`, `xargs -P4`, 300s
timeout/snap):
- Completed-so-far failures (unit tally divergence): **0022, 0025,
  0031, 0032, 0048**.
- Anomalous (EXIT=0 but NO `Results:` line, output truncated after
  `PSTART step=germanPurchase`): **0021, 0029** — AI purchase snaps
  that appear to bail/abort silently; need a direct look (NOT a clean
  pass, NOT a tally-diff fail).
- All other completed snaps PASS.
- Batch tail (the slow AI simulation-walk snaps 0037/0038/0040/0065/
  0066 + 0067–0104) still running at session pause; resume terminal
  was `08525aa9-…`.

**IMPORTANT discovery for the iter-50 fix:** the helper names the
iter-48/49 plan referenced — `pro_determinism_sorted_unit_keys_with_uuid`
and `pro_determinism_sorted_territory_keys` — **DO NOT EXIST** in the
Odin tree (grep across `odin_flat/` returns nothing). iter-50 must
CREATE them. `Unit` has no `unit_get_id` accessor exposed but the raw
field `u.id` is a `Uuid :: [16]u8` (see
`game_data.odin:12`); byte-lexicographic order on `u.id` equals Java's
`UUID.toString()` lexical order (hyphens sit at fixed offsets, hex is
lowercase), so a sort comparator can be `slice.sort_by` on a
`mem.compare(a.id[:], b.id[:]) < 0` predicate. Territory order = sort
by `territory_get_name`. NOTE: the iter-43–47 composite-key sort
sites in `pro_move_utils.odin` / `pro_purchase_ai.odin` exist on BOTH
Java and Odin sides (e.g. `amphibUnitSortKey`) so they still converge;
the REAL Approach-A payoff is at the UNPATCHED `keySet()`/map-iteration
sites in `ProNonCombatMoveAi` / `ProTerritory` copy-ctor that now
iterate a TreeMap (UUID order) on the Java side while Odin iterates a
raw-pointer map (ASLR order).

(prev iter 49 entry below.)

2026-05-29 (iter 49 — Java refactor + snapshot regen SHIPPED) —
**Approach A Java side delivered. New `ProDeterministicOrder` helper +
21 keyed-collection fields across 5 Pro data classes converted to
UUID/name-ordered TreeMap/TreeSet. All 104 snapshots regenerated from
the refactored Java and swapped in. Regen integrity verified (snap
0001 PASS on unchanged Odin).**

What shipped:
- New helper `ProDeterministicOrder.java`
  (`.../ai/pro/util/`): `UNIT_BY_UUID`
  (`Comparator.comparing(u -> u.getId().toString())`) +
  `TERRITORY_BY_NAME` (`Comparator.comparing(Territory::getName)`),
  plus `unitMap()/unitMap(src)/unitSet()/unitSet(src)/territoryMap()/
  territoryMap(src)` factory helpers (TreeMap/TreeSet with the
  comparator; the `(src)` variants do `putAll`/`addAll` so the final
  copy-ctor pattern stays a one-liner).
- **CRITICAL FIX not in the iter-48 plan:** the comparators MUST be
  serializable. The first regen attempt crashed with
  `NotSerializableException:
  ProDeterministicOrder$$Lambda` at
  `GameDataUtils.translateIntoOtherGameData` →
  `IoUtils.writeToMemory` (called from
  `BattleCalculator.translateCollectionIntoOtherGameData`). The Pro
  AI maps ARE reachable from the GameData object graph that the
  battle calculator / sim-walk deep-copies via Java serialization;
  with `LinkedHashMap` this serialized silently, with a plain-lambda
  `TreeMap` comparator it throws. Fixed by intersection-casting the
  key extractors to `(Function<…,String> & Serializable)` so
  `Comparator.comparing` returns a serializable comparator.
- Fields converted (21 total):
  - `ProTerritory` (10, both primary + copy ctor): maxUnits,
    amphibAttackMap, transportTerritoryMap, isTransportingMap,
    maxBombardUnits, bombardOptionsMap, bombardTerritoryMap,
    cantMoveUnits, maxEnemyBombardUnits, tempAmphibAttackMap.
  - `ProMyMoveOptions` (5): territoryMap (Territory), unitMoveMap,
    transportMoveMap, bombardMap, bomberMoveMap (Unit).
  - `ProData` (2 + the `newUnitTerritoryMap` local): unitTerritoryMap
    (Unit), unitsToBeConsumed (Unit).
  - `ProTransport` (2): transportMap, seaTransportMap (Territory).
  - `ProOtherMoveOptions` (2 fields, 2 factory-method locals):
    maxMoveMap, moveMaps (Territory).
  - (Iter-48 plan said "24 fields"; actual keyed-collection count is
    21 — the iter-48 inventory double-counted a few non-keyed/list
    fields.)
- Build verified: `compileJava` + `compileTestJava` BUILD SUCCESSFUL.
- Snapshot regen: `/tmp/iter49_regen.sh` (gradle
  `*Ww2v5JacocoRun.runWithSnapshots` --rerun-tasks +
  `process_snapshots.py`). rc=0 both stages, 104 pairs. Output
  `/tmp/regen_iter49_processed/...`.
- Old snaps backed up to
  `triplea/conversion/odin_tests/server_game_run_next_step/snapshots.iter48_baseline/`
  then replaced with regen output. **Only the `snapshots/` dir was
  swapped — the hand-customized driver
  `test_server_game_run_next_step.odin` (which uses
  `run_snapshot_tests_server_game` + `game.test_server_game_run_next_step`,
  NOT the regen default `run_snapshot_tests`) was kept.**
- Verification: snap 0001 PASS on unchanged Odin binary (17ms).
  Confirms (a) regen pipeline works with refactored Java, (b) Odin's
  UUID comparison is correct against the relabeled snaps, (c)
  deterministic engine steps survive regen.

**KEY CORRECTION to iter-48 root-cause framing:** iter-48 claimed
"Java is FULLY content-deterministic across JVM runs (Unit.hashCode =
UUID)". That is WRONG — `Unit.id = UUID.randomUUID()` is freshly
random on every JVM run (confirmed at `Unit.java:122`), so Java's
HashMap/LinkedHashMap iteration over Unit keys is NOT reproducible
across runs. Approach A still works, but for a subtler reason: within
ONE snapshot set the UUIDs are FROZEN in `before.json`; Java's
`TreeMap(UNIT_BY_UUID)` makes its AI decisions a pure function of
those frozen UUIDs, and the Odin replay (loading the same frozen
UUIDs and sorting identically — once iter-50 lands) matches by
construction. This is exactly why regen is mandatory: the OLD snaps
encoded LinkedHashMap-insertion-order decisions Odin couldn't
replicate; the NEW snaps encode UUID-order decisions Odin CAN
replicate. (Also explains why the iter-48 regen "diff vs on-disk
expected clean" was wrong — the regen diff is 100% UUID + timestamp
churn because UUIDs are random per run; structure was byte-size
identical.)

No Odin code changed this iter. The full Odin batch against the new
snaps (to characterise which AI snaps now fail pending the iter-50
sort-at-iteration work) is the iter-50 kickoff task.

## Last action (prev iter 48)

2026-05-26 (iter 48 — KICKOFF, not closed) — **STRATEGY PIVOT: Approach
A (uniform sort-by-UUID on BOTH sides + snapshot regen) authorised by
user.** Iter-43 → iter-47 chased per-site sort fixes for 5 iterations
(9+ sort sites added in `pro_purchase_ai`, `pro_move_utils`); each fix
exposed the next leak (allocator-perturbation antipattern). Iter-47
proved BOTH `calculate_move_routes` AND `calculate_amphib_routes`
receive non-deterministic inputs in `Pro_Territory.units` /
`Pro_Territory.amphib_attack_map` at SZ 60–63 (China coast); leak is
upstream in NCM planner sub-procs (`move_units_to_best_territories`).

**Root cause analysis (definitive):**
- Java `Unit.hashCode()` = `id.hashCode()` (UUID) — content-deterministic
  across JVM runs.
- Java `Territory.hashCode()` = `Objects.hashCode(name)` (via
  `DefaultNamed`) — content-deterministic across JVM runs.
- ⇒ **Java is FULLY content-deterministic.** All ASLR-flakiness lives
  on the Odin side, where `map[^Unit]…` / `map[^Territory]…` keys are
  raw pointers hashed by ASLR-randomised heap address.
- Java mostly uses `LinkedHashMap`/`LinkedHashSet` (24 known fields in
  Pro AI layer; iter-48 inventory). Odin uses raw pointer-keyed maps
  everywhere, sometimes with parallel-insertion-order slices
  (Pro_My_Move_Options does this; Pro_Territory does NOT — that's the
  smoking gun for iter-47's findings).

**Why Approach B (Odin-only) was inadequate:** would require
per-site forensics — for every iteration site, determine whether Java
iterates `LinkedHashMap` (insertion-order) or `HashMap` (UUID-bucket
order) and replicate the right Java-specific order in Odin. 5 prior
iterations of this approach failed to converge: fixing one site
shifts allocator addresses and exposes the next pointer-map leak
downstream. Pattern-matching exhausted.

**Approach A scope (this session decided):**
- **Mechanism (M1):** Java-side type-system enforcement. Replace
  `LinkedHashMap<Unit,V>` / `HashMap<Unit,V>` → `TreeMap<Unit,V>` keyed
  on `UNIT_BY_UUID` comparator. Replace `LinkedHashSet<Unit>` /
  `HashSet<Unit>` → `TreeSet<Unit>` keyed on `UNIT_BY_UUID`. Same for
  Territory → `TERRITORY_BY_NAME` comparator. Add new
  `ProDeterministicOrder` helper class in
  `games.strategy.triplea.ai.pro.util`.
- **Scope (S2):** AI Pro layer only —
  `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/`.
  Engine + delegates left alone (they don't have this issue because
  iteration order doesn't affect game outcome in those code paths,
  and we don't want a 1000-site refactor for no benefit).
- **Sort key:** Unit → `id.toString()` (UUID canonical hex);
  Territory → `name`. UUID-hex matches Odin's existing
  `pro_determinism_sorted_unit_keys_with_uuid` UUID-bytes tiebreak.
- **Odin side:** sort-at-iteration using existing
  `pro_determinism_sorted_unit_keys_with_uuid` /
  `pro_determinism_sorted_territory_keys` helpers; extend for
  nested-map cases (`map[^Unit]map[^Territory]struct{}`) as needed.

**This-iter delivery (iter 48):**
- Regen pipeline VERIFIED on unmodified Java (kicked off at 08:54;
  see `/tmp/iter48_regen.sh`, log `/tmp/iter48_regen.log`, flag
  `/tmp/iter48_regen_done.flag`). Diff vs on-disk snapshots will
  confirm pipeline matches current state byte-for-byte.
- Plan documented; no code changes shipped this iter.
- Iter 49+ will execute the Java refactor + regen + Odin refactor +
  validation across multiple sessions (estimated 3 sessions: 49 =
  Java + regen, 50 = Odin sort-at-iter for Pro_Territory family +
  validation, 51 = Odin sort-at-iter for combat/purchase locals +
  final validation).

**Inventory results (subagent reports):**
- Java side: 24 declared `Map<Unit,…>` / `Set<Unit>` /
  `Map<Territory,…>` / `Set<Territory>` fields across 5 files
  (ProTerritory, ProMyMoveOptions, ProOtherMoveOptions, ProData,
  ProTransport). Plus ~100 local vars + 7 stream chains.
- Odin side: ~200 iteration sites; majority order-independent
  (sum/dedup). ~30 sites where order influences AI decisions.

## Last action (prev iter 47)

2026-05-26 (iter 47) — **TWO distinct NCM leak surfaces FULLY LOCALISED
via `MOVE_ROUTES_DIGEST` probe.** New helper `pro_move_routes_digest`
(`pro_ncm_trace.odin`) dumps FNV-1a64 of sorted
`(start->end | sorted unit_type:count)` route triples for filtered
player, with per-row dump. Wired into `pro_non_combat_move_ai_do_move`
at 4 checkpoints: after `calculate_move_routes`, after the first
`do_move`, after `calculate_amphib_routes`, after the second
`do_move`. Build flag: `-define:MOVE_ROUTES_DIGEST=true`.

5× ASLR-on `/tmp/snaprun_iter47` snap 0089 (with NCM_END_STATE +
MOVE_ROUTES_DIGEST):

| run | result | calc_move_routes | calc_amphib_routes | Japan ncm_exit  |
|-----|--------|------------------|--------------------|-----------------|
| 1   | PASS   | n=16 h=1363e32a  | n=15 h=5219a2c9    | aaGun+arty+factory+inf (n=4) |
| 2   | FAIL   | n=16 h=18455437  | n=15 h=5219a2c9    | same n=4        |
| 3   | FAIL   | n=15 h=f93da473  | n=15 h=2ed1b981    | aaGun+armour+factory (n=3) |
| 4   | PASS   | n=15 h=f93da473  | n=14 h=2dc90c2d    | aaGun+armour+factory (n=3) |
| 5   | FAIL   | n=15 h=f93da473  | n=15 h=5219a2c9    | aaGun+factory (n=2) |

⇒ **2/5 PASS** (within iter-46 noise band; probes amplify allocator
perturbation as expected).

**LEAK D (NEW) — `calculate_move_routes` SZ 63 transport routing.**
Run 1 vs run 2 (same `calc_amphib_routes` digest, different
`calc_move_routes`): one run emits `63 Sea Zone->60 Sea Zone|transport:1`
while the other emits `63 Sea Zone->62 Sea Zone|transport:1`. Same SZ
63 transport routed to different destination ⇒ planner output `pt.units`
at SZ 60 vs SZ 62 differs across runs. **Iter-42 MOVE_PLAN proof was
incomplete** — it filtered only Japan/Manchuria/Yunnan destinations
and missed all sea-zone Pro_Territory entries.

**LEAK A residual (iter-43 amphib fix was incomplete) — `calculate_amphib_routes`
amphib load/destination flip.** Run 3 vs run 4 (identical
`calc_move_routes` digest, different `calc_amphib_routes`): run 3
emits an EXTRA `63 Sea Zone->60 Sea Zone|transport:1` repositioning
that run 4 doesn't. Run 3 vs run 5 (same `calc_move_routes`,
different `calc_amphib_routes`): SZ 60→61 vs 60→62 with different
loaded units; SZ 62→61 emission flips; Buryatia destination flips
between SZ 62 and SZ 63. Iter-43's UUID-stable sort on transports
was insufficient because the upstream `pt.amphib_attack_map` itself
differs between runs ⇒ leak is in whichever NCM-planner sub-proc
POPULATES `amphib_attack_map`, not in the amphib-route emission
itself.

**Both leaks confirmed UPSTREAM of `calculate_move_routes` /
`calculate_amphib_routes`.** The planner sets `pt.units` and
`pt.amphib_attack_map` differently across runs at SZ 60, 61, 62, 63
(China-coast sea zones around Japan). Iter-42 MOVE_PLAN missed these
because it filtered to land destinations only.

Build: `/tmp/snaprun_iter47`. Runner: `/tmp/iter47_runner.sh`.
Artifacts: `/tmp/iter47_run{1..5}.{stdout,stderr}`. New helper:
`pro_move_routes_digest` in
`odin_flat/games__strategy__triplea__ai__pro__util__pro_ncm_trace.odin`.

No code fix shipped this iteration — instrumentation + diagnosis only.

## Last action (prev iter 46)

2026-05-25 (iter 46) — **NCM_END_STATE digest probe SHIPPED;
NCM-exit divergence PROVEN.** New helper
`pro_ncm_end_state_dump` (`pro_ncm_trace.odin`) dumps per-territory
`(unit_type:count,...)` sorted summary for filtered player at NCM
exit + purchase entry. Wired into
`pro_non_combat_move_ai_do_non_combat_move` (after
`09_after_doMove`) and `pro_purchase_ai_purchase` (entry).
Build flag: `-define:NCM_END_STATE=true`.

**Smoking gun.** 5× ASLR-on `/tmp/snaprun_ncmend_iter46` snap 0089:

| run | result | Japan units at ncm_exit                                            |
|-----|--------|--------------------------------------------------------------------|
| 1   | FAIL   | aaGun:1, armour:1, artillery:1, factory:1, infantry:1  (n=5)       |
| 2   | FAIL   | aaGun:1, factory:1                                       (n=2)     |
| 3   | FAIL   | aaGun:1, armour:1, factory:1                            (n=3)      |
| 4   | FAIL   | aaGun:1, armour:1, artillery:1, factory:1, infantry:1  (n=5)       |
| 5   | PASS   | aaGun:1, artillery:1, factory:1, infantry:1            (n=4)       |

`ncm_exit` == `purchase_entry` for ALL 5 runs ⇒ no mutation between
NCM and purchase. **The divergence is fully NCM-introduced.** The
purchase pool outcome (armour=1 infantry=8 vs expected armour=0
infantry=10) is a downstream symptom of NCM leaving different
land-unit residuals in Japan: when more land units remain in Japan,
fewer infantry need to be purchased to defend; when fewer remain,
more must be bought.

**Regression analysis.** Iter-43 reported `09_after_doMove` at Japan
byte-identical n=3 in 4/5 runs (run5 n=4). Iter-46 sees 4 DISTINCT
NCM outcomes (n=2,3,4,5). The iter-44/45 sort-fix helper calls
allocate fresh `[dynamic]^Unit` / `[dynamic]^Territory` slices on
every greedy purchase iteration; those allocations perturb the
allocator → shift heap addresses → shift NCM's pointer-keyed
`map[^Territory]struct{}` iteration order → different
move-planning decisions on Japan. iter-46 runs 3 (n=3, types
aaGun+armour+factory) and 5 (n=4, types aaGun+artillery+factory+
infantry) MATCH iter-43 outcomes; runs 1, 4 (n=5) and run 2 (n=2)
are NEW outcomes introduced by iter-44/45 allocator perturbation.

This is the textbook ALLOCATOR-PERTURBATION ANTIPATTERN. The
iter-44/45 fixes are not wrong per se (they ARE necessary for
purchase-AI determinism), but they expose more NCM nondeterminism
than was visible before. Fixing NCM is therefore strictly required.

**Root layer narrowed.** The `pro_non_combat_move_ai_move_*` family
populates `Pro_Territory.units` (the move plan that feeds
`do_move`). Candidates (`pro_non_combat_move_ai.odin`):
- `move_units_to_best_territories` (l.1479) — primary planner
- `move_units_to_defend_territories` (l.3628) — defender allocator
- `move_one_defender_to_land_territories_bordering_enemy` (l.372)
- `prioritize_defend_options` (l.3246)
- `move_infra_units` (l.4707)
- `move_consumables_to_factories` (l.1118)
- `move_allied_carried_fighters` (l.317)

Build: `/tmp/snaprun_ncmend_iter46`. Runner: `/tmp/iter46_runner.sh`.
Artifacts: `/tmp/iter46_run{1..5}.{stdout,stderr}`,
`/tmp/iter46_progress.log`. No code fix shipped this iteration —
instrumentation + diagnosis only.

## Last action (prev iter 45)

2026-05-25 (iter 45) — **`purchase_land_units` neighbours-map sort fix
SHIPPED (mirror of iter-44 l.3654 fix at l.3043 + 4 additional UUID-sort
sites in `purchase_defenders` and `purchase_factories`/can-hold loop).
Stock PASS rate 3/5 → 2/5 — no improvement; failure pattern unchanged.**

5× ASLR-on stock baseline `/tmp/snaprun_stock_iter45` snap 0089:

| run | result | divergence |
|-----|--------|------------|
| 1   | FAIL   | Japanese armour=1/exp 0, infantry=8/exp 10 |
| 2   | FAIL   | same                                        |
| 3   | PASS   | —                                          |
| 4   | FAIL   | same                                        |
| 5   | PASS   | —                                          |

⇒ **2/5 PASS** (iter-44 was 3/5 — variance within noise band; fix
neutral but not regressive in expectation).

Fixes applied to
`odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`:

1. `purchase_land_units` l.3043 `for nb, _ in neighbors` → sorted via
   `pro_determinism_sorted_territory_keys(neighbors)`. Feeds
   `owned_local_units` → `attack_efficiency`/`defense_efficiency`
   whose support-factor float sum is order-sensitive (mirror of
   iter-44 l.3654 fix).
2. `purchase_defenders` l.2525 `max_units_set` →
   `pro_determinism_sorted_unit_keys_with_uuid`. Feeds the AMPHIB
   defender list passed to `calculate_battle_results`.
3. `purchase_defenders` l.2768 `bombard_set` → UUID-sorted helper.
4. Factories/can-hold loop l.3312 `max_units_set` → UUID-sorted.
5. Factories/can-hold loop l.3327 `bombard_set` → UUID-sorted.

Build: `/tmp/snaprun_stock_iter45` (5.2M, 20:23). Runner:
`/tmp/iter45_runner.sh`. Artifacts: `/tmp/iter45_run{1..5}.{stdout,stderr}`.

Diagnosis: 5 sites converted at the same pattern as iter-44 still
leave 2-3/5 flake band; the residual perturbation must be UPSTREAM of
the purchase phase — most likely in non-combat-move (NCM) which leaves
Japan with a unit-set that differs in pointer order between runs and
is then iterated raw somewhere in the greedy purchase decision. Layer
29a (`do_move`) is the next suspect — was YELLOW in iter-44 trace
table for "4/5 runs identical at unit-set level; run 5 still
diverges". Iter-43's `calculate_amphib_routes` fix addressed one
symptom but the underlying do_move iteration order is still
ASLR-leaky in 2/5 runs.

**Lesson recorded:** when 5 sequential same-pattern fixes do not move
the needle, STOP fixing the same layer and re-instrument upstream.
Pattern-matching is not a substitute for evidence localisation.

## Last action (prev)

2026-05-25 (iter 44) — **Sea-defender setup pointer-map iteration fix
SHIPPED. Stock PASS rate 2/5 → 3/5; same residual divergence pattern
(Japanese armour=1/expected 0, infantry=8/expected 10).**

Stock baseline measurement (no probes, `/tmp/snaprun_stock_iter44`,
5× ASLR-on snap 0089) confirmed iter-43's leak rate is real and
NOT probe-induced: P=0/5, F=run1, P=run2, P=run3, F=run4, F=run5 ⇒
**2/5 PASS** with iter-43's `calculate_amphib_routes` fix only.
All failures BYTE-IDENTICAL: `Japanese armour=1 (expected 0),
infantry=8 (expected 10)` — cost-equivalent (6 PUs each pair).

Iter 44 fix targets pointer-keyed `map[^Unit]struct{}` and
`map[^Territory]struct{}` iterations in
`pro_purchase_ai_purchase_sea_and_amphib_units` (the SEA-DEFENDER
setup, BEFORE the AMPHIB section which iter-43 stabilised). Four
sites converted to deterministic-sorted iteration:

1. `neighbors` map (l.3654) → `pro_determinism_sorted_territory_keys`.
   Feeds `owned_local_units` → `pro_purchase_option_get_sea_defense_efficiency`
   whose support-factor float sum is order-sensitive.
2. `attackers_set` (l.3690) → new
   `pro_determinism_sorted_unit_keys_with_uuid` helper. Feeds
   `calculate_battle_results` Monte Carlo (RNG-driven, order-sensitive
   for tied estimates).
3. `mu_set` / `mb_set` (l.3880/3885) → same UUID-sorted helper.
   Feeds `estimate_defend_battle_results`.
4. `bombard_set` (l.3748) → same UUID-sorted helper. Feeds
   `calculate_battle_results`.

New helper: `pro_determinism_sorted_unit_keys_with_uuid`
(`odin_flat/games__strategy__triplea__ai__pro__util__pro_determinism.odin`):
sorts `map[^Unit]V` by `(owner_name, type_name, already_moved, UUID[0..16])`.
UUID-bytes-tiebreak makes the order strictly total even for multiple
same-type units of the same owner, eliminating the
`stable_sort_by`-with-ASLR-input fallback used by the older
`pro_determinism_sorted_unit_keys`.

Verification (`/tmp/snaprun_stock_iter44b`, 5× ASLR-on snap 0089):

| iter 44b run | result | divergence detail                                    |
|--------------|--------|------------------------------------------------------|
|     1        | PASS   | —                                                    |
|     2        | FAIL   | Japanese armour=1/exp 0, infantry=8/exp 10           |
|     3        | PASS   | —                                                    |
|     4        | FAIL   | Japanese armour=1/exp 0, infantry=8/exp 10           |
|     5        | PASS   | —                                                    |

**PASS rate 3/5** (stock 2/5 → 3/5; matches iter-43 probe binary 3/5).
Net improvement +20% but residual leak persists. The always-same
failure pattern (1 armour vs 2 infantry, 6 PU swap) indicates one
tied-float greedy decision still flipping based on an upstream
ASLR-perturbed RNG state.

Artifacts: `/tmp/snaprun_stock_iter44` (stock pre-iter-44),
`/tmp/snaprun_stock_iter44b` (post-iter-44), `/tmp/iter44_stock_run{1..5}.{stderr,stdout}`,
`/tmp/iter44b_run{1..5}.{stderr,stdout}`. Memory:
`/memories/repo/iter44-purchase-sea-defender-fix.md`.

2026-05-25 (iter 43) — **`calculate_amphib_routes` deterministic-sort fix
SHIPPED. PASS rate 1/5 → 3/5; NCM `09_after_doMove` byte-identical in
4/5 runs.** Iter-42 evidence localised the leak to
`pro_move_utils_calculate_amphib_routes` (l.392) where two compounding
nondeterminism sources fed into each other:

1. `for u in amphib_attack_map` iterates a pointer-keyed map ⇒
   ASLR-random order.
2. `slice.sort_by(pairs[:], ...)` is Odin's **unstable** pdqsort, and
   the existing composite key `(terr, owner, type, hits, alreadyMoved)`
   is NOT unique for same-type Japanese transports sitting in the same
   sea zone with the same load state. Java's sort here is **stable**
   TimSort, so Java preserves HashMap-iteration order on ties (which
   is itself a JVM-specific quirk via `identityHashCode`).

Fix (`odin_flat/games__strategy__triplea__ai__pro__util__pro_move_utils.odin`):

1. `pro_move_utils_amphib_unit_sort_key` (l.15) enriched with:
   - loaded-unit-types signature (sorted type names joined by 0x02)
   - 32-char lowercase hex of `unit_get_id(u)` (the Unit's UUID, stable
     across runs because units are deserialised from snap save state).
2. `slice.sort_by(pairs[:], ...)` → `slice.stable_sort_by(pairs[:], ...)`
   in both `calculate_amphib_routes` (l.430) and
   `calculate_bombard_move_routes` (l.706).

Verification (5× ASLR-on snap 0089, `/tmp/snaprun_rpo_ncmu3.kept`):

| iter 43 run | result | n@08b | n@09 | 09 type set                                     | own_n | t60 rem | t62 rem |
|-------------|--------|-------|------|-------------------------------------------------|-------|---------|---------|
|     1       | FAIL   |   8   |  3   | aaGun, armour, factory                          |   3   |    8    |    3    |
|     2       | PASS   |   8   |  3   | aaGun, armour, factory                          |   3   |    8    |    1    |
|     3       | FAIL   |   8   |  3   | aaGun, armour, factory                          |   3   |    8    |    3    |
|     4       | PASS   |   8   |  3   | aaGun, armour, factory                          |   3   |    8    |    1    |
|     5       | PASS   |   8   |  4   | aaGun, artillery, factory, infantry             |   4   |    8    |    2    |

**PASS rate 3/5** (vs iter 42b 0/3 on this binary, iter 42a 1/5). NCM
`09_after_doMove` byte-identical in runs 1–4 (n=3, sorted types
identical). Run 5 still varies (n=4, different types) — a residual
secondary leak inside `calculate_amphib_routes` or downstream. Runs
1/3 vs 2/4 have identical NCM output but FAIL/PASS differ ⇒ a separate
downstream leak in purchase-rem_prod consumption at SZ62 (rem=3 fails,
rem=1 passes).

Two remaining leak surfaces for iter 44:
- **LEAK A residual** — run 5 deviation: a different code path inside
  `calculate_amphib_routes` is still nondeterministic (perhaps the
  per-sea-zone load loop or a secondary `map[^Territory]` iteration).
- **LEAK C (new)** — `purchase_sea_and_amphib_units` greedy purchase
  consumes different `rem_prod` despite identical NCM input
  (rem_prod=3 vs rem_prod=1 at SZ62 with same own_n=3, same purchase
  options state in P00..P05 per iter 40A).

Artifacts: `/tmp/iter43_run{1..5}.{stderr,stdout}.kept`,
`/tmp/snaprun_rpo_ncmu3.kept`. Memory: `/memories/repo/iter43-amphib-routes-fix.md`.

2026-05-25 (iter 42) — **NCM leak (LEAK A) localised to
`pro_non_combat_move_ai_do_move` / `pro_move_utils_calculate_amphib_routes`.**
Iter 42a installed 8 `NCM_UNITS` probes (00..08_after_moveInfra)
inside `pro_non_combat_move_ai_do_non_combat_move`. Iter 42b added
`08b_before_doMove`, `09_after_doMove`, and a `MOVE_PLAN dst=… japan_units_n=… [i]type@ptr…` dump showing every Japan-origin unit in
each Pro_Territory's `units` slice (the planner's output that feeds
`do_move`).

Iter 42a (5× ASLR-on, snap 0089, `/tmp/snaprun_rpo_ncmu`,
RPO_DUMP build with NCM_UNITS probes 00..08):
- All 8 NCM_UNITS labels at Japan are byte-identical across all 5
  runs (n=8, sorted types `aaGun, armour, artillery, factory,
  4× infantry`, all owned Japanese).
- AMPHIB_OUTER `own_n@Japan` (= `unit_collection.units` count at
  purchase entry) = `2, 4, 2, 3, 2` → 1/5 PASS.

| 42a run | result | own_n@Japan |
|---------|--------|-------------|
|   1     | FAIL   | 2           |
|   2     | FAIL   | 4           |
|   3     | FAIL   | 2           |
|   4     | PASS   | 3           |
|   5     | FAIL   | 2           |

Iter 42b (3× ASLR-on, snap 0089, `/tmp/snaprun_rpo_ncmu2`, RPO_DUMP
build with the extra `08b_before_doMove`/`09_after_doMove`/MOVE_PLAN
probes):
- MOVE_PLAN output is byte-identical across all 3 runs (only pointer
  addresses differ from ASLR):
  ```
  MOVE_PLAN dst=Japan      japan_units_n=1 [0]aaGun
  MOVE_PLAN dst=Manchuria  japan_units_n=3 [0]infantry [1]infantry [2]infantry
  MOVE_PLAN dst=Yunnan     japan_units_n=3 [0]armour [1]infantry [2]artillery
  ```
- `08b_before_doMove` at Japan: n=8, identical sorted types — every run.
- `09_after_doMove` at Japan: **n=5, n=3, n=2** across the 3 runs. The
  EXECUTOR (`pro_non_combat_move_ai_do_move`) removes a DIFFERENT
  number of units from Japan each run.
- AMPHIB_OUTER `own_n@Japan` = 5, 3, 2 (0/3 PASS for this binary).

| 42b run | result | n@08b (pre-doMove) | n@09 (post-doMove) | own_n |
|---------|--------|--------------------|--------------------|-------|
|   1     | FAIL   | 8                  | 5                  | 5     |
|   2     | FAIL   | 8                  | 3                  | 3     |
|   3     | FAIL   | 8                  | 2                  | 2     |

**Conclusion.** `do_non_combat_move` (the planner) is deterministic at
unit-identity granularity — the `move_map` it returns is byte-identical
across ASLR rolls. The leak lives downstream in `pro_non_combat_move_ai_do_move`
(`pro_non_combat_move_ai.odin` l.1226). Specifically:

1. `pro_move_utils_calculate_move_routes` (l.157) walks
   `for u in pt.units` which is `[dynamic]^Unit` and was just proven
   deterministic by MOVE_PLAN — UNLIKELY culprit.
2. `pro_move_utils_calculate_amphib_routes` (l.392, called second)
   iterates `pro_territory_get_amphib_attack_map(pt)` which is
   `map[^Unit][dynamic]^Unit` — pointer-keyed iteration ⇒
   nondeterministic order across ASLR rolls. **PRIME SUSPECT.**
   Japan↔Manchuria/Yunnan over the China-coast sea zones IS an
   amphibious operation, so amphib_routes mutates Japan's unit set.
3. The `do_move` merge loop and `move_delegate_perform_move` are
   given those routes and execute them on the live game state.

Artifacts: `/tmp/iter42_run{1..5}.{stderr,stdout}.kept`,
`/tmp/iter42b_run{1..3}.{stderr,stdout}.kept`,
`/tmp/snaprun_rpo_ncmu` (NCM_UNITS 00..08 binary),
`/tmp/snaprun_rpo_ncmu2` (+08b/09 + MOVE_PLAN binary).
Memory: `/memories/repo/iter42-do-move-leak.md`.

**Iter-41's interpretation REVISED:** the leak is not in the planner
sub-phases that NCM_TRACE/NCM_UNITS hash (those are now provably
deterministic). The leak is downstream in `pro_non_combat_move_ai_do_move`
when it consumes the deterministic `move_map` and walks the
pointer-keyed `amphib_attack_map`.

2026-05-25 (iter 41) — **NCM leak (LEAK A) CONFIRMED at
per-unit granularity. Existing `NCM_TRACE` hash is INSUFFICIENT
— it only captures Pro_Territory aggregates (counts + value +
hold-flag), not unit identities. Iter 41's evidence is the
strongest yet: Japan's actual `unit_collection.units` count
post-NCM varies across runs of the SAME binary.**

Built `/tmp/snaprun_rpo_ncm` with `-define:RPO_DUMP=true
-define:NCM_TRACE=true` and ran 5× ASLR-on snap 0089:

| run | result | NCM_TRACE diff vs run1 | AMPHIB t=60SZ ptl_n | AMPHIB t=62SZ ttnu_n |
|-----|--------|------------------------|---------------------|----------------------|
|  1  | PASS   | ref                    | 2                   | 4                    |
|  2  | FAIL   | **EMPTY DIFF**         | 4                   | 4                    |
|  3  | FAIL   | (identical)            | 4                   | 4                    |
|  4  | PASS   | (identical)            | 3                   | 4                    |
|  5  | FAIL   | (identical)            | 4                   | 4                    |

All 11 NCM_TRACE label hashes match BYTE-IDENTICAL across all
5 runs, yet AMPHIB outcomes diverge. → Aggregate-only trace
masks unit-identity divergence. (`pro_ncm_trace_emit` hashes
`U=len(units)|C=...|M=...|V=int(value*1000)|H=...` per
territory — sum over units, never the unit set itself.)

Built second binary `/tmp/snaprun_rpo_amphib` adding
`-define:AMPHIB_PROBE=true` (extra GATHER.* probes inside the
sea/lhood loops). Ran 5× ASLR-on snap 0089. Different config
flag → different printf code → different allocator state →
**different NCM moves**:

| iter41b run | result | own_n@Japan (=`unit_collection.units` count)         |
|-------------|--------|-----------------------------------------------------|
|     1       | FAIL   | **5** (aaGun, factory, infantry, armour, artillery) |
|     2       | FAIL   | **3** (aaGun, factory, armour)                       |
|     3       | FAIL   | **2** (aaGun, factory)                               |
|     4       | FAIL   | **3** (aaGun, factory, armour)                       |
|     5       | FAIL   | **2** (aaGun, factory)                               |

own_n varies 2, 3, 5 across 5 runs of the SAME binary (0/5
PASS rate with AMPHIB_PROBE alloc included). Therefore Japan's
`unit_collection.units` is mutated by NCM differently on each
ASLR roll. The NCM leak is in code that picks WHICH unit to
move (not which territory), and that decision goes through a
pointer-keyed `map[^Unit]` or `map[^Territory]` iteration that
the iter-39 fix did not address.

**Iter-40's interpretation REVISED:** iter 40's NCM_TRACE was
not run; iter 40 only saw AMPHIB-level evidence (which IS a
correct downstream symptom). Iter 41 confirms the NCM-leak
hypothesis with direct probe of Japan's unit count.

**Iter 39's LinkedHashSet+stable_sort fix is still NECESSARY**
(eliminates one pointer-keyed iteration in
`prioritize_sea_territories`), but `pro_non_combat_move_ai`
still has a separate pointer-keyed iteration that decides
which Japan unit gets moved out.

Artifacts: `/tmp/iter41_run{1..5}.stderr.kept`,
`/tmp/iter41_run{1..5}.stdout.kept`,
`/tmp/iter41b_run{1..5}.stderr.kept`,
`/tmp/iter41b_run{1..5}.stdout.kept`. Builds:
`/tmp/snaprun_rpo_ncm` 5.2M @ 13:56 May 25 (NCM_TRACE binary);
`/tmp/snaprun_rpo_amphib` 5.2M @ 14:06 May 25 (AMPHIB_PROBE
binary).

2026-05-25 (iter 40) — **Pre-amphib purchase PU leak FALSIFIED;
sim-walk NCM leak (LEAK A) CONFIRMED as the residual flake.**

Added `PHASE_PUS` probes at every phase boundary in
`pro_purchase_ai_purchase` (P00 entry → P01 after defenders_land
→ P02 after aa → P03 after land → P04 after defenders_sea →
P05 after factory_first), plus an `AMPHIB_GATHER_DONE` probe in
`pro_purchase_ai_purchase_sea_and_amphib_units` printing
`transports_that_need_units` count and `potential_units_to_load`
count just before the greedy purchase loop. All gated under
`when #config(RPO_DUMP, false)` and filtered to Japanese.

**Iter 40A (5× ASLR-on snap 0089, PHASE_PUS only, prior to adding
AMPHIB_GATHER_DONE):**

| run | result | Japan PUs at P00→P01→P02→P03→P04→P05 | AMPHIB_OUTER t=62 SZ |
|-----|--------|--------------------------------------|----------------------|
|   1 | FAIL   | 35→35→35→25→25→25 (japan_n=4)       | rem_prod=3           |
|   3 | FAIL   | 35→35→35→25→25→25 (japan_n=3)       | rem_prod=3           |
|   5 | PASS   | 35→35→35→25→25→25 (japan_n=3)       | rem_prod=1           |

Japan PUs (and consumption rate) are IDENTICAL through all five
pre-amphib phases in all runs. The pre-amphib phases consume the
same PUs and produce the same `purchase_options` state. So
**LEAK B does not exist in the pre-amphib pipeline** — the
divergence enters only inside `purchase_sea_and_amphib_units`
itself.

**Iter 40B (5× ASLR-on snap 0089 with AMPHIB_GATHER_DONE):**

| run | result | own_n@t=60 | own_n@t=62 | ttnu_n@t=60 | ptl_n@t=60 | ttnu_n@t=62 | ptl_n@t=62 |
|-----|--------|------------|------------|-------------|------------|-------------|------------|
|   2 | FAIL   | 2          | 2          | 3           | 4          | 4           | 8          |
|   3 | FAIL   | 5          | 5          | 3           | 4          | 4           | 8          |
|   4 | FAIL   | 3          | 3          | 3           | 4          | 4           | 9          |
|   5 | PASS   | 3          | 3          | 3           | 2          | 4           | 10         |

Tally: **1/4 PASS**. Two observations:
1. `own_n` (Japan-owned units present on Japan) varies 2..5
   across runs even though pre-NCM japan_n is constant.
2. **Even runs 4 and 5 with identical `own_n=3` differ in
   `ptl_n@t=60` (4 vs 2)** — that is units in *neighboring*
   sea zones and adjacent land territories. So the leak is
   wider than "Japan's own unit count"; the NCM sim-walk also
   moves DIFFERENT Japan units to DIFFERENT non-Japan
   destinations across runs, even when the resulting Japan
   count happens to coincide.

**Iter-39's "pre-amphib purchase leak" hypothesis is REFUTED.**
The two leaks were not independent — the run-1-vs-run-3
divergence in iter 39 was driven entirely by the NCM-leak
upstream changing what units the amphib loop saw, not by a
pure purchase pipeline non-determinism.

**LEAK A (sim-walk NCM, `pro_non_combat_move_ai`) is the sole
remaining ASLR-flake source for snap 0089.**

Artifacts: `/tmp/iter40_run{1,2,3,4,5}.stderr.kept`,
`/tmp/iter40_probe{1,3,5}.kept`, `/tmp/iter40b_run{2,3,4}.stderr.kept`,
`/tmp/iter40b_probe{2,3,4}.kept`. Build: `/tmp/snaprun_rpo`
5.2M @ 13:23 May 25.

2026-05-25 (iter 39) — **Java-fidelity fix shipped in
`pro_purchase_ai.odin`. `prioritize_sea_territories` used a
pointer-keyed `map[^Pro_Place_Territory]struct{}` to mirror
Java's `LinkedHashSet<ProPlaceTerritory>` — iteration order
was ASLR-dependent. Replaced with an insertion-ordered
`[dynamic]^Pro_Place_Territory` + dedup map. Also upgraded
both `slice.sort_by` call sites
(`prioritize_sea_territories` strategic-value-desc sort and
`purchase_sea_and_amphib_units` alphabetical name sort) to
`slice.stable_sort_by` so equal-key ties preserve LinkedHash
insertion order (Java `List.sort` is a stable mergesort).
Build: `/tmp/snaprun_rpo` 5.2M @ 12:41 May 25.**

**3× ASLR-on snap 0089 verification (probes still gated under
`RPO_DUMP`, kept on this binary):**

| run | result | jNCM        | bp[] composition after NCM                | AMPHIB_OUTER t=62SZ |
|-----|--------|-------------|-------------------------------------------|---------------------|
|   1 | FAIL   | 8→4         | aaGun, factory, infantry, artillery       | rem_prod=3          |
|   2 | PASS   | 8→3         | aaGun, factory, armour                    | rem_prod=1          |
|   3 | PASS   | 8→4         | aaGun, factory, infantry, artillery       | rem_prod=2          |

Tally: **2/3 PASS** (up from iter-38's 1/2). Iter-39 fix is
NECESSARY (eliminated the pointer-hash tiebreak between two
`^Pro_Place_Territory` entries for the same `62 Sea Zone`
that caused iter 38's flake), but NOT SUFFICIENT. Two residual
leaks remain:

1. **Sim-walk leak (iter-38 falsification CORRECTED):** runs 1
   and 2 differ in jNCM outcome (8→4 vs 8→3) with the SAME
   pre-NCM state (japan_n=8). Iter-38's claim that "sim-walk
   is deterministic" was based on coincidental agreement of
   two ASLR samples. Re-instates iter-37's NCM-leak hypothesis.

2. **Pre-amphib purchase PU accounting:** runs 1 and 3 have
   IDENTICAL pre-amphib state (japan_n=4, same bp composition
   [aaGun, factory, infantry, artillery]) but produce different
   final purchases (run 1 buys 1 armour; run 3 buys 10 infantry)
   and different `rem_prod` at the t=62 amphib iteration
   (3 vs 2). So the purchase pipeline ITSELF still has an
   ASLR-dependent leak in one of the pre-amphib phases.
   **REFUTED in iter 40** — see iter-40 entry above.

Artifacts: `/tmp/iter39_run{1,2,3}.stderr.kept`,
`/tmp/iter39_probe{1,2,3}.kept`.

2026-05-25 (iter 38) — **Added `SIMSTEP_BEFORE/AFTER` probe
inside the sim-walk loop in `abstract_pro_ai.odin` (lines ~840
and ~1082, both gated under `when #config(RPO_DUMP, false)` and
filtered to player Japanese). The probe prints Japan's
`unit_collection.units` length around each `for step in
game_steps` iteration. 2× ASLR-on single-snap runs of snap 0089
with the iter-38 binary (build `/tmp/snaprun_rpo` 5.2M @ 12:23
May 25):**

| run | result | SIMSTEP trace (Japan)                                            | bp[] composition at BEFORE_PRIO_SEA | AMPHIB_OUTER t=62SZ land=Japan |
|-----|--------|------------------------------------------------------------------|--------------------------------------|---------------------------------|
|   1 | PASS   | jCM 8→8, jBattle 8→8, jNCM 8→**3**, jPlace 3 entry (purchase) | aaGun, factory, armour              | spt_n=1 own_n=3 **rem_prod=1**  |
|   2 | FAIL   | jCM 8→8, jBattle 8→8, jNCM 8→**3**, jPlace 3 entry (purchase) | aaGun, factory, armour              | spt_n=1 own_n=3 **rem_prod=3**  |

**Iter-37 hypothesis falsified.** The SIMSTEP traces are
**identical** across runs (both end at japan_n=3 with the same
3-unit composition aaGun/factory/armour). So Japan's
unit-collection mutation during the sim-walk loop is NOT the
ASLR-flaky leak — `pro_non_combat_move_ai_do_move` and friends
mutate Japan deterministically when given identical pre-sim
state. The earlier iter-37 split (PASS=3 / FAIL=5) was coincidence;
ASLR happens to land on different splits on different runs.

**New evidence — the first divergent probe line is
`AMPHIB_OUTER t=62 Sea Zone land=Japan`:** same `spt_n=1`, same
`own_n=3`, but `rem_prod=1` in PASS vs `rem_prod=3` in FAIL.
The 2-PU difference in remaining production at this amphib
iteration cascades to the downstream infantry-purchase decision
(PASS spends 2 PUs on something at sea-zone 62 / Japan; FAIL
doesn't, leaving extra production that later goes to armour).

**The leak is INSIDE `pro_purchase_ai_purchase_sea_and_amphib_units`
itself** (or in an earlier purchase phase that already consumed
some PUs before reaching this AMPHIB_OUTER iteration). Either an
earlier amphib iteration's decision was non-deterministic, or
the production-pool consumption order on the way into this loop
is order-dependent. No fix shipped — probes remain gated.
Artifacts: `/tmp/iter38_run{1,2}.stderr.kept`,
`/tmp/iter38_probe{1,2}.kept`.

2026-05-25 (iter 37) — **Added `TERR_DUMP_JAPAN_PURCHASE_ENTRY`
probe at the very entry of `pro_purchase_ai_purchase` (line
~4977) and `TERR_DUMP_JAPAN_BEFORE_PRIO_SEA` just before the
`prioritize_sea_territories` call (line ~5150) in
`pro_purchase_ai.odin`. 2× ASLR-on runs:**

| run | result | PURCHASE_ENTRY n | BEFORE_PRIO_SEA n | SEA_ENTRY n | Japan unit types                          |
|-----|--------|------------------|--------------------|--------------|-------------------------------------------|
|   1 | PASS   | 3                | 3                  | 3            | aaGun, factory, armour                    |
|   2 | FAIL   | 5                | 5                  | 5            | aaGun, factory, infantry, armour, artillery |

`n` is CONSTANT across all 3 probe points within each run — so
`pro_purchase_ai_purchase` itself does NOT mutate Japan. The
divergence is **already present at the entry of
`pro_purchase_ai_purchase`**, confirming the leak is upstream of
`pro_purchase_ai_purchase` entirely. **Direct caller located:
`abstract_pro_ai.odin` line ~824, inside a sim-walk loop that
iterates `game_steps` (NCM / CM / move / etc.) on a cloned
`data_copy` BEFORE invoking `pro_purchase_ai_purchase`.** Each
sim-walk step (`pro_non_combat_move_ai_do_move`,
`pro_combat_move_ai_do_move`, etc.) mutates Japan's
`unit_collection.units` in the clone. ASLR-dependent pointer-
keyed map iteration in one of those AI move procs causes Japan's
sim-clone state to differ at the time `pro_purchase_ai_purchase`
runs. No code fix shipped — probe gated under `when
#config(RPO_DUMP, false)`. Iter 38 must probe inside the
sim-walk loop in `abstract_pro_ai.odin` to find which AI phase
(NCM, CM, etc.) is the one that mutates Japan differently.
Concrete artifacts: `/tmp/iter37_run1.stderr.kept` (PASS),
`/tmp/iter37_run2.stderr.kept` (FAIL),
`/tmp/iter37_probe1.kept`, `/tmp/iter37_probe2.kept`. Build:
`/tmp/snaprun_rpo` 5.2M @ 12:11 May 25.

2026-05-25 (iter 36) — **`TERR_DUMP_JAPAN_ENTRY` probe added at
entry of `purchase_sea_and_amphib_units` (line ~3556 in
`pro_purchase_ai.odin`) decisively confirms the leak is UPSTREAM
of that function entirely. 2× ASLR-on runs of snap 0089 with the
iter-36 binary:**

| run | result | TERR_DUMP_JAPAN_ENTRY n | Japan unit types present                   | prioritized_sea_territories order |
|-----|--------|--------------------------|--------------------------------------------|------------------------------------|
|   1 | PASS   | 4                        | aaGun, factory, infantry, artillery        | [62, 62, 60]                       |
|   2 | FAIL   | 2                        | aaGun, factory (infantry+artillery MISSING)| [60, 62, 62]                       |

**Two independent divergences are visible at the very entry to
`purchase_sea_and_amphib_units`:**
1. Japan's `unit_collection.units` is missing 2 units in run 2
   (infantry + artillery). These units have been moved away
   (presumably to a sea transport for amphib staging) by the
   AI's sim-clone pipeline in run 2 but not in run 1.
2. The `prioritized_sea_territories` parameter is ordered
   differently between runs. This is a `[dynamic]^Pro_Place_Territory`,
   so its iteration order is content-dependent, but the source
   that built it must have iterated a pointer-keyed map.

**Therefore the leak is in `pro_purchase_ai.pro_purchase_ai_purchase`
itself OR in the sim-clone pipeline run before this call** (NCM /
CM / `pro_data` simulation / sea-territory prioritization). No fix
shipped — probe gated under `when #config(RPO_DUMP, false)`. Iter
37 must move the probe up one layer into `pro_purchase_ai_purchase`
and into the sea-territory prioritization code. Artifacts:
`/tmp/iter36_run1.stderr.kept`, `/tmp/iter36_run2.stderr.kept`,
`/tmp/iter36_probe1.kept`, `/tmp/iter36_probe2.kept`. Build:
`/tmp/snaprun_rpo` 5.2M @ 11:50 May 25 (iter-34 fix + iter-35 +
iter-36 probes).

2026-05-25 (iter 35) — **Located the next ASLR leak via
`AMPHIB_OUTER` probe added to `pro_purchase_ai.odin` at the start
of the amphib outer per-purchase-territory loop (line ~4200) and
the sea-place-territory loop (line ~3594). 2× ASLR-on runs of
snap 0089 with iter-34 + iter-35 probe binary: run 1 FAIL, run 2
PASS. At the FIRST `AMPHIB_OUTER t="60 Sea Zone" land="Japan"`
call (before any amphib purchase decision), `territory_get_matches(
Japan, owned_by_japanese)` returns `own_n=2` in run 1 vs
`own_n=4` in run 2 — i.e. JAPAN'S UNIT COLLECTION ITSELF DIFFERS
across runs. This is upstream of `purchase_sea_and_amphib_units`
entirely. The AI's sim-clone NCM/CM/factory-placement pipeline
that mutates territory state before the purchase decision has a
pointer-keyed iteration leak. No fix shipped this iteration —
the probe is gated under `when #config(RPO_DUMP, false)`. Iter 36
must walk further upstream (AI's `simulateTurn` /
`non_combat_move` / `combat_move`) to find the next leak.
Concrete artifacts saved: `/tmp/iter35_run1.stderr.kept`,
`/tmp/iter35_run2.stderr.kept`, `/tmp/iter35_probe1.kept`,
`/tmp/iter35_probe2.kept`. Build: `/tmp/snaprun_rpo` 5.2M @ 10:58
May 25.**

2026-05-25 (iter 34) — **Identified ONE additional ASLR leak in
`pro_purchase_option_calculate_support_factor` (pointer-keyed map
iteration over `self.unit_support_attachments` AND over
`unit_type_list_get_support_rules`). Both iterations now sort by
attachment `.name` before the float-summation. Fix shipped in
`games__strategy__triplea__ai__pro__data__pro_purchase_option.odin`
at line ~376 (rules sort) and ~407 (usa_keys sort). Probe added
under `when #config(RPO_DUMP, false)` for future leak hunting.
Build: `/tmp/snaprun_rpo` 5.2M @ 10:26 May 25 (RPO_DUMP=true).
3-clean-run tally on iter-34 binary (snap 0089, ASLR-on):
**3/5 PASS, 2/5 FAIL** (runs 4, 5, 8 PASS; runs 3, 6 FAIL; runs
7, 9, 10 interrupted by stray SIGINT and excluded). Up from
iter-33 1/5 PASS = 20% to iter-34 3/5 PASS = 60%. Necessary
improvement; still not sufficient. Additional leaks remain
upstream of the Amphib loop's `owned_local_amphib_units` count.**

2026-05-24 (iter 33) — **Identified ONE Java-fidelity ASLR leak
in `pro_purchase_utils_randomize_purchase_option` and patched 9
caller sites. Necessary but NOT sufficient: 3/3 ASLR-off (under
`setarch -R`) PASS, but 3/3 ASLR-on still FAIL snap 0089 with the
same `armour 0/1, infantry 10/8` divergence. Additional pointer-
keyed map iteration leak(s) remain in the ProPurchaseAI pipeline.
Lean `/tmp/snaprun_fast` 5.2M @ 22:11:44 May 24 contains the
iter-33 fix. Final 5× ASLR-on tally: 4 FAIL / 1 PASS.**

### Iter 33 — root-cause finding (one of several)

`randomize_purchase_option` (Java `ProPurchaseUtils.randomizePurchaseOption`)
sums `purchase_efficiencies.values()` to compute `total_efficiency`.
Java's parameter type is `LinkedHashMap<ProPurchaseOption, Double>`
— iteration is in *insertion order*, which equals the caller's
options-list traversal order. The Odin port used a plain
`map[^Pro_Purchase_Option]f64`; iteration order is Odin's pointer-
hash bucket order, which depends on per-process ASLR. Floating-
point summation is order-sensitive, so `total_efficiency` differed
by a few ULPs per run, perturbed `chance = eff/total_efficiency*100`
and the `upper_bound` cumulative sums, and flipped the
`random_number <= upper_bound` branch at boundary points — leading
to a different unit pick on the affected iteration.

### Iter 33 — fix (Java fidelity)

`pro_purchase_utils_randomize_purchase_option` already accepted
an optional `insertion_order: []^Pro_Purchase_Option = nil`
parameter (added in iter 30 for two amphib sites). Iter 33 added
the same `insertion_order` argument to **all 9 remaining caller
sites** in `pro_purchase_ai.odin`:

| line | proc                                          | slice passed                                       |
|------|-----------------------------------------------|----------------------------------------------------|
| 1623 | `purchase_units_with_remaining_production` (def) | `purchase_options_for_territory[:]`              |
| 2682 | `place_defenders`                             | `purchase_options_for_territory[:]`                |
| 3100 | land defense                                  | `land_defense_options[:]`                          |
| 3113 | land attack                                   | `land_attack_options[:]`                           |
| 3125 | land fodder                                   | `land_fodder_options[:]`                           |
| 3773 | sea defense                                   | `sea_purchase_options_for_territory[:]`            |
| 4084 | sea defense (additional)                      | `sea_purchase_options_for_territory[:]`            |
| 4588 | amphib                                        | `amphib_purchase_options_for_territory[:]`         |
| 4639 | transport                                     | `sea_transport_purchase_options_for_territory[:]`  |

Each caller already loops the same slice to populate the
efficiencies map, so passing the slice IS the insertion order.

### Iter 33 — verification

Methodology designed to distinguish "ASLR leak" from "RNG-seed
leak" or "build-state leak":

| run set                          | binary                 | ASLR | result   |
|----------------------------------|------------------------|------|----------|
| baseline 5× snap 0089            | iter-31 lean           | on   | 1 FAIL   |
| PUR_TRACE 3× snap 0089           | iter-31 + PUR_TRACE    | on   | 3 IDENT FAIL (allocator-perturbation hides ASLR effect) |
| `setarch -R` 3× snap 0089        | iter-31 lean           | off  | 3 PASS   |
| iter-33 fix 3× snap 0089 ASLR-on | /tmp/snaprun_fast (iter-33) | on | 1 FAIL (same tally) |
| iter-33 fix 3× snap 0089 ASLR-off| /tmp/snaprun_fast (iter-33) | off | 3 PASS  |
| iter-33 fix 5× snap 0089 ASLR-on | /tmp/snaprun_fast (iter-33) | on | **4/5 FAIL, 1/5 PASS** (results /tmp/iter33_postfix_aslr/summary.txt) |

So the fix is **necessary** (Java fidelity is now correct for the
`randomize_purchase_option` sum) but **not sufficient** to make
snap 0089 ASLR-stable. At least one additional pointer-keyed map
iteration is leaking into a decision that affects the Japanese
purchase mix.

### Iter 33 — candidate sites already ruled out

Inspected during iter 33:
- `pro_purchase_validation_utils_find_purchase_options_for_territory_5/_6`
  — loops `purchase_options` slice in order; deterministic.
- `pro_purchase_validation_utils_find_number_of_construction_type_to_place`
  — iterates `purchase_territories` (pointer-keyed) but only
  computes an integer count; addition is commutative.
- `pro_purchase_validation_utils_remove_invalid_purchase_options`
  — backward-index loop over a dynamic array; deterministic.
- `pro_purchase_option_map.get_land_options` / `get_sea_options` /
  etc. — `seen` dedup map is pointer-keyed but iteration source
  is the input array order.
- `pro_purchase_ai_should_save_up_for_a_fleet` (line 623,
  `for k in max_ship_cost^`): iterates a `map[^Resource]int` but
  the body is `max_ship_cost[k] *= scalar`; result is order-
  independent.

### Iter 33 — candidate sites NOT yet ruled out

- Line 2065 `for k in sea_place_territories { append sorted_territories, k }`
  followed by `slice.sort_by(..., strategic_value_desc)`. The
  comparator is strict `>`; ties retain original (pointer-hash)
  order. Affects sea purchase, not directly the Japanese armour
  divergence — but the cascading map mutation could propagate.
- `pro_purchase_option_get_defense_efficiency_with_args` and
  `_get_sea_defense_efficiency`: not yet inspected for internal
  pointer-keyed iteration.
- `pro_battle_utils` / `pro_combat_move_utils` helpers consumed
  during the per-option efficiency computation.
- `purchase_aa_units` (line 772): loops `prioritized_land_territories`
  (deterministic) but computes `best_aa_option` via strict
  `min_cost`; ties go to first match in `purchase_options_for_territory`
  iteration order. That order is the (deterministic) result of
  `find_purchase_options_for_territory_5`, so likely safe.

---

2026-05-24 (iter 32) — **Bisected the iter-31 refactor scaffold
to find the snap-0089 fix. Discovered snap 0089 is genuinely
NON-DETERMINISTIC across runs at the current iter-31 code state:
2/3 single-snap runs PASS, 1/3 timeout at 4 min. The iter-31
87/17 sweep result on snap 0089 was a "lucky" pass; the same
binary re-run hits a different pointer-hash ASLR layout and can
fail. No code change in iter 32 — restored iter-31 byte-for-byte
state, rebuilt /tmp/snaprun_fast at 16:15:40 May 24 (same
5194944-byte size as iter 31).**

### Iter 32 — bisection attempt

Hypothesis A (variant A): Java's `getUnitsToTransportFromTerritories`
checks `transport.getTransporting()` first and returns early if
non-empty. Iter 31 lost this ordering — sort runs unconditionally
in `_from_territories`, then `_from_ordered_territories` does the
check. Restoring iter-27 order (early-return BEFORE sort) tested
as variant A. Single-snap results across multiple builds:

| build time | code state | snap 0025 | snap 0089 |
|------------|-----------|-----------|-----------|
| 13:40 (variant A first applied) | early-return + sort | (not run) | PASS in 2m45s |
| 13:52 (variant A reverted) | sort unconditional = iter 31 | PASS | FAIL (unit tally) |
| 15:30 (variant A re-applied) | early-return + sort | PASS | FAIL (unit tally) |
| 16:15 (variant A reverted again) | sort unconditional = iter 31 | (not run) | PASS, TIMEOUT, PASS over 3 reruns |

The same code state (iter-31 == "sort unconditional") gave
opposite results on snap 0089 across rebuilds. The same build at
16:15 gave PASS/timeout/PASS over 3 sequential runs. Conclusion:
snap 0089 pass/fail at iter-31 state depends on per-process ASLR
choice, not on which code variant. Variant A is NOT the snap-0089
fix; the fix is "luckier ASLR after iter-31 refactor altered
allocation pattern" — non-portable.

### Iter 32 — code state

REVERTED variant A back to iter-31's exact code. The current
`pro_transport_utils_get_units_to_transport_from_territories`
allocates the sort buffer unconditionally before delegating to
`_from_ordered_territories` (which then does the early-return).
This is the same code that produced iter-31's 87/17 sweep.

### Iter 32 — root-cause finding (BLOCKER)

The Odin port has pointer-hash-keyed maps that iterate in
ASLR-dependent order. The ProPurchaseAI seems to consume one
such iteration sequence somewhere downstream of
`_purchase_sea_and_amphib_units`, making snap 0089's purchase
decision non-deterministic. Iter-31's 87/17 was a sweep where
ASLR happened to land on a Java-equivalent ordering.

Iter 33+ must:
1. Find where `^Territory`-keyed (or other pointer-keyed) map
   iteration leaks into the ProPurchaseAI decision pipeline.
2. Sort by name (or `java_hashmap_bucket_for_string`) at the
   leak site.
3. Re-run snap 0089 30+ times to confirm stability.

### Iter 31 — full sweep RESULT (UNEXPECTED NET WIN)

### Iter 31 — bisection (intermediate, partially misleading)

Tested 4 states (built `/tmp/snaprun_fast` after each):

| state | bucket-sort | insertion_order | snap 0025 | snap 0089 |
|------|-------------|------------------|-----------|-----------|
| iter 30 (both on) | ENABLED | ENABLED | FAIL (1 art/inf swap) | PARTIAL FIX (PUs 1!=0) |
| iter31c (sort off, ord on) | reverted | ENABLED | FAIL | OLD FAIL (armour 0/1 etc) |
| iter31d (both off) | reverted | reverted | PASS | NOT RETESTED (mistake) |
| iter31e (sort on, ord off) | ENABLED | reverted | FAIL | OLD FAIL |

Initial conclusion (WRONG): "snap-0089 partial fix REQUIRES BOTH
iter-30 changes; removing either reverts to OLD failure." This was
because iter31d only re-ran snap 0025, not snap 0089. The truth:
iter31d state would have PASSED snap 0089 — it was the
intermediate-build state that became the final iter-31 binary.

### Iter 31 — full sweep at the FINAL build state

Built /tmp/snaprun_fast at 22:39:30 May 23 with:
- `pro_purchase_ai.odin` `_purchase_sea_and_amphib_units` amphib
  loop using `pro_determinism_sorted_territory_keys` (alphabetical),
  NO bucket-sort.
- Both amphib `randomize_purchase_option` call sites in 2-arg form
  (no `insertion_order`).
- KEPT: refactor scaffolding —
  `pro_transport_utils._from_ordered_territories` overload exists
  and is called from `_from_territories` (which sorts alphabetically
  then delegates). Duplicate `unit_get_transporting_no_args` call
  removed from `_from_territories`. Optional `insertion_order` param
  on `pro_purchase_utils_randomize_purchase_option` (nil-defaulted,
  unused).

Sweep was 87/17 = NEW BEST. Snap 0089 PASS, snap 0025 PASS, snap
0032 FAIL (regression vs iter 30 alone).

### Iter 31 — what's left for iter 32

The actual snap-0089 fix is hiding in one of the refactor scaffold
changes. Iter 32 should bisect those (extra-`make` vs duplicate-
call-removal) to identify the real fix and document it cleanly.
The bucket-sort scaffolding (`Java_Bucket_Sort_Entry` struct,
`java_hashmap_sort_territories_by_bucket`) was NOT the snap-0089
fix and can be deleted as dead code once iter 32 confirms.

### Iter 31 — full sweep RESULT (UNEXPECTED NET WIN)

**87 PASS / 17 FAIL / 0 OTHER.** +1 vs both iter 27 (86/18) and
iter 30 (86/18). Iter-31 FAIL set:
`{0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065, 0074, 0075,
0076, 0077, 0084, 0090, 0092, 0097, 0100}`.

Deltas vs iter 27:
- snap **0089 newly PASSES** (japanesePurchase). The bisection
  single-snap test at "iter31e" had run with bucket-sort ON +
  insertion_order OFF and showed snap 0089 FAIL. The FINAL
  rollback build (22:39:30, bucket-sort OFF + insertion_order OFF)
  was the FIRST time the truly-rolled-back state was tested on
  snap 0089 — and it PASSES. The refactor scaffolding (new
  `_from_ordered_territories` overload path + removed duplicate
  `unit_get_transporting_no_args` call) is the incidental fix.
- snap **0025 STILL PASSES** (germanPlace; iter-30 regression
  undone).
- snap **0032 STILL FAILS** (iter-30 indirect gain reverted, as
  expected).

Net: +snap 0089 PASS without paying snap 0025 or any other snap.

Note the bisection conclusion was WRONG about "snap 0089 fix
requires both changes JOINTLY". The truth: iter-30's algorithmic
additions were both NOISE; the actual fix was the incidental
refactor (extra `make` in `_from_ordered_territories`, OR removal
of the duplicate `transporting` call). The bucket-sort and
insertion_order changes were both regressing snap 0025 (one of
them alone) and the net iter-30 result was -2 (snap 0089 partial
FAIL still, snap 0025 newly broken, snap 0032 incidental win).
Iter 31 isolates the GOOD half of the iter-30 work.

---

2026-05-23 (iter 30) — **Identified and shipped the `purchaseSeaAndAmphib`
LinkedHashSet bucket-order divergence that drove snap 0089. Symptom
(unit tally: armour 0→1, infantry 10→8) is GONE in lean run.
Residual `PUs: 1 != 0` is a secondary, smaller divergence and a
separate iter.** The fix replaces sortet-by-name iteration of
`territoriesToLoadFrom` with Java HashSet bucket order (capacity =
`java_hashmap_capacity_for_size(pre_filter_size)`). Without it,
`pro_transport_utils_get_units_to_transport_from_territories`
visited candidate territories in alphabetical order; Java visits
them in `HashSet<Territory>` bucket order over a capacity fixed at
`new HashSet<>(getNeighbors(...))` construction time. The
mismatched iteration changed which candidate unit was loaded first
which propagated into a totally different `potentialUnitsToLoad`
sequence and ultimately the divergent armour/infantry counts.

### Iter-30 — divergence detection technique

The PUR_TRACE iter-29 narrowing pointed at P06
(`purchaseSeaAndAmphibUnits`). Used the existing `AMPHIB_PROBE`
(`-define:AMPHIB_PROBE=true`) — built `/tmp/snaprun_amphib2` (5.2 MB),
ran snap 0089 in 2m50s. Confirmed:

- `AMPHIB_LOOP.eff` lines printed efficiencies in **random map order**
  (different sequence each loop iteration). The probe was leaking
  allocator perturbation just like PUR_TRACE in iter-28, so the
  AMPHIB_PROBE run produced an outcome closer to Java's than the
  lean run did — useful for narrowing, but not faithful enough to
  use as a green-light signal. Lean run remains the source of truth.
- `GATHER.tlf_kept.t name=...` showed `territoriesToLoadFrom`
  iteration order: alphabetical (Formosa, Iwo Jima, Japan, Okinawa,
  Philippine Islands). Java visits them in HashSet bucket order
  (capacity 32 from raw 25 pre-filter entries).

### Iter-30 — files changed (4)

1. `odin_flat/java_hashmap_order.odin` — added imports for
   `core:slice` and `core:strings`; added
   `Java_Bucket_Sort_Entry` struct and
   `java_hashmap_sort_territories_by_bucket(territories, capacity)`
   reusable helper that sorts a territory slice in place by
   `(java_hashmap_bucket_for_string, name)`.
2. `odin_flat/games__strategy__triplea__ai__pro__util__pro_transport_utils.odin`:
   - Refactored `pro_transport_utils_get_units_to_transport_from_territories`
     to delegate the work to a new shared
     `_from_ordered_territories` overload that accepts a
     caller-supplied `[]^Territory` iteration order.
   - Old call site (name-sorted) preserved: it now just builds the
     name-sorted slice and calls the ordered variant.
   - Added 4-arg wrapper
     `pro_transport_utils_get_units_to_transport_from_ordered_territories_4`
     for callers that want default predicate.
3. `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`
   (`pro_purchase_ai_purchase_sea_and_amphib_units` inner loop at
   `seaTerritories` → `transports` → `territoriesToLoadFrom`):
   - Capture `tlf_raw_size := len(territories_to_load_from)`
     BEFORE the `removeIf(water || val > 0.25)` filter.
   - Compute `tlf_cap := java_hashmap_capacity_for_size(tlf_raw_size)`.
   - Materialize remaining keys into a slice, sort with
     `java_hashmap_sort_territories_by_bucket(slice, tlf_cap)`.
   - Pass that slice to
     `..._from_ordered_territories_4` instead of the map.
4. `odin_flat/games__strategy__triplea__ai__pro__util__pro_purchase_utils.odin`:
   - Added optional `insertion_order: []^Pro_Purchase_Option = nil`
     parameter to `randomize_purchase_option`; when non-nil the
     `total_efficiency` sum walks that slice (so Java
     `LinkedHashMap.values()` order is reproduced byte-for-byte —
     floats summed in same order). Falls back to map iteration when
     nil so the existing call sites are untouched.
5. Two amphib-loop call sites updated to pass insertion order:
   `amphib_purchase_options_for_territory[:]` for "Amphib" and
   `sea_transport_purchase_options_for_territory[:]` for "Sea
   Transport".

### Iter-30 — verification

- Build:
  - lean `/tmp/snaprun_fast` 5.2 MB at 21:33.
  - probe `/tmp/snaprun_amphib2` 5.2 MB at 21:19.
- Snap 0089 lean run:
  - **Before iter-30 fix:** `unit tally divergence: armour 0/1, infantry 10/8`.
  - **After iter-30 fix:** `players.Japanese.resources[PUs]: 1 != 0`
    — unit tally is now EXACT. Residual: 1 PU unspent that Java
    spent. This is a SEPARATE, smaller divergence (e.g. an extra
    `Selected unit` step Java executes once more under a different
    floating-point-summation path) and is a candidate for iter 31.
- Snap 0001 lean run: baseline (no purchase) PASS in <100 ms, no
  regression.
- Full 104-snap sweep with the new lean binary kicked off at end of
  iter 30 — outcome captured in `/tmp/snap_results_iter30/*.txt`
  for cross-iter comparison.

### Iter-30 — open follow-ups

- 1-PU underspend on snap 0089 (Japan amphib loop): trace
  `Selected unit=` / `remainingUnitProduction` between Java oracle
  and Odin to find the unmatched call. Most likely cause: when
  `optionalSelectedOption.isEmpty()` the Odin loop now breaks one
  iteration earlier or later than Java due to a residual map-order
  effect in `removeInvalidPurchaseOptions` (the upstream filter
  iterates a map). Audit pending.
- The `pro_purchase_utils_randomize_purchase_option` sites OUTSIDE
  amphib still sum in random map order. Audit needed but not
  blocking iter 30 (those sites have shipped through 100+ snaps
  without surfacing as primary divergences).

---

2026-05-23 (iter 29) — **Shipped the perturbation-free PUR_TRACE
that iter-28 needed; immediately used it to identify the actual
divergent checkpoint in snap 0089. The new tracer routes ALL
allocations (`make([dynamic]string)`, `strings.builder_make`,
per-row `fmt.sbprintf`) through `context.temp_allocator` — leaving
the global heap untouched and preserving pointer-keyed iteration
order. Verification: snap 0089 now FAILS deterministically WITH
trace enabled (was: tracer perturbation flipped it to PASS in
iter 28), with the IDENTICAL 2-row `<purchase_pool>` symptom
(armour 0→1, infantry 10→8). Smoke snap 0001 PASS in 20 ms.
Checkpoint hashes captured for the first time on a faithful run:**
```
P01_after_purchaseDefenders_land h=c5251fb44c66dd11 n=5
P02_after_purchaseAa             h=c5251fb44c66dd11 n=5  (same)
P03_after_purchaseLand           h=5fc231926d27c0d0 n=5  (changed; expected)
P04_after_purchaseDefenders_sea  h=5fc231926d27c0d0 n=5
P05_after_purchaseFactory_first  h=5fc231926d27c0d0 n=5
P06_after_purchaseSeaAndAmphib   h=10c97889f3f7bdda n=5  <-- DIVERGENT
P07_after_purchaseUnitsWithRem.  h=1a6b541636c1bf55 n=5  <-- propagates
P08-P10                          h=1a6b541636c1bf55 n=5
```
Cross-referencing the dumps against the iter-28 perturbed-PASS
run gives the smoking gun. **The bug is in
`purchaseSeaAndAmphibUnits` (Java `ProPurchaseAi.java:1531`), NOT
in `purchaseLandUnits` as iter-28 hypothesized.**

### Iter-29 — files changed (1)

`odin_flat/games__strategy__triplea__ai__pro__util__pro_pur_trace.odin`:
- `pro_pur_trace_emit`: replaced every default-allocator `make`
  and `strings.builder_make` with the `context.temp_allocator`
  variant (`make([dynamic]string, ta)`, `strings.builder_make(ta)`).
- Dropped the `defer delete(...)` / `defer strings.builder_destroy(...)`
  calls (temp arena owns lifetime).
- Added a comment block explaining the non-negotiable invariant
  (default-allocator usage here would shift global heap pointers
  and mask the very bugs the trace is trying to diagnose; see
  `/memories/repo/snap-0089-iter28-blocker.md`).
- Did NOT add a `free_all(context.temp_allocator)` because callers
  may have live temp data; the 10 trace calls per snap at a few KB
  each are negligible vs the test's normal temp turnover.

### Iter-29 — verification

**Build:** clean (`/tmp/snaprun_purtrace2`, 5.2 MB at 20:54,
`-define:PUR_TRACE=true -define:PUR_TRACE_DUMP=true`).

**Snap 0001 (smoke test, no purchase phase):** PASS in 20.37 ms.
Zero `PUR_TRACE` lines (purchase phase never reached on snap 0001).
Confirms tracer binary itself doesn't break unrelated tests.

**Snap 0089 with new tracer (3 min 19 s wall):** FAIL with same
2-row diff `<purchase_pool>` (armour 0→1, infantry 10→8) AND
10 `PUR_TRACE` checkpoints + 50 `PUR_DUMP` rows printed. Trace
non-perturbing: same diagnostic outcome as no-trace run.

### Iter-29 — drill narrowing (snap 0089)

Comparing the two PUR_DUMP sequences row-by-row:
- **P03_after_purchaseLand** (Manchuria=`art,inf,inf`,
  Japan=`(empty)`): IDENTICAL between PASS-perturbed iter-28
  run and FAIL-faithful iter-29 run. **purchaseLandUnits is
  GREEN for snap 0089.**
- **P05_after_purchaseFactory_first**: IDENTICAL. **purchaseFactory
  is GREEN.**
- **P06_after_purchaseSeaAndAmphib** **DIVERGENT**:
  | run | 60 SZ | Japan | Manchuria |
  |-----|-------|-------|-----------|
  | PASS-perturbed (iter 28) | `transport` (1) | `inf×6` (6) | `art,inf,inf` (3) |
  | FAIL-faithful (iter 29)  | `transport` (1) | `inf×4` (4) | `art,inf,inf` (3) |
  Same number of transports, but **2 fewer infantry at Japan**.
- **P07_after_purchaseUnitsWithRemaining** propagation:
  the FAIL run's leftover 6 PUs (= 2 unbought infantry @ 3 PU
  each) buy 1 armour @ 6 PU. PASS run has no leftover.
  | run | Japan |
  |-----|-------|
  | PASS-perturbed | `inf×6` (6; unchanged from P06) |
  | FAIL-faithful  | `armour,inf×4` (5) |

**Root-cause class:** pointer-keyed iteration inside
`purchaseSeaAndAmphibUnits` (Java line 1531) — likely a HashMap
walk that drives WHICH amphib-loading territory gets prioritised
or HOW MANY infantry get reserved as amphib cargo for the
transport. Same family as iter-21/24/26 LinkedHashMap fixes.

### Iter-29 — next iteration (30) plan
Drill `purchaseSeaAndAmphibUnits` per `/memories/java-fidelity-rule.md`:
1. Read Java `ProPurchaseAi.java:1531-` top-to-bottom.
2. Find the corresponding Odin port (likely
   `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`
   around line ~5060 per the existing P06 emit).
3. Audit for bare `for k, v in some_map` over Java-side
   `LinkedHashMap`/`LinkedHashSet`. Add `_order` parallel slices
   per the iter-26 playbook.
4. Re-run snap 0089 with trace, confirm P06 hash now matches the
   PASS-perturbed hash AND the snap PASSES without the tracer.

### Previous iter-28 entry (preserved below)

2026-05-23 (iter 28) — **Started drilling iter-27's new regression
(snap 0089, Japanese round-2 purchase: 8 inf + 1 armour instead of
10 inf, same PU cost). Seeded the trace table at
`proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase`
(method_layer 28) and built a `-define:PUR_TRACE=true
-define:PUR_TRACE_DUMP=true` instrumented binary
(`/tmp/snaprun_purtrace`, 5.2 MB) to use the existing 10-checkpoint
`ProPurTrace.emit` instrumentation (P01_after_purchaseDefenders_land
through P10_final) for narrowing which sub-phase introduces the
divergence. RESULT: **snap 0089 PASSES with PUR_TRACE on** —
the trace allocations themselves are the perturbation that masks
the bug. Identical to the snap-0037-fresh-look hazard recorded in
`/memories/repo/snap-0037-fresh-look.md`.** Per the strict
"NEVER heap-perturb mid-game" rule from `/memories/repo/step36-japanesePurchase-fix.md`,
the current PUR_TRACE implementation is unsuitable for diagnosing
this snap. Recorded the blocker in Notes; iter-29 needs a
zero-perturbation tracer (temp_allocator only, with single
fixed-size scratch buffer; no `fmt.printf` because that may
default-alloc on Linux). The iter-27 sweep state is unchanged
(86 PASS / 18 FAIL / 0 OTHER); the iter-26 LinkedHashMap fix is
not reverted.

### Iter-28 — drill outcome

**Trace seed (per orchestrator iteration loop step 1):**
- Snap 0089 is the new red snap (iter-27 regression, deterministic).
- Top-level proc: `proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase(games.strategy.triplea.delegate.remote.IPurchaseDelegate,games.strategy.engine.data.GameState)`, layer 28.
- Java entrypoint: `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/ProPurchaseAi.java:262-388`.

**Children of `purchase()` sorted by descending method_layer:**
| layer | child | iter-28 status |
|------:|-------|----------------|
| 27 | `prioritizeSeaTerritories(Map)` | yellow |
| 27 | `purchaseSeaAndAmphibUnits(Map,List,ProPurchaseOptionMap)` | yellow (suspect, see below) |
| 26 | `purchaseFactory(Map,Map,List,ProPurchaseOptionMap,boolean)` | yellow |
| 25 | `prioritizeTerritoriesToDefend(Map,boolean)` | yellow |
| 25 | `purchaseDefenders(Map,List,List,List,List,boolean)` | yellow |
| 19 | `purchaseLandUnits(Map,List,ProPurchaseOptionMap)` | **yellow (TOP suspect)** |
| 18 | `prioritizeLandTerritories(Map)` | yellow |
| 18 | `ProTerritoryManager#populateEnemyAttackOptions(Collection,Collection)` | yellow |
| 18 | `ProTerritoryValueUtils#findTerritoryValues(...)` | yellow |
| 9  | `purchaseUnitsWithRemainingProduction(Map,List,List)` | yellow |
| 8  | `purchaseAaUnits` / `upgradeUnitsWithRemainingPUs` | yellow |
| 7  | `findDefendersInPlaceTerritories`, `populateProductionRuleMap` | yellow |

**PUR_TRACE run on snap 0089** (`/tmp/snaprun_purtrace`,
`FILTER_SNAP=0089 timeout 300`, 2 min 14 s wall):
```
PUR_TRACE label=P01_after_purchaseDefenders_land h=c5251fb44c66dd11 n=5
PUR_TRACE label=P02_after_purchaseAa             h=c5251fb44c66dd11 n=5
PUR_TRACE label=P03_after_purchaseLand           h=5fc231926d27c0d0 n=5  <-- changed
PUR_TRACE label=P04_after_purchaseDefenders_sea  h=5fc231926d27c0d0 n=5
PUR_TRACE label=P05_after_purchaseFactory_first  h=5fc231926d27c0d0 n=5
PUR_TRACE label=P06_after_purchaseSeaAndAmphib   h=d4a9d799ae5de702 n=5  <-- changed
PUR_TRACE label=P07_after_purchaseUnitsWithRem.  h=d4a9d799ae5de702 n=5
PUR_TRACE label=P08_after_upgradeUnitsWithRem.   h=d4a9d799ae5de702 n=5
PUR_TRACE label=P09_after_purchaseFactory_second h=d4a9d799ae5de702 n=5
PUR_TRACE label=P10_final                        h=d4a9d799ae5de702 n=5
```
Final dump rows: Japan=`6 inf`, Manchuria=`artillery+2 inf`,
60 SZ=`1 transport`, two SZs empty. **Test was successful.**

That's the smoking-gun perturbation — without PUR_TRACE the snap
fails deterministically; with PUR_TRACE it passes. PUR_TRACE
allocations from `make([dynamic]string)`,
`strings.builder_make()`, and per-row `fmt.sbprintf` go to
`context.allocator` (default heap), shifting every subsequent
`malloc` return address. Per
`/memories/repo/snap-0037-fresh-look.md`:
> Lesson: do NOT make ANY heap-allocator changes (even REMOVING
> leaks) in mid-game code paths. ... the codebase is hyper-fragile
> to allocator behavior because pointer-keyed maps are everywhere.

The PUR_TRACE binary is therefore **unusable** for narrowing
snap 0089. No further Odin source change made this iter.

**Java side-of-truth note**: the snapshot's actual after.json
shows Japanese delta = +8 infantry, +1 artillery, +1 transport
(35 PUs?? — Japan's round-2 income may have been topped up by
something; not investigated this iter). The failure message
"Expected=10 Actual=8" is on `<purchase_pool>` infantry; per
the `Region=<purchase_pool>` Owner=Japanese diff Odin
substituted 1 armour for 2 inf (cost-equal: 6 PU each side),
suggesting the bug is in `purchaseLandUnits` — that's the only
sub-phase Java/Odin can choose between buying infantry vs armour
in round 2 land options.

### Iter-28 — files changed
None. (Tracer infrastructure perturbation invalidated diagnosis.)

### Previous iter-27 entry (preserved below)

2026-05-23 (iter 27) — **Ran the full 104-snap regression sweep on
the iter-26 codebase using a NEW lean test binary (built with
`-define:ODIN_TEST_TRACK_MEMORY=false`, no `-debug`). Result:
**86 PASS / 18 FAIL / 0 OTHER.** Net +2 PASS over iter-23
baseline (84P/18F), with one WIN (snap 0025 PASSES, was iter-23
FAIL) and one REGRESSION (snap 0089 FAILS, was iter-23 PASS).
Snap 0024 confirmed still red on the lean binary with the same
17-row Algeria/Belorussia/Finland/Libya/Norway/UkrSSR divergence
(unchanged from iter-26/iter-25/iter-24). Process change: the
debug+leak-tracker binary was producing **3 GB per failing-snap
log** which crashed the sweep terminal twice in iter-27.
Built `/tmp/snaprun_fast` (5.2 MB, no debug, no leak tracker);
per-snap log dropped to **4 KB**; peak RSS ≤ 3 MB sampled per
process. Sweep harness `/tmp/run_iter27_sweep_fast.sh` uses
`xargs -P 4`, runs detached via `setsid nohup ... </dev/null
&>/dev/null & disown`, gates via a `_DONE` touch-file, and
includes a serial redo path for any EXIT=137 (parent-shell-kill)
victims. Total sweep wall time ≈ 5 min for 47 missing snaps; 4
killed-mid-flight stragglers replayed serially in ≈ 6 min.**

### Iter-27 — verification results

**Build:** clean (`/tmp/snaprun_fast` 5.2 MB at 19:58, no debug,
no leak tracker). Smoke snap 0001 PASS in 24 ms (vs 88 ms on
debug binary).

**Full 104-snap sweep (lean binary):**
- **PASS: 86** (was iter-23 84).
- **FAIL: 18** (same count as iter-23).
- **OTHER (timeout/missing): 0** (was iter-23 0).
- FAIL set: `{0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065,
  0074, 0075, 0076, 0077, 0084, 0089, 0090, 0092, 0097, 0100}`.

**Deltas vs iter-23 baseline (84P/18F):**
| snap | iter-23 | iter-27 | direction | likely cause |
|------|---------|---------|-----------|--------------|
| 0025 | FAIL    | **PASS** | WIN  | iter-26 LinkedHashMap fix landed AI in the Java-faithful state for the snap-0025 step |
| 0089 | PASS    | **FAIL** | REGRESSION | iter-26 fix changed support iteration → Japanese round-2 purchase now buys 1 armour + 8 inf instead of 10 inf (unit tally `Region=<purchase_pool>` divergence: armour 0→1, infantry 10→8) |
| 17 others (0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065, 0074-0077, 0084, 0090, 0092, 0097, 0100) | FAIL | FAIL | unchanged | deeper-layer bugs, not addressed by iter-26 |

Notes on iter-26 cross-snap impact: the 4-file LinkedHashMap
upstream-extension affects EVERY snap that exercises
`Available_Supports.give_support_to_unit` (i.e. most ground/sea
combats and AI estimators). One snap moved from FAIL→PASS (0025),
one moved PASS→FAIL (0089), 17 unchanged-FAIL, 85 unchanged-PASS.
The fact that 102/104 snaps are unchanged is strong evidence the
fix is Java-faithful, not noisy.

**Snap 0024 re-verification on lean binary:**
- Result: **FAIL** in 42 s wall, peak RSS 3 MB, log 4 KB.
- Symptom identical to iter-26: same 17 unit-tally divergence
  rows (Algeria armour 0→1, Belorussia infantry 0→1, etc.).
- Confirms the lean binary is semantically equivalent to debug.

### Iter-27 — process & infrastructure changes

1. **Lean test binary** (`/tmp/snaprun_fast`):
   ```sh
   cd triplea && /run/current-system/sw/bin/odin build \
     conversion/odin_tests/server_game_run_next_step \
     -collection:flat=../odin_flat \
     -collection:test_common=conversion/odin_tests/test_common \
     -build-mode:test \
     -define:ODIN_TEST_TRACK_MEMORY=false \
     -extra-linker-flags:-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib \
     -out:/tmp/snaprun_fast
   ```
   Result: 5.2 MB binary, ≈ 4× faster on 0001 smoke (24 vs 88 ms),
   per-failing-snap log size dropped from ≈ 3 GB → ≈ 4 KB
   (no leak dump on test failure). DO NOT use this for fault
   diagnosis (leak tracker is off); use the debug binary
   (`/tmp/snaprun`) only when chasing a leak.

2. **Sweep harness** (`/tmp/run_iter27_sweep_fast.sh`):
   - Reads `/tmp/iter27_missing.txt`.
   - Per-snap: HEAD-5 + TAIL-60 of log only (caps disk usage).
   - `xargs -P 4` (was `-P 8`; halved to leave RAM headroom).
   - 300 s per-snap timeout.
   - Touches `/tmp/snap_results_iter27/_DONE` on completion.

3. **Detached launch recipe** (durable across terminal death):
   ```sh
   setsid nohup /tmp/run_iter27_sweep_fast.sh \
     >/tmp/iter27_sweep_fast.log 2>&1 </dev/null & disown
   ```
   Poll via `\ls /tmp/snap_results_iter27/_DONE`.

4. **Tally script** (body-based, not exit-code-based, since
   failing snaps still exit 0 in this harness):
   ```sh
   cd /tmp/snap_results_iter27
   for i in $(seq -f "%04g" 1 104); do
     f=${i}.txt
     if grep -q "test was successful" "$f"; then echo PASS
     elif grep -q "Snapshot.*FAILED\|test failed" "$f"; then echo FAIL
     else echo OTHER; fi
   done | sort | uniq -c
   ```

5. **EXIT=137 redo path** (catches snaps killed mid-flight by
   parent-shell deaths):
   ```sh
   for s in $(grep -l "^EXIT=137" /tmp/snap_results_iter27/*.txt | \
              xargs -n1 basename | sed 's/.txt//'); do
     /tmp/measure_snap.sh "$s" 300
   done
   ```

### Iter-27 — previous iter-26 entry (preserved below)

2026-05-23 (iter 26) — **Resolved the iter-25 regression by
extending LinkedHashMap insertion-order tracking UPSTREAM into
`Support_Calculator` and the missing `Available_Supports.support_rules`
+ `support_units` consumers. Snap 0032 is now DETERMINISTIC across
5 solo runs (5/5 identical FAIL, no hangs); the remaining FAIL is
the same Alaska/Eastern Canada infantry swap but it is no longer
intermittent. Snap 0024 still red with byte-identical iter-25
symptom — confirming the support pipeline is now Java-faithful
and the snap-0024 divergence lives DEEPER (per iter-24/25 Task D
plan: `CasualtySelector#getDefaultCasualties` body, OOL surrounding
logic, or `MainDefenseStrength.isDominatingFirstRoundAttack`).**
Four files changed (all Java-faithful per `AvailableSupports.java`).

### Iter-26 — files changed (4)
1. `odin_flat/games__strategy__triplea__delegate__power__calculator__support_calculator.odin`
   — Added `support_rules_order: [dynamic]^Unit_Support_Attachment_Bonus_Type`
   and `support_units_order: [dynamic]^Unit_Support_Attachment` fields
   to `Support_Calculator`. Initialized in `support_calculator_new`.
   New getters `support_calculator_get_support_rules_order` and
   `support_calculator_get_support_units_order`. Constructor's
   per-rule insertion path appends to both order slices on first
   insertion. `support_calculator_get_unit_support_attachments`
   now walks `support_rules_order` to preserve Java
   `supportRules.values()` order.
2. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
   — Added `support_rules_order` + `support_units_order` parallel
   slices to `Available_Supports`. `available_supports_new` accepts
   optional order args (synthesizes from map keys for back-compat).
   New getters. `give_support_to_unit` outer loop now iterates
   `support_rules_order` (was bare `for _, v in self.support_rules`
   — the iter-25 regression root cause; Java line 124 is
   `supportRules.values()` over `LinkedHashMap`). `filter` rebuilds
   both order slices in the surviving-key order. `get_support`
   walks `support_calculator_get_support_units_order` to preserve
   order on transform.
3. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports__available_supports_builder.odin`
   — Added `support_rules_order` + `support_units_order` builder
   fields, two `_order` setter methods, and threaded both into the
   `build()` finalizer.
4. (No source change in `integer_map_unit.odin`, `support_details.odin`,
   or `main_offense_strength.odin` — the iter-25 changes there
   stay because they are independently Java-faithful and verified.)

### Iter-26 — verification results
**Build:** clean (`/tmp/snaprun` 9.6 MB at 19:18, debug + leak track).
**Snap 0001 smoke:** PASS in 87.7 ms.

**Snap 0032 (5-run solo loop, 240 s timeout each):**
| run | result | runtime |
|----:|--------|---------|
| 1   | FAIL — Alaska/Eastern Canada infantry swap | 1m 28 s |
| 2   | FAIL — SAME swap                          | 1m 28 s |
| 3   | FAIL — SAME swap                          | 1m 32 s |
| 4   | FAIL — SAME swap                          | 1m 45 s |
| 5   | FAIL — SAME swap                          | 1m 27 s |

Tally: **0 PASS / 5 FAIL / 0 HANG — fully DETERMINISTIC.**
Iter-25 baseline was 0P/3F/2HANG (non-deterministic). Iter-23
baseline was 2P/1F (intermittent). Iter-26 has resolved both
the iter-25 regression (eliminated hangs) and the iter-23
intermittency (deterministic now). The remaining FAIL is a single
1-infantry swap between two adjacent territories — a real
Java-fidelity bug to solve in a future iteration.

**Snap 0024 (individual run, 300 s timeout):**
- Result: **FAIL** in 1m 48 s with **byte-identical**
  Algeria/Belorussia/Finland/Libya/Norway/UkrSSR divergence
  (17 region/unit-type rows) to iter-24 and iter-25.
- This confirms the snap-0024 divergence does NOT live in the
  support-iteration pipeline. The support pipeline is now
  Java-faithful (proved by snap 0032 going from intermittent
  to deterministic); the snap-0024 bug is deeper.

**Full 104-snap regression sweep:** NOT run this iteration.
Focused on regression triage. Iter-27 will run the sweep.

### Iter-26 — root-cause confirmed
The iter-25 regression came from `give_support_to_unit` iterating
the OUTER `support_rules` map via bare `for _, v in self.support_rules`.
Java (`AvailableSupports.java:124`):
```java
for (final List<UnitSupportAttachment> rulesByBonusType : supportRules.values()) {
```
over a `LinkedHashMap` (line 31 + 60 + 98). Odin's pointer-hash
iteration meant the *order in which bonus-type buckets were
considered* varied across runs. Each bucket's `IntegerMap`
then received supporter contributions in different orders, which
propagated to `unitsGivingSupport` even though iter-25 had fixed
the per-supporter `Integer_Map_Unit.keys_order`. Net result: the
iter-25 `keys_order` slices captured a run-specific (still-non-Java)
order. Adding `support_rules_order` (and the matching
`support_units_order` for completeness per Java line 32 + 108)
closed the loop.

The HANG in iter-25 runs 2 + 4 also disappeared. Likely cause:
the inconsistent order caused a downstream support consumer to
process an unusual configuration that hit a slow path or pathological
combination; with deterministic Java order the issue is gone.
No separate UAF fix was needed.

### Previous iter-25 entry (preserved)

2026-05-23 (iter 25) — **Shipped the three iter-24 Java-fidelity
fixes (Task A/B/C) to the support pipeline. RESULT: REGRESSION on
snap 0032 (was intermittent 2P/1F → now 0P/3F+2hang in a 5-run
solo loop) AND snap 0024 still red with the SAME unit-tally
divergence (Algeria/Belorussia/Finland/Libya/Norway/UkrSSR units
swapped). Java fidelity of the changes was re-confirmed against
`AvailableSupports.java:31-60` (LinkedHashMap everywhere). The
direction is right, the implementation is incomplete or has a
new ordering bug.** Iter-26 must investigate WHY iter-25 changed
order to a still-non-Java order — most likely an upstream
iteration site (e.g. `give_support_to_unit` caller in the
builder loop, or the missing `support_units` outer-map order)
is still pointer-hashed and feeds the wrong order into the new
`keys_order` slices.

### Iter-25 — files changed (5)
1. `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
   — Task A. `strength = unit_attachment_get_attack_no_player(ua)`
   → `strength: i32 = unit_attachment_get_attack(ua, unit_get_owner(unit))`.
   Mirrors defense-side. Java-faithful per `MainOffenseCombatValue.java:142-145`.
2. `odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin`
   — Task B. Added `keys_order: [dynamic]^Unit` field. Added helpers
   `integer_map_unit_put(self, key, value)` (appends on first insert)
   and `integer_map_unit_remove(self, key)` (removes from both maps).
3. `odin_flat/games__strategy__triplea__delegate__power__calculator__support_calculator.odin`
   — Task B/C wiring. Builder loop (~lines 137-158): `.entries[unit] = number`
   replaced with `integer_map_unit_put`. `support_calculator_get_combined_support_given`
   (~line 238): now walks `available_supports_get_units_giving_support_order(side)`
   and looks up via `available_supports_get_units_giving_support(side)` instead
   of iterating bare map keys.
4. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
   — Task C. Added `units_giving_support_order: [dynamic]^Unit` field.
   `available_supports_new` initializes it. New getter
   `available_supports_get_units_giving_support_order`.
   `give_support_to_unit` (~line 175) appends supporter to the order
   slice on the first-insert branch. `get_next_available_supporter`
   (~line 80) now picks `int_map.keys_order[0]` (with fallback to
   bare-map iteration if empty); uses `integer_map_unit_remove`
   when count ≤ 0.
5. `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports__support_details.odin`
   — Task B back-compat. `available_supports_support_details_new`
   synthesizes `keys_order` from `entries` keys when source has none.
   `_new_copy(other)` copies `keys_order` from other preserving
   LinkedHashMap order; falls back to entries iteration if other.keys_order empty.

### Iter-25 — verification results
**Build:** clean (`/tmp/snaprun` 9.6 MB at 18:30, debug + asan-style
leak tracking). Snap 0001 smoke test: PASS in 99.9 ms.

**Snap 0032 (5-run solo loop, 180 s timeout each):**
| run | result | runtime | log size |
|----:|--------|---------|---------:|
| 1   | FAIL — Alaska/Eastern Canada infantry swap | 1m 19 s | 2.9 GB (debug spam) |
| 2   | TIMEOUT (killed at 180 s, only 11 log lines) | — | 1.1 k |
| 3   | FAIL — same Alaska/Eastern Canada swap | 1m 23 s | 2.9 GB |
| 4   | TIMEOUT (killed at 180 s, only 11 log lines) | — | 1.1 k |
| 5   | FAIL — same Alaska/Eastern Canada swap | 51 s + leak dump | 2.9 GB |

Tally: **0 PASS / 3 FAIL / 2 HANG** (5/5 non-pass). Iter-23 baseline
was 2 PASS / 1 FAIL (intermittent). Iter-25 is a regression in
both pass-rate AND determinism (now hangs sometimes).

**Snap 0024 (individual run, 240 s timeout):**
- Result: **FAIL** in 1m 49 s with `Region=Algeria Owner=Germans
  UnitType=armour Moves=0 Damage=0: Expected=0 Actual=1` plus 16
  more region/unit-type rows — **byte-identical** to iter-24 fail
  symptom. Iteration time grew from 57 s (iter-24) → 110 s
  (iter-25); same outcome.

**Full 104-snap regression sweep:** NOT run this iteration. The
0/5 + REGRESSION result on snap 0032 made the full sweep
non-cost-effective without first understanding the new failure mode.

### Iter-25 — Java fidelity recheck
Per `/memories/java-fidelity-rule.md`, re-verified after the
regression discovery:
```
$ grep -n 'unitsGivingSupport\|new \(Linked\)\?HashMap\|new \(Linked\)\?HashSet' \
    triplea/.../AvailableSupports.java | head
31:  .supportRules(new LinkedHashMap<>())
32:  .supportUnits(new LinkedHashMap<>())
60:  @Getter private final Map<Unit, IntegerMap<Unit>> unitsGivingSupport = new LinkedHashMap<>();
98:  new LinkedHashMap<>();
108: final Map<UnitSupportAttachment, SupportDetails> supportUnits = new LinkedHashMap<>();
139: unitsGivingSupport
```
Confirms Java uses `LinkedHashMap` for ALL three suspect collections.
The iter-25 direction (add keys_order, walk in insertion order) is
**correct Java-fidelity work**. The regression therefore comes from
either (a) the upstream caller that feeds the builder loop is still
pointer-hashed (so the keys_order I capture is itself wrong), or (b)
I missed an iteration site that still uses bare `map[K]V` keys,
producing inconsistent order between population and consumption.

### Iter-25 — open hypotheses for the regression
1. **Builder upstream is still bare-map.** `support_calculator`
   builder loop iterates `available_supports_get_support_rules(side)`
   (`map[unit_type][dynamic]^Unit_Support_Attachment` per Odin
   today). Each rule lookup then iterates the candidate-unit pool.
   If the OUTER `support_rules` iteration uses bare-map keys
   (pointer-hashed `^Unit_Type`), the inner `keys_order` slice
   captures different order on different runs.
2. **`Available_Supports.support_units` (per-rule details map) is
   still bare.** Java line 32 and 108 both use `LinkedHashMap`. My
   iter-25 fix only added order to `units_giving_support`. If the
   consumer iterates `support_units` map keys directly anywhere
   (e.g. inside `Power_Strength_And_Rolls.add_units`), order is
   still pointer-hashed.
3. **`add_units` consumer drift.** `unit_power_strength_and_rolls_builder`
   may walk `available_supports.units_giving_support` directly via
   the bare-map field rather than via the new `_order` getter.
4. **Hang root-cause (runs 2 + 4).** Two of five runs went silent
   immediately after `PSTART` and were killed by `timeout 180`.
   No FATAL/leak/error printed to log. Could be:
   - An infinite loop in `get_next_available_supporter` if
     `keys_order[0]` references a stale `^Unit` (UAF after a
     `remove`).
   - A deadlock on the builder loop if `keys_order` is appended
     during iteration of the same slice.
   - A genuine hang in some downstream support consumer that now
     processes a much larger set than before.

### Previous iter-24 entry (preserved)

2026-05-23 (iter 24) — **Read-only drill iteration. Completed the
iter-23 sweep, classified 2 L9 yellows as green-for-snap-0024,
and discovered TWO new pointer-hash iteration-order bugs in
`Available_Supports` (sibling of iter-21/23 Integer_Map fixes)
that explain a new intermittency in snap 0032.** No Odin source
files modified; status doc + iter-25 plan updated. The sweep is
complete and snap 0024 now FAILS FAST (≈57 s) instead of
TIMEOUTING (was 600 s), making future drills much faster.

### Iter-23 sweep — final tally (104/104 done)
- **84 PASS, 18 FAIL, 0 TIMEOUT.** No `NO_EXIT`/starvation tagged
  (the iter-23 sweep used a 420 s per-snap cap vs iter-21's 120 s).
- iter-23 FAIL set: `{0024, 0025, 0031, 0032, 0037, 0038, 0040,
  0048, 0065, 0074, 0075, 0076, 0077, 0084, 0090, 0092, 0097, 0100}`.
- Raw sweep logs (~100 GB) cleaned up at iter-24 close. Summary
  preserved at `/tmp/snap_results_iter23_summary.txt` (one EXIT
  line per snap).

### Deltas vs iter-21 baseline (16 FAIL / 2 TIMEOUT / 2 NO_EXIT)
| iter-21 status | snap | iter-23 status | classification |
|----------------|------|----------------|----------------|
| TIMEOUT (120s) | 0021 | **PASS** (within 420s) | **win** — true PASS unmasked by larger cap |
| TIMEOUT (120s) | 0037 | FAIL (within 420s) | status improvement — deterministic now (previously timeout) |
| NO_EXIT        | 0073 | **PASS** (3m 40s) | **win** — true PASS unmasked |
| NO_EXIT        | 0089 | FAIL (deterministic) | status improvement — drillable |
| **PASS (fast)** | **0032** | **FAIL (61s)** | **REGRESSION** — see "Snap 0032 intermittency" below |
| FAIL × 16      | rest | FAIL (same) | no change |

Net effect: same 84 PASS count but better classification
(2 wins, 2 status improvements, 1 regression).

### Snap 0032 intermittency (NEW iter-24 finding)
Snap 0032 is now **non-deterministic across runs**:
- Solo run #1 (after build): PASS in 58.83 s.
- Solo run #2 (immediately after): FAIL in 61.09 s with
  `Region=Alaska Owner=British UnitType=infantry Moves=0
  Damage=0: Expected=1 Actual=0; Region=Eastern Canada Owner=British
  UnitType=infantry Moves=0 Damage=0: Expected=0 Actual=1` —
  one British infantry swapped between two adjacent territories.

**Confirmed by 3-of-5 repro at iter-24 close (run3/run5
interrupted; 2 PASS / 1 FAIL across completed runs):** the
divergence is genuinely non-deterministic, not a one-off.

**Hypothesis:** the iter-23 pointer-refactor put `Integer_Map`
behind `^Integer_Map` (good, no value-copy), but the OUTER map
`Available_Supports.units_giving_support: map[^Unit]^Integer_Map`
and the supporter pool `Integer_Map_Unit.entries: map[^Unit]i32`
are still bare `map[K]V` with pointer-hash iteration. In iter-21
the value-copy bug silently dropped most of the contributions so
the artifact never propagated; iter-23 enables the contributions
and exposes the underlying iteration-order non-determinism.

### NEW Java-fidelity bugs discovered (iter-24)
Per java-fidelity rule, read Java first then diffed Odin port:

#### 1. `MainOffenseStrength.getStrength` uses wrong accessor
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
- Java (`MainOffenseCombatValue.java:142-145`):
  ```java
  int strength = ua.getAttack(unit.getOwner());
  ```
  `getAttack(player)` adds tech bonus +
  clamps to `min(diceSides, max(0, attack + bonus))`.
- Odin:
  ```odin
  strength: i32 = unit_attachment_get_attack_no_player(ua)
  ```
  `_no_player` returns the raw `self.attack` — no tech bonus,
  no dice-sides clamp.
- **Impact on snap 0024:** WW2v5 has no Russian attack tech
  bonuses and all Russian attack values ≤ 6 (dice sides), so this
  divergence is mathematically inert for snap 0024. But the bug is
  real and may affect other snaps (e.g. heavy-bomber tech games or
  unit types with attack > diceSides).
- **Fix:** call `unit_attachment_get_attack(ua, unit_get_owner(unit))`
  instead. Mirror the existing defense-side which is correct.

#### 2. `Available_Supports.get_next_available_supporter` iterates pointer-hash order
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin:78-95`
- Java (`AvailableSupports.java:168-179`):
  ```java
  final Unit u = CollectionUtils.getAny(intMap.keySet());
  ```
  `IntegerMap.keySet()` returns a `LinkedHashSet` (iter-21 fix
  established Java's IntegerMap is LinkedHashMap-backed);
  `CollectionUtils.getAny` returns `iterator().next()` — the
  **first-inserted** key.
- Odin:
  ```odin
  int_map := &details.support_units   // type: ^Integer_Map_Unit
  for k, _ in int_map.entries { u = k; break }
  ```
  `Integer_Map_Unit.entries` is bare `map[^Unit]i32` — pointer-hash
  iteration. `Integer_Map_Unit` does **not** have a `keys_order`
  field; iter-21 only added it to `Integer_Map`.
- **Impact:** when there are ≥ 2 candidate supporters of the same
  rule (e.g. 2 Russian artillery for 3 infantry), Java
  deterministically picks the first-inserted; Odin picks whichever
  pointer hashes lowest, which varies across runs because
  `^Unit` addresses are heap-allocation-order dependent.
- **Fix:** add `keys_order: [dynamic]^Unit` to `Integer_Map_Unit`;
  maintain at insertion in `available_supports_support_details_new`,
  `_new_copy`, and any other writers; walk `keys_order[0]` in
  `get_next_available_supporter`.

#### 3. `Available_Supports.units_giving_support` outer map is bare
File: `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin:10` (struct field)
- Java's equivalent is `Map<Unit, IntegerMap<Unit>>` populated via
  `computeIfAbsent` in `giveSupportToUnit`. The Java map is a
  `LinkedHashMap` (per the bootstrap rewrite comment at end of
  `CasualtyUtil.java`, "global LHM rewrite"); insertion order is
  the order supporters first contributed support.
- Odin: bare `map[^Unit]^Integer_Map`, pointer-hash iteration.
- **Impact:** downstream consumers (`SupportCalculator.getCombinedSupportGiven`,
  `PowerStrengthAndRolls.addUnits`) iterate this map and append into
  `unit_support_power_map`. Different outer iteration order →
  different append order in `Power_Strength_And_Rolls.unit_support_power_map`
  → different tie-break order in `CasualtyOrderOfLosses` worst-unit
  selection → different casualty pick → cascading outcome divergence.
- **Fix:** add parallel `[dynamic]^Unit` insertion-order list to
  `Available_Supports`; walk it instead of bare-map iteration in
  `support_calculator_get_combined_support_given` and in the
  `giveSupportToUnit` body.

### L9 classifications for snap 0024 (iter 24)
Per orchestrator rules, drilled the L9 yellow children of
`casualty_selector_select_casualties` in descending `method_layer`:

| L9 child | snap-0024 classification | rationale |
|----------|--------------------------|-----------|
| `Player#selectCasualties` → `DummyPlayer.selectCasualties` | **green** | Verified Java: `keepAtLeastOneLand` and `orderOfLosses` both default false/empty. Java AI never calls `setKeepOneAttackingLandUnit` (only UI calls it, see `BattleCalculatorPanel.java:589`). With both flags false/empty, Java returns `defaultCasualties` unchanged — exact match for Odin's `Dummy_Player` nil-vtable fallback to `player_select_casualties` (identity). |
| `CasualtyUtil#getDependents` | **green** | Snap 0024 UkrSSR battle has no transports → `transport_tracker_transporting_and_unloaded` returns empty for every unit → dependents map values all empty. Map iteration order can't affect outcome of empty maps. Also confirmed downstream consumer `unit_separator_categorize_with_options` only uses `separator_categories.dependents[current]` as a per-key lookup (not iteration). |
| `CombatValue` concrete impl | **yellow (still)** | Two new Java-fidelity bugs found (see "NEW Java-fidelity bugs"). #1 (`MainOffenseStrength` uses `_no_player`) is inert for snap 0024. #2 and #3 (`Available_Supports` pointer-hash iteration) likely cause snap 0032 intermittency and *may* cause snap 0024 divergence cascade. |

### Build status
No Odin source files modified in iter 24. Build is unchanged from
iter 23 (`/tmp/snaprun` from 17:38).

### Pre-iter-24 history (preserved)

2026-05-23 (iter 23) — **Applied the pointer-refactor planned in
iter 22.** Changed `Power_Strength_And_Rolls.unit_support_power_map`
and `…_rolls_map` from `map[^Unit]Integer_Map` (value-stored) to
`map[^Unit]^Integer_Map` (pointer-stored). Lambdas
`_add_units_0` / `_2` now call `integer_map_new()` to heap-allocate.
Getter return types updated to `map[^Unit]^Integer_Map`.

In `casualty_order_of_losses.odin`, dropped all `&` operators on
`support_power_for_unit` / `support_rolls_for_unit` since they are
now `^Integer_Map` (passed directly to
`integer_map_key_set`/`integer_map_get_int`).

### Build & individual snap results
- Build: clean. `/tmp/snaprun` rebuilt at 17:38.
- Snap 0001: PASS, 67 ms (was 85 ms iter 21 — within noise).
- Snap 0017: PASS, 73 ms (was 50 ms iter 21 — within noise).
- Snap 0032: PASS, **1m 6s** (was iter-21 PASS — much slower now).
- Snap 0073: PASS, **3m 40s** (was iter-21 PASS — vastly slower).
- Snap 0024: TIMEOUT at 600s (was iter-21 FAIL with unit-tally
  divergence in 37s). The refactor correctly enables Java-faithful
  support propagation, which dramatically increases the AI's
  evaluation workload. Whether snap 0024 will eventually PASS or
  still diverge cannot be determined inside 600s.

### What this proves
- The iter-22 root-cause classification was correct: Integer_Map
  stored by value lost mutations through `m[k]`. The refactor is
  semantically equivalent to Java's `Map<Unit, IntegerMap<Unit>>`
  reference storage.
- Iter-21 was silently underperforming Java fidelity in
  PowerStrengthAndRolls.addUnits — support contributions to the
  worst-unit calculation in CasualtyOrderOfLosses were truncated
  to the first append (because each subsequent
  `existing := m[k]; integer_map_add_map(&existing, …)` discarded
  the keys_order updates done by the previous iteration).
- The slowdown is intrinsic, not a regression bug: the AI was
  previously skipping work that should have been done. Snap 0001
  (no battles) shows zero slowdown, confirming the cost is only in
  the casualty/combat path.

### 104-snap regression sweep (iter 23)
Running with 420-second per-snap cap (vs iter-21's 120 s) and
parallel `-P 8`. Started at 17:43; results in
`/tmp/snap_results_iter23/`. **Sweep was at 68/104 at session
end (55 PASS, 5 FAIL, rest in flight):**
```
FAILS (partial, at 68/104): 0024, 0025, 0031, 0032, 0038
```
- Snap 0032 PASSED individually (1m 6s, see above) but FAILED in
  the parallel sweep — likely `-P 8` starvation pushing it past
  the 420s cap. Re-verify individually.
- Snaps 0024, 0025, 0031, 0038 were all FAIL in iter 21; their
  iter-23 status will be known when the sweep completes.

To analyze when complete:
```sh
ls /tmp/snap_results_iter23/ | wc -l  # should be 104
grep -h "^EXIT=" /tmp/snap_results_iter23/*.txt | \
  awk -F: '{print $2}' | sort | uniq -c
for f in /tmp/snap_results_iter23/*.txt; do
  l=$(tail -1 "$f"); case "$l" in *:0) ;; *) echo "$l" ;; esac
done | sort
```
(See "Next action" for iter-24's verification + remaining drill.)

### Files changed (iter 23)
- `odin_flat/games__strategy__triplea__delegate__power__calculator__power_strength_and_rolls.odin`
  - Struct: `unit_support_power_map` / `unit_support_rolls_map`
    fields → `map[^Unit]^Integer_Map`.
  - Getters: return type `map[^Unit]^Integer_Map`.
  - `lambda_add_units_0` / `_2`: return `^Integer_Map` via
    `integer_map_new()`.
  - `lambda_add_units_1` / `_3`: drop `existing := …` round-trip;
    pass `self.unit_support_power_map[supporter]` directly.
  - `power_strength_and_rolls_new`: `make(map[^Unit]^Integer_Map)`.
- `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_order_of_losses.odin`
  - Drop `&` on all `support_power_for_unit` /
    `support_rolls_for_unit` arguments to `integer_map_key_set`
    and `integer_map_get_int`.

### Pre-iter-23 history (preserved)

2026-05-23 (iter 22) — **Discovered the iter 21 IntegerMap fix is
INCOMPLETE in a critical site: `map[^Unit]Integer_Map` stores
Integer_Map BY VALUE, but `Integer_Map.keys_order` is `[dynamic]rawptr`
whose descriptor (data ptr / len / cap) is copied on map read. Any
mutation via `existing := m[k]; integer_map_add_map(&existing, …)`
without write-back loses the keys_order updates — only
`map_values` (a Odin map descriptor with shared backing storage)
survives. Identified the smoking-gun sites in
`power_strength_and_rolls_lambda_add_units_1` and `_3` (lines 86
and 109 of `power_strength_and_rolls.odin`).**

### Java source confirms intent
`PowerStrengthAndRolls.addUnits` (lines 130-133):
```
strengthCalculator.getSupportGiven().forEach((supporter, supportedUnits) ->
    unitSupportPowerMap.computeIfAbsent(supporter, (newSupport) -> new IntegerMap<>())
        .add(supportedUnits));
```
The IntegerMap RETURNED by `computeIfAbsent` is the actual stored
instance — `.add(supportedUnits)` mutates the *stored* IntegerMap,
not a copy. In Java this works because Map<K,V> stores references,
not value copies.

### Attempted fix (reverted — caused timeout)
Added write-back after `integer_map_add_map`:
```odin
self.unit_support_power_map[supporter] = existing
self.unit_support_rolls_map[supporter] = existing
```
Build clean. Snap 0001 still passed in 85ms. **Snap 0024 timed out
at 300s** (vs iter 21's 37s) — the fix correctly enables support
propagation, which Java-faithfully changes Russian artillery + air
combat support → AI's NCM ProBattleUtils calculator likely
re-evaluates far more candidate moves. Reverted to keep the build
green; tracked as iter-23 work.

### Root-cause classification
This is the same family of bug as iter 21 but at a *different
storage tier*: iter 21 fixed iteration order *within* Integer_Map.
Iter 22 finding is that Integer_Map cannot safely live as a value
inside `map[K]Integer_Map` because Odin `[dynamic]` descriptors
copy by value, losing keys_order updates whenever the underlying
buffer reallocates *or* the len/cap fields advance.

### Next-iter (23) plan
Two options:
  1. **Pointer the inner maps**: change
     `unit_support_power_map: map[^Unit]Integer_Map` →
     `map[^Unit]^Integer_Map`. Allocate `Integer_Map` on the heap
     in `lambda_add_units_0` / `_2`. Mutations now go through a
     pointer; no write-back needed. RIPPLES into every reader site
     (about 10 in casualty_order_of_losses + 4 in
     power_strength_and_rolls itself + getters). Surface this
     refactor as a discrete commit.
  2. **Add write-back** as the iter-22 patch did, then
     PROFILE/CAP the snap 0024 simulator workload. Either:
       (a) increase the per-snap timeout, or
       (b) verify Java's snap 0024 also takes this long (it
           probably doesn't — JVM JIT vs Odin debug, plus possible
           AI memoization differences).
The pointer-refactor (option 1) is the correct fix because it
eliminates the value-copy hazard structurally. It also benefits
the AaPowerStrengthAndRolls site that has the same pattern.

### Pre-iter-22 history (preserved)

2026-05-23 (iter 21) — **Fixed the L8 yellow node:
`Integer_Map` LinkedHashMap insertion-order divergence.**
Per java-fidelity-rule, read
`triplea/lib/java-extras/src/main/java/org/triplea/java/collections/IntegerMap.java`:
Java's `IntegerMap` is backed by `LinkedHashMap` (insertion-order
iteration). Odin's `Integer_Map` used a bare `map[rawptr]i32`
which iterates in pointer-hash order. The casualty drill from
iter 20 (`CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`)
uses `integer_map_key_set` to walk the supporter→supported maps and
moves each supported unit to position 0 of `sortedUnitsList` via
`inject_at`. Different iteration order → different worst-unit
picks → different battle outcome.

### Fix
`odin_flat/org__triplea__java__collections__integer_map.odin`:
added `keys_order: [dynamic]rawptr` to `Integer_Map`; added
file-private `_iorder_put_` / `_iorder_remove_` helpers; rewrote
`integer_map_put`, `_add`, `_remove_key`, `_clear`,
`_multiply_all_values_by`, `_key_set`, `_all_values_equal`,
`_total_values`, `_is_positive`, `_entry_set`, `_to_string`,
`_new_copy`, `_unmodifiable_view_of`, `_add_map`, `_subtract`,
`_greater_than_or_equal_to`, `_add_multiple`, and the
`_new_from_map` constructor to maintain and walk `keys_order`.
Updated three external `Integer_Map{map_values = make(...)}`
literals (production_rule, repair_rule, power_strength_and_rolls
lambdas, strategic_bombing_raid_battle init) to also init
`keys_order = make([dynamic]rawptr)`.

### 104-snap regression result
Iter 20 baseline: 85 PASS / 17 FAIL / 2 HANG.
Iter 21 result:  84 PASS / 16 FAIL / 2 TIMEOUT (+ 2 starvation
"NO_EXIT" in the -P 8 parallel sweep that pass individually).

Net: snap **0032 newly passes** (was FAIL). Snap **0092 went
HANG → FAIL** (deterministic now, easier to drill). Snap 0024
(iter 20 drill target) unit tally is unchanged — IntegerMap order
fix is necessary but not the *full* fix for 0024.

Individual reruns confirm snaps 0001, 0017, 0073 still PASS. The
"4 NO_EXIT" in the parallel sweep is xargs -P 8 contention
hitting the 120s per-snap cap, not regression.

### Why this matters even though 0024 still fails
Java's IntegerMap is used pervasively (TUV cost maps, support
power/rolls maps, unitProduction maps). Pointer-hash iteration was
silently corrupting Java fidelity in every code path that walks
these maps. The L8 casualty-selection drill was the wedge that
exposed it; the fix is structural and benefits the entire battle
calculator, AI move ordering, and any future divergence rooted in
the same pattern.

### Remaining suspect for snap 0024
After this fix, the casualty selection in the deterministic battle
must STILL diverge — meaning either:
(a) one of `casualty_selector_select_casualties`'s OTHER deps
    (CasualtyUtil#getDependents, AaCasualtySelector, CombatValue
    impls) still has a HashMap-order bug, or
(b) `must_fight_battle_fight`'s step ordering itself uses an
    unordered collection.

Continue the L8 drill in iter 22 — re-classify
`casualty_selector_select_casualties` as YELLOW (not red), then
descend into its remaining yellow deps sorted by
descending method_layer.

### Iter 20 prior history (preserved)

**Cleared 3 of 4 simulator-internals
suspects in one iteration. (1) Ran `scripts/mt_self_test` against
Java-captured `mt_reference_vector.txt`: 1024 raw32 + 1024 each
nextInt(6/12/8) values match Java's `MersenneTwister(42L)`
byte-for-byte. MT bit-fidelity GREEN. (2) Added `rbd_in`/`rbd_unit`
/`rbd_out`/`rbd_die` probe in `roll_dice_factory_roll_battle_dice`
gated on `"Ukraine S.S.R."` in annotation. Verified Russians' first
round dice = [0,1,1,3,3,0,0,2,0,3] which matches positions 0–9 of
the Java reference vector for `nextInt(6)`. Dice consumption
order GREEN. (3) Per-unit strength computation correct: Russian
artillery support gives 2 of 3 infantry attack=2 (1 inf stays
attack=1); fighter/armour/inf strength values all match WW2v5
XML. Active_units post-sort order matches expected
strength-descending bucket order (armour, fighter, art, inf).
Artillery support pairing GREEN. **Remaining suspect: casualty
selection order.** With the bomber present (n_def=11), defenders
win; without bomber (n_def=10), defenders are wiped — same MT(42),
same dice stream, only difference is 1 extra unit's 1 extra die.
This can only flip a deterministic battle via cascading casualty
selection: who dies first determines who keeps rolling in later
rounds, which can radically change the total hit accounting.**

### Iter 20 evidence

MT self-test:
```
raw32: 1024 values, cumulative fails: 0
nextInt6: 1024 values, cumulative fails: 0
nextInt12: 1024 values, cumulative fails: 0
nextInt8: 1024 values, cumulative fails: 0
PASS: MersenneTwister Odin port matches Java reference
```

Dice consumption (n_def=4 case, first calc-call for UkrSSR):
```
rbd_in player=Russians ann="... round 2" n_units=10 total_rolls=10 total_power=24 sides=6
rbd_unit i=0 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=1 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=2 owner=Russians type=armour    str=3 rolls=1 sides=6 cbr=true
rbd_unit i=3 owner=Russians type=fighter   str=3 rolls=1 sides=6 cbr=true
rbd_unit i=4 owner=Russians type=fighter   str=3 rolls=1 sides=6 cbr=true
rbd_unit i=5 owner=Russians type=artillery str=2 rolls=1 sides=6 cbr=true
rbd_unit i=6 owner=Russians type=artillery str=2 rolls=1 sides=6 cbr=true
rbd_unit i=7 owner=Russians type=infantry  str=2 rolls=1 sides=6 cbr=true
rbd_unit i=8 owner=Russians type=infantry  str=2 rolls=1 sides=6 cbr=true
rbd_unit i=9 owner=Russians type=infantry  str=1 rolls=1 sides=6 cbr=true  ← unsupported by artillery (correct)
rbd_die i=0..9 = [0,1,1,3,3,0,0,2,0,3] = MT.nextInt(6)[0..9] EXACT MATCH
```

Matches Java reference vector positions 0–9 exactly.
Annotation says "round 2" but this is the first fight round—
MustFightBattle increments round BEFORE the first fight step
in both Java and Odin (verified in `must_fight_battle__29.odin`).
This is a labeling convention, not a divergence.

### Iter 19 prior finding (preserved)

[iter 19 cleared max_enemy_units (artillery mov=1 in WW2v5; theo
max = 10 Russian attackers, matches Odin). Widened bc_run probe
revealed bomber's 1-die difference flips outcome from DEFENDER-win
to ATTACKER-wipe.]

### Iter 18 prior finding (preserved)

[iter 18 added `bc_run` probe; simulator internally consistent
and deterministic across 90 runs. Hand-count theory ruled out
in iter 19 once artillery mov=1 was discovered.]

### What the iter 19 widened bc_run probe revealed

```
bc_run i=0..2 t=Ukraine S.S.R. nDef=11 who=DEFENDER rounds=3 remA_n=0 remA=[]            remD_n=2 remD=[fighter=2]
bc_run i=0..2 t=Ukraine S.S.R. nDef=10 who=ATTACKER rounds=3 remA_n=2 remA=[fighter=2]    remD_n=0 remD=[]
```

With bomber: defender wins, atk wiped, 2 def fighters survive.
Without bomber: ATTACKER wins, def wiped, 2 atk fighters survive.

Same MT(42) seed in both. Removing 1 bomber (def=1) shifts the
dice stream by ~1 roll/round and dramatically flips the outcome.
Java + Odin should produce the SAME outcome given identical MT
outputs. Since Java's `after.json` shows the bomber moved to
Finland (which requires `worth_def` at ntd=3 to evaluate
`areSuccess=true` for the bomber-removed UkrSSR), Java's calc
must be returning a DIFFERENT result for the n_def=10 case
(probably `defender holds`).

### cbc_atk source-territory probe (iter 19)

```
cbc_atk i=0 owner=Russians type=infantry  src=Caucasus       movLeft=1
cbc_atk i=1 owner=Russians type=artillery src=Caucasus       movLeft=1
cbc_atk i=2 owner=Russians type=infantry  src=Caucasus       movLeft=1
cbc_atk i=3 owner=Russians type=armour    src=Caucasus       movLeft=2
cbc_atk i=4 owner=Russians type=artillery src=Caucasus       movLeft=1
cbc_atk i=5 owner=Russians type=armour    src=Karelia S.S.R. movLeft=2
cbc_atk i=6 owner=Russians type=fighter   src=Russia         movLeft=4
cbc_atk i=7 owner=Russians type=fighter   src=Caucasus       movLeft=4
cbc_atk i=8 owner=Russians type=armour    src=Russia         movLeft=2
cbc_atk i=9 owner=Russians type=infantry  src=Caucasus       movLeft=1
```

Karelia's armour reaches UkrSSR via Belorussia/West Russia
(both 2 hops, enemy-owned but `isIgnoringRelationships=true`
in `findEnemyAttackOptions`). Russia's armour reaches via
Caucasus (1-hop friendly + 1-hop enemy). Russia's artillery
(mov=1, movLeft=1) cannot reach 2-hops-away UkrSSR (matches
Odin behavior: not in list).

### Confirmation that both languages use same seed

Java harness `Ww2v5JacocoRun.java:58` sets
`SNAPSHOT_SEED = 42L` and applies it via
`PlainRandomSource.fixedSeed = SNAPSHOT_SEED` at line 82.
Odin harness `test_server_game.odin:166-170` does the same:
```
if plain_random_source_fixed_seed == nil {
    seed := new(i64)
    seed^ = 42
    plain_random_source_fixed_seed = seed
}
```
Both languages: every new `PlainRandomSource` = new
`MersenneTwister(42)`. **Same seeds across both languages.**

### Iter 19 CORRECTED hand-count (snap 0024 before.json)

MOVEMENT BUDGETS PER WW2v5_1942_2nd.xml:
- infantry=1, artillery=1 (NOT 2!), armour=2, fighter=4, bomber=6.

MAP ADJACENCIES (verified from XML connection list):
- UkrSSR neighbors: Belorussia, West Russia, Bulgaria Romania,
  Caucasus, 16 Sea Zone.
- Russia neighbors: Archangel, Caucasus, Kazakh, Novosibirsk,
  Vologda, West Russia. (NOT adjacent to UkrSSR.)
- Karelia S.S.R. neighbors: Archangel, Baltic States, Belorussia,
  Finland, West Russia, 4 SZ, 5 SZ. (NOT adjacent to Russia
  or UkrSSR.)

Routes from each Russian territory to UkrSSR:
- Caucasus → UkrSSR: 1 hop. Any unit with mov≥1 reaches.
- Russia → Caucasus → UkrSSR: 2 hops (friendly). Any unit
  with mov≥2 reaches. (armour, fighter — NOT art, NOT inf.)
- Karelia → Belorussia/West Russia → UkrSSR: 2 hops (enemy in
  middle, allowed via `isIgnoringRelationships=true`). armour
  with mov≥2 reaches.
- Archangel: 3+ hops to UkrSSR. INVALID for all land units.

Corrected theoretical max:
- inf: 3 Caucasus = 3
- art: 2 Caucasus = 2 (Russia art mov=1, can't reach)
- armour: 1 Caucasus + 1 Russia + 1 Karelia = 3
- fighter: 1 Caucasus + 1 Russia = 2

**Theoretical max: 3 + 2 + 3 + 2 = 10 attackers.**
Odin's `cbc_atk` reports 10. **EXACT MATCH — NOT A BUG.**

### Iter 17 prior history (preserved)

[iter 17 cbc_in/cbc_def/cbc_atk probe ruled out unit-attrib
lookup as bug; RNG arch verified deterministic in both languages]

### Probe data (n_def=11 case for UkrSSR)

```
cbc_in t=Ukraine S.S.R. n_atk=10 n_def=11 run_count=90 retr_air=false
cbc_def i=0 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=1 owner=Germans type=bomber   atk=4 def=1 isAir=true  isSea=false  ← correct
cbc_def i=2 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=3 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=4 owner=Germans type=fighter  atk=3 def=4 isAir=true  isSea=false
cbc_def i=5 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=6 owner=Germans type=fighter  atk=3 def=4 isAir=true  isSea=false
cbc_def i=7 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=8 owner=Germans type=armour   atk=3 def=3 isAir=false isSea=false
cbc_def i=9 owner=Germans type=infantry atk=1 def=2 isAir=false isSea=false
cbc_def i=10 owner=Germans type=armour  atk=3 def=3 isAir=false isSea=false
cbc_atk i=0 owner=Russians type=armour    atk=3 def=3
cbc_atk i=1 owner=Russians type=artillery atk=2 def=2
cbc_atk i=2 owner=Russians type=artillery atk=2 def=2
cbc_atk i=3 owner=Russians type=fighter   atk=3 def=4
cbc_atk i=4 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=5 owner=Russians type=armour    atk=3 def=3
cbc_atk i=6 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=7 owner=Russians type=infantry  atk=1 def=2
cbc_atk i=8 owner=Russians type=armour    atk=3 def=3
cbc_atk i=9 owner=Russians type=fighter   atk=3 def=4
```

All attribs match WW2v5_1942_2nd.xml. **No unit-attribute lookup bug.**

### RNG determinism architecture (verified Java + Odin)

- `PlainRandomSource` (both languages) is constructed fresh in
  every `DummyDelegateBridge` constructor.
- When `fixedSeed=42` (snapshot mode), every new
  `PlainRandomSource` seeds a new MersenneTwister with 42 →
  every battle run gets identical dice.
- `battle_calculator_calculate`'s loop creates one new bridge per
  `run_count` iteration → all 90 simulation runs produce
  identical outcomes.
- Therefore `winPct` is binary (0% or 100%) by design. The 28-TUV
  swing from removing one bomber is a real divergence in the
  simulator's deterministic output.

### What's left

The simulator uses these per-defender attributes (bomber
correctly tagged def=1 isAir=true) plus dice rolls to compute
casualties. Either:
- Dice consumption order / count differs between Odin and Java
  (e.g., Odin requests more/fewer dice per defender), OR
- Casualty selection picks different casualties given the same
  dice (e.g., bomber is wrongly chosen LAST as casualty), OR
- Battle rounds count differs (e.g., bomber prevents retreat).

All three are inside `must_fight_battle_fight` or its callees.

### Iter 16 prior history (preserved)

[iter 16 bres probe revealed the smoking gun: removing one
bomber flips winPct from 0% to 100% and tuvSwing from -4 to +24]

### Iter 15 prior history (preserved)

[iter 15 TVAL probe + cap_local probe disproved
territory_value_map and capital-local-superiority hypotheses]**

### What the bres probe revealed (full sequence)

```
ntd=1 t=Ukraine S.S.R. defN=11 def=[5 armour, 3 inf, 2 fighter, 1 bomber]
  atkN=10 atk=[3 inf, 2 art, 3 armour, 2 fighter] tuvSwing=-4 winPct=0 rounds=3
  avgAtkRemN=0 avgDefRemN=2 → worth1=false worth2=false areSuccess=true

ntd=2 t=Ukraine S.S.R. defN=11 (same with bomber) tuvSwing=-4 winPct=0
  → areSuccess=true
ntd=2 t=Baltic States defN=? tuvSwing=-21 winPct=? → areSuccess=true

ntd=3 t=Ukraine S.S.R. defN=10 def=[5 armour, 3 inf, 2 fighter] (bomber moved to Finland by pass3)
  tuvSwing=+24 winPct=100 → worth1=true areSuccess=false
ntd=3 t=Finland defN=? temp_n=2 extraUV=28 → (bomber+fighters at Finland)
  → outer loop removes Finland

ntd=3 t=Ukraine S.S.R. defN=9 def=[5 armour, 3 inf, 1 fighter] (1 fighter also moved out)
  tuvSwing=+14 winPct=100 → worth1=true areSuccess=false
  → outer loop removes Libya, ntd-- to 2

ntd=2 t=Ukraine S.S.R. defN=11 (bomber back since Finland not in prio)
  tuvSwing=-4 winPct=0 → areSuccess=true → LOOP TERMINATES
```

Final Odin plan: UkrSSR has 4 temp armour + bomber + 2 fighter +
original 1 armour + 3 inf. Bomber STAYS at UkrSSR because Finland
was removed.

### Java's expected behavior (from after.json)

- UkrSSR: 1 armour + 3 inf (kept just the cantMoveUnits; 4 temp armour released)
- Belorussia: 5 armour (+4)
- Baltic States: aaGun 1 + inf 3 + armour 4 (+4 armour)
- Finland: inf 3 + bomber 1 + fighter 2 (+air units)
- Germany/Poland/West Russia/France/Italy/NWE: all armour gone

For Java to produce this, the bomber MUST be moved to Finland in
pass 3 — which means at ntd=3, Finland must NOT be removed by the
outer loop — which means UkrSSR's `worth_def` at ntd=3 (defenders
WITHOUT bomber: 10 def or 9 def) must give `areSuccess=true`.

This requires Java's `calc.calculateBattleResults` on {5 armour,
3 inf, 2 fighter} defenders vs {3 inf, 2 art, 3 armour, 2 fighter}
attackers to return `tuvSwing ≤ 11.5` (so worth1 = (tuvSwing - 5.5)
> max(0, 6) is false). Hand-calc: defender strength=29, attacker
strength=24 — attacker actually loses slightly. tuvSwing should
be roughly 0 or negative in Java.

### Hand-verification of bomber's defensive contribution

WW2v5_1942_2nd.xml: bomber has `attack=4 defense=1 movement=6 cost=12`.

With bomber (11 def): defender strength = 5×3 + 3×2 + 2×4 + 1×1 = 30 → 5.0 hits/round
Without bomber (10 def): defender strength = 5×3 + 3×2 + 2×4 = 29 → 4.83 hits/round
Attacker strength (with art boost): 2×2 + 1×1 + 2×2 + 3×3 + 2×3 = 24 → 4.0 hits/round

Bomber adds 0.17 hits/round to defender. Should NOT flip the
battle from "attacker never wins" to "attacker always wins".
Odin's calc is computing bomber's defensive contribution
incorrectly (almost certainly).

### Iter 15 prior history (preserved)

[iter 15 TVAL probe + cap_local probe disproved
territory_value_map and capital-local-superiority hypotheses]

### What the probes proved

Added two new ARMOUR_TRACE probes (gated by ARMOUR_TRACE
config, default off):
1. `p1_ukrSSR` inside pass 1 of `move_units_to_defend_territories`:
   for each Germans armour eval at Ukraine S.S.R., dump
   `max_enemy_units` tally, `eligible_defenders` tally,
   `atkStr`, `defStr`, `est`.
2. `worth_def` inside the "Check if its worth defending" loop:
   for each {Ukraine S.S.R., Belorussia, Baltic States, Finland,
   Libya} dump `tval`, `temp_n`, `temp_avg`,
   `hasHigherStrategicValue`, `resultSwing`, `minSwing`,
   `holdValue`, `extraUV`, `worth1`, `worth2`, `areSuccessful`.

Widened the iter 13 `prio_filter` probe to also dump for
Ukraine S.S.R., Baltic States, Norway, Finland, Libya, Algeria
(not just Belorussia).

### Probe output — `prio_filter` (full table)

| t              | value | tuvSwing | hasLandRem | notFacShouldHold | removed |
|----------------|------:|---------:|:----------:|:----------------:|:-------:|
| Ukraine S.S.R. | 13.90 | 6.00     | true       | false            | **false** |
| Belorussia     | 11.40 | 0.00     | true       | true             | true    |
| Baltic States  | 2.85  | 0.10     | true       | false            | false   |
| Norway         | 2.03  | 0.10     | true       | false (notFacNoEnemyN=true) | true |
| Finland        | 1.55  | 0.10     | true       | false            | false   |
| Libya          | 1.53  | 0.10     | true       | false            | false   |
| Algeria        | 1.05  | -1.00    | false      | true             | true    |

Ukraine S.S.R. survives the prio_filter because Russians PROFIT
from attacking (tuvSwing=6 means attacker gains 6 TUV net). Java
applies the same filter and would also keep UkrSSR.

### Probe output — `p1_ukrSSR` (first iteration)

```
ARMOUR_TRACE p1_ukrSSR ntd=1 unit=... enemy_n=10 enemy=[inf=3, art=2, armour=3, fighter=2]
   elig_n=4 elig=[Germans/inf=3, Germans/armour=1] atkStr=44.000 defStr=17.000 est=171.465
```

The 10 Russian attackers (44 strength) vs 4 Germans defenders
(17 strength) gives est=171 → > 60 → pass 1 adds the armour.
This matches the snap's BEFORE state at UkrSSR exactly
(Germans had 2 fighters + 1 armour + 3 infantry; fighters have
4 movement so they're not in cantMoveUnits/eligibleDefenders
initially). Computation is correct.

### Probe output — `worth_def` (FINAL ntd=2)

```
ARMOUR_TRACE worth_def ntd=2 t=Ukraine S.S.R. tval=53.609 temp_n=4 temp_avg=14.957
   hasHigherStrat=true resultSwing=-4.000 minSwing=6.000 holdVal=7.000 extraUV=56.000
   worth1=false worth2=false areSuccess=true
```

Decoding the two worth-defending clauses (Java 1140-1148):
- `worth1 = (result_swing - hold_value) > max(0, min_swing) = (-4 - 7) > max(0, 6) = -11 > 6 = false`
- `worth2 = (!has_higher_strategic_value && (result_swing + extra_unit_value/2) >= min_swing)`
  - `has_higher_strategic_value = (territoryValueMap[t] >= average of source-territory values)`
  - `= (53.609 >= 14.957) = true` → `!true = false` → worth2 = false (short-circuit)
- both false → `areSuccessful` stays true → UkrSSR keeps the 4 armour.

### What Java must compute differently

For Java to release the 4 armour from UkrSSR, `hasHigherStrategicValue`
must be **false**, which requires `territoryValueMap[UkrSSR] <
averageValue_of_sources(Germany, Germany, Poland, West Russia)`.

So Java's `ProTerritoryValueUtils.findTerritoryValues` for UkrSSR
must return a value LOWER than Germany/Poland/West Russia. Odin's
returns 53.609 — much higher than sources (avg 14.957). **Odin's
`pro_territory_value_utils_find_territory_values` is the divergent
proc.**

With `hasHigherStrategicValue=false`:
- `worth2 = (-4 + 56/2) >= 6 = 24 >= 6 = true` → `areSuccessful=false`
- → UkrSSR removed via `prioritizedTerritories.remove(ntd-1); setCanHold(false)`
- → On next loop iter, tempUnits reset and the 4 armour re-enter unitMoveMap
- → Eventually `moveUnitsToBestTerritories` picks Belorussia for them (value-best
   canHold reachable territory).

### Iter 13 prior history (preserved)

Filter probe in `prioritize_defend_options` proves the filter that
removes Belorussia is Java-faithful (identical predicate). Bug is
NOT in the filter — moved to `move_units_to_defend_territories`
"Check if its worth defending" loop.

### Iter 13 prior probe (preserved)

Added 2 probes in `pro_non_combat_move_ai_prioritize_defend_options`
(Odin 3370 + 3430):
- `ARMOUR_TRACE prio_input`
- `ARMOUR_TRACE prio_pre_filter`
- `ARMOUR_TRACE prio_filter` (widened iter 14 to cover all 7
  affected territories, not just Belorussia)

Filter is Java-faithful: `isNotFactoryAndShouldHold = !hasFac &&
(tuvSwing≤0 || !hasLandRem)` — matches Java line 631-642
byte-for-byte. Belorussia correctly dropped (`tuvSwing=0`).
Ukraine S.S.R. correctly kept (`tuvSwing=6 > 0`).

### Iter 13 prior history (note: hypothesis was wrong)

Iter 13's hypothesis was "pass 1 commits the 4 armour to UkrSSR
because est > 60". Iter 14 confirmed pass 1 does this — but
proved that's NOT the bug. Java would also commit them in pass
1, but then the LATER "Check if its worth defending" loop
RELEASES them because UkrSSR's territory_value is less than its
sources. Odin's territory_value computation has the same
defenders enter pass 1 but FAILS the release check.

### Iter 11/12 prior history (preserved)

Per-phase ARMOUR_TRACE (`after_defend`, `after_best`,
`pre_do_move`) localized the Belorussia↔Ukraine S.S.R. armour
5/1 swap to `move_units_to_defend_territories`. Iter 12
per-armour probes proved the assignment loops work correctly
given their inputs; Belorussia was missing from
`prioritized_territories`. Iter 13 has now proved this is BY
DESIGN (Java-faithful filter).

### Iter 12 prior history (preserved)

Added fine probes inside `pro_non_combat_move_ai_move_units_to_defend_territories`
(Odin 3539+):
- `ARMOUR_TRACE iter_start num_to_defend=N prioritized=[...]`
  at top of the outer `for { ... num_to_defend += 1 }` loop.
- `ARMOUR_TRACE p1_armour_eval` / `p1_armour_pick` inside the
  "Set enough units to have chance of winning" pass for armour
  units (Germans).
- `ARMOUR_TRACE p2_armour_eval` / `p2_armour_pick` inside the
  "Set non-air units" pass for armour units (Germans).

Built `server_game_test_iter12` with `-define:ARMOUR_TRACE=true`
and ran `FILTER_SNAP=0024`. Output:

```
ARMOUR_TRACE iter_start num_to_defend=1 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=2 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=3 prioritized=["Ukraine S.S.R.", "Baltic States", "Finland", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=3 prioritized=["Ukraine S.S.R.", "Baltic States", "Libya"]
ARMOUR_TRACE iter_start num_to_defend=2 prioritized=["Ukraine S.S.R.", "Baltic States"]
```

**Belorussia never appears in `prioritized_territories`.** The
4 German armour go to Ukraine S.S.R. because that's the highest
`estimate` (171.46/129.49/101.61/81.53) in their candidate sets,
and Belorussia isn't a candidate at all. Libya armour picks
Libya (152.83). France/Italy/NW Europe armour have only Baltic
States in their reach but est=55.31 ≤ 60 → not added.

This rules out:
- Iteration ordering bugs in passes 1, 2, 3 (the assignment
  loops are working correctly given their inputs).
- `sort_unit_move_options` / `sorted_territory_keys_by_priority`
  helpers (they iterate the territories that DO exist correctly).
- `pro_sort_move_options_utils` more generally.

The bug is in:
- **`pro_non_combat_move_ai_prioritize_defend_options`** (Java
  557, Odin equivalent) — the filter loop that removes
  territories based on `canHold`, `value ≤ 0`,
  `isLandAndCanOnlyBeAttackedByAir`, `isNotFactoryAndShouldHold`,
  `canAlreadyBeHeld`, `isNotFactoryAndHasNoEnemyNeighbors`,
  `isNotFactoryAndOnlyAmphib`. One of these criteria
  incorrectly drops Belorussia.
- OR upstream: `defend_options.territory_map` doesn't even
  contain Belorussia (i.e. `populate_enemy_attack_options` or
  whoever feeds it misses Belorussia as defendable).

Java MUST include Belorussia (because Java places 5 armour
there in the snap's `after.json`). So the divergence is in one
of the two layers above.

Full iter 12 notes + iter 13 plan in
`/memories/repo/snap-0024-germanNCM.md`. The fine probes are
kept in place (compiled out by default since
`ARMOUR_TRACE :: #config(ARMOUR_TRACE, false)`).

### Iter 11 prior history (preserved)

Per-phase ARMOUR_TRACE (`after_defend`, `after_best`,
`pre_do_move`) localized the Belorussia↔Ukraine S.S.R. armour
5/1 swap to `move_units_to_defend_territories`. Finland↔Norway
and Libya↔Algeria are split across both phases.

### Iter 10 prior history (preserved)

ARMOUR_TRACE probe at `pre_do_move` proved the AI plan stored
in `move_map[t].units` is already divergent before
`pro_non_combat_move_ai_do_move` runs.

### Iter 9 prior history (preserved)

Drilled `ProNonCombatMoveAi.java:1893` ("Move land units to
territory with highest value and highest transport capacity")
and its Odin port at `pro_non_combat_move_ai.odin:2596`.
Applied the step-24 cruiser fix template: use
`unit_move_map_order` (outer LinkedHashMap order) and
`unit_move_map_inner_order` (inner LinkedHashSet order)
parallel insertion-order slices instead of unordered iteration.

Result: no change in snap 0024 → that pass is NOT the divergent
site. Edit is kept (Java-faithful, harmless). Iter 10 confirmed
the bug is in earlier planning passes.

### Iter 8 prior history (preserved)

Reproduced snap 0024 failure; corrected step-name mislabel
(germanNonCombatMove, not germanCombatMove); identified
root-cause family (Java HashMap iteration order in
`ProNonCombatMoveAi`). Hypothesized the land-move pass at
Java 1893 — iter 9 disproved that hypothesis.

### Iter 7 prior history (preserved)

**Regression sweep confirms iter 6 fix is a
net win: +3 (or more) PASS vs baseline. No real regressions.**

Ran the full 104-snap suite via the `FILTER_SNAP` xargs recipe
with a 60s per-snap timeout (results in `/tmp/snap_results/`).
Exit codes: 80 PASS, 17 FAIL (exit=1), 7 TIMEOUT (exit=124).

Baseline (post-iter6 fix expected): 78 PASS / 26 FAIL.
Delta vs baseline:

| change                | snaps                                                |
|-----------------------|------------------------------------------------------|
| fixed (was failing)   | 0033, 0041, 0049, 0069, 0085, 0093, 0101 (=7)        |
| still failing         | 0024 0025 0031 0038 0040 0048 0065 0074 0075 0076 0077 0081 0084 0090 0092 0097 0100 (=17) |
| previously-PASS now timing out at 60s | 0013 0022 0029 0073 0089 (=5) |
| previously-FAIL now timing out at 60s | 0021 0037 (=2) |

The 5 "regressed" snaps are NOT real regressions — they are slow
snaps brushing up against the 60s per-snap timeout. Verified by
re-running with `timeout 300`:
- 0013 russianPurchase **PASS** in 62.7s
- 0022 germanCombatMove **PASS** in 88.5s
- 0029 britishPurchase **PASS** in 81.0s
- 0073 germanPurchase — not retested (germanPurchase pattern like
  0021 → expected ~3 min, may pass at 300s)
- 0089 — not retested

0021 germanPurchase is the long-known 3m7s purchase compute (not
iter6's fault — see `next-steps.md` odds-calculator perf note).
0037 was a baseline failure that now times out instead of failing
fast — same root cause (`AMPHIB_PROBE` step 37 is the noted Pacific
amphib divergence per `/memories/repo/step38-japaneseBattle-status.md`).

**Conclusion: iter 6 trim is safe to keep. Effective baseline is
83+/104 PASS at 300s timeout, vs 77/104 at iter 5 (net +6 to +8).**

### Iter 6 prior history (preserved)

**FIXED SNAP 0017 russianPlace. Root cause:
harness orphan-backfill over-counted Russian pool 17 vs Java's 6.**

The breakthrough was treating the BEFORE/AFTER snapshot JSON as
ground truth and computing per-territory unit deltas directly:

```
location                 | DELTA (Russian units)
Caucasus                 | {'artillery': +2, 'infantry': +2}  # plan only
Karelia S.S.R.           | {}                                  # 0 placed!
Russia                   | {'armour': +1, 'artillery': +1}    # plan only
NOWHERE (pool)           | {'armour': -1, 'artillery': -3, 'infantry': -2}
```

Java places EXACTLY the 6 plan units (Caucasus 4 + Russia 2),
zero fallback. Then Java's `doAfterEnd` (line 80 of
`AbstractPlaceDelegate.java`) calls
`ChangeFactory.removeUnits(player, units)` which removes the
remaining 11 pool units from `player.unitsHeld` but NOT from
`data.allUnits` — orphan-units linger.

**Then tracing the pool size backwards across snaps 0001–0019**
revealed the smoking gun:

```
snap | step                    | NOWHERE Russian units
0014 | russianCombatMove       | {'infantry':2,'artillery':3,'armour':1}  # 6
0015 | russianBattle           | {'infantry':2,'artillery':3,'armour':1}  # 6
0016 | russianNonCombatMove    | {'infantry':12,'artillery':4,'armour':1} # 17!
0017 | russianPlace            | {'infantry':12,'artillery':4,'armour':1} # 17!
0018 | russianTechActivation   | {'infantry':10,'artillery':1}            # 11
```

The +11 jump from snap 15→16 IS the russianBattle casualties from
West Russia / Ukraine S.S.R. / Belorussia. Java's
`ChangeFactory.removeUnits(territory, units)` removes them from
the territory but keeps them in `data.allUnits` as orphans. They
are NOT in `player.unitsHeld`, so Java's `player.getUnits()` at
snap 17 returns the real 6, and ProPurchaseAi.place()'s line 519
`if (player.getUnits().isEmpty()) return;` correctly skips the
fallback after placing the 6 plan units.

**Odin's `test_server_game.odin` harness orphan-backfill loop
(line ~256)** adds EVERY player-owned non-on-map unit to
`gp.units_held.units`, including those 11 dead-defender orphans.
So `player.getMatches(non-construction)` returns 11 → fallback
placeUnits() executes → Russia gets +4 inf and Karelia gets
+1 inf +1 art that Java never placed.

**Fix** (`odin_flat/test_server_game.odin` after proai-state-apply):
Trim each AI player's `units_held` to match the unit-type counts
recorded in `stored_purchase_territories.can_place_territories[*].place_units`.
This restores Java's getUnits() semantics for snaps between
purchase and place. Guarded by `len(plan_counts) > 0` so snaps
with no active plan (e.g. germanPurchase snap 21, before purchase
runs) keep their existing pool. Snap 0017 now passes (~20 ms,
runtime essentially unchanged).

### Iter 5 prior history (preserved)

**Eliminated two hypotheses; identified the
remaining gap between Java and Odin in snap 0017 russianPlace.**


Instrumented `pro_purchase_ai_place_units` to dump `len(self.placements)`,
`PRODUCED[territory]=n`, and per-`UndoablePlacement` (producer,
place, n_units) at fallback entry. Findings:

| measurement | value (Odin run) | Java expected |
|------------:|-----------------:|--------------:|
| pool at fallback entry (pass 0, non-construction) | **11** | 11 ✓ |
| placements at fallback entry | **6** | 6 ✓ |
| PRODUCED[Russia] | **2** | 2 ✓ |
| PRODUCED[Caucasus] | **4** | 4 ✓ |
| PRODUCED[Karelia] (none) | absent | absent ✓ |
| prioritized territories (count) | **6** | 6 ✓ |
| prioritized order | Karelia(sv=31.8), Caucasus(sv=15.4), Russia(sv=7.6), 16SZ, 4SZ, 5SZ | same |
| need_to_defend_land | **0** | (presumed 0) |
| need_to_defend_sea | **0** | (presumed 0) |

**Disproven hypothesis**: `placements` and `produced` state at
fallback entry exactly match what Java would have. So
`getMaxUnitsToBePlacedFromFull` should return 6 for Russia and 2
for Karelia in BOTH Java and Odin. Yet Java places 0 in fallback;
Odin places 5+2=7.

**New discovery — plan UUIDs are PHANTOM**: the 6 plan unit IDs
recorded in `before-proai-state.json.players.Russians.storedPurchaseTerritories[*].canPlaceTerritories[*].placeUnits[*].id`
are NOT present anywhere in `before.json.units[]` or `after.json.units[]`.
They are ProPlaceTerritory internal planning slots, never real
game units. So both Java and Odin's plan loop iterates the plan
slots by TYPE, picks 6 matching units from `player.getUnitCollection()`,
and removes those. Pool: 17→11 (verified by python).

**New discovery — Java's `doAfterEnd` deletes pool unplaced units
but only from player.unitsHeld, NOT from `data.getUnits()` (allUnits).**
So the AFTER snapshot's "pool=11" includes the 11 orphan units
that were `removeUnits`-changed away from player.unitsHeld at end
of place phase. They still appear in `data.units` with
`owner=Russians`. This means we CANNOT directly tell from
before/after pool counts how many units were placed in fallback
vs how many doAfterEnd removed.

**Re-derived from per-territory placements**: Russia AFTER has
+1 armour +1 art (= plan only, no fallback). Karelia AFTER has 0
new units. Caucasus AFTER has +2 inf +2 art (= plan only). So
Java's fallback placed **zero** units at Russia/Karelia/Caucasus.

**Verified outside `getMaxUnitsToBePlacedFromFull`**:
- ProAi state loader honors `canHold` from proai-state JSON
  (`odin_flat/test_proai_state_loader.odin:159`), but the place()
  flow creates FRESH `Pro_Purchase_Territory` via
  `pro_purchase_utils_find_purchase_territories`, so the loaded
  `canHold=False` for Karelia is **discarded** before the
  prioritize step. Same as Java (Java also calls
  `findPurchaseTerritories` fresh).
- All 5 players use `whoAmI=AI:Hard (AI)` → ProAi (no test-only AI).
- `PlaceDelegate.java` is empty (just `extends AbstractPlaceDelegate`)
  — no method overrides that could change behavior.

**Remaining hypothesis (untested)**: Java's actual runtime
exhibits a side effect not captured by paper-trace. Most likely:
**Java's `placeDefenders` flow DOES enter `placeDefenders`** for
Russia/Karelia/Caucasus, places defenders that consume the full
production capacity, and THEN the fallback returns max=0 because
producers are saturated. Odin returns `need_to_defend_*=0`, so
Odin skips placeDefenders entirely. Difference is in
`prioritize_territories_to_defend` filter logic:
- `enemy_attack_options.getMax(t) == nil` filters territories
  with no enemy attacks. If Odin's territory_manager misses
  enemy attack options Java sees for Russia/Karelia/Caucasus,
  Odin skips them in needToDefend.
- That code path is in `pro_territory_manager.populate_enemy_attack_options`
  — a separate, deeper subsystem.

Files instrumented this iter:
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`:
  added `PLACE_PRIORITIZED_DUMP`, `PLACE_NEED_TO_DEFEND_LAND`,
  `PLACE_NEED_TO_DEFEND_SEA`, and extended `PLACE_UNITS_FALLBACK_ENTRY`
  with `placements=N`, per-placement detail, and `PRODUCED[t]=n`.

No code changes. No fix made.

---

### Iter 4 history (preserved for reference)

2026-05-22 (iter 4) — **Drilled `get_max_units_to_be_placed_from_full`**
via printfs on `(prod, at, production, ucahbph, ucap, returned,
origF, ownerOrig, wasFact, maxCon, csw_to_n)` gated by
`player==Russians && at in {Russia, Karelia S.S.R.}`. Confirmed the
port's algorithm mirrors Java exactly per
`triplea/game-app/game-core/src/main/java/games/strategy/triplea/delegate/AbstractPlaceDelegate.java`
lines 1129-1320; same branch decisions, same arithmetic. Output for
snap 0017 russianPlace fallback:

| call | prod | at | production | ucap | branch | returned |
|------|------|----|------------|------|--------|----------|
| pre-plan | Russia | Russia | 8 | 0 | plain | 8 |
| during plan (after 1 placed) | Russia | Russia | 8 | 1 | plain | 7 |
| **fallback** | Russia | Russia | 8 | 2 | plain | **6** |
| fallback per-attempt (1-4 of 6) | Russia | Russia | 8 | 3,4,5,6 | plain | 5,4,3,2 |
| **fallback** | Karelia | Karelia | 2 | 0 | plain | **2** |
| fallback per-attempt (1 of 2) | Karelia | Karelia | 2 | 1 | plain | 1 |
| Caucasus | Caucasus | 8 (?) | 4 | 4 | plain | 0 |

Key facts the printf-dump confirms:
- `origF=false` for all three Russian factories (WW2v5 XML does
  not set `originalFactory=true` and `setOriginalFactory` is only
  called via XML reflection — so Java has `origF=false` too).
- `ra=null` for Russians in WW2v5 (no `RulesAttachment`; verified
  by grepping the XML).
- `wasFact=true` for Russia and Karelia (all three have a starting
  factory in the WW2v5 XML — `unitPlacement unitType="factory"`).
- `production=8` (Russia) and `production=2` (Karelia) match the
  territory `unitProduction` field.
- `unitCountAlreadyProduced` correctly grows as plan units land.
- `csw_to_n=true` branch only adds bookkeeping for water adjacency;
  for land (Russia, Karelia) the `production_can_not_be_moved`
  equals `unit_count_already_produced` and the branch reduces to
  `unitCountHaveToAndHaveBeenBeProducedHere = unit_count_already_produced`.
  So the final return is `max(0, production - ucap)`.

Ground truth from `before/after.json`:
- Russia BEFORE: factory + aaGun + infantry + fighter; AFTER (Java):
  same + 1 armour + 1 artillery (matches plan exactly).
- Karelia BEFORE: factory + armour; AFTER (Java): same (no
  placements).
- Caucasus BEFORE: factory + aaGun + infantry + armour + fighter;
  AFTER (Java): same + 2 infantry + 2 artillery (matches plan).
- Russians pool BEFORE: 12 inf + 4 art + 1 armour = 17.
- Russians pool AFTER (Java): 10 inf + 1 art = 11. Δ = -2 inf
  -3 art -1 armour = exactly the 6 plan units.

So Java's fallback `placeUnits` places **zero** units beyond the
plan; Odin places 5 at Russia + 2 at Karelia = 6 extras (Russia 5
of 6 attempts succeed; the 6th `playerHasEnoughUnits` rejects
because the unit was already moved away during Karelia's iteration
— see "frozen player_units" note below).

The algorithm on paper computes max=6 (Russia) and max=2 (Karelia)
in **both** Java and Odin. Yet Java places 0. The divergence must
therefore be **outside `getMaxUnitsToBePlacedFromFull`** in code
the orchestrator has not yet inspected. Most likely candidates:

1. **`player_units` is a SNAPSHOT in Odin's `pro_purchase_ai_place_units`**
   (line 339 of `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`,
   via `unit_collection_get_units` at
   `odin_flat/games__strategy__engine__data__unit_collection.odin:9`
   which returns a fresh `[dynamic]^Unit` COPY). Java does
   `player.getMatches(unitMatch)` inside the inner loop, returning
   the LIVE pool each iteration. This means after Karelia consumes
   2 units, Java sees 9 in pool but Odin still sees 11. **However**,
   this only explains why Odin's 6th attempt at Russia fails (the
   2 already-consumed units appear in Odin's `matched`); it does
   NOT explain why Java places 0 (which requires Java's max=0).

2. **`placeDefenders` divergence**: maybe Java's `placeDefenders`
   silently consumes Russia/Karelia production (sets some state)
   that makes `getPlaceableUnits` return 0 later. Odin shows the
   instrumented `pro_purchase_ai_place_defenders` performed 0
   placements (no GMUTBPF_RET output between the plan loop and
   `PLACE_UNITS_FALLBACK_ENTRY`).

3. **The snap is technically correct but encodes Java's
   `placeDelegate` state at the moment of snap-capture, which
   may carry hidden state** (e.g., a non-empty `produced` map at
   step START due to lingering state from a previous step's
   delegate save/load). The Odin harness's
   `test_server_game_register_ww2v5_delegates` constructs a fresh
   `AbstractPlaceDelegate` with `produced={}`. If Java's actual
   state had `produced[Russia]=8` at step start (e.g., due to a
   bug-or-feature in `loadState` from the snap fixture), Java
   would compute `max(0, 8-8)=0` immediately.

4. **Java AbstractPlaceDelegate#produced may be unioned across
   players** in some edge case I haven't found. Russia + Caucasus
   producing means produced has 6 entries total; if `getAlreadyProduced`
   returns "all 6" (instead of just Russia's 2), then `ucap=6`,
   `max=8-6=2`, fallback places only 2 at Russia. Hmm, still
   doesn't reach 0.

No fix made this iteration — instrumentation only. Confirmed
the suspect-leaf code itself is faithful to Java.

## Next action

**Iter 72: drill `ProCombatMoveAi#prioritizeAttackOptions` — the attack-territory
PRIORITY order that decides Yunnan-before-Burma (Odin) vs Burma-before-Yunnan
(Java).** This is the sole lever for the snap-0038 fighter rows: the FIC fighter
ties on every other dimension (Yunnan & Burma both dist=1, win=100, land-safe),
so whichever territory is earlier in `prioritized_territories` wins it. Fixing
the order should resolve all 4 fighter rows (the Yunnan fighter moves to Burma;
the 30 Sea Zone / second-Burma rows are downstream of that reassignment).

Concrete steps:
1. **Get the Odin order (already instrumented):** the `PLAN_PROBE` build prints
   `DUA_PT player=Japanese iter=1 t=<name> value=<f64>` for each prioritized
   territory in order. Rebuild `-define:PLAN=true` and run FILTER_SNAP=0038;
   grep `DUA_PT`. Confirm Yunnan's index < Burma's index and capture both
   `value=` numbers.
2. **Get Java ground truth:** run the oracle and probe
   `ProCombatMoveAi.prioritizeAttackOptions` (where `prioritizedTerritories` is
   finally sorted) — dump the ordered territory list + each
   `ProTerritory.getValue()` and the comparator sub-keys (find the field where
   Yunnan and Burma tie-break differently). Write to `/tmp/jprobe_0038.txt`
   (Gradle swallows stdout — MUST write to a file). snap 0038 = round-1
   japaneseCombatMove.
3. **Diff + faithful-port:** locate the comparator term where Odin orders
   Yunnan<Burma but Java orders Burma<Yunnan; port it faithfully (NOT an invented
   tie-break / sort-by-name). Rebuild clean (no probe defines), re-run
   FILTER_SNAP=0038. When GREEN, re-run TWICE more (rebuild once) for
   layout-invariance, THEN the full 104-snap batch (prioritization touches ALL
   combat moves — regression check mandatory; baseline now 90/104).

Probe locations (gated, left in place):
- `AIR_PROBE`/`CSL` in `pro_combat_move_ai.odin` air block (~2980) +
  `can_air_safely_land_after_attack` (~265) — build `-define:AIR_PROBE=true`.
- `PLAN_PROBE` `DUA_PT`/`DUA_ITER` in the same proc — build `-define:PLAN=true`.

Build/run recipe (shell wrapper strips a leading `cd`; use ABSOLUTE paths + a
SUBSHELL for the run):
- Build: `export SQDIR=/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib;
  export LIBRARY_PATH=$SQDIR:$LIBRARY_PATH; export
  LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH; odin build
  /home/caleb/todin/triplea/conversion/odin_tests/server_game_run_next_step
  -collection:flat=/home/caleb/todin/odin_flat
  -collection:test_common=/home/caleb/todin/triplea/conversion/odin_tests/test_common
  -build-mode:test -define:PLAN=true -out:/tmp/snaprun_prio -no-bounds-check
  -o:minimal`.
- Run: `( cd /home/caleb/todin/triplea && export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
  FILTER_SNAP=0038 LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && timeout 360
  /tmp/snaprun_prio > /tmp/snap0038_prio.log 2>&1 )` then `grep -aE "DUA_PT"`.
- Java oracle: `export
  JAVA_HOME=/nix/store/c3pl7bqrx3d2rc3dh98z6yaj0mv1p52g-openjdk-21.0.10+7 &&
  export PATH=$JAVA_HOME/bin:$PATH && cd triplea && ./gradlew --no-daemon
  --quiet :game-app:smoke-testing:test --tests
  "*Ww2v5JacocoRun.runWithSnapshots"`; probes write `/tmp/jprobe_0038.txt`.

## Next action (prev iter 71 plan — EXECUTED in iter 71; superseded)

_(The iter-71 plan was "drill the 4 fighter rows"; executed — localized to the
attack-territory priority order; see iter-72 plan above.)_

## Next action (prev iter 69 plan — EXECUTED in iter 70)

**Iter 70: (A) run the FULL snap batch to confirm the iter-69 markNoMovement
guard fix caused no regression; (B) drill the remaining snap-0038 RED — the 4
fighter rows (an independent air-move destination divergence).** The iter-69

## Next action (prev iter 68 plan — EXECUTED in iter 68)

**Iter 68 (DONE): port the load-from territory order fix.** Done — see Last
action. The cargo-order root cause is fixed; a narrower already_moved
divergence remains (now the iter-69 target). Original iter-68 plan preserved
below.

**Iter 68: PORT THE FIX — make Odin's transport load-from set iterate in
Java's LinkedHashSet INSERTION order instead of alphabetical, then verify
snap 0038 goes green.** Root cause is fully pinned (iter-67): the
armour/artillery tie is broken by load-from territory iteration order;
Java uses insertion order (Kwangtung before Japan for the SFE set), Odin
sorts alphabetically (Japan first). Concrete steps:
1. **Java reference:** `ProTransport.transportMap` is
   `Map<Territory, Set<Territory>>` where the value is a `LinkedHashSet`
   (`ProTransport.java:14-25`), populated by
   `computeIfAbsent(t, k -> new LinkedHashSet<>()).addAll(loadFromTerritories)`.
   The insertion order of `loadFromTerritories` comes from
   `ProTerritoryManager.findAmphibMoveOptions` — read it top-to-bottom and
   note the exact iteration that builds the load-from set.
2. **Odin structure:** `Pro_Transport.transport_map` value is currently an
   unordered `map[^Territory]struct{}` (loses order); `find_amphib_move_options`

## Next action (prev iter 67 plan — executed in iter 67)

**Iter 67 (DONE): get Java's intermediate Alaska state via the Java oracle.**
Ran the oracle; found Java attacks Alaska too (both transports get artillery)
and root-caused the divergence to the load-from territory iteration order
(alphabetical vs LinkedHashSet insertion). See Last action. (Original iter-67
plan below.)
- Add a probe in the JAVA `ProCombatMoveAi.determineTerritoriesToAttack`
  (behind a `-D` flag, e.g. `-Dpro.dua.dump`) printing, per `numToAttack`
  step: each `territoriesToTryToAttack` territory name, its assigned
  `patd.getUnits()` (types), `result.getWinPercentage()`, the
  `estimateStrengthDifference` vs `getStrengthEstimate()`, and
  `areSuccessful`. ALSO print whether Alaska is in `prioritizedTerritories`
  and its attackValue from `prioritizeAttackOptions`. Run via the
  `*Ww2v5JacocoRun` harness (the heavy oracle path) filtered to the
  japaneseCombatMove turn.
- Mirror the same dump on the Odin side (extend DUA_REMOVE_DECIDE to also
  print the assigned attacker types + estimateStrengthDifference per step).
  Compare: if Java assigns FEWER/weaker attackers to Alaska (→ lower win%
  → removed) while Odin over-assigns (→ win%=100 → kept), descend into the
  unit-assignment in `tryToAttackTerritories` (which units reach Alaska)
  or the battle-result estimation (`estimateBattleResult` /
  ProOddsCalculator, layers 15/14). If Java simply never has Alaska in the
  prioritized list, descend into `prioritizeAttackOptions` /
  `findAmphibMoveOptions` instead.
- Faithful-port reminder: once the divergent decision is pinned, port the
  Java logic exactly (NOT an invented tie-break). Then rebuild, re-run
  `FILTER_SNAP=0038`, confirm SFE = {artillery, infantry m4}, and re-run
  twice (rebuild once) to confirm layout-invariance.

Build/run recipe (probes): `cd …/triplea && export
SQDIR=/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib &&
export LIBRARY_PATH=$SQDIR:$LIBRARY_PATH
LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && odin build
conversion/odin_tests/server_game_run_next_step
-collection:flat=/home/caleb/todin/odin_flat
-collection:test_common=conversion/odin_tests/test_common
-build-mode:test -define:PLAN=true -out:/tmp/snaprun_0038planN
-no-bounds-check -o:minimal`. Run: `export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
FILTER_SNAP=0038 LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && timeout 360
/tmp/snaprun_0038planN > /tmp/snap0038_planN.log 2>&1` (CWD MUST be
`…/triplea`). Java oracle: locate the Ww2v5JacocoRun harness under
`templates/` / `triplea` test sources.

## Next action (prev iter 66 plan — executed in iter 66)

**Iter 66 (DONE): identify the SPECIFIC prior commit that consumes Japan's
artillery.** Result: the 60 SZ → Alaska amphib (see Last action). The
plan below was the iter-66 plan; it is now executed.

**Iter 65 (DONE): hunt the pointer-order-dependent map/set iteration.**
Iter-64 proved (a) snap 0038's cargo divergence is the SFE transport
loading armour vs Java's artillery (the two units TIE at effective-attack
3, so the choice is purely a tie-break / iteration-order artifact), and
(b) the planner outcome is deterministic per-binary but shifts with memory
layout (plan3 build → 1-territory divergence, plan4 build → 8-territory
divergence) ⇒ a pointer-hash map/set iteration is leaking
non-Java-faithful order into combat-move decisions. Concrete steps:
- Enumerate the `map[^...]...` / set iterations on the snap-0038
  combat-move path that are iterated WITHOUT first sorting keys via
  `pro_determinism_sorted_*` / `java_hashmap_bucket_for_string`. Start
  at the cargo path: the load-from territory's `unit_collection.units`
  ordering after simulate-move/undo (does Odin re-add units in a
  different order than Java's `UnitCollection` List?), then
  `transport_map_list` / `amphib_attack_options` / `attack_map`
  iteration in `pro_combat_move_ai.odin`.
- For EACH suspect, check the Java oracle: Java iterates `HashMap`/
  `HashSet` in hash-bucket order keyed on stable fields (territory name,
  unit type/owner) — replicate that exact order via the existing
  `java_hashmap_bucket_for_string` helper or a stable key sort. This is
  the user's standing "no sort-by-id / no pointer order" directive made
  concrete. Port faithfully — do NOT invent a new comparator Java lacks.
- Decisive instrumentation already in place: the `CARGO_CMP` probe
  (gated `when PLAN_PROBE`) prints the load-from candidate order. Use it
  to confirm whether, after a determinism fix, Japan's order is stably
  `artillery,armour` (matching before.json / Java) on the SFE transport
  selection.
- Cross-check with a Java smoke: add a probe in
  `ProTransportUtils.getUnitsToTransportFromTerritories` (behind
  `-Dpro.ncm.trace.dump`) printing the gathered `units` order for the
  Japan load, run `*Ww2v5JacocoRun`, and confirm Java sees artillery
  before armour. Then rebuild Odin, re-run `FILTER_SNAP=0038`, and
  verify the divergence shrinks toward green (SFE = {artillery, infantry
  m4}). Re-run TWICE more (and ideally rebuild once) to confirm the
  divergence is now layout-INVARIANT.

Build recipe (probes): `cd …/triplea && export
SQDIR=/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib &&
export LIBRARY_PATH=$SQDIR:$LIBRARY_PATH
LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && odin build
conversion/odin_tests/server_game_run_next_step
-collection:flat=/home/caleb/todin/odin_flat
-collection:test_common=conversion/odin_tests/test_common
-build-mode:test -define:PLAN=true -out:/tmp/snaprun_0038planN
-no-bounds-check -o:minimal`. Run: `export
TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP=0038
LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && timeout 360
/tmp/snaprun_0038planN > /tmp/snap0038_planN.log 2>&1` then grep
`CARGO_CMP|AMPHIB|0038 FAILED`. NOTE the run CWD must be
`…/triplea` (relative `snapshots/` path) — running from repo root gives
a vacuous "No snapshots found ... test successful".

## Next action (prev iter 64 plan — superseded; Alaska was a red herring)

**Iter 64: prove WHY Odin pairs the artillery-carrying transport with
Alaska (value 8.0) while Java puts the artillery in Soviet Far East
(value 1.6).** Iter-63 proved the cargo SORT is faithful and the real
lever is the amphib transport→destination assignment in
`tryToAttackTerritories` (Odin commits BOTH an Alaska AND an SFE amphib
attack; Alaska steals the lone Japan artillery because it is prioritised
first; Java does NOT consume the artillery on Alaska, since the snapshot
flags ONLY SFE and Japan has exactly one artillery). Concrete steps:
- Add a gated per-transport probe in the Odin amphib loop
  (`pro_combat_move_ai.odin`, the `for pro_transport_data_outer in
  transport_map_list` loop ~l.2210) dumping: transport identity (UUID
  prefix), home sea zone, ordered `amphib_attack_options` targets, the
  chosen `min_win_territory`, the cargo `min_amphib_units_to_add`, and
  the `already_attacked_units_dyn` membership of the Japan artillery.
- Add the matching Java probe (behind `-Dpro.ncm.trace.dump`) in
  `ProCombatMoveAi.tryToAttackTerritories` at the `amphibAttackOptions`
  build + the entry loop, and run a Java smoke (`*Ww2v5JacocoRun`) so we
  see whether Java's `transportMapList` even produces an Alaska amphib
  option for these transports, and which transport→territory pairing it
  makes.
- Likely culprits to diff (in descending order): (1) whether Odin's
  amphib-target enumeration (`findAmphibMoveOptions` /
  `populateAttackOptions`) admits Alaska as an amphib target for a
  Japan-area transport that Java rejects (range / canal / unload
  predicate); (2) `removeTerritoriesWhereTransportsAreExposed` /
  the can-hold + transport-exposed filtering dropping Alaska in Java
  but not Odin; (3) the transport→destination pairing order. Port the
  divergent predicate faithfully (NOT a sort-by-uuid). Then rebuild,
  verify snap 0038 fully green (SFE = {artillery, infantry m4}), and
  walk back UP.

Build recipe (probes): `cd …/triplea && export
SQDIR=/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib &&
export LIBRARY_PATH=$SQDIR:$LIBRARY_PATH
LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && odin build
conversion/odin_tests/server_game_run_next_step
-collection:flat=/home/caleb/todin/odin_flat
-collection:test_common=conversion/odin_tests/test_common
-build-mode:test -define:PLAN=true -define:AMPHIB_TRACE=true
-out:/tmp/snaprun_0038plan -no-bounds-check -o:minimal`. Run:
`export TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP=0038
LD_LIBRARY_PATH=$SQDIR:$LD_LIBRARY_PATH && timeout 360
/tmp/snaprun_0038plan > /tmp/snap0038_plan.log 2>&1` then grep
`AMPHIB|PRIO|DUA_PT`.

---

## Next action (prev iter 63 plan — now executed in iter 63)

**Iter 63: snap 0038 advanced — the amphib CONQUEST now works (owner =
Japanese ✓ after the iter-62 transported_by boxing fix). The remaining
divergence is which CARGO UNITS were selected for the assault.**
Observed tally diff:
```
Soviet Far East / Japanese / armour    moves=4 dmg=0: Expected=0 Actual=1
Soviet Far East / Japanese / artillery moves=4 dmg=0: Expected=1 Actual=0
Soviet Far East / Japanese / infantry  moves=3 dmg=0: Expected=0 Actual=1
Soviet Far East / Japanese / infantry  moves=4 dmg=0: Expected=1 Actual=0
```
Odin loaded `{armour, infantry(moves=3)}`; Java loaded
`{artillery, infantry(moves=4)}`. So: (a) wrong unit TYPE picked
(armour vs artillery), and (b) the infantry that moved has a different
moves-remaining (3 vs 4) — suggesting a different infantry instance was
chosen and/or it took a longer path. This is exactly the user's
standing directive territory: **a sort-by-UUID is selecting arbitrary
cargo units where the canonical sort must key on (unit_type, owner,
territory, moves_remaining, hp_remaining, transport-cost, …).**
Drill-down plan:
- Find where the amphib cargo set is chosen — `ProTransportUtils` /
  `populateAmphibAttacks` / `getUnitsToTransport` and the
  `ProTerritory.amphibAttackMap` / `ProTerritoryManager.findAmphibMoveOptions`
  load-from-territory unit selection. Look for any `sort` / `slice.sort`
  / comparator keyed on unit id/uuid in the Odin port and compare to
  Java's `ProTransportUtils.getUnitsToTransportFromTerritories` /
  `ProTransportUtils.findBestUnitsToLandTransport` ordering.
- Re-enable `AMPHIB_TRACE`/`PLAN` probes (already gated) to dump the
  candidate cargo list + chosen units for Soviet Far East and diff
  ordering vs Java.
- Replace any UUID sort with the attribute-based sort (faithful to
  Java's comparator). Then rebuild + verify snap 0038 fully green and
  walk back UP.

Build recipe (clean, probes gated out by default):
`cd …/triplea && export SQLITE_LIB=… LD_LIBRARY_PATH=… LIBRARY_PATH=… &&
odin build conversion/odin_tests/server_game_run_next_step
-collection:flat=/home/caleb/todin/odin_flat
-collection:test_common=conversion/odin_tests/test_common
-build-mode:test -out:/tmp/snaprun_XXXX -no-bounds-check -o:minimal`.
Add `-define:AMPHIB_TRACE=true -define:PLAN=true` to enable probes.
Run: `export TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP=0038 &&
timeout 360 /tmp/snaprun_XXXX 2>&1 | grep -aE 'PATTERN'`.

The other 12 RED (after 0038):
0031 0037 0040 0048 0065 0074 0075 0084 0090 0092 0097 0100. Several
unit-tally snaps (0040 0048 0065 0075 0084 0090 0092 0100) timed out
at 320 s during iter-61 characterization — bump the per-snap timeout
to capture their full diffs. 0037 = Japanese PUs 16!=1; 0097 =
Americans PUs 1!=19 (both purchase/resource). 0031 = britishBattle
resolution; 0074 = German sub/bomber move-selection.
**NEW RED from iter-62 (regression-exposed, part of the cluster):**
0032 britishNonCombatMove, 0089 japanesePurchase r2 — both were green
on baseline; both expose the same cargo/unit-SELECTION bug as 0038.
Full RED set now (15): 0031 0032 0037 0038 0040 0048 0065 0074 0075
0084 0089 0090 0092 0097 0100.

Artifacts: Odin clean fix binary `/tmp/snaprun_0038fix`
(iter-62 transported_by fix, probes gated out); `/tmp/snaprun_0024fix`
(iter-60 clean baseline); per-snap results `/tmp/iter60_res/*.txt`;
iter-61 characterization `/tmp/iter61_diag/*.txt` + `/tmp/iter61_full/*.txt`.

---

## Next action (prev iter 62 plan — now executed)

**Iter 62: descend into snap 0038's `ProCombatMoveAi#doMove` (layer
29) — find why Odin does not amphibiously conquer Soviet Far East.**
The amphibious-assault path is `doMove` → `determineTerritoriesToAttack`
(`:28`) → `determineUnitsToAttackWith` (`:28`) → `tryToAttackTerritories`
(`:27`); the amphib MOVE OPTIONS originate in
`ProTerritoryManager.populateAttackOptions` → `findAmphibMoveOptions`.
First step (cheap, do before deeper probes): determine whether Odin
even ENUMERATES Soviet Far East as an attackable amphib target.
- Read the Odin `findAmphibMoveOptions` port side-by-side with
  `ProTerritoryManager.java`; check the transport-load-from-Japan +
  unload-at-Soviet-Far-East option is generated.
- If the option is ABSENT → descend into `findAmphibMoveOptions`
  (append as the new bottom row, strictly lower `method_layer`);
  instrument the transport/cargo/distance/load-unload predicates.
- If PRESENT-but-not-chosen → descend into the attack-value /
  `determineTerritoriesToAttack` selection.
- Port faithfully (NOT a sort-by-UUID). Then walk back UP per protocol.
**RESULT: root cause was NOT in enumeration/selection/routing — it was
the `transported_by` reference-property boxing bug in `unit.odin`
(setter expected boxed `^^Unit` but call sites pass raw `^Unit`).
Fixed; SFE now conquered. See "Last action" above.**

---

## Next action (prev iter 60 plan — now executed)

**Iter 61: pick a fresh RED snap and start a new drill-down.** Iter 60
resolved the Ukraine air-landing divergence at its root (the
`BattleTracker.conquered` serialization gap, layers 29c–29f), greening
0024, 0076, 0077, 0089 → **91/104**. The 13 remaining RED:
0031 0037 0038 0040 0048 0065 0074 0075 0084 0090 0092 0097 0100.

## Next action (prev iter 60 plan — now executed)

**Iter 60: descend into `findAirMoveOptions` (layer 29e) — find why
Odin's 2 fighters + 1 bomber can move-to-defend `Ukraine S.S.R.` but
Java's can't — and locate where the 3 extra `cantMoveUnits` infantry
are set.** Iter 59's `JAVA_DEFROSTER` roster diff pinned the +6
Ukraine defenders to two groups: Odin's `maxUnits` has **+2 fighter +1
bomber** (Java maxUnits=5 {armour4, arty1}; Odin=8 {armour4, arty1,
fighter2, bomber1}); Odin's `cantMoveUnits` has **+3 infantry** (Java
cantMove=1 {armour1}; Odin=4 {armour1, inf3}). `maxAmphibUnits`
matches.

Concretely for iter 60:
- **Air group:** producer is
  `ProTerritoryManager.findAirMoveOptions`
  (`ProTerritoryManager.java:929`, reached via `populateDefenseOptions`
  → `findDefendOptions` `:650`). Read it top-to-bottom and diff
  against the Odin port. Add a gated probe (behind `pro.ncm.trace.dump`
  / `ARMOUR_TRACE`) for the German NCM turn dumping, per candidate air
  unit, whether it's added to Ukraine's `maxUnits` and the deciding
  inputs (air range / remaining movement, `canLandAirUnits` at a
  landing territory, `already-moved`/committed flag). Find why Odin
  admits the 2 fighters + bomber Java rejects.
- **Infantry group:** `cantMoveUnits` is NOT set in
  `ProTerritoryManager`; grep for where `addCantMoveUnit` /
  `setCantMoveUnits` is called (likely `ProNonCombatMoveAi`
  move-generation / `findDefenders`). Instrument the 3 infantry to
  see why Odin marks them can't-move while Java moves them out.
- Pick whichever sub-divergence resolves first; append the real
  divergent callee as the new bottom row (strictly lower
  `method_layer`). Then port that step faithfully (NOT a sort-by-UUID),
  re-run, and **walk back UP** popping rows (re-check 29d→29c→…→snap)
  until snap 0024 goes green.
- Run recipe unchanged: Java smoke `-Dpro.ncm.trace.dump=true` then
  `grep -rhoE 'PATTERN[^<]*' .../build/test-results | sort -u`; Odin
  rebuild `/tmp/snaprun_0024trace` (ARMOUR_TRACE) then
  `FILTER_SNAP=0024 ... | grep -aE 'PATTERN' | sort -u`.

Probes left in place (gated): Java `JAVA_TVAL`/`JAVA_TVAL2` in
`findLandValue`, `JAVA_MINRES` + `JAVA_CANHOLD` + `JAVA_CANHOLD3` +
`JAVA_DEFROSTER` in `determineIfMoveTerritoriesCanBeHeld` (all behind
`pro.ncm.trace.dump`). Odin `JAVA_TVAL`/`JAVA_TVAL2`, `minres`,
`prio_*`, `landloop_*`, `JAVA_CANHOLD` + `JAVA_CANHOLD3` +
`JAVA_DEFROSTER` (all behind `ARMOUR_TRACE`).

Then continue with the other 16 RED (all genuine AI-decision
divergences, no longer ordering artifacts):
- **0037** — `players.Japanese.resources[PUs]: 16 != 1`. A
  purchase/resource-accounting divergence, not a unit-tally one.
  Also slow (>300 s) — may need a longer per-snap timeout to see the
  full divergence. Trace the Japanese purchase step.
- **Remaining 14** (0031 0038 0040 0048 0065 0074 0075 0076 0077
  0084 0089 0090 0092 0100) — all "unit tally divergence" AI
  move/purchase snaps. Map each to the lowest-layer Java↔Odin proc
  that first diverges (append trace rows with strictly-decreasing
  method_layer per the protocol).

Verify the 8 Odin `_with_loc` sort sites (pro_purchase_ai.odin lines
2524 2769 3314 3332 3720 3764 3914 3921) each have a matching wired
Java site; sites 3914/3921 (mu_set/mb_set) and 2524/2769 may map to
Java methods not yet inspected — if RED persists there, that's the
gap.

---

## Next action (prev iter 51 plan — now executed in iter 52)

**Iter 51: STRATEGY CORRECTION — replace UUID ordering with CONTENT
ordering. (User directive 2026-05-29: "any sorts by id are a red
flag … replace with a sort focused on unit type, owner, territory,
moves remaining, hp remaining, + ship/bombard/transport attributes …
our snapshot comparison treats ids as arbitrary.")**

WHY iter-49's UUID approach is wrong: the snapshot comparator keys
units by CONTENT only — `Territory_Unit_Key = {type, owner,
already_moved, unit_damage}` (see
`test_common/game_state_compare.odin:72`); UUIDs are explicitly
ignored. So (a) Odin cannot reproduce Java's UUID order for units
created mid-simulation (fresh `UUID.randomUUID()` on the Java side,
non-matching ids on the Odin side), and (b) ordering AI decisions by
UUID is unreproducible by a content-equivalent replay. Content
ordering IS reproducible because Odin reproduces content.

HARD CONSTRAINT discovered: iter-49 made the 21 fields
`TreeMap`/`TreeSet` KEYED ON the comparator. A pure content
comparator returns 0 for two content-identical units (e.g. 2
infantry, same owner/moves/damage) → TreeMap/TreeSet would COLLAPSE
them to one key, corrupting unit multiplicity (`unitMoveMap` etc.).
And "no id tiebreak" rules out the content+UUID escape hatch.
⇒ The TreeMap/TreeSet FIELD-TYPE change must be REVERTED to
LinkedHashMap/HashMap/LinkedHashSet (identity-keyed → preserves
multiplicity). Ordering becomes SORT-AT-ITERATION (stable) on BOTH
sides — content-identical units are interchangeable so tie order
cannot affect the content-compared outcome.

Plan:
1. `ProDeterministicOrder.java`: `UNIT_BY_CONTENT` is DONE (mirrors
   Odin's `pro_determinism_unit_property_less` field order, serializable,
   with a javadoc'd "never key a TreeMap on this" warning). Add a
   `sortedUnits(Collection)` / `sortedUnitKeys(Map)` helper returning a
   stable content-sorted `List<Unit>` for iteration, plus a `_withLoc`
   variant taking `ProData.unitTerritoryMap` for multi-territory sites
   (mirrors Odin's `_with_loc`). Keep `TERRITORY_BY_NAME`.
2. REVERT the 21 field types in ProTerritory / ProMyMoveOptions /
   ProData / ProTransport / ProOtherMoveOptions back to their
   original LinkedHashMap/HashMap/LinkedHashSet (git-diff the iter-49
   change to get the exact originals).
3. Sort-at-iteration in Java at the order-sensitive consumption
   sites (the `keySet()`/`entrySet()`/`values()` loops in
   ProNonCombatMoveAi, ProCombatMoveAi, ProPurchaseAi, ProMoveUtils,
   etc.) using `UNIT_BY_CONTENT` / `TERRITORY_BY_NAME`.
4. Mirror the SAME content sort at the SAME sites in Odin (new
   helpers `pro_determinism_sorted_units` / `…_territory_keys` in an
   Odin determinism util — they do NOT exist yet despite the iter-49
   plan referencing UUID-named variants).
5. Regenerate all 104 snapshots from the corrected Java; re-run the
   batch. Target: ≥ the 81/104 iter-50 baseline, with the 23
   non-passers converging.

**NO open confirmations remain** — the design is now forced by the
TreeMap-mutable finding (above): identity-keyed maps + sort-at-iteration
is the only correct option. Autonomous defaults adopted: comparator =
Odin's exact field order; "territory" handled via the `_with_loc`
location tiebreak at multi-territory iteration sites (Odin already does
this via `pro_data.unit_territory_map`; Java must add the equivalent at
those sites since a `Comparator<Unit>` cannot see external location).

## Next action (prev iter 50 plan — superseded by user directive)

**Iter 50: full Odin batch characterisation + Odin sort-at-iteration.**
(Characterisation DONE — 81/104 PASS, see Snap status. The
"Odin sort-at-iteration mirroring TreeMap UUID order" step is
CANCELLED and replaced by the iter-51 content-ordering plan above.)

## Next action (prev iter 49 plan — now executed)

**Iter 49: execute Java refactor + snapshot regen.**


Plan for iter 49:

1. **Add Java helper `ProDeterministicOrder.java`** in
   `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/`:
   ```java
   public final class ProDeterministicOrder {
     public static final Comparator<Unit> UNIT_BY_UUID =
         Comparator.comparing(u -> u.getId().toString());
     public static final Comparator<Territory> TERRITORY_BY_NAME =
         Comparator.comparing(Territory::getName);
     private ProDeterministicOrder() {}
   }
   ```

2. **Refactor 24 field declarations** across 5 Pro data classes:
   - `ProTerritory.java` (10 fields: maxUnits, amphibAttackMap,
     transportTerritoryMap, isTransportingMap, maxBombardUnits,
     bombardOptionsMap, bombardTerritoryMap, cantMoveUnits,
     maxEnemyBombardUnits, tempAmphibAttackMap). Also fix the 2
     copy-constructor lines (l.120, l.137) which currently use raw
     HashMap.
   - `ProMyMoveOptions.java` (5 fields: territoryMap, unitMoveMap,
     transportMoveMap, bombardMap, bomberMoveMap).
   - `ProData.java` (2 fields: unitTerritoryMap, unitsToBeConsumed).
   - `ProTransport.java` (2 fields: transportMap, seaTransportMap).
   - `ProOtherMoveOptions.java` (2 fields: maxMoveMap, moveMaps).

   Pattern:
   ```java
   // before
   private final Map<Unit, List<Unit>> amphibAttackMap = new LinkedHashMap<>();
   // after
   private final Map<Unit, List<Unit>> amphibAttackMap =
       new TreeMap<>(ProDeterministicOrder.UNIT_BY_UUID);
   ```

3. **Local variables and stream chains** (~100 sites) — DEFERRED to
   iter 50. They're inside method bodies and most are
   order-independent (sum, dedup). Iter-49 ships only the field
   declarations; iter-50 audits which locals' iteration order
   affects game state.

4. **Build verification**:
   ```bash
   cd /home/caleb/todin && nix develop --command bash -c "
     cd triplea && ./gradlew --no-daemon \
       :game-app:game-core:compileJava \
       :game-app:smoke-testing:compileTestJava \
       -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest"
   ```

5. **Regen snapshots** using verified iter-48 pipeline. Output to
   `/tmp/regen_iter49_processed/server_game_run_next_step/snapshots/`.
   Diff against current on-disk snapshots — expect divergence at
   many snaps (because Java ordering is now UUID-sorted, not
   LinkedHashMap-insertion-order). Save existing snaps to
   `triplea/conversion/odin_tests/server_game_run_next_step/snapshots.iter48_baseline/`
   then replace with regen output.

6. **Re-run Odin under existing iter-47 binary** against new
   snapshots — expect mass failure (Odin code still iterates raw
   pointer maps). This is the iter-49 deliverable: Java refactor
   shipped, snaps regenerated, Odin failures characterised.

7. Update status doc + memory + task_complete.

**Plan for iter 50:**

1. **Add Odin helper** for nested-map sort (the
   `map[^Unit]map[^Territory]struct{}` case found in
   pro_combat_move_ai). Probably called
   `pro_determinism_sorted_unit_to_territory_set_pairs`.

2. **Refactor Pro_Territory iteration sites** to sort by UUID at
   every iteration of `amphib_attack_map`, `max_units`,
   `transport_territory_map`, `is_transporting_map`,
   `max_bombard_units`, `bombard_options_map`,
   `bombard_territory_map`, `cant_move_units`,
   `max_enemy_bombard_units`, `temp_amphib_attack_map`. Cross-file
   sweep (~20–30 iteration sites).

3. **Refactor Pro_My_Move_Options / Pro_Other_Move_Options /
   Pro_Data / Pro_Transport iteration sites** similarly.

4. **Build + 5× ASLR** against iter-49's regenerated snapshots.
   Target 5/5 PASS on snap 0089. Then run full 0001–0104 batch to
   verify no regression.

5. Update status doc + memory + task_complete.

**Plan for iter 51 (contingency):**
- Audit and fix the ~100 Java local variables + 7 stream chains
  where iteration order affects state.
- Same on Odin side.
- Re-regen snaps; re-validate.

## Next action (prev iter 48)

1. Add `PLAN_INPUT_DIGEST` probe in `pro_ncm_trace.odin`: dump
   `(territory_name, sorted unit_type:count for pt.units,
   sorted transport_id->[sorted unit_types of value] for
   pt.amphib_attack_map)` over ALL Pro_Territory entries in move_map.
   Hash the whole thing with FNV-1a64; also dump per-territory rows
   so PASS vs FAIL diff can be done at row level. Filter to
   Japanese-owned units.

2. Wire `PLAN_INPUT_DIGEST` at the entry of
   `pro_non_combat_move_ai_do_move` (i.e. right before
   `calculate_move_routes`), in `pro_non_combat_move_ai.odin` l.1226.
   This is the snapshot of the move_map AS PASSED to the route
   calculators — if THIS digest differs across runs, the leak is in
   the PLANNER (`move_units_to_best_territories` etc.); if it is
   IDENTICAL across runs, the leak is INSIDE `calculate_move_routes`
   itself.

3. Rebuild `/tmp/snaprun_iter48` with
   `-define:NCM_END_STATE=true -define:MOVE_ROUTES_DIGEST=true
   -define:PLAN_INPUT_DIGEST=true`. Run 5× ASLR-on snap 0089.

4. Tabulate `PLAN_INPUT_DIGEST` per run. Two outcomes:
   - **Digest varies across runs ⇒** leak is in `pro_non_combat_move_ai`
     planner. Diff the per-territory rows between any PASS and any
     FAIL run; the first differing territory localises the leak.
     Walk into the move-planner sub-proc that writes `pt.units` or
     `pt.amphib_attack_map` at that territory.
   - **Digest identical across runs ⇒** leak is in
     `pro_move_utils_calculate_move_routes` /
     `_calculate_amphib_routes` themselves. Re-audit the two procs
     for pointer-keyed map iteration or unstable sort with non-unique
     comparator key. Likely:
     - `move_validator_carrier_must_move_with` returns a `Map<Unit,
       Collection<Unit>>` (Java) ⇒ Odin `map[^Unit][dynamic]^Unit`;
       iterating it inside `unitList.add` could be order-sensitive.
     - `pro_data.unit_territory_map` is a pointer-keyed map; if
       `pro_data_get_unit_territory(u)` returns nondeterministic for
       sibling units, the `startTerritory == t` filter flips.
     - `map.get_route_for_unit` might iterate `map_data.neighbors`
       (pointer-keyed) for tied-distance routes.

5. Java fidelity: re-read `ProMoveUtils.calculateMoveRoutes` (l.72)
   and `calculateAmphibRoutes` (l.200) line-by-line for any
   `Map.Entry` iteration, `getMatches(...)` call, or
   `Stream<Territory>` consumer whose Java order is HashSet/HashMap
   bucket-order while the Odin port iterates raw pointer-map.

6. Apply iter-44 deterministic-sort pattern at every identified site.

7. Rebuild stock binary `/tmp/snaprun_stock_iter48` (NO probes),
   run 5× ASLR-on snap 0089. Target ≥ 4/5 PASS.

8. Update status doc 4 sections + memory + task_complete.

## Next action (prev iter 47)

Iter-46 proved NCM is the leak via NCM_END_STATE digest divergence.
Need to narrow which specific `pro_non_combat_move_ai_move_*` proc
flips the Japan-resident decision.

Plan:

1. Add per-proc entry/exit `MOVE_PLAN_DIGEST` probe (FNV-1a64 of
   sorted territory+unit-type-count tuples for Japan-origin units
   in EVERY `Pro_Territory.units`). Wire to fire at the start AND
   end of these procs in `pro_non_combat_move_ai.odin`, in calling
   order:
   - `move_units_to_best_territories` (l.1479) — primary
   - `move_units_to_defend_territories` (l.3628)
   - `move_one_defender_to_land_territories_bordering_enemy` (l.372)
   - `prioritize_defend_options` (l.3246)
   - `move_infra_units` (l.4707)
   - `move_consumables_to_factories` (l.1118)
   - `move_allied_carried_fighters` (l.317)
   Filter to Japanese.

2. Rebuild `/tmp/snaprun_ncmend_iter47` with
   `-define:NCM_END_STATE=true -define:MOVE_PLAN_DIGEST=true`.
   Run 5× ASLR-on snap 0089.

3. Diff PASS-run-5 vs FAIL-run-2 (most extreme divergence,
   n=4 vs n=2). The FIRST proc whose EXIT digest differs while
   ENTRY digest matches is the leak site. (If all procs already
   diverge at entry, walk further upstream into
   `do_non_combat_move` prep — `find_units_that_can_move`,
   `territory_manager_set_attack_options`, etc.)

4. Inside the identified proc, search for:
   - `for X, _ in <map[^Territory]_>` patterns
   - `for X, _ in <map[^Unit]_>` patterns
   - `slice.sort_by(...)` (likely unstable; convert to
     `stable_sort_by` if comparator has ties)
   - `pro_territory_get_max_units(...)` / similar map-returning
     calls iterated raw

5. Apply iter-44 deterministic-sort pattern:
   `pro_determinism_sorted_territory_keys(m)` for territory-keyed
   maps, `pro_determinism_sorted_unit_keys_with_uuid(m)` for
   unit-keyed maps.

6. Java fidelity: read the equivalent
   `ProNonCombatMoveAi.<methodName>` and confirm the Java order
   the Odin sort must match. Java HashMap iteration over
   `Set<Territory>` is bucket-order; Odin port must replicate via
   `pro_determinism_sorted_*` helpers (territory name is the
   stable surrogate per `/memories/java-hashmap-iteration-order.md`).

7. Rebuild stock `/tmp/snaprun_stock_iter47`, run 5× ASLR-on,
   target NCM_END_STATE digest identical across all 5 runs ⇒
   downstream purchase pool will converge automatically (already
   stabilised iter-44/45). Snap 0089 should hit 5/5 PASS.

8. Update status doc 4 sections + memory + task_complete.

**Important — runner discipline.** Last 2 sessions burned tokens
polling the 5-run batch. NEW PROTOCOL: launch via
`setsid nohup ... & disown` and end the turn immediately after
verifying the runner pid exists; the terminal-completion notification
fires automatically on next turn. Do NOT call `tail --pid` or
sleep loops as foreground sync commands.

## Next action (prev iter 46)

Evidence: iter-44 fixed 4 pointer-map iterations in
`purchase_sea_and_amphib_units` (3/5 PASS). Iter-45 fixed 5 more
across `purchase_land_units` + `purchase_defenders` +
`purchase_factories` (2/5 PASS). Total 9 sites converted, NO movement
on flake rate. The downstream `purchase_pool` divergence (`armour=1
infantry=8` vs expected `armour=0 infantry=10`) is therefore caused
by an UPSTREAM input difference, not by purchase-internal iteration.

Most likely upstream culprit: `do_move` (layer 29a, YELLOW in trace
table since iter-43 because "4/5 runs identical at unit-set level;
run 5 still diverges"). The 2-3 ASLR failure runs likely leave Japan
with a different `unit_collection` after NCM than the 2-3 PASS runs;
that flows into `unplaced_units` derivation at
`pro_purchase_ai.odin` l.2908 (`unit_collection_get_units(...)`).

Plan:

1. Add `NCM_END_STATE` probe at the END of
   `pro_non_combat_move_ai_simulate_non_combat_move` (or
   `do_move`): for each player dump
   `(player_name, sorted_unit_summary)` where summary is sorted
   `(territory_name, unit_type_name, count)` triples for every
   territory the player owns. Filter to Japanese.
2. Re-run 5× ASLR-on `/tmp/snaprun_stock_iter45`. Tabulate per-run
   probe digest. Expect PASS runs to share digest A, FAIL runs to
   share digest B. The first divergent `(territory, unit_type)`
   pair localises which NCM movement decision flipped.
3. From the diverging `(territory, unit_type)` walk into the
   NCM move-pipeline call that placed/removed that unit. Likely
   sites: `pro_combat_move_utils_calculate_amphib_routes` (already
   patched iter-43), `pro_simulate_turn_utils_simulate_battles`,
   or a `getMatches`/`getNeighbors` iteration in
   `simulate_non_combat_move`'s prioritisation loops.
4. Java fidelity rule: re-read `ProNonCombatMoveAi.doMove` end-to-end
   for every `Set<Territory>`/`HashSet<Unit>`/`Map.Entry` iteration
   whose order Java fixes via LinkedHashSet patch.
5. Apply iter-44/45 sorted-iteration pattern at every identified site.
6. Rebuild stock binary `/tmp/snaprun_stock_iter46`, run 5× ASLR-on,
   target ≥ 4/5 PASS.
7. **HARD STOP after iter-46.** If still ≤ 3/5 PASS, escalate to
   FULL `random_number` call-count comparison between PASS and FAIL
   stderr to localise the first divergent RNG call (rather than
   continue pattern-matching).
8. Update status doc 4 mutable sections + memory note + task_complete.

Do NOT add more purchase-AI sort sites without first proving via
NCM_END_STATE digest that the purchase pool sees identical inputs
across runs.

## Next action (prev iter 45)

Plan:

1. Add `PURCH_STATE` probe at the entry of
   `pro_purchase_ai_purchase_sea_and_amphib_units` AND after every
   `randomize_purchase_option` call inside the SEA-DEFENDER and
   SUPERIORITY loops, dumping `(label, random_number, total_eff,
   chosen_unit_type, resource_tracker_pus)`. Filter to Japanese.
2. Re-run 5× ASLR-on `/tmp/snaprun_stock_iter44b` with probes on.
   The first divergent `random_number` between PASS and FAIL runs
   localises the RNG-state perturbation site.
3. Walk BACKWARDS from that site to find the last preceding
   `java_math_random()` call whose call-count differs by an odd
   number. The intervening code path has a hidden branch on a
   pointer-keyed iteration.
4. Also audit `purchase_land_units` (l.2868) for the same
   pattern — Japan's `unitIsNotSea()` matches include the units
   that NCM left in Japan, and those drive the land-purchase
   greedy loop's `attack_efficiencies` / `defense_efficiencies`
   computation. Likely sites:
   - `unit_collection_get_units(game_player_get_unit_collection(self.player))`
     iteration order at l.2908 (passed to `unplaced_units`).
   - `neighbors` map at l.3043 (mirror of l.3654 fix).
5. Java fidelity rule: re-read
   `ProPurchaseAi.purchaseLandUnits` + `purchaseSeaAndAmphibUnits`
   for any remaining `getMatches(...)` / `getNeighbors(...)`
   iteration whose order Java fixes via LinkedHashSet patch but
   Odin still iterates raw.
6. Apply iter-44 pattern (sorted-iteration helper) at every
   identified site.
7. Rebuild stock, run 5× ASLR-on, target ≥ 4/5 PASS.
8. Update status + memory + task_complete.

### Iter 44 — original plan (kept for reference)

**Iter 44: chase the two residual leaks revealed by iter-43.**
Iter-43 shipped the deterministic-sort fix for
`calculate_amphib_routes` (UUID tie-break in sort key + `stable_sort_by`
in both pair-sort sites). PASS rate jumped 1/5 → 3/5. Two surfaces
remain:

**LEAK A residual** — run 5 of iter 43 produced a different
post-NCM Japan unit set (n=4 vs n=3 in runs 1–4). Either:
- A second `map[^X]` iteration inside `calculate_amphib_routes`
  not covered by the iter-43 fix (the per-transport load loop's
  inner ordering of unloaded cargo, the `move_batcher` route
  segmentation, or the carry/loaded-units selection).
- A separate proc on `do_move`'s critical path (e.g.
  `calculate_move_routes` for non-amphib units when the
  `routes_must_move_with` map is iterated as `map[^Unit]`).

**LEAK C (new)** — runs 1 vs 2 (and 3 vs 4) have BYTE-IDENTICAL
NCM output (n=3, same types) but FAIL/PASS differ based on
`rem_prod` at SZ62 (3 vs 1). So `purchase_sea_and_amphib_units`
itself flakes the amount of remaining production it consumes,
despite a deterministic input. Iter 39's
`prioritize_sea_territories` fix covers TERRITORY iteration;
LEAK C is at the per-territory greedy-purchase loop level —
likely another `map[^X]` (e.g. `purchaseTerritories` map for
remaining production tracking).

Concrete plan:

1. Add a probe `AMPHIB_INNER` inside `calculate_amphib_routes`
   AFTER the main sort loop completes, dumping (a) full sorted
   pair list `[i]uuid|type|loadedSig`, (b) for each transport
   the chosen route + selected loaded-unit UUIDs. Filter to
   Japanese + Manchuria/Yunnan destinations.
2. Re-run 5× ASLR-on snap 0089. Identify the first AMPHIB_INNER
   line that differs in run 5 vs runs 1/2/3/4. That points to
   the residual nondeterminism inside the proc.
3. Independently add a probe `PURCH_GREEDY` inside
   `purchase_sea_and_amphib_units` BEFORE the greedy loop and
   AFTER each iteration, dumping `(picked_option, remaining_pus,
   remaining_prod_per_territory_sorted)`. Compare runs 1 vs 2
   (same NCM input, different result).
4. Java fidelity rule: read
   `ProMoveUtils.calculateAmphibRoutes` again specifically for
   the inner loops (l.240–360) and
   `ProPurchaseAi.purchaseSeaAndAmphibUnits` (search for
   greedy purchase section). Find equivalent
   `LinkedHashMap`/`Map` iteration and apply the
   `parallel-list + dedup` pattern.
5. Rebuild `/tmp/snaprun_rpo_ncmu4`, run 5× ASLR-on snap 0089.
6. Drop RPO_DUMP, run 5× ASLR-on with stock binary. Target ≥
   4/5 PASS.
7. Update status + memory; task_complete.

### Iter 43 — original plan (kept for reference)

**Iter 43: fix amphib-routes pointer-map iteration.** Iter 42
localised the leak to `pro_non_combat_move_ai_do_move` (l.1226):
the `move_map` it receives is byte-deterministic but the actual
units it removes from Japan vary across ASLR rolls. Prime
suspect: `pro_move_utils_calculate_amphib_routes` (l.392)
iterates `pro_territory_get_amphib_attack_map(pt)`, which is
`map[^Unit][dynamic]^Unit` — pointer-keyed map iteration is
nondeterministic across ASLR.

Concrete plan:

1. Read `pro_move_utils_calculate_amphib_routes`
   (`odin_flat/games__strategy__triplea__ai__pro__util__pro_move_utils.odin`
   l.392) end to end.
2. **Java fidelity rule:** read Java
   `triplea/game-app/game-core/src/main/java/games/strategy/triplea/ai/pro/util/ProMoveUtils.java`
   `calculateAmphibRoutes` end to end. Identify every
   `LinkedHashMap`/`LinkedHashSet`/`Map.Entry` iteration; record
   the insertion-order key sequence.
3. Convert every Odin `for k, v in some_map[^Unit]…` iteration
   in that proc to the parallel `[dynamic]^Unit` + dedup
   `map[^Unit]struct{}` pattern from
   `/memories/java-hashmap-iteration-order.md`. The
   `amphib_attack_map` itself needs a parallel insertion-order
   list `amphib_attack_order: [dynamic]^Unit` populated at every
   write site (search for `pro_territory_get_amphib_attack_map(...)
   [...] = ...` or `set_amphib_attack_map`).
4. Also audit `pro_move_utils_calculate_move_routes` (l.157)
   for any pointer-map iteration that snuck past iter-42's
   MOVE_PLAN probe (e.g. carrier-must-move-with map).
5. Rebuild `/tmp/snaprun_rpo_ncmu3` (same build cmd as iter 42,
   different `-out:` label) and verify 09_after_doMove +
   MOVE_PLAN are identical across 5 ASLR-on snap-0089 runs.
6. Then drop RPO_DUMP and run 5× ASLR-on snap 0089 with the
   stock binary. Target ≥ 90% PASS (≥ 4/5).
7. If 09_after_doMove now identical but result still flakes:
   widen probes downstream of `do_move` (e.g. battle
   precache, unit reorder in target territory).
8. Update doc + memory; task_complete.

### Iter 43 — context from iter 42

- The planner (`do_non_combat_move`) is byte-deterministic at
  unit-identity granularity (NCM_UNITS 00..08 + MOVE_PLAN).
- The executor (`do_move`) is NOT deterministic — Japan's
  post-state varies n=2/3/5 across runs (09_after_doMove).
- Iter-39's `prioritize_sea_territories` fix is necessary but
  not sufficient.
- `calculate_amphib_routes` (called second by `do_move`) is the
  prime suspect because amphibious operations from Japan to
  China-coast destinations DO mutate Japan's `unit_collection`,
  and the proc iterates a pointer-keyed transport map.

### Iter 42 — original plan (kept for reference)

**Iter 42: per-unit identity NCM probe.** Iter 41 proved the
existing NCM_TRACE hash (aggregate per-territory) cannot
detect the leak because the leak is at unit-identity level
(NCM moves different *individual* units in different runs
while preserving territory counts). Concrete plan:

1. Add a new probe `NCM_UNITS` in
   `pro_non_combat_move_ai_do_non_combat_move` that DUMPS
   Japan's `unit_collection.units` as a sorted-by-type list
   at the top of each major NCM sub-phase. Sort by
   `(unit_type_name, unit_owner_name)` so output is identical
   across ASLR rolls IF underlying state is identical.
   Gate under `when #config(RPO_DUMP, false)` and filter to
   `pname == "Japanese"`. Place at: entry, after
   `find_units_that_cant_move`, after `move_one_defender_to_land`,
   after `move_units_to_defend_territories`, after
   `move_units_to_best_territories`, after `move_infra_units`.
2. Also probe destination set: for each major sub-phase that
   moves units, print "MOVED unit_type=X from=Japan to=Y" lines
   in the same Japan-filtered gate.
3. Build with `-define:RPO_DUMP=true` (NCM_TRACE no longer
   needed — its aggregate hash is provably useless here).
4. Run 5× ASLR-on snap 0089 (~2m40 each).
5. Diff NCM_UNITS traces between runs. First sub-phase where
   the post-state SORTED unit list differs is the leak site.
   First MOVED line that differs identifies which unit got
   moved differently.
6. Open that proc in `pro_non_combat_move_ai.odin`. Look for
   `map[^Unit]`, `map[^Territory]`, or `map[^Pro_Territory]`
   iteration in the path that picks units to move. Compare
   to Java's equivalent (`find triplea/game-app -path
   "*/main/java/*ProNonCombatMoveAi.java"`). Apply
   insertion-order/sort-by-name fix.
7. Verify: rebuild, 5× snap 0089 ASLR-on, target ≥ 90% PASS.
8. Update doc + memory; task_complete.

### Iter 42 — context from iter 41

- AMPHIB outputs and PHASE_PUS confirm pre-NCM state and
  purchase pipeline are fully deterministic.
- NCM_TRACE proves territory-aggregate state is identical
  across ASLR (so move-map structure is preserved).
- Iter 41b proves Japan's `unit_collection.units` count
  itself varies 2/3/5 across runs (NCM physically moves
  different counts of units off Japan).
- So the leak is in NCM choosing WHICH unit to move (or how
  many), via a pointer-keyed iteration that the iter-39 fix
  did not address. Likely candidates: ordering inside
  `move_units_to_defend_territories`,
  `move_units_to_best_territories`, or unit-selection helpers
  called from them (e.g. `pro_purchase_validation_utils` /
  `pro_transport_utils` for sea-bound units).

### Iter 41 — concrete plan

1. Add a Japan-filtered probe inside
   `pro_non_combat_move_ai_simulate_non_combat_move` (and/or
   `pro_non_combat_move_ai_do_move`) that prints, per phase
   inside NCM:
   - Japan's `unit_collection.units` count
   - The number of Japan-owned units selected to MOVE from Japan
   - The destination territories chosen (by name, sorted)
   Gate under `when #config(RPO_DUMP, false)` + Japanese-only.
2. Build with `-define:RPO_DUMP=true`.
3. Run 5× ASLR-on snap 0089 (~2m40 each).
4. Diff probe traces — the first NCM sub-phase where Japan's
   `units_moved_count` or destination set differs between runs
   is the leak site.
5. Open `pro_non_combat_move_ai.odin` at that phase. Apply
   Java fidelity rule: `find triplea/game-app -path
   "*/main/java/*ProNonCombatMoveAi.java"`, read the
   equivalent Java method, find the `HashSet<Territory>`,
   `HashMap<...>`, or `LinkedHashSet<...>` whose iteration
   feeds the move decision. Apply iter-33 insertion_order or
   iter-34 sort-by-name fix to the Odin port.
6. Verify: rebuild, 5× snap 0089 ASLR-on, target ≥ 90% PASS.
7. Update doc + memory; task_complete.

### Iter 41 — context from iter 40

- `pro_purchase_ai_purchase` and `purchase_sea_and_amphib_units`
  are FULLY deterministic when given the same `purchase_options`
  + `purchase_territories` + Japan-owned units (verified by
  identical PHASE_PUS, identical ttnu_n, identical ptl_n@t=60
  across 4 iter-40B runs).
- The flake is exclusively `own_n` (Japan land units present),
  determined by NCM sim-walk before purchase.
- Iter-39's `prioritize_sea_territories` LinkedHashSet fix
  remains correct + necessary.
- Iter-40 added probes (PHASE_PUS, AMPHIB_GATHER_DONE) are
  gated and harmless to leave in place.

### Iter 41 — verification

After fix(es): 10× snap 0089 ASLR-on, target ≥ 90% PASS.
After ≥ 90% sustained, full 104-snap sweep vs iter-31
baseline (87/17).

### Pre-iter-40 next-action history (preserved)

**Iter 40: pursue both residual leaks in parallel.**
to find why `rem_prod` (remaining production) at the
`t=62 Sea Zone land=Japan` AMPHIB_OUTER iteration differs by 2
PUs across ASLR runs (PASS=1 vs FAIL=3). The leak is either
(a) in an earlier amphib outer iteration that mutated
`purchase_territories` / `pro_purchase_territory.purchase_resources`
non-deterministically, OR (b) in a pre-amphib phase
(`purchase_aa_units`, `purchase_defenders`,
`purchase_land_units`, factory placement) that consumed
production in ASLR-dependent order, OR (c) in the iteration
order of the outer amphib loop itself.**

### Iter 39 — concrete plan

1. **Map iteration order entering the amphib loop.** Add a probe
   immediately before `for sea_purchase_territory in
   sea_place_territories` (or whatever drives AMPHIB_OUTER) that
   dumps `sea_place_territories` keys in iteration order. Compare
   PASS vs FAIL. If different, the input map is pointer-keyed —
   sort by `.name` (java-hashmap helper if needed).

2. **`rem_prod` decomposition.** Add a probe at AMPHIB_OUTER for
   ALL iterations (not just t=62/Japan), printing
   `(iter_idx, t_name, land_name, japan_PUs_remaining,
   pus_consumed_so_far)`. Diff PASS vs FAIL — the first row
   where `pus_consumed_so_far` differs is the leak boundary.

3. **Pre-amphib production probe.** Add probes at the entry of
   each pre-amphib purchase phase
   (`purchase_aa_units`, `purchase_defenders_land`,
   `purchase_defenders_sea`, `purchase_land_units`,
   `purchase_factory`) printing Japan's `getResources().get(PUs)`.
   If a PASS/FAIL split appears here, the leak is in that phase.

4. **Apply fix.** Once site is identified, sort the offending
   pointer-keyed iteration source by name (see iter-34 pattern
   in `pro_purchase_option.odin` or iter-33 `insertion_order`
   pattern). Re-run 10× ASLR-on, target ≥ 90% PASS.

### Iter 39 — context from iter 38

- SIMSTEP probe traces are IDENTICAL across runs (jCM 8→8,
  jBattle 8→8, jNCM 8→3) — sim-walk loop is NOT the leak.
- Japan's unit composition at BEFORE_PRIO_SEA is IDENTICAL
  (aaGun, factory, armour in both runs).
- First divergent probe line: `AMPHIB_OUTER t=62 Sea Zone
  land=Japan ... rem_prod=1` vs `rem_prod=3`. Same `spt_n=1`,
  same `own_n=3` — only the production remaining differs.
- The leak therefore is in the purchase-phase production
  accounting, not in the sim-clone state.
- Candidate-site shortlist from earlier inspection: the OUTER
  amphib iteration order over `sea_place_territories` (iter-32
  noted this as a non-deterministic strict-`>` sort with
  pointer-hash tiebreak); and the resource-allocation in
  `purchase_aa_units` (iter-33 noted strict-min tiebreak).

### Pre-iter-38 next-action history (preserved)

**Iter 38: probe inside the sim-walk loop in
`abstract_pro_ai.odin` (line ~836–~970) to identify WHICH
AI-phase step mutates Japan's `unit_collection.units`
differently across ASLR runs. Print Japan's unit count BEFORE
and AFTER each `step_name` iteration, gated on `Japanese`. The
step whose AFTER count first diverges across two runs is the
leak site. Then walk into that step (likely
`pro_non_combat_move_ai_do_move` or `pro_combat_move_ai_do_move`)
to find the pointer-keyed map iteration.**

### Iter 38 — concrete plan

1. **Probe in sim-walk loop** (line ~836 in `abstract_pro_ai.odin`,
   inside `for step in game_steps`):
   - BEFORE step execution: `SIMSTEP_BEFORE step=%s japan_n=%d`
   - AFTER step execution: `SIMSTEP_AFTER step=%s japan_n=%d`
   - Gate: `when #config(RPO_DUMP, false)` and player == Japanese.
   - Use `game_map_get_territory_or_null(game_data_get_map(data_copy), "Japan")`.

2. **Run 2× ASLR-on.** Diff the SIMSTEP traces. The first step
   whose AFTER count differs is the leak site.

3. **Walk into the offending step proc.** Find the pointer-keyed
   `map[^T]...` iteration; sort by `.name` before iterating (see
   `/memories/repo/iter34-support-factor-fix.md`).

4. **Verification.** After fix: 10× snap 0089 ASLR-on, target
   ≥ 90% PASS. After ≥ 90% sustained, full 104-snap sweep vs
   iter-31 baseline (87/17).

### Iter 38 — context from iter 37

- The sim-walk loop runs `pro_data_initialize_simulation` once
  per step, then executes the step's delegate (NCM, CM, move,
  etc.) on `data_copy`. Each step can mutate
  `data_copy`'s territory unit collections.
- Iter-37 evidence shows Japan's collection differs by 2 units
  (PASS=3: aaGun/factory/armour; FAIL=5: aaGun/factory/infantry/
  armour/artillery) at entry of `pro_purchase_ai_purchase`. So
  during the sim walk, some step moved 2 extra units to Japan
  in run 2 vs run 1, OR moved 2 units away from Japan in run 1.
  Either way it is an AI-decision divergence inside the sim
  pipeline.

### Pre-iter-37 next-action history (preserved)

**Iter 37: probe `pro_purchase_ai_purchase` (the immediate caller
of `purchase_sea_and_amphib_units`) and the sea-territory
prioritization code to bisect whether the leak is (a) in the
sim-clone NCM/CM pipeline that moves Japan's infantry+artillery
away, or (b) in the prioritized-sea-territory list construction.
Both divergences shown in iter 36 must be tracked separately.**

### Iter 37 — concrete plan

1. **Probe A — Japan unit count at entry of
   `pro_purchase_ai_purchase`** (the immediate caller of
   `purchase_sea_and_amphib_units`). If `n=4` here and `n=2` at
   the called-function entry, the leak is BETWEEN those two
   points (sea-defender purchase / transport purchase /
   load-units-onto-transports). If `n` already differs at
   `pro_purchase_ai_purchase` entry, the leak is in the
   sim-clone pipeline that runs before purchase.

2. **Probe B — `prioritized_sea_territories` source**. Find where
   this list is constructed (search for the variable name and the
   call site that passes it to `purchase_sea_and_amphib_units`).
   Add a probe that prints the source map's iteration order and
   the resulting list order. Look for `map[^Pro_Place_Territory]`
   or `map[^Territory]` populated from a Java `LinkedHashMap`.

3. **If Probe A shows leak between the two functions**: focus on
   `purchase_sea_and_amphib_units` callees that mutate Japan
   (`pro_transport_utils_load_units_on_transports` or similar).
   Apply the iter-33 `insertion_order` fix or the iter-34 name-
   sort fix.

4. **If Probe A shows leak in sim-clone pipeline**: walk back
   into `pro_non_combat_move_ai`, `pro_combat_move_ai`, or
   `pro_data` construction. Look for `map[^Territory]^Pro_Territory`
   or `map[^Unit]...` iteration that decides which units move.

### Iter 37 — verification

After fix: 10× snap 0089 ASLR-on, target ≥ 90% PASS. After
≥ 90% sustained, full 104-snap sweep vs iter-31 baseline (87/17).

### Pre-iter-36 next-action history (preserved)

**Iter 36: walk upstream of `purchase_sea_and_amphib_units` to
find the pointer-keyed map iteration leak that causes Japan's
unit collection to differ between ASLR-on runs at the start of
the Amphib outer loop.**

### Iter 36 — concrete evidence from iter 35

`/tmp/iter35_probe1.kept` vs `/tmp/iter35_probe2.kept`:
- Both runs: Land Fodder/Attack CSF calls identical (units_n=13,
  14, 15 matching, same artillery sf=0.9095).
- First `AMPHIB_SEA_PT t="60 Sea Zone"` reached identically.
- First `AMPHIB_OUTER t="60 Sea Zone" land="Japan"`:
  - Run 1 (FAIL): `own_n=2`
  - Run 2 (PASS): `own_n=4`

The Japan territory unit collection differs by 2 owned-by-Japanese
units. `territory_get_matches` and `unit_is_owned_by` are both
pointer-stable (use name-based `game_player_equals`). Therefore
`territory.unit_collection.units` itself has different contents
across runs.

### Iter 36 Task A — find what mutates Japan's units before purchase

Likely culprits (in order):

1. **AI sim-clone NCM (non_combat_move) phase** — runs inside
   `pro_data` simulation; moves Japanese units between
   territories deterministically given iteration order. Any
   pointer-keyed map iteration (e.g. `map[^Territory]...`,
   `map[^Unit]...`) in this pipeline leaks ASLR into the final
   unit placement.
2. **AI sim-clone CM (combat_move) phase** — same risk profile.
3. **`pro_data_set_start_of_turn_data` / `pro_data` construction**
   — if this snapshots the live game state via a pointer-keyed
   map iteration, the clone state can differ.
4. **`unit_collection_add_unit` ordering** — if units are added
   from a pointer-keyed source, the dynamic-array order of
   `unit_collection.units` is ASLR-dependent. (Iteration order of
   `units` itself is deterministic once populated; the leak is in
   how it gets populated.)

### Iter 36 Task B — narrow with TERR_DUMP probe

Add a probe at the start of `purchase_sea_and_amphib_units` (line
~3549 in `pro_purchase_ai.odin`) that dumps Japan's unit
collection contents:

```odin
when #config(RPO_DUMP, false) {
    if game_player_get_name(self.player) == "Japanese" {
        japan := game_map_get_territory_by_name(gm, "Japan")
        if japan != nil && japan.unit_collection != nil {
            fmt.eprintf("TERR_DUMP_JAPAN n=%d\n", len(japan.unit_collection.units))
            for u, i in japan.unit_collection.units {
                fmt.eprintf("  u[%d] type=%s owner=%s ptr=%p\n", i,
                    unit_type_get_name(unit_get_type(u)),
                    game_player_get_name(unit_get_owner(u)), u)
            }
        }
    }
}
```

If `TERR_DUMP_JAPAN n=N` differs at entry, the leak is BEFORE
`purchase_sea_and_amphib_units` — in `purchase` itself or in
`pro_data` setup. If `n` is identical at entry but the OUTER
amphib loop sees different counts, the leak is within
`purchase_sea_and_amphib_units` (the sea-defender or
transport-loop logic mutating Japan).

### Iter 36 Task C — once leak located, apply name-sort fix

Same pattern as iter 33/34: build a `[dynamic]^T` from the
pointer-keyed map, `slice.sort_by` predicate on `.name`, iterate
sorted array. See `/memories/repo/iter34-support-factor-fix.md`
for canonical pattern.

### Iter 36 Task D — verification

After fix: 10× snap 0089 ASLR-on, target ≥ 90% PASS. After
≥ 90% sustained, full 104-snap sweep vs iter-31 baseline (87/17).

### Pre-iter-35 next-action history (preserved)

**Iter 35: hunt the REMAINING ASLR leak that causes
`owned_local_amphib_units` (or whatever feeds `units` in the
Amphib `calculate_support_factor` call) to count differently
across ASLR runs. The iter-34 fix made `calculate_support_factor`
itself deterministic given identical inputs, but the inputs
themselves still vary upstream.**

### Iter 35 — concrete evidence of upstream leak

Compare run 5 (PASS) vs run 6 (FAIL), both with iter-34 fix +
`RPO_DUMP=true` probe. The first 3 CSF rows (Land Fodder/Attack
loop) are byte-identical between runs:

```
CSF self=artillery def=false ... units_n=12 sf=0.9095   (both)
RPO label=Land Fodder n=4 total=86600346550413632 rand=7.7085  (both)
CSF self=artillery def=false ... units_n=13 sf=0.9095   (both)
RPO label=Land Attack n=2 total=6.4928703605844084139e+25 rand=77.51  (both)
CSF self=artillery def=false ... units_n=14 sf=0.9095   (both)
RPO label=Land Fodder n=4 total=86600346550413632 rand=27.88  (both)
```

Then divergence at the start of Amphib processing:
- Run 5: `CSF ... units_n=4 sf=0` → `RPO Amphib n=4 total=8.18e22 rand=89.92`
- Run 6: `CSF ... units_n=6 sf=0` → `RPO Amphib n=4 total=8.18e22 rand=89.92`

Same `rand` (so RNG path is identical), but the `units` list
passed to `calculate_support_factor` has 2 different elements.
`units = [new_artillery] + non_consumed(owned_local_amphib_units)`,
so `owned_local_amphib_units` differs by 2 between runs.

`owned_local_amphib_units = territory_get_matches(land_territory,
matches_unit_is_owned_by(self.player))` — same player, same
territory, but different unit count. Hypothesis: the OUTER
iteration over place territories (`t`) reaches a different
`land_territory` first, OR an earlier purchase decision placed
units differently into `start_of_turn_data` / a sim clone.

### Iter 35 Task A — pinpoint upstream divergence

Add a probe at the top of the Amphib outer loop (line ~4030 and
~4150 in `pro_purchase_ai.odin`) that emits:
```
AMPHIB_OUTER t=<place_t_name> pt=<purchase_t_name> land=<land_t_name> own_local_n=<n>
```
Run 5×. The first run where this line diverges from run 1
pinpoints the leaking iteration order (`t` in place territories,
or `purchase_territory` in `selected_purchase_territories`).

### Iter 35 Task B — candidate leak sites

In order of suspicion:

1. **Place territory iteration order** — `place_territories`
   (member of `pro_data` or computed earlier). If built from a
   pointer-keyed map (`map[^Territory]^Pro_Place_Territory`)
   without a parallel insertion-order array, iteration is
   ASLR-dependent.
2. **`amphib_purchase_options_for_territory` ordering** — built
   by `find_purchase_options_for_territory_5`. Already verified
   deterministic at iter 33, but re-confirm with the iter-34
   binary + probe.
3. **`pro_transport_utils_select_units_to_transport_from_list`**
   — picks units to load on transports. If it iterates a
   pointer-keyed map internally, the resulting
   `selected_units` list (and therefore the remaining
   `potential_units_to_load` set) differs across runs.
4. **`pro_territory_value_utils_find_territory_values`** —
   returns a `map[^Territory]f64`; if a strict-`>` comparator
   ranks ties by pointer identity downstream, leaks.

### Iter 35 Task C — verification

After patching, run snap 0089 30× ASLR-on with the lean (no
RPO_DUMP) iter-35 binary. Target: 30/30 PASS. If pass rate
improves but is still <100%, repeat the probe-narrow-fix loop.

### Iter 35 Task D (deferred) — Java side patch

`unitSupportAttachments` in `ProPurchaseOption.java` is a
`HashSet<UnitSupportAttachment>` (built via `Collectors.toSet()`).
`UnitTypeList.getSupportRules()` is also a `HashSet`. Java's
HashSet iterates in identity-hash bucket order, which is
JVM-run-dependent. The snap was captured by ONE specific JVM
run; the Odin iter-34 fix sorts by `name` to be deterministic
but does NOT necessarily match the JVM order Java had when the
snap was captured. If snap 0089 turns out to FAIL even with
deterministic Odin order, add a `patch_unit_support_attachments`
in `scripts/patch_triplea.py` that sorts both sources by name in
the Java code (Collectors.toCollection(LinkedHashSet::new) with
a pre-sort), then re-capture snapshots.

### Iter 35 Task E — fix for stray SIGINT during long batch runs

When running `for i in 6 7 8 9 10; do ... done` and polling via
chat-tool terminals, killing a polling terminal sends SIGHUP to
the zsh session, which propagates SIGINT to running children.
The Odin test runner catches SIGINT and prints
`"Caught interrupt signal. Stopping all tests."` — corrupting
mid-loop runs. Workaround: launch batch via `nohup` and detach,
or use a fresh sub-shell with `setsid`.

### Pre-iter-34 next-action history (preserved)

**Iter 34: hunt the REMAINING pointer-keyed map iteration leak(s)
that keep snap 0089 ASLR-dependent even after the iter-33
`randomize_purchase_option` insertion-order fix.**

The iter-33 fix is shipped (Java fidelity gain — sum now in
`LinkedHashMap.values()` order at all 9 sites). But 4/5 ASLR-on
runs still FAIL snap 0089 with the IDENTICAL `Japanese armour 0/1,
infantry 10/8` tally. At least one additional pointer-keyed map
iteration leaks into the decision pipeline.

### Iter 34 Task A — re-narrow under the iter-33 binary

Rebuild PUR_TRACE on top of iter-33 fix (toggle PUR_TRACE=true
on /tmp/snaprun_purtrace). Run PUR_TRACE binary 5× ASLR-on and
collect P01-P10 hashes per run. **If hashes vary between runs**
the first variant checkpoint is the new leak surface. **If hashes
are identical (PUR_TRACE perturbs allocations enough to mask the
leak as before)**, fall back to a lighter probe.

Cheaper alternative: add a probe like `AMPHIB_PROBE` that prints
`PUR_PROBE` lines (a single newline-per-decision) with no map
allocation. Acceptable allocations: temp_allocator only. Goal:
log every option chosen (line, label, option name, computed
upper_bound, random_number) at each randomize_purchase_option
return for the Japanese player. Compare 2 ASLR-on runs and diff
the first divergent line.

### Iter 34 Task B — inspect the not-yet-ruled-out sites

In order of suspicion:

1. **`pro_purchase_option_get_defense_efficiency_with_args`** and
   `_get_sea_defense_efficiency` — these may iterate a unit list
   or owner-keyed map internally. They are called inside the
   `for ppo in purchase_options_for_territory` loop in each
   caller, so any pointer-hash leak here perturbs each option's
   efficiency value (not just the sum).
2. **`pro_battle_utils_estimate_strength`** and related TUV
   calculators — used during `_should_save_up_for_a_fleet` and
   defender-need calculations. Java uses `LinkedHashMap` or
   sorted iteration; check Odin equivalents.
3. **`pro_other_move_options_get_max`** (line 794 in
   purchase_aa_units) — returns an enemy attack option; if
   `max` is computed via map iteration with strict comparator,
   ties leak.
4. **`prioritized_sea_territories` build** — the strict-`>`
   strategic_value comparator on line 2065/3580; ties leak.
5. **`removeInvalidPurchaseOptions` callee chain** —
   `_check_if_carriers_can_be_placed`, `_get_unused_carrier_capacity`,
   any `map[^Unit]...` iteration in carrier/transport accounting.

### Iter 34 Task C — verification

Once a candidate fix is in, run snap 0089 30× ASLR-on. Target:
30/30 PASS. If even 1 FAIL, additional leaks remain.

After 30/30 ASLR-on PASS, run full 104-snap sweep and compare vs
iter-31's 87/17 baseline. Any regression on previously-PASSING
snaps is a new bug.

### Iter 34 Task D (deferred) — snap 0024/0031 drilling

Same priority as iter 32/33. Pick the smallest remaining failing
non-purchase snap after snap 0089 is stable.

### Pre-iter-33 next-action history (preserved)

**Iter 33: hunt the pointer-keyed map iteration leak in the

**Iter 32: investigate WHICH iter-30 refactor scaffold change
actually fixed snap 0089. Two candidates:**

1. New `_from_ordered_territories` overload's extra
   `[dynamic]^Territory` allocation in the caller (allocator-state
   shift, classic snap-0089-iter-28 perturbation pattern in
   reverse).
2. Removal of the duplicate `unit_get_transporting_no_args` call
   in `_from_territories` (iter 31 hypothesis 1).

If #2 is the fix, that's the kind of clean Java-fidelity finding
worth preserving and the rest of the refactor scaffold can be
deleted as dead code. If #1 is the fix, we're back in allocator-
perturbation land and need to find the REAL Java divergence that
the extra `make` happens to mask.

**Method:** strip the refactor scaffold down to one change at a
time, rebuild, re-run snap 0089. If pass: keep, move on. If fail:
you've found the fix.

### Iter 32 Task B — Drill snap 0024 or 0032 next
After the snap-0089 cause is isolated, pick the smallest remaining
failing snap to attack. Likely candidates:
- snap 0024 (germanNonCombatMove) — long-standing leaf, never
  fully isolated. Re-confirm vs current binary.
- snap 0032 (britishNonCombatMove) — was a iter-30 incidental
  PASS; check whether iter-31's PASS-rate change exposes a
  cleaner divergence pattern.

### Iter 32 Task C (deferred) — Java HashSet replica
Still worth doing eventually for future amphib/transport snap
fixes (snap 0037 Pacific amphib, etc.), but no longer urgent.
See iter-31 root-cause analysis above.

### Pre-iter-31 next-action history (preserved)

**Iter 31 has TWO priorities; pick the smaller one first.**

### Task A — Investigate snap 0025 regression (PRIORITY)
Iter 30 introduced a 1-unit swap regression on snap 0025
(germanPlace: 1 art ↔ 1 inf swap between Germany and Italy). This
is the EXACT same symptom pattern as the pre-iter-26 failure. The
fact that snap 0032 newly PASSES suggests the iter-30 fix
correctly moves SOME AI state toward Java-faithful, but the snap
0025 regression suggests SOMETHING in the iter-30 change is
shifting allocator/pointer-keyed state for non-amphib callers.

Hypotheses (in order):
1. **`pro_transport_utils_get_units_to_transport_from_territories`
   refactor allocates an extra `[dynamic]^Territory`** via
   `pro_determinism_sorted_territory_keys` (line 728 of
   `pro_transport_utils.odin`) even for callers that never used
   it before. The extra `make` call shifts allocator state,
   which propagates to downstream pointer-keyed map iteration
   (classic snap-0089-iter-28 perturbation pattern).
   **First experiment:** inline the sort back into the original
   function body (no helper call) and re-run snap 0025; if it
   passes, the allocator-perturbation hypothesis is confirmed.
2. **`randomize_purchase_option` signature change.** The optional
   `insertion_order: []^Pro_Purchase_Option = nil` param may cause
   Odin's default-param ABI to emit different code at non-amphib
   call sites. **Second experiment:** revert the signature
   (overload via separate procs) and re-run snap 0025.
3. **The bucket-sort logic is wrong for some edge case.** Germany
   DOES purchase transports in round 1 (Mediterranean access);
   the bucket sort may produce a candidate order that's "Java
   faithful for amphib" but breaks something else. Compare
   `AMPHIB_PROBE_JAVA.GATHER.tlf_kept.t name=` (Java oracle, log
   from iter 29) against `GATHER.tlf_kept.t name=` from the
   iter-30 amphib probe to confirm the bucket order matches Java.

If Task A determines the regression is allocator-perturbation
(hypothesis 1), the fix is to PRE-ALLOCATE the sort buffer once
per call site instead of inside the helper. If it's hypothesis
2, split the proc into two named variants. If it's hypothesis 3,
re-examine the Java HashSet semantics in
`purchaseSeaAndAmphibUnits` (capacity might need to be smallest
pow-2 ≥ `Math.max(16, neighbors.size())` not the raw collection).

### Task B — Drill snap 0089's residual `PUs: 1 != 0`
Iter 30 fixed the LinkedHashSet bucket-order bug in
`purchaseSeaAndAmphibUnits`; unit tally is now exact, but Japan
ends the snap with 1 PU unspent that Java spent.

Re-build `/tmp/snaprun_purtrace2` with the iter-29 PUR_TRACE +
iter-30 fix on top, capture the P06 hash and compare against the
iter-29 baseline (`P06=10c97889f3f7bdda`). The new P06 should hash
differently; check whether it now matches the iter-28 "PASS"
hash (`d4a9d799ae5de702`) or some third value.

Then enable `-define:AMPHIB_PROBE=true` (`/tmp/snaprun_amphib2`)
and capture `AMPHIB_LOOP.*` lines. Diff against the Java
`AMPHIB_PROBE_JAVA.*` block in
`ProPurchaseAi.java:1750-2280` (the Japanese-only
`System.err.println` instrumentation already in place).

Suspected residual: when `optionalSelectedOption.isEmpty()` after
`removeInvalidPurchaseOptions` filters out an option, the Odin
filter walks a map (random order) where Java walks a list
(deterministic). One iteration goes one way and the other goes
the other way, leaving a 3-PU option on the floor while leaving
1 PU undeducted from `remainingUnitProduction`.

Java entry points to audit:
1. `ProPurchaseValidationUtils.removeInvalidPurchaseOptions`
   (per `LinkedHashMap` declaration order).
2. `ProPurchaseValidationUtils.findPurchaseOptionsForTerritory`.
3. The amphib-loop `optionalSelectedOption.isEmpty()` break (Java
   lines ~2190 / 2240). Both branches must match Java; the trace
   table in iter-29 already captured the relevant call chain.

### Task C — Audit `randomize_purchase_option` non-amphib sites
The other 6 call sites in `pro_purchase_ai.odin` still call
`randomize_purchase_option` without `insertion_order`. For
Java-faithful behavior, each should pass the corresponding
options-list slice. Defer to iter 32 unless Task A regression
flagged it.

### Pre-iter-30 next-action history (preserved)

**Iter 30: Drill `purchaseSeaAndAmphibUnits` per java-fidelity-rule.**
_Status: DONE — fix shipped, snap 0089 unit-tally divergence gone,
residual 1-PU passed to iter 31 (Task B). Side effect: snap 0032
PASS gain; snap 0025 FAIL regression to drill in iter 31 (Task A)._

### Pre-iter-29 next-action history (preserved)

**Iter 29: Drill `purchaseSeaAndAmphibUnits` per java-fidelity-rule.**
_Status: DONE — perturbation-free tracer shipped, P06 narrowed to
`purchaseSeaAndAmphibUnits`._

Iter-29 narrowed snap 0089's divergence to P06
(`purchaseSeaAndAmphibUnits`), Java `ProPurchaseAi.java:1531-`.
The bug class is pointer-keyed iteration (same family as
iter-21/24/26 LinkedHashMap fixes); the AI plans 2 fewer
infantry at Japan than Java does.

### Task A — Zero-perturbation PUR_TRACE (PRIORITY)
Modify `odin_flat/games__strategy__triplea__ai__pro__util__pro_pur_trace.odin`:
1. Replace every `make(...)`, `strings.builder_make(...)`,
   `append(...)` with `context.temp_allocator`-allocated equivalents:
   ```odin
   rows := make([dynamic]string, context.temp_allocator)
   ut_names := make([dynamic]string, context.temp_allocator)
   sb := strings.builder_make(context.temp_allocator)
   full := strings.builder_make(context.temp_allocator)
   ```
2. Drop the `defer delete(...)` calls (temp_allocator owns lifetime).
3. Add `free_all(context.temp_allocator)` at the END of
   `pro_pur_trace_emit` so subsequent trace calls don't accumulate.
4. Audit `fmt.printf` — on Linux glibc it routes through
   `core:io/_print` which may default-alloc on first invocation per
   thread. If snap 0089 STILL passes with trace on after this fix,
   replace `fmt.printf` with `os.write(os.stdout, transmute([]u8)
   <stack buffer formatted via temp_allocator>)`.
5. Verify the fix by re-running snap 0089 with trace and confirming
   the snap still FAILS (the bug is preserved AND the trace lines
   appear). The expected behavior is exactly the same FAIL message
   as the no-trace run.

Sanity check: snap 0001 + 5 random PASS snaps must STILL pass with
the new tracer enabled and disabled — proving the temp_allocator
change is itself zero-perturbation.

### Task B — Once tracer is non-perturbing, descend on snap 0089
With a working tracer, the iter-28 trace table can extend:
1. Compare the four checkpoint hashes (P01, P03, P06, P10) against
   a Java reference run. The first divergent checkpoint identifies
   which sub-phase introduces the bug. Iter-28 evidence already
   strongly suggests **P03 (purchaseLand)** since that's where
   inf-vs-armour is chosen in Java's round-2 logic.
2. If P03 is the divergent checkpoint, add a 19→? drill into
   `purchaseLandUnits` (Java line 1063 in ProPurchaseAi.java).
3. The bug class is pointer-keyed iteration order
   (same family as iter-21/24/26 LinkedHashMap fixes). Likely
   culprit: a HashMap-backed collection in `findUnitsThatCanFightOnWater`,
   `findPurchaseOptionsForTerritory`, or the option-ranking step
   inside `purchaseLandUnits` walks a bare Odin map rather than a
   parallel `_order` slice.

### Task C — Snap 0024 / 0032 / 0037 drill (parallel)
If iter-29 ships Task A early, also drill snap 0024
(germanNonCombatMove unit-tally divergence; same casualty/combat
layer suspects as iter-26/27 Next action Task B) and snap 0032
(britishNonCombatMove 1-infantry swap; iter-26 deterministic but
still red). These are pre-existing iter-23 carry-overs unaffected
by the iter-26 fix.

### Pre-iter-28 next-action history (preserved)

**Iter 27 → Iter 28 plan: Drill the iter-27 regression (snap 0089)
AND descend on snap 0024.** _Status: PARTIAL — snap 0089 drill
blocked on perturbation-free tracer; iter 29 will resume._

### Pre-iter-27 next-action history (preserved)

**Iter 26: Diagnose and resolve the iter-25 regression on snap 0032
before any further forward work.** _Status: DONE \u2014 root cause was
upstream bare-map iteration in `give_support_to_unit` over the
`support_rules` LinkedHashMap; fix shipped iter 26._
The L9 yellows are already classified (iter-24): DummyPlayer
green, CasualtyUtil.getDependents green-for-snap, CombatValue
fixed-as-much-as-possible. Time to descend to L8 inside
`casualty_selector_select_casualties` body and the OOL impl body:

1. **`CasualtySelector#getDefaultCasualties`** (`triplea/game-app/.../delegate/battle/casualty/CasualtySelector.java`).
   Find with: `find triplea/game-app -path "*/main/java/*CasualtySelector.java"`.
   Read the method top-to-bottom; locate the auto-choose branch;
   verify Odin port at
   `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_selector.odin`
   matches line-by-line.

2. **`CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`**.
   `find triplea/game-app -path "*/main/java/*CasualtyOrderOfLosses.java"`.
   The iter-22 deep dive only verified the `add_remove` loop and
   `keep_lowest_strength_first` flag; the SURROUNDING logic in the
   same proc (sort key construction, tie-break ordering, comparator
   plumbing) was assumed green. Re-verify those parts byte-for-byte.

3. **`MainDefenseStrength.isDominatingFirstRoundAttack`** (`MainDefenseCombatValue.java`).
   WW2v5 has no first-round-attack units AFAIK; verify nothing in
   snap 0024 trips a side-effect. Cheap sanity check; only worth
   doing if Tasks 1 & 2 don't find the bug.

### Task C — Snap 0032 single-infantry swap
With snap 0032 deterministic but still red, this is now drillable
in normal trace-table style. The symptom is a 1-unit swap between
two adjacent territories during `britishNonCombatMove`. Likely
candidates (descending `method_layer`):
- `MoveValidator.validateMoveForRequiresUnitsToMove` or similar
  movement-validation tie-break.
- Pro AI's `ProNonCombatMoveAi` move sort/pick order (cf.
  `/memories/repo/step24-cruiser-divergence.md` precedent).
- Cheap to seed: pick `britishNonCombatMove` step's top-level proc
  from `port.sqlite`, drill in descending `method_layer`.

### Task D — Hand off if iter-27 budget exhausted
If iter-27 runs out of budget between Task A and Task B/C, the
deterministic state of snap 0032 + the sweep results are enough
for iter-28 to pick up cleanly.

### Pre-iter-27 next-action history (preserved)

**Iter 26: Diagnose and resolve the iter-25 regression on snap 0032
before any further forward work.** _Status: DONE \u2014 root cause was
upstream bare-map iteration in `give_support_to_unit` over the
`support_rules` LinkedHashMap; fix shipped iter 26._

### Task A — Identify the hang root cause (PRIORITY)
Runs 2 + 4 of the iter-25 5-run loop died silently after `PSTART`.
With memory tracking enabled and `timeout 180`, no FATAL or leak
dump made it to disk, so the process hit a tight infinite loop
or hit a UAF that segfaulted before flush.

Steps:
1. Build a non-leak-tracking variant of `/tmp/snaprun` (drop
   `-debug` and use `-define:ODIN_TEST_TRACK_MEMORY=false`) so
   crashes produce a usable stack:
   ```sh
   cd triplea && /run/current-system/sw/bin/odin build \
     conversion/odin_tests/server_game_run_next_step \
     -collection:flat=../odin_flat \
     -collection:test_common=conversion/odin_tests/test_common \
     -build-mode:test -define:ODIN_TEST_TRACK_MEMORY=false \
     -extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib" \
     -out:/tmp/snaprun_fast
   ```
2. Re-run snap 0032 a few times with `timeout 180`. If a hang
   reproduces, attach `strace -f -e signal=none -o /tmp/strace.log
   -p $(pgrep snaprun_fast)` to see whether it's a busy loop
   (no syscalls), a poll/wait, or a segfault.
3. If it's a busy loop, check `get_next_available_supporter` for:
   - Use-after-remove of `keys_order[0]` (the remove zeroes the
     slot in entries but does the next iteration find the freed
     `^Unit` and re-loop?).
   - Mutation of `keys_order` while iterating it.

### Task B — Audit missed iteration sites
The iter-25 fix may be incomplete. Grep for ALL consumers of the
three suspect maps and confirm each one uses an `_order` slice:
```sh
cd odin_flat
grep -n 'units_giving_support\b' games__strategy__triplea__delegate__power__calculator__*.odin
grep -n 'support_units\b'        games__strategy__triplea__delegate__power__calculator__*.odin
grep -n 'support_rules\b'        games__strategy__triplea__delegate__power__calculator__*.odin
grep -n '\.entries\b'            games__strategy__triplea__delegate__power__calculator__integer_map_unit*.odin
```
For each `for k, v in ...` over a bare map field, replace with
walks via the parallel `_order` slice. Candidate sites likely
missed:
- `unit_power_strength_and_rolls_builder.add_units` — does it
  iterate `available_supports.units_giving_support` directly?
- `Available_Supports.support_units` — Java line 32 + 108 say
  LinkedHashMap; Odin field is still bare `map[…]^Support_Details`
  with no `_order` parallel slice. If any caller iterates it, add
  one.
- `support_calculator` builder loop — does the OUTER walk over
  `support_rules` use bare-map iteration order?

### Task C — Bisect-revert if Task A/B are inconclusive
If Task A/B don't pinpoint the regression, revert iter-25 changes
one at a time and re-run snap 0032 (3 runs each):
1. Revert Task A only (MainOffenseStrength accessor) — should be
   inert for snap 0032.
2. Revert Task B only (`Integer_Map_Unit.keys_order` + helpers +
   builder + consumer rewrites). If 0032 stabilizes back to
   2P/1F or better, the regression is here.
3. Revert Task C only (`units_giving_support_order` + getter +
   producer + consumer). If 0032 stabilizes back to 2P/1F or
   better, the regression is here.

### Task D — Once snap 0032 is back to deterministic PASS
Re-run individual snap 0024 with `timeout 300`. If still red, the
bug is deeper than the support pipeline. Next yellow candidates
in descending `method_layer`:
- `CasualtySelector#getDefaultCasualties` (layer 16) body itself.
- `CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl`
  surrounding logic (`add_remove` undo-loop,
  `keep_lowest_strength_first` flag).
- `MainDefenseStrength.isDominatingFirstRoundAttack` (verify
  WW2v5 has no first-round attack units).

### Task E — Full 104-snap regression sweep
Once snap 0032 PASSes ≥ 5/5 and snap 0024 either passes or its
failure mode is fully characterized, run the full sweep at -P 8
with 420 s cap:
```sh
cd /home/caleb/todin/triplea && mkdir -p /tmp/snap_results_iter26 && \
  rm -f /tmp/snap_results_iter26/*.txt && \
  printf '%s\n' $(seq -f "%04g" 1 104) | \
  xargs -P 8 -I{} sh -c 'timeout 420 env \
    TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP={} /tmp/snaprun_fast \
    > /tmp/snap_results_iter26/{}.txt 2>&1; \
    echo "EXIT={}:$?" >> /tmp/snap_results_iter26/{}.txt'
for f in /tmp/snap_results_iter26/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```
Compare against iter-23 baseline (84P / 18F).

### Pre-iter-26 next-action history (preserved)

**Iter 25: Implement the three iter-24 fixes, then re-run sweep.**

### Task A — Fix `MainOffenseStrength` Java-fidelity bug (small)
`odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
```odin
// BEFORE
strength: i32 = unit_attachment_get_attack_no_player(ua)
// AFTER
strength: i32 = unit_attachment_get_attack(ua, unit_get_owner(unit))
```
Mirror the existing defense-side, which already calls
`unit_attachment_get_defense(ua, owner)`.

### Task B — Fix `Integer_Map_Unit` LinkedHashMap order (small)
`odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin:4`:
```odin
Integer_Map_Unit :: struct {
    entries:    map[^Unit]i32,
    keys_order: [dynamic]^Unit,   // NEW — parallel LinkedHashMap order
}
```
Then audit every write site of `Integer_Map_Unit.entries` and
keep `keys_order` synchronized at put/clear/remove. Critical writers:
- `available_supports_support_details_new` and `_new_copy` in
  `available_supports/support_details.odin`
- Anywhere else that does `imu.entries[k] = v` for the first time
  (grep `\.entries\[` in `odin_flat/` filtered to `Integer_Map_Unit`
  context). The IDE rename would also catch struct-literal writers.

Then rewrite `available_supports_get_next_available_supporter`
(`available_supports.odin:78-95`) to pick `details.support_units.keys_order[0]`
(after dropping any 0-count keys via a single forward scan), so
behavior matches Java's `LinkedHashSet.iterator().next()`.

### Task C — Fix `Available_Supports.units_giving_support` LinkedHashMap order (medium)
`available_supports.odin:10`: add a parallel insertion-order slice:
```odin
Available_Supports :: struct {
    support_rules:                map[...][dynamic]^Unit_Support_Attachment,
    support_units:                map[...]^Available_Supports_Support_Details,
    units_giving_support:         map[^Unit]^Integer_Map,
    units_giving_support_order:   [dynamic]^Unit,   // NEW
}
```
Insertion sites:
- `available_supports.giveSupportToUnit` — append `supporter` to
  the order slice on first insertion into `units_giving_support`.
- `support_calculator_get_combined_support_given` — when iterating
  `support_from_friends` / `support_from_enemies`, walk the
  `units_giving_support_order` slice instead of bare map keys.

After these three fixes:
1. Rebuild `/tmp/snaprun`.
2. Confirm snap 0032 deterministic (10 individual runs all PASS).
3. Re-run individual snap 0024 with `timeout 300` to see new
   behavior (could PASS, could FAIL with different tally).
4. Re-run full 104-snap sweep at `-P 8` with 420s cap; record
   new pass/fail tally.

### Task D — If snap 0024 still red after iter-25
Per java-fidelity rule, the bug is deeper than support-iteration.
Next candidates in descending `method_layer`:
- `CasualtySelector#getDefaultCasualties` (layer 16) — wraps
  `CasualtyOrderOfLosses`; the body itself may have a divergent
  control-flow path (e.g. early-return in `auto_choose_casualties`
  branch). Drill its body.
- `CasualtyOrderOfLosses#sortUnitsForCasualtiesWithSupportImpl` —
  iter-23 fixed support storage; verify the surrounding logic
  (`add_remove` undo-loop, `keep_lowest_strength_first` flag,
  etc.) is byte-for-byte Java-faithful.
- `MainDefenseStrength.isDominatingFirstRoundAttack` —
  WW2v5 has no "first round attack only" units AFAIK, but verify.

### Pre-iter-25 next-action history (preserved)

**Iter 24 (planned and executed): Read-only orchestrator drill.**
Confirmed sweep, drilled 2 L9 yellows green-for-snap-0024,
identified 3 new fixes (planned for iter 25). No code changes.

**Iter 24 prior next-action draft (preserved):**
**Iter 24: Two parallel verification tasks once the iter-23 sweep
finishes.**

### Task A — analyze sweep results (5 min)
```sh
for f in /tmp/snap_results_iter23/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```
Expected outcomes per snap (compare against iter-21 baseline):
- **same PASS** → green for both iters, no concern.
- **iter-21 PASS → iter-23 FAIL** → REGRESSION; investigate (the
  refactor changed observable behavior here in a way that
  diverges from Java).
- **iter-21 FAIL → iter-23 PASS** → win, mark snap done.
- **iter-21 FAIL → iter-23 FAIL** → still divergent at L9; descend
  to next yellow dep (see Task B).
- **iter-21 PASS → iter-23 TIMEOUT** → likely just slow; bump
  per-snap cap and re-run individually.
- **iter-21 TIMEOUT → iter-23 PASS/FAIL** → workload-shape change,
  same analysis tier as PASS.

### Task B — snap 0024 deeper drill
If snap 0024 is still red after the iter-23 refactor:
1. Run with `timeout 1200` (20 min) to confirm whether it eventually
   converges to PASS, FAIL with different tally, or genuinely
   diverges.
2. If it diverges, the next yellow L9 dep is the Java HashMap-order
   bug in `CasualtyUtil.getDependents` (Java line 30):
   `final Map<Unit, Collection<Unit>> dependents = new LinkedHashMap<>();`
   Odin port (`odin_flat/.../casualty_util.odin:25`) uses bare
   `map[^Unit][dynamic]^Unit` → still pointer-hash iteration order.
3. Or the next layer up — `Player#selectCasualties` →
   `DummyPlayer.selectCasualties` (Java DummyPlayer.java:189-247);
   gap analysis was captured in iter 22 notes (defender side
   harmless because `keep_one_land=false` hardcoded; attacker
   side requires verifying the
   `attacker_keep_one_land_unit` flag value at the snap-0024
   battle_calculator construction site).

### Task C — performance budget review
The iter-23 refactor exposed a 30–60× slowdown in some snaps. If
snap regression catches a real timeout regression (not just slow),
profile the casualty-selection hot path:
- The N=11 defender loop in `casualty_order_of_losses_sort_…_impl`
  is O(N² × M) where M = average support fan-out per unit.
- Java JIT optimizes this; Odin debug build does not. Consider
  building with `-o:speed` (`-o:size` makes it worse) for
  regression sweeps if the timeouts persist.

### Pre-iter-24 next-action history (preserved)

**Iter 23 (planned and executed): Refactor `unit_support_power_map`
/ `unit_support_rolls_map` from `map[^Unit]Integer_Map` to
`map[^Unit]^Integer_Map` so Integer_Map lives on the heap and
mutations propagate without write-back.** (Done — see "Last action".)

### Why
Iter 22 proved the iter 21 keys_order field is correctly
maintained inside Integer_Map, but is lost whenever an
Integer_Map is stored BY VALUE inside another map. Odin maps
copy values on read; `[dynamic]` descriptors that get appended
inside a local copy never write back. The only safe storage
pattern for "Java reference-typed value inside a Map" is to use
a pointer.

### Concrete files to change

1. `odin_flat/games__strategy__triplea__delegate__power__calculator__power_strength_and_rolls.odin`
   - Lines 13-14: `map[^Unit]Integer_Map` → `map[^Unit]^Integer_Map`
   - Lines 53, 59: getter return type
   - Lines 73, 79: lambdas `_add_units_0` / `_2` — return `^Integer_Map`
     constructed via `integer_map_new()`
   - Lines 86-96, 109-118: lambdas `_add_units_1` / `_3` — drop the
     value-copy idiom; pass the stored pointer directly to
     `integer_map_add_map`
   - Lines 196-197: init `make(map[^Unit]^Integer_Map)`

2. `odin_flat/games__strategy__triplea__delegate__battle__casualty__casualty_order_of_losses.odin`
   - All `support_power_for_unit := unit_support_power_map[u]`
     and `support_rolls_for_unit := …` sites: receive `^Integer_Map`,
     drop the `&` when calling `integer_map_key_set` etc.
   - `in unit_support_power_map` checks unchanged (still keyed by ^Unit).
   - `delete_key(&unit_support_power_map, worst_unit)` unchanged.

3. `odin_flat/games__strategy__triplea__delegate__power__calculator__aa_power_strength_and_rolls.odin`
   - Inspect for identical pattern; apply same refactor if present.

### After refactor
- Build: `odin build conversion/odin_tests/server_game_run_next_step
  -collection:flat=../odin_flat -collection:test_common=conversion/odin_tests/test_common
  -build-mode:test -out:/tmp/snaprun -extra-linker-flags:-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib`
- Test snap 0024 with `timeout 600` (allow 10 min; if Java-faithful
  support truly is heavier, this is real, not a hang).
- If snap 0024 passes, re-run the 104-snap regression sweep.
- If snap 0024 STILL diverges (different output, not timeout),
  return to the trace table — drill the next yellow dep below.

### Backup descent path (if iter 23 doesn't fix snap 0024)

Resume L8 drill in descending-layer order:
- `CasualtySelector#getDefaultCasualties` (layer 16)
- `Player#selectCasualties` (layer 17) — abstract; descend via
  override (`DummyPlayer.selectCasualties` is NOT yet ported in
  Odin — see iter-22 trace below for the gap analysis).
- `CasualtyUtil#getDependents` (layer 6) — uses LinkedHashMap;
  Odin port at `odin_flat/.../casualty_util.odin:25` uses bare
  `map[^Unit][dynamic]^Unit` → still pointer-hash. Add a parallel
  `[dynamic]^Unit` recorded at insertion.
- `CombatValue#getEnemyUnits` / `getFriendUnits` (layer 0,
  abstract) — descend via concrete `MainOffenseCombatValue` /
  `MainDefenseCombatValue` impl.

### Iter 22 trace data — DummyPlayer.selectCasualties gap

Java `DummyPlayer.selectCasualties` (lines 189-247) has two
conditional tweaks beyond the default Player implementation:
  (a) `keepAtLeastOneLand`: swap last-killed land for cheapest
      non-land
  (b) `orderOfLosses`: override default casualty order
Without either flag, Java returns `defaultCasualties` unchanged
— identical to Odin's nil-vtable fallback in
`player_select_casualties` (player.odin:294-332). Defender side
of `dummy_delegate_bridge_new` hardcodes `false` for
`keep_one_land_unit` (line 113); attacker side takes it as a
parameter. **TODO before iter-24:** verify what value
`battle_calculator` passes for `attacker_keep_one_land_unit` in
snap 0024's UkrSSR sims. If `true`, port DummyPlayer.selectCasualties
(install a vtable slot on Dummy_Player → Abstract_Ai). If
`false`, this is a parity gap to fix later but not snap 0024's
cause.

### Prior next-action history (preserved)

**Iter 22 (planned but mostly diagnostic):** Resume L8 casualty-
selection drill. The `Integer_Map` LinkedHashMap fix (iter 21)
is structural and necessary but did not by itself fix snap 0024.
Re-classify `casualty_selector_select_casualties` from
green-by-mt-fix back to yellow, then descend into its still-yellow
deps in descending `method_layer` order from port.sqlite:

```sql
SELECT d.depends_on_key, m.method_layer
FROM dependencies d
JOIN methods m ON m.method_key = d.depends_on_key
LEFT JOIN test_status ts ON ts.entity_key = d.depends_on_key
WHERE d.primary_key = '<selectCasualties key>'
  AND m.is_abstract = 0
  AND COALESCE(ts.status,'yellow') = 'yellow'
ORDER BY m.method_layer DESC;
```

Top candidates (from iter 21 sqlite query):
- `CasualtySelector#getDefaultCasualties` (layer 16) — wraps
  CasualtyOrderOfLosses; iter 21 fixed the LinkedHashMap leak
  but not the higher-layer logic itself.
- `Player#selectCasualties` (layer 17) — abstract; descend via
  override to `AbstractAi#selectCasualties` /
  `ProAi#selectCasualties`.
- `CasualtyUtil#getDependents` (layer 6) — uses Map<Unit,
  Collection<Unit>>; HashMap-order risk again.
- `CombatValue#getEnemyUnits` / `getFriendUnits` (layer 0,
  abstract) — descend via concrete CombatValue impl (probably
  `MainDiceRoll`'s combat value).

Tier A classification: capture fixtures for
`CasualtyOrderOfLosses.sortUnitsForCasualtiesWithSupport` and
`CasualtySelector.getDefaultCasualties` via
`scripts/capture_proc_snapshot.py` then
`scripts/gen_replay_tests.py`. Re-run snap 0024 individually
after each green child to detect when the cumulative fix lands.

### Iter 20 next-action history (preserved)

**Iter 20: Drill into simulator internals to find why Odin's
`must_fight_battle_fight` produces a DIFFERENT outcome from Java
for the n_def=10 (no bomber) case with the same MT(42) dice.**

Why this is the next step:
- Iter 19 cleared `pro_territory_get_max_enemy_units` (Odin's
  10-attacker count is correct given correct adjacencies +
  artillery mov=1).
- Iter 19's widened `bc_run` probe shows Odin's simulator gives
  ATTACKER wins for the n_def=10 case (bomber removed). Java's
  observable behavior (after.json: bomber moved to Finland)
  REQUIRES Java's simulator to give DEFENDER holds for that case.
- So Java + Odin diverge on a single deterministic battle run
  with identical seed and identical units.
- Most likely causes (in order of likelihood):
  1. **Dice consumption order**: which unit rolls 1st, 2nd, ...
     within a round affects which random number it consumes.
  2. **Casualty selection order**: who dies first determines
     who keeps rolling next round.
  3. **Artillery support pairing**: which infantry is boosted
     by which artillery determines combined strength.
  4. **MersenneTwister output divergence**: Odin's MT(42) may
     not produce bit-for-bit identical outputs to Java's
     Apache Commons Math MT(42).

Plan:
1. Add MT-output verification probe: print first 30 nextInt(6)
   outputs from a fresh MT(42) in Odin. Run a tiny Java program
   that does the same. Compare. If they diverge, fix Odin's MT.
2. If MT outputs match: add per-round dice probe in
   `dice_roll_roll_dice` or wherever rolls happen for the battle.
   Dump (unit_type, owner, die_value, hit?) per roll per round.
3. Compare against Java's `DiceRoll.rollDiceLowLuck` or
   `DiceRoll.rollDiceNormal` (depending on which mode is on).
4. Fix the divergence per java-fidelity-rule.md.

Files of interest:
- `/odin_flat/games__strategy__triplea__delegate__must_fight_battle.odin`
  (`must_fight_battle_fight`, fight_loop)
- `/odin_flat/games__strategy__triplea__delegate__dice_roll.odin`
  (roll_dice / unit ordering for dice)
- `/odin_flat/games__strategy__triplea__delegate__casualty_selector.odin`
  (casualty_selector_select_casualties already inspected iter 18)
- `/odin_flat/games__strategy__engine__random__plain_random_source.odin`
  + `mersenne_twister.odin`
- Java refs:
  - `MustFightBattle.java#fightLoop` / `BattleStep` enum
  - `DiceRoll.java#rollDice` (LowLuck / Normal)

### Trace table (iter 24)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red (FAIL in 57s — was 600s timeout iter-23, faster after sweep finished and CPU pressure released) |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories`                                                | red    |
|  L3   | "Check if its worth defending" loop                                               | red    |
|  L4   | `pro_odds_calculator_calculate_battle_results_2` for UkrSSR                       | red    |
|  L7   | `must_fight_battle_fight` / fight_loop                                            | red    |
|  L8   | MT(42), dice order, art support, active_units                                     | green (iter 20) |
|  L8   | `casualty_selector_select_casualties`                                             | yellow |
|  L9   | `Integer_Map` LinkedHashMap (within and stored-by-value)                          | green (iter 21 + iter 23) |
|  L9   | `Player#selectCasualties` → `DummyPlayer.selectCasualties`                        | **green (iter 24 — Java fidelity verified: AI never sets `setKeepOneAttackingLandUnit`, defaults to false; orderOfLosses empty; identical to Odin nil-vtable fallback)** |
|  L9   | `CasualtyUtil.getDependents` HashMap-order                                        | **green for snap 0024 (iter 24 — no transports in UkrSSR battle, dependents values all empty; downstream consumer only uses per-key lookup, not iteration). Still divergent in the abstract; only safe-by-context for snap 0024.** |
|  L9   | `CombatValue` concrete impl (`Main_Offense_Combat_Value` / `Main_Defense_Combat_Value`) | **yellow with 3 specific suspects identified (iter 24, see "NEW Java-fidelity bugs" in Last action):** (1) `MainOffenseStrength` uses `_no_player`; (2) `Available_Supports.get_next_available_supporter` pointer-hash; (3) `Available_Supports.units_giving_support` outer-map pointer-hash. Hypothesis: #2 + #3 cause snap 0032 intermittency and may cause snap 0024 divergence cascade. Iter 25 fixes all three. |

### Trace table (iter 23 prior — preserved)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red    |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories` (Java 763 / Odin 3539)                         | red |
|  L3   | "Check if its worth defending" loop (Java 1086-1148 / Odin 4319+)                 | red |
|  L4   | `pro_odds_calculator_calculate_battle_results_2` for UkrSSR                       | red (iter 16) |
|  L5   | `pro_territory_get_all_defenders` / `pro_territory_get_max_enemy_units`           | green (iter 19) |
|  L5   | `pro_territory_manager_populate_enemy_attack_options` for UkrSSR                  | green (iter 19) |
|  L5   | `pro_odds_calculator_call_battle_calc` (Odin 144)                                 | green (iter 17) |
|  L6   | unit attribute lookup (atk/def/isAir/isSea per defender)                          | green (iter 17) |
|  L6   | RNG seeding (PlainRandomSource construction)                                      | green (iter 17) |
|  L6   | `battle_calculator_calculate` per-run loop                                        | green (iter 18) |
|  L7   | `must_fight_battle_fight` / fight_loop                                            | red (iter 19) |
|  L8   | MT(42) bit-fidelity vs Apache Commons Math                                        | **green (iter 20 — mt_self_test PASS for 1024 raw32 + 1024 each nextInt 6/12/8)** |
|  L8   | dice consumption order (`roll_dice_factory_roll_battle_dice`)                     | **green (iter 20 — first 10 dice for Russians round-2 = [0,1,1,3,3,0,0,2,0,3] = MT reference)** |
|  L8   | artillery support pairing                                                         | **green (iter 20 — 2 of 3 inf get str=2 boost, 1 inf stays str=1)** |
|  L8   | active_units order (`power_strength_and_rolls.build`)                             | **green (iter 20 — sorted descending by str/sides as expected; ties don't affect hit count when all in bucket share threshold)** |
|  L8   | casualty selection order (`casualty_selector_select_casualties`)                  | **red (iter 21 drill target)** |
|  L4   | `pro_battle_utils_estimate_strength_difference` for UkrSSR pass 1                 | green by inspection (iter 14) |
|  L4   | `pro_territory_get_eligible_defenders`                                            | green by inspection (iter 14) |
|  L3   | `ProSortMoveOptionsUtils.sortUnitMoveOptions`                                     | green |
|  L2b  | `move_units_to_best_territories` (Java 1264 / Odin 1450)                          | green |
|  L2c  | `prioritize_defend_options` (Java 557, filter loop Java 631)                      | green by Java fidelity (iter 13) |
|  L3   | upstream `populate_defend_options` / `enemy_attack_options`                       | yellow (recursive concern: defend_options uses enemy_attack_options) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                  | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                            | green (iter 9) |

### Trace table (iter 14)

| layer | proc / decision site                                                              | status |
|-------|-----------------------------------------------------------------------------------|--------|
|  top  | snap 0024 germanNonCombatMove                                                     | red    |
|  L1   | `pro_non_combat_move_ai_move`                                                     | red    |
|  L2a  | `move_units_to_defend_territories` (Java 763 / Odin 3539)                         | red (UkrSSR kept armour because worth-defending check passes) |
|  L3   | "Set enough units" pass 1 (Java 807 / Odin 3704)                                  | **green** (commits 4 armour to UkrSSR per design; Java also does this) |
|  L3   | "Set non-air units" pass 2 (Java 830 / Odin 3768)                                 | green (iter 12) |
|  L3   | "Set air units" pass 3 (Java 871)                                                 | yellow (no role in armour swap) |
|  L3   | **"Check if its worth defending" loop (Java 1086-1148 / Odin 4319+)**             | **red (iter 15 drill target via territory_value_map)** |
|  L4   | `pro_battle_utils_estimate_strength_difference`                                   | **green by inspection** (formula matches Java line-by-line at Odin 297) |
|  L4   | `pro_territory_get_eligible_defenders`                                            | **green by inspection** (matches Java line-by-line at Odin 503; composition correct — 3 Germans inf + 1 armour at UkrSSR before adds) |
|  L4   | `pro_territory_get_max_enemy_units`                                               | **green by inspection** (10 Russian attackers match probe + snap before.json: 3 inf + 2 art + 3 armour + 2 fighter) |
|  L4   | `pro_odds_calculator_calculate_battle_results` (min_battle)                       | green (returns tuvSwing=6 hasLandRem=true; matches expected for 4v10 with attacker profit) |
|  L4   | **`pro_territory_value_utils_find_territory_values`** (Java `ProTerritoryValueUtils#findTerritoryValues`) | **red (iter 15 drill target — Odin returns UkrSSR=53.609 vs sources avg 14.957; Java must return ≤ sources avg for the strategic-value escape clause to trigger)** |
|  L3   | `ProSortMoveOptionsUtils.sortUnitMoveOptions`                                     | green |
|  L2b  | `move_units_to_best_territories` (Java 1264 / Odin 1450)                          | green (would place 5 at Belorussia if armour were released from defend phase) |
|  L2c  | `prioritize_defend_options` (Java 557, filter loop Java 631)                      | **green by Java fidelity** (iter 13) |
|  L3   | upstream `populate_defend_options` / `enemy_attack_options`                       | green (iter 13 probe shows move_map_size=26, Belorussia present) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                  | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                            | green (iter 9) |
|  L3   | `pro_non_combat_move_ai_do_move`                                                 | green (iter 10) |
|  L3   | land-move pass (Java 1893 / Odin 2596)                                           | green (iter 9) |

### Loose ends from iter 7
- Re-run snaps 0073, 0089 with `timeout 300` to confirm pass/fail
  (still classified as "slow not regression").
- Bump per-snap timeout in `run_phase_snapshots_parallel.sh` and
  the parallel recipe in this file from 60s → 180s.

### Recipe to rerun the iter 7 sweep
```sh
cd triplea && rm -rf /tmp/snap_results && mkdir -p /tmp/snap_results
export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
ls conversion/odin_tests/server_game_run_next_step/snapshots/ | \
  xargs -P 6 -I{} sh -c \
    'timeout 180 env FILTER_SNAP={} ./server_game_test_iter9 \
     > /tmp/snap_results/{}.txt 2>&1; \
     echo "EXIT={}:$?" >> /tmp/snap_results/{}.txt'
for f in /tmp/snap_results/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```

(Note: switch to `server_game_test_iter9` from iter 9 onwards —
that binary contains the harmless land-move-pass ordering fix.)

### Known active hangs (NOT regressions)
- Snap 0021 (germanPurchase): pre-existing 3m7s purchase compute
  (per `next-steps.md` odds-calculator perf note). Not a hang per
  se, just very slow. Skip in fast sweeps.

### Iter 8 prior preserved (see Last action for details)

### Iter 6 prior preserved (see Last action for details)

### Iter 5 prior history (preserved)

Files of immediate interest if continuing snap 0017:
- `odin_flat/games__strategy__triplea__ai__pro__data__pro_territory_manager.odin`
  (where `enemy_attack_options` is populated)
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin:1172`
  (`prioritize_territories_to_defend`)
- `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin:1638`
  (`place_defenders`)

Instrumentation still in place: `PLACE_*` printfs in
`pro_purchase_ai_place_units` and `pro_purchase_ai_place`
(gated by `pname == "Russians"`). Remove via grep for
`is_russians_dbg` and `PLACE_PRIORITIZED_DUMP` etc when done.

### Iter 5 prior history (preserved)

**Switch strategy. The leaf-walking has hit a wall** because
the leaf proc matches Java line-by-line. The divergence must be
in surrounding state or another sibling proc not yet visited.
Two cheap pivots:

1. **Compare `placements` list state** between Java and Odin at
   the moment of fallback `getPlaceableUnits(Russia)`. Java's
   `getMaxUnitsToBePlacedFromFull` `countSwitchedProductionToNeighbors`
   branch ITERATES `self.placements` — if Java has MORE
   `UndoablePlacement` entries with `producer_territory=Russia`,
   it might compute `productionCanNotBeMoved` differently and
   eventually return 0. Add a printf at start of
   `abstract_place_delegate_get_max_units_to_be_placed_from_full`
   logging `len(self.placements)` and the (producer,
   place_territory, len(units)) of each, gated for Russia. Compare
   to expected Java state of 6 placements
   (4 at Caucasus + 2 at Russia).

2. **Bypass leaf-walk; try cluster-fix**: pick another red snap
   that is NOT a place-step (e.g. snap 0024 germanCombatMove,
   31s, "unit tally divergence") and see if its root cause is
   completely different. If 0024's root cause turns out to be the
   same as 0017's, the cluster of place-step snaps (0017, 0025,
   0040, 0041) will all benefit. If it's different, fix it in
   isolation and revisit 0017 later.

3. **Add the snapshot harness improvement**: change
   `unit_collection_get_units` to return a slice/view of the live
   `units` array instead of a copy, OR refactor every caller that
   iterates `player.getUnits()` during placement to re-query at
   each iteration (matching Java's `player.getMatches()` semantics).
   This alone won't fix 0017's gap but it is a known semantic
   divergence that may cascade-fix other place-step snaps.

**Recommendation for next iter**: tackle (1) first because it
finishes the 0017 drill, then (3) for cleanup. Keep the existing
instrumentation in `pro_purchase_ai_place_units` and
`abstract_place_delegate_get_max_units_to_be_placed_from_full`.

Alternative seeds (cluster by likely shared root):
- **0024/0025** (germanCombatMove / germanPlace round 1): different
  delegate, may flush out a non-place-related bug pattern.
- **0040/0041** (americanPurchase/americanPlace round 1).
- **0021** (germanPurchase): canonical "PUs not spent". Slow (3m7s).

## Trace table

**Iter 61 — characterized all 13 remaining RED + seeded a fresh
descent on snap 0038 (japaneseCombatMove).** First-divergence per red
snap (from `/tmp/iter61_diag` + `/tmp/iter61_full`):
- **0038** `territories.Soviet Far East.owner: 'Russians' != 'Japanese'`
  — Odin fails to AMPHIBIOUSLY conquer the undefended Soviet Far East.
  Inputs ALL present in before.json: Japanese transports in 60 Sea
  Zone (+battleship+destroyer) and 61 Sea Zone (+destroyer), cargo
  (4 infantry, 1 artillery, 1 armour) in Japan, target Russian +
  EMPTY, adjacent via 63 Sea Zone. After: Soviet Far East = Japanese
  {artillery, infantry}. Genuine AI port divergence (not a harness
  gap). **← NEW DESCENT TARGET (cleanest single-field symptom).**
- **0097** `players.Americans.resources[PUs]: 1 != 19` (americanPurchase r2) — purchase/resource accounting.
- **0031** britishBattle r1 — unit tally (17 Sea Zone naval battle: Odin keeps British fighter, loses German battleship+transport; Germany factory damage 2→0). Battle-resolution divergence.
- **0074** unit tally — German subs Java→22 Sea Zone vs Odin→18 Sea Zone; bomber Java→Russia vs Odin→United Kingdom. Move-selection divergence.
- **0040 0048 0065 0075 0084 0090 0092 0100** — unit tally; several timed out at 320 s (need longer per-snap timeout to capture full diff). Characterize next.

| layer | method_key |
|------:|------------|
|  snap | **0038 japaneseCombatMove RED** — amphib CONQUEST works (iter-62). Divergence is pure CARGO: Odin loads SFE transport with {armour, infantry m3}, Java with {artillery, infantry m4}. Alaska is a RED HERRING (iter-64): `after.json` shows Alaska stays AMERICAN in BOTH (the iter-63 AMPHIB→Alaska lines were a non-final planning iteration); only SFE diverges. |
|  29   | proc:games.strategy.triplea.ai.pro.ProCombatMoveAi#doMove (layer 29) — descent parent. |
|  ~~27~~ | ~~proc:ProCombatMoveAi#tryToAttackTerritories~~ — **EXONERATED for the Alaska theory (iter-64).** Java does NOT attack Alaska (60 SZ transport stays home); both Java & Odin run a single SFE amphib assault. The transport→destination loop is not the lever. |
|  26   | ~~proc:ProTransportUtils#getUnitsToTransportFromTerritories / selectUnitsToTransportFromList (cargo selection)~~ — **EXONERATED (iter-65).** Real transportCost: inf=2, artillery=3, armour=3, capacity=5. `CARGO_PRE` probe proves the pre-sort gather for `loadFrom=[Japan]` is STABLY `[inf×4,artillery,armour]` (artillery before armour, matching before.json); the comparator/sort/select are faithful. armour is selected ONLY when Japan's artillery is already in the ignore set (`ignored=2`) so Japan gathers only armour and the next artillery comes from Kwangtung (sorts after Japan). The cargo BODY is correct — the divergence is in its INPUT (the ignore set). |
|  ~~25→back-up~~ | **EXONERATED as the locus (iter-66): the ignore set is a SYMPTOM, not the bug.** The ignore set contains Japan's artillery because Odin commits a 60 SZ→Alaska amphib (consuming it) BEFORE the SFE commit. The amphib loop, reset, unit-assignment (sorted keys), and unload-dest (java_hashmap bucket) in `tryToAttackTerritories` (layer 27) are all FAITHFUL line-by-line vs Java. So the bug is NOT in layer 27's body. |
|  28 ↑BACK-UP | ~~`ProCombatMoveAi#determineTerritoriesToAttack` (layer 28)~~ — **iter-66 hypothesis WRONG (corrected iter-67).** Java DOES attack Alaska in snap 0038 (JPROBE_COMMIT round=1: `Alaska=[infantry,artillery]`), so Java does NOT remove Alaska here. Alaska's attack just doesn't conquer (stays American). Not the divergence locus. |
|  26→FIXED | ~~`ProTransportUtils#getUnitsToTransportFromTerritories` load-from territory ORDER (iter-67 ROOT CAUSE)~~ — **FIXED in iter-68.** Was: armour & artillery TIE on cost AND attack, so the STABLE cargo sort preserves the load-from territory order; Java's `ProTransport.transportMap` value is a LinkedHashSet fed from a HashSet (accumulated bucket order), Odin sorted ALPHABETICALLY. Fix: added insertion-ordered `transport_map_order` to Pro_Transport, sort each `addTerritories` call's load set by Java HashMap bucket order, accumulate with LinkedHashSet dedup, and read the ordered list at the combat amphib commit. RESULT: SFE cargo TYPE now correct (artillery+infantry) and source-territory diff (Manchuria/Kiangsu) GONE. NOTE: a single bucket-sort of the final set was NOT enough (`Manchuria,Kwangtung,Kiangsu,Japan` ≠ Java `Kwangtung;Kiangsu;Japan;Manchuria`); per-call accumulation required. |
|  <26→FIXED | ~~**amphib-unload movement accounting — cargo lands with `already_moved=3` (Odin) vs `4` (Java)** (iter-68 NEW BOTTOM ROW)~~ — **ROOT CAUSE FOUND + FIXED in iter-69.** Java's `ChangeFactory.markNoMovementChange(Collection<Unit>)` overload (the one used by MovePerformer via `markNoMovementChange(Set.of(unit))`) GUARDS each reset with `if (getMovementLeft() >= 0)`. Amphib-unloaded cargo has over-accumulated (already_moved=3 > max=1 ⟹ movementLeft=-2 < 0), so Java SKIPS the reset (leaves 3), then `markMovementChange` adds the unload cost (1) ⟹ 4. Odin's 3 MovePerformer call sites called the UNGUARDED single-unit proc → reset to max+1=2 → +1 ⟹ 3. FIX: added the `unit_get_movement_left(unit) >= 0` guard at those 3 sites in `move_performer.odin`. Confirmed via JPROBE_0038 oracle data. RESULT: SFE infantry/artillery rows GONE (already_moved=4 ✓). |
|  <26 NEW (air) | **air-move DESTINATION divergence — 4 fighter rows (iter-69).** After the iter-69 movement-accounting fix, snap 0038's ONLY remaining tally diff is fighters: `30 Sea Zone fighter Moves=1 Exp=1 Act=0`, `Burma fighter Moves=1 Exp=1 Act=0`, `Burma fighter Moves=2 Exp=1 Act=2`, `Yunnan fighter Moves=1 Exp=0 Act=1`. **iter-71 LOCALIZED via AIR_PROBE/CSL probes in `pro_combat_move_ai_determine_units_to_attack_with` (air block ~2980) + `can_air_safely_land_after_attack` (~265).** Odin's combat-move air choices (all win%=100 ⟹ FIRST safe territory in priority-iteration order wins): Manchuria-ftr→Anhwei(d1), Japan-ftr→Buryatia(d2; Anhwei d3 unsafe), **FIC-ftr→Yunnan(d1; Anhwei d3 unsafe, Yunnan & Burma BOTH d1 safe)**, 50SZ-ftr→none(Yunnan/Burma d3 unsafe). Java expects the FIC fighter at **Burma** (Exp=1), NOT Yunnan (Exp=0). EXONERATED this pass: (a) `can_air_safely_land_after_attack` is LINE-BY-LINE faithful to `ProCombatMoveAi.java:2115` (isAdjacentToAlliedFactory ∥ distance ≤ range/2; range=movementLeft, distance=getDistanceIgnoreEndForCondition); (b) the territory iteration order is faithful — `tryToAttackTerritories` (`ProCombatMoveAi.java:1374`) rebuilds each unit's value set as a `LinkedHashSet` in `prioritizedTerritories` order (NOT the upstream `HashSet` from `ProTerritoryManager.java:1062`), so Odin's `sorted_territory_keys_by_priority` matches. The FIC fighter has Yunnan & Burma BOTH dist=1/win=100/safe — the ONLY differentiator is the PRIORITY ORDER of Yunnan vs Burma. Odin orders `[Anhwei;Yunnan;Burma]`, Java must order `[Anhwei;Burma;Yunnan]`. ⟹ the bug is UPSTREAM in attack-territory prioritization. |
|  <26 NEW (prio) | **NEW BOTTOM ROW (iter-71): attack-territory PRIORITY order — Yunnan vs Burma.** The FIC fighter's destination is decided purely by which of Yunnan/Burma comes first in `prioritized_territories` (both dist=1, win=100, land-safe). Odin puts Yunnan before Burma; Java the reverse. NEXT (iter-72): drill `ProCombatMoveAi#prioritizeAttackOptions` (the territory value/sort that builds `prioritizedTerritories`). Get Java ground truth on the round-1 Japanese combat-move prioritized-territory list (probe the ordered list + each territory's `ProTerritory.getValue()` / attack-value sort keys → write to `/tmp/jprobe_0038.txt`), diff vs the Odin `DUA_PT` order (PLAN_PROBE already prints `DUA_PT ... value=`). Find the comparator field where Yunnan/Burma tie-break diverges and port it faithfully. method_layer < air block. AIR_PROBE/CSL probes are gated (`when AIR_PROBE`), left in place per the PLAN_PROBE convention. |
|  layout | **Pointer-order determinism bug (iter-64) — the actual root.** Same binary run twice → IDENTICAL 12-line divergence (deterministic per-binary). But iter-63 `plan3` build → 1-territory divergence (SFE only); logically-equivalent `plan4` build → 8-territory divergence (fighters→Burma/Yunnan/30SZ, Japan armour+infantry, Kiangsu, Kwangtung, SFE). ⇒ the Pro combat-move planner's outcome depends on pointer-hash map/set iteration order (memory layout), not a Java-faithful key ordering. `pro_determinism_sorted_territory_keys` / `java_hashmap_bucket_for_string` cover SOME sites, not all. NEXT (iter-65): find the uncovered pointer-keyed iterations on the snap-0038 combat path (start: territory unit-collection order after simulate-move/undo; then `transport_map_list`/`amphib_attack_options`/`attack_map`) and port each to Java's hash-bucket/stable-key order. Faithful port only — NOT an invented tie-break. |

**Iter 61 trace (snap 0038, pre-iter-64) — superseded above:**

| layer | method_key |
|------:|------------|
|  27   | proc:ProCombatMoveAi#tryToAttackTerritories (layer 27) — iter-63 thought the Alaska/SFE amphib pairing was the lever; iter-64's after.json analysis disproved it (Alaska un-attacked in both). |

**Iter 60 (RESOLVED) — snap 0024 descent, layers 29c–29f closed:**

| layer | method_key |
|------:|------------|
|  29f  | **ROOT CAUSE (iter-60) — RESOLVED.** Snapshot harness never serialized `BattleTracker.conquered`; Odin's tracker was empty so `was_conquered("Ukraine S.S.R.")=false` where Java (just-conquered, round-1) returns true. Fix: `GameStateJsonSerializer.serializeBattleTracker` emits `{"conquered":[…]}`; Odin harness replays it into the battle delegate after registration (`test_server_game.odin` + `json_loader.odin` + `snapshot_runner.odin`); snapshots regenerated. snap 0024 now `before.json battleTracker.conquered=["Belorussia","Ukraine S.S.R."]`. |
|  29e  | proc:ProTerritoryManager#findAirMoveOptions — **RESOLVED (iter-60).** Odin admitted Ukraine air ONLY because the empty tracker made `airCanLandOnThisAlliedNonConqueredLandTerritory(Ukraine)=true`. With `conquered` populated it returns false (matching Java); the port itself was faithful. |
|  29d  | proc:ProTerritoryManager#populateDefenseOptions defender set — **RESOLVED (iter-60).** Air over-assign was the 29e/29f tracker gap. The "+3 infantry cantMoveUnits" was a RED HERRING (Java's `DEFROSTER round=1` also produces a `cantMoveN=4 {inf3}` row; both Java rows have maxN=5, no air). |
|  29c  | ~~determineIfMoveTerritoriesCanBeHeld~~ — **RESOLVED (iter-60).** Verdict math faithful; flipped only because of the 29f over-count. |

**Prior (now-closed) descent rows:**

| layer | method_key |
|------:|------------|
|  snap | **0024 germanNonCombatMove** — was RED (German armour Java→Belorussia vs Odin→Ukraine S.S.R.); GREEN after iter-60. |
|  29   | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove → simulateNonCombatMove (entry) |
|  ~~29a~~  | ~~moveUnitsToBestTerritories assignment loop~~ — **EXONERATED (iter-56, ARMOUR_TRACE landloop probes).** The land-assignment loop faithfully picks the max-value territory. Probe `landloop_terr` shows Odin values: **Belorussia=44.112 canHold=true, Ukraine S.S.R.=53.609 canHold=true** — Ukraine is genuinely higher-valued, so units flow there CORRECTLY given those inputs. Moreover `phase=after_defend` already shows Ukraine=armour4/bomber1/fighter2 and Belorussia=empty, so the armour split is decided in the DEFEND phase from territory VALUE, not in this leftover loop. The loop is not the divergence; the territory VALUE input is. |
|  29b  | ~~ProTerritoryValueUtils#findLandValue capitalOrFactoryValue~~ — **`capitalOrFactoryValue` EXONERATED (iter-57, JAVA_TVAL byte-identical: Belorussia 39.734, Ukraine 47.640).** The only divergent term in `value = nearbyEnemyValue·landMass/maxLandMass + capitalOrFactoryValue` is **Belorussia's `nearbyEnemyValue` (Java 6.250 vs Odin 5.500, Δ0.75)**. nbe breakdown: Java's Belorussia nbe includes Ukraine S.S.R. (d1, +1.0) and excludes Finland; Odin includes Finland (d2, +0.25) and excludes Ukraine. Root mechanism (JAVA_TVAL2): `territoriesThatCantBeHeld` membership is INVERTED — Java: Ukraine inCantBeHeld=true / Finland=false; Odin: Finland=true / Ukraine=false (both owner=Germans, isEnemyRaw=false, so they only enter via the cantBeHeld branch). Producer = `getCantHoldTerritories()` (`ProTerritoryManager.java:333`) = defend-map territories with `isCanHold()==false`. (All downstream of the 29f tracker gap — RESOLVED iter-60.) |
|  ~~28~~  | ~~prioritizeDefendOptions filter~~ — **EXONERATED (iter-55).** Both Java and Odin remove Belorussia on `isNotFactoryAndShouldHold` (tuvSwing=0.000 ≤ 0). Java's `JAVA_MINRES` confirms identical filter inputs. NOT the divergence. |
|  ~~27~~  | ~~minBattleResult population~~ — **EXONERATED (iter-55, PROVEN byte-identical).** Java `JAVA_MINRES` and Odin `ARMOUR_TRACE minres` both compute Belorussia `atk={armour=3,fighter=2}(5) minDef={armour=1,infantry=2}(3) tuvSwing=0.000 winPct=100.0 rounds=1.0` and Ukraine `tuvSwing=6.000`. The min-result and odds calculator are NOT the divergence. iter-54's "min-result is the lever" conclusion is WRONG — both sides agree on the min-result; the redistribution happens downstream in the assignment loop. |

## Trace table (prev iter 49 — Approach A, superseded by iter 52)

**Iter 49 — Approach A Java side SHIPPED. The 21 keyed-collection
fields below are now TreeMap/TreeSet with serializable UUID/name
comparators; 104 snapshots regenerated + swapped; snap 0001 PASS.
The remaining RED rows stay RED until the iter-50 Odin
sort-at-iteration lands. NOTE: the iter-48 "Java is FULLY
content-deterministic across runs" claim is corrected — Unit.id is
random per JVM run; determinism holds only WITHIN a snapshot set
(frozen UUIDs), which is exactly why regen was required.**

| layer | method_key |
|------:|------------|
|  ALL  | **DONE (iter 49)**: 21 `Map<Unit,…>`/`Set<Unit>`/`Map<Territory,…>`/`Set<Territory>` fields in `ai.pro.data.*` + `ai.pro.ProData` (5 files) → TreeMap/TreeSet via `ProDeterministicOrder` factories (serializable `UNIT_BY_UUID` / `TERRITORY_BY_NAME` comparators). Build OK; snaps regenerated. |
|  ALL  | **REFACTOR TARGET (iter 50)**: ~30 Odin iteration sites where order influences AI decisions; sort-at-iteration using existing `pro_determinism_sorted_unit_keys_with_uuid` / `pro_determinism_sorted_territory_keys` helpers |
|  ALL  | **DEFERRED (iter 51)**: ~100 Java local-variable / stream-chain iteration sites; only those where order affects state |
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — **RED until iter 50 Odin fix** |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED until iter 50** |
|  29a-i  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToBestTerritories — RED (writes pt.units + pt.amphib_attack_map at sea zones non-deterministically on Odin side; iter 50 fix is sort-at-iteration of pt fields) |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateMoveRoutes — RED until iter 50 |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — RED until iter 50 |

## Trace table (prev iter 48)

**Iter 48 — STRATEGY PIVOT to Approach A (uniform sort-by-UUID on
BOTH Java + Odin sides; snapshot regen required). Pattern-matching
single-site sort fixes EXHAUSTED at iter 47 (5 prior iterations, 9+
sort sites added, no convergence). Java is FULLY content-deterministic
(Unit.hashCode = UUID, Territory.hashCode = name); all flakiness is
Odin-side raw-pointer-keyed map iteration. Per-site forensics required
to distinguish LinkedHashMap-insertion vs HashMap-bucket iteration
order; type-system enforcement (TreeMap/TreeSet keyed on UUID/name
comparator) makes both sides match by construction without
per-site analysis. Scope: AI Pro layer only (S2); regen all 104
snapshots.**

| layer | method_key |
|------:|------------|
|  ALL  | **REFACTOR TARGET (iter 49)**: 24 declared `Map<Unit,…>` / `Set<Unit>` / `Map<Territory,…>` / `Set<Territory>` fields in `games.strategy.triplea.ai.pro.data.*` (5 files) → swap LinkedHashMap/HashMap/LinkedHashSet/HashSet for TreeMap/TreeSet with `ProDeterministicOrder.UNIT_BY_UUID` / `TERRITORY_BY_NAME` comparator |
|  ALL  | **REFACTOR TARGET (iter 50)**: ~30 Odin iteration sites where order influences AI decisions; sort-at-iteration using existing `pro_determinism_sorted_unit_keys_with_uuid` / `pro_determinism_sorted_territory_keys` helpers |
|  ALL  | **DEFERRED (iter 51)**: ~100 Java local-variable / stream-chain iteration sites; only those where order affects state |
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — **RED until iter 50 Odin fix** |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED until iter 50** |
|  29a-i  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToBestTerritories — RED (writes pt.units + pt.amphib_attack_map at sea zones non-deterministically on Odin side; iter 50 fix is sort-at-iteration of pt fields) |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateMoveRoutes — RED until iter 50 |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — RED until iter 50 |

## Trace table (prev iter 47)

**Iter 47 — TWO distinct leak surfaces fully localised via
`MOVE_ROUTES_DIGEST` probe. (a) `calculate_move_routes` SZ 63
transport routing differs (LEAK D NEW). (b) `calculate_amphib_routes`
loaded-unit / destination flip (LEAK A residual). Both proven UPSTREAM
of the route calculators — `pt.units` and `pt.amphib_attack_map` at
SZ 60, 61, 62, 63 differ across runs. Iter-42 MOVE_PLAN was incomplete
(filtered land destinations only). Iter-48 must add PLAN_INPUT_DIGEST
at NCM-planner exit to localise which sub-proc populates the differing
sea-zone Pro_Territory state.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — **RED, leak confirmed at NCM-planner-exit; sea-zone Pro_Territory state differs across runs** |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED, INPUTS differ** (route calculators receive different `pt.units` / `pt.amphib_attack_map` at sea zones 60-63) |
|  29a-i  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToBestTerritories (l.1479) — **RED, iter-48 PRIMARY suspect** (populates pt.units + pt.amphib_attack_map at attack/defence sea zones) |
|  29a-ii | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToDefendTerritories (l.3628) — **RED, iter-48 secondary suspect** |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateMoveRoutes (l.204) — **RED, LEAK D (NEW)** (SZ 63 transport routes to SZ 60 in some runs, SZ 62 in others; leak is in INPUT pt.units, not proc body — iter-48 PLAN_INPUT_DIGEST to confirm) |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes (l.439) — **RED, LEAK A residual** (iter-43 stable_sort + UUID tiebreak insufficient; input `pt.amphib_attack_map` differs across runs at SZ 60-63) |
|  29d  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombardMoveRoutes — GREEN (preemptive iter-43 stable_sort fix; not on snap-0089 critical path) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — GREEN at phase-PU level |
|  27a-d  | ProPurchaseAi#purchaseSeaAndAmphibUnits + purchaseLandUnits + purchaseDefenders + purchaseFactories — GREEN (iter-44/45 9-site sort fixes) |
|    27 | ProPurchaseAi#prioritizeSeaTerritories — GREEN (iter 39) |
|    18 | ProPurchaseOption#calculateSupportFactor — GREEN (iter 34) |
|    18 | ProPurchaseUtils#randomizePurchaseOption — GREEN (iter 33) |

## Trace table (prev iter 46)
Japan unit-set differs in 4 distinct outcomes across 5 ASLR runs
(n=2,3,3,4,5). NCM-exit digest == purchase-entry digest ⇒
divergence is fully NCM-introduced; purchase-AI layer 27a–d
already stabilised by iter-44/45 sort fixes. Root layer is layer
29a `do_move` (or its planner inputs); iter-47 must localise
which `move_*` sub-proc populates `Pro_Territory.units`
nondeterministically.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — **RED, iter-46 confirmed leak** (NCM_END_STATE digest varies across runs; planner-level fix needed) |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED** (still primary suspect; planner output to do_move differs ⇒ leak is in move-planning procs, not do_move itself) |
|  29a-i | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToBestTerritories (l.1479) — **RED, iter-47 primary suspect** (populates Pro_Territory.units; pointer-keyed map iteration likely) |
|  29a-ii | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveUnitsToDefendTerritories (l.3628) — **RED, iter-47 secondary suspect** |
|  29a-iii | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveOneDefenderToLandTerritoriesBorderingEnemy (l.372) — yellow |
|  29a-iv | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#prioritizeDefendOptions (l.3246) — yellow |
|  29a-v | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveInfraUnits (l.4707) — yellow |
|  29a-vi | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveConsumablesToFactories (l.1118) — yellow |
|  29a-vii | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#moveAlliedCarriedFighters (l.317) — yellow |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — YELLOW (iter-43 fix shipped: UUID tie-break + stable_sort; primary leak fixed but secondary leak likely amplifies NCM planner divergence) |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombardMoveRoutes — GREEN (preemptive iter-43 stable_sort fix) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — GREEN at phase-PU level |
|  27a  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — GREEN (iter-44 4-site sort fix) |
|  27b  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseLandUnits — GREEN (iter-45 l.3043 neighbours sort fix) |
|  27c  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseDefenders — GREEN (iter-45) |
|  27d  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseFactories — GREEN (iter-45) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — GREEN (iter 39 fix) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — GREEN (iter 34 fix) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — GREEN (iter 33 fix) |

## Trace table (prev iter 45)

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — GREEN at planner granularity |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED, iter-46 PRIMARY suspect** (4/5 runs identical at unit-set level; FAIL runs leave Japan with different unit_collection that flows into purchase_pool divergence) |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — YELLOW (iter-43 fix shipped: UUID tie-break + stable_sort; primary leak fixed but a secondary inner-loop nondeterminism may remain) |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombardMoveRoutes — GREEN (preemptive iter-43 stable_sort fix) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — GREEN at phase-PU level |
|  27a  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — GREEN (iter-44 4-site sort fix; no further internal divergence — inputs vary) |
|  27b  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseLandUnits — GREEN (iter-45 l.3043 neighbours sort fix; mirrors iter-44 l.3654) |
|  27c  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseDefenders — GREEN (iter-45 max_units_set + bombard_set UUID-sort) |
|  27d  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseFactories (can-hold loop) — GREEN (iter-45 max_units_set + bombard_set UUID-sort) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — GREEN (iter 39 fix shipped) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — GREEN (iter 34 fix) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — GREEN (iter 33 fix) |

## Trace table (prev iter 44)

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — GREEN at planner granularity |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — YELLOW (4/5 runs identical at unit-set level; run 5 still diverges) |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — YELLOW (iter-43 fix shipped: UUID tie-break + stable_sort; primary leak fixed but a secondary inner-loop nondeterminism remains in run 5) |
|  29c  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateBombardMoveRoutes — GREEN (preemptive iter-43 stable_sort fix) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — GREEN at phase-PU level |
|  27a  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — **YELLOW** (iter-44 4-site sort fix shipped; stock 2/5 → 3/5; residual 1 tied-float greedy decision still flipping — likely in SUPERIORITY loop's `randomize_purchase_option` or in upstream `purchaseLandUnits` which iter-45 must audit) |
|  27b  | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseLandUnits — **RED, iter-45 LEAK D suspect** (l.3043 `for nb, _ in neighbors` mirror of iter-44 fix at l.3654; populates `owned_local_units` for `attackEfficiency`/`defenseEfficiency`) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — GREEN (iter 39 fix shipped) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — GREEN (iter 34 fix) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — GREEN (iter 33 fix) |

Invariant satisfied (30 > 29 > 28 > 27 > 18). Layer 27a moved from RED
(iter 43 LEAK C target) to YELLOW (iter 44 fix shipped; residual). New
suspect: 27b (`purchaseLandUnits` has the same `for nb, _ in neighbors`
pattern at l.3043 that iter-44 just fixed at l.3654).

**Iter 42 — snap 0089 ASLR-flaky; NCM leak confirmed at
per-unit identity granularity. NCM_TRACE aggregate hash is
PROVABLY insufficient (all 5 runs in iter-41A have BYTE-
IDENTICAL hash but divergent AMPHIB outcomes). The iter-41B
binary (extra AMPHIB_PROBE alloc) shows own_n@Japan = 5, 3, 2
across 3 ASLR runs of the same binary, conclusively proving
the NCM physically moves a different number of units off Japan
depending on ASLR roll. Iter-42 must add per-unit identity
probe (NCM_UNITS) inside the NCM sub-phases to find the
specific pointer-keyed iteration. PASS rate iter-41A: 2/5.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — GREEN at planner granularity (iter-42 NCM_UNITS 00..08 + MOVE_PLAN all byte-identical across 3 runs) |
|  29a  | proc:games.strategy.triplea.ai.pro.ProNonCombatMoveAi#doMove — **RED, iter-43 SOLE TARGET** (iter-42 evidence: 09_after_doMove differs n=5/3/2 across 3 runs of SAME binary while 08b_before_doMove identical n=8) |
|  29b  | proc:games.strategy.triplea.ai.pro.util.ProMoveUtils#calculateAmphibRoutes — RED (prime suspect inside `doMove`; iterates pointer-keyed `amphib_attack_map`) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — GREEN |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — GREEN given inputs |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — GREEN (iter 39 fix shipped) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — GREEN (iter 34 fix) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — GREEN (iter 33 fix) |

Invariant satisfied (30 > 29 > 28 > 27 > 18). Layer 29 now split into
29 (planner = GREEN) and 29a/29b (executor = RED). Iter 43 attacks
29b (`calculateAmphibRoutes`) per iter-42 evidence.

**Iter 40 — snap 0089 ASLR-flaky; iter-39 fix verified, iter-39
"pre-amphib purchase PU leak" hypothesis REFUTED. Pre-amphib
purchase pipeline is FULLY DETERMINISTIC (PHASE_PUS at all five
boundaries identical 35→25 across 5 ASLR samples). Sole
residual flake source is the sim-walk NCM step
(`pro_non_combat_move_ai`): runs 2–5 produce DIFFERENT
`own_n@Japan` (2..5) and DIFFERENT `ptl_n` in adjacent
sea/land neighbors even when `own_n` happens to coincide.
Iter 40B PASS rate 1/4 on the iter-40 probe binary.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow (drives the NCM sim-clone whose output varies) |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — **RED, iter-41 SOLE TARGET** (iter-40 evidence: Japan-owned unit set delivered to amphib loop differs across ASLR runs at constant pre-NCM state) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — **GREEN at all 5 phase boundaries** (iter 40A: PHASE_PUS identical 35→25 across 5 runs) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — **GREEN at GATHER and at greedy loop** (iter 40B: `ttnu_n` identical across runs; `ptl_n` differs ONLY because of upstream NCM-driven neighbor state) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — **GREEN (iter 39 fix shipped — LinkedHashSet + stable_sort)** |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (30 > 29 > 28 > 27 > 18). All layers except
29 are now eliminated as flake sources. Iter 41 attacks layer 29
exclusively.

**Iter 39 — snap 0089 ASLR-flaky; 2/3 PASS on iter-39 binary
(up from baseline 1/2). Java-fidelity fix shipped:
LinkedHashSet semantics restored in `prioritize_sea_territories`;
both pertinent `slice.sort_by` calls upgraded to
`slice.stable_sort_by`. Two residual leaks suspected (sim-walk
NCM and pre-amphib purchase PU accounting). Run-1-vs-Run-3
evidence (same pre-amphib state, different final purchase)
suggested a purchase-side leak — **refuted in iter 40**.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — yellow (iter-39 evidence: NCM outcome ASLR-dependent in some samples) |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.ProNonCombatMoveAi#simulateNonCombatMove — yellow (iter-40 LEAK A target) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — yellow (iter-39 evidence: identical pre-amphib state still produces different purchase across ASLR runs) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — **GREEN at outer-loop boundary** (iter 39 evidence: same iteration sequence both runs; leak is in pre-amphib phases) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#prioritizeSeaTerritories — **GREEN (iter 39 fix shipped — LinkedHashSet + stable_sort)** |
|    27 | pre-amphib purchase phases (`purchase_aa_units`, `purchase_defenders_land`, `purchase_defenders_sea`, `purchase_land_units`, `purchase_factory`) — yellow (iter-40 LEAK B target) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (30 > 29 > 28 > 27 > 18). Iter 40 must
attack both yellow rows in parallel (sim-walk NCM at layer 29
and pre-amphib phases at layer 27).

**Iter 38 — snap 0089 ASLR-flaky; iter-37 hypothesis
falsified. Sim-walk loop is DETERMINISTIC across runs
(SIMSTEP trace identical: jCM 8→8, jBattle 8→8, jNCM 8→3).
Japan's unit composition at BEFORE_PRIO_SEA is identical
(aaGun, factory, armour). First divergent probe:
`AMPHIB_OUTER t=62 Sea Zone land=Japan` with `rem_prod=1`
(PASS) vs `rem_prod=3` (FAIL). Leak is in the purchase-phase
production accounting, downstream of sim-walk and upstream of
that AMPHIB_OUTER iteration.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — **GREEN** (iter 38: sim-walk steps deterministic) |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.\* (NCM / CM / move sim-clone steps) — **GREEN at boundary** (iter 38: SIMSTEP traces identical) |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent), PRIMARY SUSPECT |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — flaky (ASLR-dependent), CONTAINS LEAK BOUNDARY (iter 38 evidence: first divergent line is inside this function's outer loop) |
|    26 | amphib outer loop iteration / `sea_place_territories` order / per-iter `rem_prod` accounting — yellow, IDENTIFY VIA ITER-39 PROBES |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (30 > 29 > 28 > 27 > 26 > 18). Iter 39
must probe the layer-26 amphib loop entrance + per-iteration
`rem_prod` to find the source.

**Iter 37 — snap 0089 ASLR-flaky; leak DEFINITIVELY localized
to the sim-walk loop in `abstract_pro_ai.odin` (the AI's
pre-purchase simulation of NCM/CM/etc. on a cloned `data_copy`).
Japan's `unit_collection.units` count is CONSTANT across all 3
probe points within `pro_purchase_ai_purchase` (PURCHASE_ENTRY,
BEFORE_PRIO_SEA, SEA_ENTRY), but DIFFERS across ASLR runs at the
very entry. Direct caller: `abstract_pro_ai.odin` line ~824,
inside `for step in game_steps`.**

| layer | method_key |
|------:|------------|
|    30 | proc:games.strategy.triplea.ai.pro.AbstractProAi#purchase (sim-walk caller) — flaky, PRIMARY SUSPECT |
|    29 | proc:games.strategy.triplea.ai.pro.simulate.\* (NCM / CM / move sim-clone steps inside the sim-walk loop) — yellow, IDENTIFY VIA SIMSTEP PROBE in iter 38 |
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — **GREEN at function-boundary** (iter 37 evidence: n is constant within this function) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — **GREEN at function-boundary** (iter 36 evidence) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (30 > 29 > 28 > 27 > 18). Iter 38 must
identify which sim-walk step is the leak source.

**Iter 36 — snap 0089 ASLR-flaky; leak CONFIRMED upstream of
`purchase_sea_and_amphib_units` by `TERR_DUMP_JAPAN_ENTRY` probe.
Run 1 PASS: 4 Japan units at entry, sea-prio order [62,62,60].
Run 2 FAIL: 2 Japan units at entry (infantry+artillery already
moved away), sea-prio order [60,62,62]. Two divergences visible
simultaneously: (a) Japan's unit collection has been mutated
differently before purchase, and (b) the prioritized-sea-territory
ordering is itself ASLR-dependent.**

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent); SUSPECT layer (iter 37 probes inside) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — **GREEN at function-boundary** (iter 36 evidence: input state already divergent on entry) |
|    27 | proc:games.strategy.triplea.ai.pro.simulate / pro_non_combat_move_ai / pro_combat_move_ai — yellow, PRIMARY SUSPECT (mutates Japan unit collection before purchase) |
|    27 | sea-territory prioritization (whatever populates `prioritized_sea_territories`) — yellow, SECONDARY SUSPECT (order differs across runs) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (28 > 27 > 18). Iter 37 must probe inside
`pro_purchase_ai_purchase` to bisect the layer-27 suspects.

**Iter 35 — snap 0089 ASLR-flaky; leak located UPSTREAM of

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — green (verified deterministic given identical input state; iter 35 evidence) |
|    27 | proc:games.strategy.triplea.ai.pro.simulate.\* (NCM/CM sim-clone pipeline) — yellow, NEW SUSPECT (iter 36 to identify via TERR_DUMP_JAPAN probe) |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (28 > 27 > 18). Iter 36 demotes layer-27
suspect (NCM/CM sim-clone) further by narrowing TERR_DUMP_JAPAN
diff.

**Iter 34 — snap 0089 ASLR-flaky, another leak fixed at layer 18
(`calculate_support_factor`). Pass rate up from 20% (iter 33) to
60% (iter 34). Additional upstream leak remains that causes
`owned_local_amphib_units` count to differ across ASLR runs.**

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — yellow (outer Amphib loop suspected; iter 35 probes the `t`/`purchase_territory` iteration) |
|    26 | ??? (iter 35 will identify via AMPHIB_OUTER probe diff) — yellow, suspected leak |
|    18 | proc:games.strategy.triplea.ai.pro.data.ProPurchaseOption#calculateSupportFactor — **GREEN (iter 34 fix shipped: sort `rules_dyn` and `usa_keys` by attachment `.name` before float-sum; deterministic given identical inputs)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix at all 9 caller sites)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection |

Invariant satisfied (28 > 27 > 26 > 18). Iter 35 targets the
remaining layer-26/27 ordering leak.

**Iter 33 — snap 0089 ASLR-flaky, ONE leak fixed at layer 18,
others remain.** The `randomize_purchase_option` insertion-order
sum bug is patched. ASLR-on still fails 4/5 (1/5 PASS); another
pointer-keyed map iteration leaks downstream.

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — green via inspection |
|    26 | ??? (iter 34 will identify via PUR_TRACE-on-fix or lightweight probe) — yellow, suspected leak |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption — **GREEN (iter 33 fix shipped at all 9 caller sites; sum now matches Java LinkedHashMap insertion order)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#findPurchaseOptionsForTerritory — green via iter-33 inspection (loops dynamic array, deterministic) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions — green via iter-33 inspection (backward-index loop) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#findNumberOfConstructionTypeToPlace — green via iter-33 inspection (integer count, order-insensitive) |

Invariant satisfied (28 > 27 > 26 > 18). Iter 34 targets remaining
layer-18 candidates: efficiency calculators, battle/TUV utils,
carrier/transport accounting.

**Iter 32 — snap 0089 RECLASSIFIED as ASLR-FLAKY.** Iter-31's
PASS on snap 0089 was determined to be a per-process ASLR roll.
The same iter-31 binary produces PASS-PASS-PASS or PASS-FAIL-PASS
across reruns of the same single snap. Iter 32 did not change
code; restored byte-for-byte iter-31 state.

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase — flaky (ASLR-dependent) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits — green via iter-31 inspection (Java fidelity is correct here; the leak is downstream) |
|    26 | ??? (iter 33 will identify via probe) — yellow, suspected leak site |

Invariant satisfied (28 > 27 > 26). Iter 33 must instrument the
ProPurchaseAI decision pipeline to find a `^Territory`-keyed or
`^Unit`-keyed map iteration whose order varies with ASLR.

**Iter 31 — snap 0089 RESOLVED (incidentally).** Full sweep at
22:39 confirms snap 0089 PASSES with iter-30 algorithmic changes
reverted but refactor scaffolding kept. Root cause unknown until
iter 32 isolates which scaffold change is the fix (extra
`[dynamic]^Territory` allocation OR removed duplicate
`unit_get_transporting_no_args` call).

No trace-table layer drilling needed iter 31; the win was the
sweep itself. Iter 32 trace-table targets pick from remaining
FAIL set `{0024, 0031, 0032, 0037, 0038, 0040, 0048, 0065, 0074-
0077, 0084, 0090, 0092, 0097, 0100}` — prefer non-amphib snaps
to avoid re-entering the `territoriesToLoadFrom` Java HashSet
faithfulness rabbit hole.

**Iter 30 — snap 0089 (japanesePurchase round 2) drill.** Hash-
analysis (PUR_TRACE, iter 29) → AMPHIB_PROBE (iter 30) →
`territoriesToLoadFrom` iteration order is the LinkedHashSet
bucket-order bug. Fix shipped; unit-tally divergence is gone.
Residual layer-26 1-PU underspend punted to iter 31.

| layer | method_key |
|------:|------------|
|    28 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchase(games.strategy.triplea.delegate.remote.IPurchaseDelegate,games.strategy.engine.data.GameState) — yellow (residual PUs 1!=0; unit tally now green) |
|    27 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#purchaseSeaAndAmphibUnits(java.util.Map,java.util.List,games.strategy.triplea.ai.pro.data.ProPurchaseOptionMap) — yellow (children below still need pass for residual PU) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProTransportUtils#getUnitsToTransportFromTerritories(GamePlayer,Unit,Set,Collection,Predicate) — **GREEN (iter 30 fix; was the primary bug, now correct)** |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseUtils#randomizePurchaseOption(java.util.Map,String) — yellow (amphib/transport call sites now pass `insertion_order`; 6 other call sites still sum in map order) |
|    18 | proc:games.strategy.triplea.ai.pro.util.ProPurchaseValidationUtils#removeInvalidPurchaseOptions(...) — yellow (suspected child for residual 1-PU, audit pending iter 31) |

Invariant satisfied (28 > 27 > 18). Iter 31 descends layer-18
`removeInvalidPurchaseOptions` and adjacent option-list iteration
sites with AMPHIB_PROBE turned on.

### Iter-29 / 30 outcomes (kept compact)

- iter 29: hashes pinpoint P06 (`purchaseSeaAndAmphib`); land-phase
  hypothesis FALSIFIED.
- iter 30: `territoriesToLoadFrom` Java HashSet bucket order
  reproduced via `java_hashmap_capacity_for_size(raw)` + new
  `java_hashmap_sort_territories_by_bucket(...)` helper; insertion-
  order parameter added to `randomize_purchase_option` for the two
  amphib-loop call sites so the float-sum is Java-order-faithful.
- iter 30 unit tally is now EXACT for snap 0089; only PUs differ.

**Eliminated branches** (don't re-descend, hash-confirmed identical
between PASS and FAIL runs):
- `purchaseDefenders_land`, `purchaseAa`, `purchaseLandUnits`
  (P01–P03 identical hashes).
- `purchaseDefenders_sea`, `purchaseFactory_first` (P04–P05
  identical hashes; would be GREEN-FOR-SNAP-0089).
- `purchaseUnitsWithRemainingProduction`,
  `upgradeUnitsWithRemainingPUs`, `purchaseFactory_second`
  (P07–P10 differ but ONLY because they correctly react to the
  bad P06 state by spending leftover PUs).

### Previous iter-17 trace (preserved for reference)

Snap 0017 (russianPlace) drill — iter 4, leaf instrumented and
verified Java-faithful. Bug NOT at this leaf.

| layer | method_key |
|------:|------------|
|    27 | proc:games.strategy.triplea.ai.pro.AbstractProAi#place(boolean,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate,games.strategy.engine.data.GameState,games.strategy.engine.data.GamePlayer) |
|    26 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#place(java.util.Map,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate) |
|    18 | proc:games.strategy.triplea.ai.pro.ProPurchaseAi#placeUnits(java.util.List,games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate,java.util.function.Predicate) — **GREEN** body |
|     ? | proc:games.strategy.triplea.delegate.AbstractPlaceDelegate#getPlaceableUnits(java.util.Collection,games.strategy.engine.data.Territory) — **GREEN** (algorithm matches Java; returns 6 for Russia, 2 for Karelia; the same Java would return per paper-trace) |
|     ? | proc:games.strategy.triplea.delegate.AbstractPlaceDelegate#getMaxUnitsToBePlacedFromFull(...) — **GREEN** (printf-confirmed faithful to Java line-by-line; verified all branches) |
|     ? | **UNKNOWN PARENT** — Russia/Karelia diff must come from `placements` list, `produced` map, or `placeDefenders` state mismatch — none of which the leaf itself controls |

Invariant satisfied (27 > 26 > 18 > 0). The leaf is green, so by
the orchestrator's bottom-up rule the bug is in a SIBLING or
PARENT, not deeper.

**Verified green branches** (don't re-descend):
- The plan-driven loop in `pro_purchase_ai_place` (lines ~2173–2249
  in `odin_flat/games__strategy__triplea__ai__pro__pro_purchase_ai.odin`)
  matches Java exactly. Caucasus +2 inf +2 art is identical in both
  runs. This means `pro_purchase_ai_do_place`, the unit-matching
  by-name loop, and `sorted_purchase_territories` all work.
- `pro_purchase_ai_place_units` (lines ~330-415 in same file) —
  body is byte-identical to Java. Loop, isError check, min(max,
  size), continue semantics all correct. Confirmed via printf.
- `abstract_place_delegate_get_max_units_to_be_placed_from_full`
  (line 1441 in
  `odin_flat/games__strategy__triplea__delegate__abstract_place_delegate.odin`)
  — printf-confirmed faithful, returns same value Java would
  per paper-trace.
- WW2v5 game data: `ra=null` (no RulesAttachment), `wasFactoryThereAtStart=true`
  for Russia/Karelia/Caucasus, `originalFactory=false` (XML doesn't
  set it and `setOriginalFactory` is only reflectively invoked
  from XML).

**Yellow branches** (not yet classified, may still be wrong):
- `pro_purchase_ai_place_defenders`: instrumentation confirms 0
  placements on snap 0017 (no GMUTBPF lines between plan loop and
  fallback). If Java's place_defenders ALSO places 0, both agree.
  If Java places some at Russia/Karelia that Odin doesn't, this
  is the bug.
- **`unit_collection_get_units` returns a COPY (snapshot) not a
  view** of the live `[dynamic]^Unit`. Java's
  `player.getMatches(unitMatch)` returns matches from the LIVE
  pool each call. This causes Odin's `pro_purchase_ai_place_units`
  to re-attempt placements of units that an earlier iteration
  already removed (Russia tries the 6 first units in
  `placeable_units.getUnits()` which still includes Karelia's
  taken 2). The 6th Russia attempt fails on
  `playerHasEnoughUnits` — that's the source of the "5 of 6"
  partial placement we observe in the instrumentation.
- The `placements` list and `produced` map state at the moment
  fallback's `getPlaceableUnits(Russia)` runs.

Resolved snap 0053 trace (kept as a reference example):

| layer | method_key |
|------:|------------|
|    20 | proc:games.strategy.triplea.delegate.InitializationDelegate#start() |
|    13 | proc:games.strategy.triplea.delegate.InitializationDelegate#init(games.strategy.engine.delegate.IDelegateBridge) |
|    10 | proc:games.strategy.triplea.delegate.InitializationDelegate#initShipyards(games.strategy.engine.delegate.IDelegateBridge) |
|     1 | proc:games.strategy.engine.data.changefactory.AddProductionRule#perform(games.strategy.engine.data.GameState) |
|     0 | proc:games.strategy.engine.data.ProductionFrontier#addRule(games.strategy.engine.data.ProductionRule) |

Resolution: bug NOT in any of these procs (all faithful to Java).
The bug was one layer up in the **harness** —
`test_server_game_run_next_step` constructs a fresh
`Initialization_Delegate` via `test_server_game_register_ww2v5_delegates`
but never sets `need_to_initialize=false` for snaps that aren't
the very first one. Fix applied in `odin_flat/test_server_game.odin`.

**Lesson for future drills:** when the entire dependency chain matches
Java, check (a) the snapshot fixture loader (`json_loader.odin`)
for missing fields, and (b) the snap harness setup
(`test_server_game.odin` constructor + `_register_*_delegates` and
the runner in `snapshot_runner.odin`). The bug may live in the
shim, not the port.

When populated, format is strictly:

| layer | method_key |
|------:|------------|
|   34  | proc:games.strategy.triplea.ai.AbstractAi#start(java.lang.String) |
|   13  | proc:games.strategy.engine.delegate.IPurchaseDelegate#purchase(...) |

Invariant: `method_layer` strictly decreases down the table. Every
appended row is one of (a) a red child, or (b) the override target
of an abstract routing node above it.

## Snap status

**Iter 71 — no batch run (single-snap air-move drill on 0038).** RED set
UNCHANGED (14, from iter-70): **0025 0031 0032 0037 0038 0040 0048 0065 0074
0075 0084 0090 0097 0100.** 0038 fighter divergence LOCALIZED: the FIC fighter
ties Yunnan vs Burma (both dist=1, win=100, land-safe); Odin's attack-territory
PRIORITY order puts Yunnan first, Java puts Burma first. `can_air_safely_land_after_attack`
and the territory iteration order are both EXONERATED (faithful). New descent
target = `ProCombatMoveAi#prioritizeAttackOptions`. No logic change yet. Baseline
full-suite 90/104 green (iter-70).

**Iter 70 — FULL 104-snap batch (regression check on the iter-69 markNoMovement
guard).** Result: **90 PASS / 14 FAIL**, no timeouts/errors. FAIL set (14):
**0025 0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0090 0097 0100.**
Delta vs iter-62 baseline RED (15): **newly GREEN 0089, 0092** (the iter-68
amphib-order fix rippled through the Pro AI sims); **newly RED 0025** —
attributed by direct A/B test (built `/tmp/snaprun_iter68` with the 3 guards
reverted): **0025 PASSES on iter-68, FAILS on iter-69 → the markNoMovement
guard caused it.** BUT the guard is a FAITHFUL port: all 3 Java MovePerformer
sites call `ChangeFactory.markNoMovementChange(Set.of(unit))` (the guarded
Collection overload, `getMovementLeft().compareTo(ZERO) >= 0`), verified in
`MovePerformer.java:366,379,474` + `ChangeFactory.java:215-225`. So 0025's new
divergence (germanPlace r1: Germany +1 artillery/−1 infantry, Italy −1
artillery/+1 infantry — all Moves=0 placed units) is a LATENT pre-existing
`already_moved` divergence in the germanPlace AI simulation that the faithful
guard now EXPOSES, NOT a reason to un-port. Per precedent (faithful fix that
exposes a downstream bug is KEPT), the guard stays; net suite improved 89→90.
0038 still RED on the 4 fighter rows only. **DECISION: KEEP the guard; 0025
becomes a new RED to drill (latent already_moved divergence in germanPlace).**

**Iter 64 — no batch run (single-snap drill on 0038).** Working RED set
(15, unchanged from iter-62/63): **0031 0032 0037 0038 0040 0048 0065
0074 0075 0084 0089 0090 0092 0097 0100.** 0038 still RED — root cause
now identified: the SFE transport loads armour where Java loads
artillery, because armour & artillery TIE at effective-attack 3 and the
tie-break depends on a pointer-order-dependent unit/map iteration in the
combat-move planner (deterministic per-binary but layout-sensitive; see
Last action + Trace table). Baseline full-suite ~89/104 green (iter-62).

**Iter 68 — no batch run (single-snap drill on 0038 + APPLIED FIX).** RED set
UNCHANGED (15): **0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0089 0090
0092 0097 0100.** 0038 cargo-order root cause FIXED (SFE type + source
territories now match Java); snap still RED on a narrower already_moved=3-vs-4
amphib-unload divergence (iter-69 target). Full batch NOT re-run yet — the
iter-68 amphib-order change touches all amphib planning; re-run the batch once
0038 is green to confirm no regressions.

**Iter 67 — no batch run (single-snap drill on 0038 + JAVA ORACLE).** RED set
UNCHANGED (15): **0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0089 0090
0092 0097 0100.** 0038 ROOT-CAUSED: load-from territory order (alphabetical
sort vs Java LinkedHashSet insertion order) breaks the armour/artillery tie.
Fix scoped for iter-68. No logic change yet.

**Iter 66 — no batch run (single-snap drill on 0038).** RED set UNCHANGED
(15): **0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0089 0090 0092
0097 0100.** 0038 trace BACKED UP to layer 28 (`determineTerritoriesToAttack`):
Java GROUND TRUTH (after.json) = Alaska American / SFE artillery; Odin
spuriously keeps Alaska (win%=100) and the 60 SZ→Alaska amphib consumes
Japan's artillery before SFE. No logic change yet.

**Iter 65 — no batch run (single-snap drill on 0038).** RED set UNCHANGED
(15): **0031 0032 0037 0038 0040 0048 0065 0074 0075 0084 0089 0090 0092
0097 0100.** 0038 cargo body EXONERATED; localised to the amphib commit
order that fills the ignore set (see Last action + Trace table). No logic
change yet.

**Iter 63 — no batch run (single-snap drill on 0038).** Working RED set
(15, from iter-62): **0031 0032 0037 0038 0040 0048 0065 0074 0075 0084
0089 0090 0092 0097 0100.** 0038 still RED (amphib cargo: SFE gets armour
not artillery — localised to `tryToAttackTerritories` transport→dest
pairing, see Trace table). Baseline full-suite ~89/104 green (iter-62).

**Iter 52 — full 104-snap batch against freshly-regenerated
content-ordered snaps: 87/104 PASS** (+6 vs the 81/104 iter-49/50
baseline). Lean binary `/tmp/snaprun_iter52`; per-snap parallel run
(`xargs -P4`, each worker `cd triplea` first, `FILTER_SNAP={}` env,
300 s timeout); results in `/tmp/iter52_results/`. Pass/fail tallied
on the `Results: N passed, M failed` line per file.

EXIT distribution: 87×0, 16×1, 1×124 (timeout = 0037, which also
shows a real PUs divergence).

**17 non-passing snaps (87 passing):**
- 16 with a clean "0 passed, 1 failed" Results line: **0024 0031 0038
  0040 0048 0065 0074 0075 0076 0077 0084 0089 0090 0092 0097 0100**.
- 1 with no Results line — **0037** — interrupted by the 300 s
  timeout (exit 124) but printed a real divergence
  `Snapshot 0037 FAILED: players.Japanese.resources[PUs]: 16 != 1`.

**Newly GREEN this iter (7):** 0021 0022 0025 0029 0032 0073 0091 —
exactly the AI snaps whose ordering iter-49 had made UUID-dependent;
content sort-at-iteration now reproduces them.

**New regression (1):** 0024 — German unit move/placement tally
divergence (Algeria/Belorussia/Finland). Real divergence, top of the
iter-53 queue.

Backup of the iter-49 snaps remains at
`…/server_game_run_next_step/snapshots.iter49_backup/` (104 files).
On-disk snaps are now the iter-52 content-ordered regen.

---

**Iter 49 — snapshots REGENERATED from Approach-A Java + swapped in.**
All 104 before/after pairs in
`triplea/conversion/odin_tests/server_game_run_next_step/snapshots/`
are now derived from the TreeMap/TreeSet-ordered Pro AI (gradle
`*Ww2v5JacocoRun.runWithSnapshots --rerun-tasks` →
`process_snapshots.py`, both rc=0). Old snaps preserved at
`…/snapshots.iter48_baseline/`. Driver `.odin` kept (NOT the regen
default). Spot-check: **snap 0001 PASS** on unchanged Odin (17ms) —
regen + UUID-comparison integrity confirmed. **Full 104-snap batch
NOT yet run against the new snaps — that is the iter-50 kickoff
deliverable.** Expectation: deterministic engine snaps PASS; the ~18
AI-heavy snaps (incl. 0089) stay RED until the iter-50 Odin
sort-at-iteration lands.

---

Ground truth from 2026-05-23 (iter 27) full parallel run via
lean test binary `/tmp/snaprun_fast` (no debug, no leak tracker),
`xargs -P 4` with 300 s per-snap timeout. Results in
`/tmp/snap_results_iter27/`. **104 snaps.**

**Iter 27 (after iter-26 LinkedHashMap fix lands): 86 PASS, 18 FAIL,
0 OTHER.**
_Iter 23 (after pointer-refactor): 84/18/0. Iter 21: 84/16/2T/2NE.
Iter 20 = 85/17/2 HANG. Iter 7 = 80/17/7 TIMEOUT. Iter 5 = 77 PASS._

**Iter 39 — no full sweep.** Code FIX shipped in
`pro_purchase_ai.odin`: `prioritize_sea_territories` now
mirrors Java's `LinkedHashSet` semantics via insertion-ordered
list + dedup map; both `slice.sort_by` calls upgraded to
`slice.stable_sort_by`. Iter-39 binary `/tmp/snaprun_rpo` 5.2M
@ 12:41 May 25 (iter-34 fix + iter-35/36/37/38 probes + iter-39
LinkedHashSet/stable-sort fix, RPO_DUMP=true).

Iter-39 single-snap reruns (build 12:41, snap 0089, ASLR-on,
`TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result | duration   | jNCM    | bp[] composition after NCM                  | AMPHIB t=62 rem_prod |
|-----|--------|------------|---------|----------------------------------------------|-----------------------|
|   1 | FAIL   | 2m06s      | 8→4     | aaGun, factory, infantry, artillery         | 3                     |
|   2 | PASS   | 2m39s      | 8→3     | aaGun, factory, armour                      | 1                     |
|   3 | PASS   | 2m40s      | 8→4     | aaGun, factory, infantry, artillery         | 2                     |

Tally: **2/3 PASS** (~67%). Improvement vs baseline (iter-38
single-pair was 1/2 = 50%). Two residual leaks remain (see
"Notes / blockers"). Artifacts:
`/tmp/iter39_run{1,2,3}.stderr.kept`,
`/tmp/iter39_probe{1,2,3}.kept`.

**Iter 38 — no full sweep.** Focus was bisecting the iter-37
sim-walk-loop hypothesis. The hypothesis was falsified: SIMSTEP
traces are identical across runs, sim-walk steps are
deterministic. New leak boundary localized to inside
`pro_purchase_ai_purchase_sea_and_amphib_units` (first
divergent probe line: `AMPHIB_OUTER t=62 Sea Zone land=Japan`
with `rem_prod=1` PASS vs `rem_prod=3` FAIL). No fix shipped;
SIMSTEP probes added to `abstract_pro_ai.odin` (lines ~840 and
~1082), all gated under `when #config(RPO_DUMP, false)`.
Iter-38 binary `/tmp/snaprun_rpo` 5.2M @ 12:23 May 25
(iter-34 fix + iter-35/36/37/38 probes).

Iter-38 single-snap reruns (build 12:23, snap 0089, ASLR-on,
`TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result | SIMSTEP jNCM | BEFORE_PRIO_SEA n | bp[] composition       | AMPHIB_OUTER t=62SZ rem_prod |
|-----|--------|--------------|--------------------|------------------------|------------------------------|
|   1 | PASS   | 8→3          | 3                  | aaGun, factory, armour | 1                            |
|   2 | FAIL   | 8→3          | 3                  | aaGun, factory, armour | 3                            |

Definitive: sim-walk and pre-amphib state are IDENTICAL; the
divergence first surfaces as a 2-PU difference in remaining
production at the t=62/Japan amphib iteration. Artifacts:
`/tmp/iter38_run{1,2}.stderr.kept`,
`/tmp/iter38_probe{1,2}.kept`.

**Iter 37 — no full sweep.** Focus was bisecting the iter-36
leak by adding two more probes upstream within
`pro_purchase_ai.odin`. No fix shipped; iter-37 binary
`/tmp/snaprun_rpo` 5.2M @ 12:11 May 25 (iter-34 fix + iter-35
+ iter-36 + iter-37 probes, all gated on `RPO_DUMP`).

Iter-37 single-snap reruns (build 12:11, snap 0089, ASLR-on,
`TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result | PURCHASE_ENTRY | BEFORE_PRIO_SEA | SEA_ENTRY | Japan unit types                          |
|-----|--------|----------------|------------------|-----------|-------------------------------------------|
|   1 | PASS   | 3              | 3                | 3         | aaGun, factory, armour                    |
|   2 | FAIL   | 5              | 5                | 5         | aaGun, factory, infantry, armour, artillery |

Constant within run, divergent across runs at the very first
probe — leak is upstream of `pro_purchase_ai_purchase`.
Artifacts: `/tmp/iter37_run{1,2}.stderr.kept`,
`/tmp/iter37_probe{1,2}.kept`.

**Iter 36 — no full sweep.** Focus was decisively locating the
iter-35 residual leak via boundary probe. No fix shipped; one
new probe (`TERR_DUMP_JAPAN_ENTRY`) added at line ~3556 in
`pro_purchase_ai.odin`, gated under `when #config(RPO_DUMP, false)`.
Iter-36 binary `/tmp/snaprun_rpo` 5.2M @ 11:50 May 25 (iter-34
fixes + iter-35 + iter-36 probes).

Iter-36 single-snap reruns (build 11:50, iter-34 fix + iter-35 +
iter-36 probes, snap 0089, ASLR-on, `TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result | TERR_DUMP_JAPAN_ENTRY n | first AMPHIB_OUTER own_n | sea-prio order |
|-----|--------|--------------------------|---------------------------|----------------|
|   1 | PASS   | 4                        | 4 (Japan)                 | [62, 62, 60]   |
|   2 | FAIL   | 2                        | 2 (Japan)                 | [60, 62, 62]   |

Definitive: divergence is present BEFORE
`purchase_sea_and_amphib_units` is called. Artifacts:
`/tmp/iter36_run{1,2}.stderr.kept`, `/tmp/iter36_probe{1,2}.kept`.

**Iter 35 — no full sweep.** Focus was narrowing the iter-34
residual leak. No fix shipped; an `AMPHIB_OUTER` probe was added
(gated under `when #config(RPO_DUMP, false)`) at line ~3594 and
~4200 in `pro_purchase_ai.odin`. Iter-35 binary
`/tmp/snaprun_rpo` 5.2M @ 10:58 May 25 (iter-34 fixes + iter-35
probe).

Iter-35 single-snap reruns (build 10:58, iter-34 + iter-35 probe,
snap 0089, ASLR-on, `TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result | first AMPHIB_OUTER own_n |
|-----|--------|--------------------------|
|   1 | FAIL   | 2 (Japan)                |
|   2 | PASS   | 4 (Japan)                |

Concrete divergence captured in `/tmp/iter35_probe1.kept` vs
`/tmp/iter35_probe2.kept`. Land purchase CSF rows are identical
between runs; first AMPHIB_OUTER `own_n` differs.

**Iter 34 — no full sweep.** Focus was the next ASLR-leak hunt
beyond iter 33's `randomize_purchase_option` fix. Iter-34
`/tmp/snaprun_rpo` built 10:26 May 25 (5.2 MB) with the
`calculate_support_factor` sort fix AND a probe gated on
`-define:RPO_DUMP=true`. Sweep deferred to iter 35+ (or whenever
snap 0089 is ASLR-stable).

Iter-34 single-snap reruns (build 10:26, iter-34 code + probe,
snap 0089, ASLR-on, `TRIPLEA_BATTLE_PRECACHE_ENABLED=0`):

| run | result   | notes |
|-----|----------|-------|
|   3 | FAIL     | iter-34 fix without probe; same `armour 0/1, infantry 10/8` tally |
|   4 | PASS     | iter-34 fix without probe |
|   5 | PASS     | iter-34 fix + probe; artillery `sf=0.9095` across all CSF calls |
|   6 | FAIL     | iter-34 fix + probe; artillery `sf=0.606` at Amphib call #2 because `units_n=7` (vs 6 in run 5) — upstream leak |
|   8 | PASS     | iter-34 fix + probe |
| 7,9,10 | INTERRUPTED | killed by stray SIGINT from chat-tool terminal cleanup; excluded from tally |

**3/5 PASS = 60%** (vs iter-33 1/5 = 20%). Necessary
improvement; still flaky.

**Iter 33 — no full sweep.** Focus was the snap-0089 ASLR-leak
hunt. Iter-33 lean `/tmp/snaprun_fast` built 22:11:44 May 24
(5.2 MB) with `randomize_purchase_option` insertion-order fix at
all 9 caller sites. Sweep deferred to iter 34 (or whenever snap
0089 is ASLR-stable); the iter-33 fix is a Java-fidelity gain
that should not regress anything but a sweep is the proof.

Iter-33 single-snap reruns (build 22:11:44, iter-33 code, snap 0089):

| set                            | ASLR | result               |
|--------------------------------|------|----------------------|
| postfix_noaslr (`setarch -R`)  | off  | 3/3 PASS (~2m10s ea) |
| postfix_aslr                   | on   | 4/5 FAIL, 1/5 PASS (same `armour 0/1, infantry 10/8` tally on failures; see /tmp/iter33_postfix_aslr/summary.txt) |

The fix is necessary but not sufficient. Additional leaks remain.

**Iter 32 — no full sweep.** Confirmed snap 0089 is ASLR-flaky
at the iter-31 code state. Restored iter-31 byte-for-byte; built
/tmp/snaprun_fast at 16:15:40 May 24 (5194944 bytes). Did not
re-sweep; expected result is "87/17 or 86/18 depending on the
roll of ASLR for snap 0089."

Iter-32 single-snap reruns (build 16:15:40, iter-31 code):
- snap 0089 run 1: PASS (2m40s)
- snap 0089 run 2: TIMEOUT (4m00s — same FAIL outcome but ran
  past the 240s budget; rc=124, killed)
- snap 0089 run 3: PASS (2m26s)

Iter-32 single-snap reruns at variant-A states (build 15:30):
- snap 0089: FAIL with `armour 0/1, infantry 10/8` unit tally
- snap 0025: PASS

The two states (variant A applied OR not) both produced FAIL on
snap 0089 across single runs but the iter-31 sweep saw PASS. The
variant doesn't matter; snap 0089 is genuinely flaky.

**Iter 31 sweep (DONE).** Lean binary `/tmp/snaprun_fast`
rebuilt 22:39:30 May 23 with iter-30 algorithmic changes reverted
but refactor scaffolding preserved. Results in
`/tmp/snap_results_iter31/*.txt`.

**Iter 31 sweep tally: 87 PASS / 17 FAIL / 0 OTHER.** Net +1 vs
both iter 27 (86/18) and iter 30 (86/18). NEW BEST.

Iter-31 FAIL set (17): `{0024, 0031, 0032, 0037, 0038, 0040,
0048, 0065, 0074, 0075, 0076, 0077, 0084, 0090, 0092, 0097,
0100}`.

**Deltas vs iter-27 FAIL set (-1):**
- snap **0089 newly PASSES** (japanesePurchase). Iter-30 attempted
  to fix this with bucket-sort + insertion_order in the amphib
  loop; both turned out to be noise. The actual fix is incidental
  to the iter-30 refactor: either the new
  `pro_transport_utils_get_units_to_transport_from_ordered_territories`
  overload's extra `[dynamic]^Territory` allocation shifts
  allocator state into a Java-faithful position, OR removal of
  the duplicate `unit_get_transporting_no_args` call (iter 31
  hypothesis 1) was the real fix.

**Deltas vs iter-30 FAIL set (+1, -2):**
- snap **0025 returns to PASS** (regression fixed by reverting
  the bucket-sort / insertion_order changes).
- snap **0089 newly PASSES** (full pass, not just partial like
  iter 30).
- snap **0032 reverts to FAIL** (iter-30's indirect gain on this
  snap depended on bucket-sort, which is now reverted).

**Iter 30 sweep (DONE).** Lean binary `/tmp/snaprun_fast` rebuilt
21:33 May 23 with the 4-file fix in §Last action. Results in
`/tmp/snap_results_iter30/*.txt`.

**Iter 30 sweep tally: 86 PASS / 18 FAIL / 0 OTHER.** Same count
as iter 27 but the FAIL set rotated by one snap:

Iter-30 FAIL set (18): `{0024, 0025, 0031, 0037, 0038, 0040, 0048,
0065, 0074, 0075, 0076, 0077, 0084, 0089, 0090, 0092, 0097, 0100}`.

**Deltas vs iter-27 FAIL set (+1 / -1):**
- snap **0032 newly PASSES** (was iter-27 FAIL; britishNonCombatMove
  Alaska/Eastern Canada infantry swap). The iter-30 bucket-order
  fix to `purchaseSeaAndAmphib` indirectly stabilised an earlier
  AI computation that propagated to snap 0032 — confirms iter-30
  is on the right track for the LinkedHashSet bug class.
- snap **0025 newly FAILS** (was iter-27 PASS; germanPlace, 1 art ↔
  1 inf swap between Germany and Italy). **REGRESSION introduced
  by iter 30** — same symptom pattern as the pre-iter-26 failure
  (1-unit swap between two adjacent territories). Surprising,
  since Germany doesn't run the amphib loop in WW2v5 round 1, and
  the `randomize_purchase_option` nil-default path is supposed
  to be byte-identical to the old behavior. Two hypotheses for
  iter 31:
  1. The `pro_transport_utils_get_units_to_transport_from_territories`
     refactor (line 711) now allocates an intermediate slice via
     `pro_determinism_sorted_territory_keys` even when the caller
     didn't ask for it. The extra `make([dynamic]^Territory)` may
     have shifted a pointer-keyed map iteration somewhere
     downstream (allocator perturbation, classic snap-0089-iter-28
     pattern).
  2. The optional-parameter signature change on
     `randomize_purchase_option` may have caused the Odin
     compiler to emit slightly different code at non-amphib call
     sites (default-param ABI). Less likely but possible.

**Iter 27 deltas vs iter-23 baseline (net +2 PASS, 0 net FAIL change):**
- snap **0025 newly PASSES** (was iter-23 FAIL). Iter-26
  LinkedHashMap fix lands the AI in the Java-faithful state at the
  divergent step — a real WIN.
- snap **0089 newly FAILS** (was iter-23 PASS-slow). The same
  iter-26 fix changed Japanese AI's perceived combat strength →
  round-2 purchase swap: armour 0→1, infantry 10→8. New
  deterministic FAIL (2-row symptom in `<purchase_pool>`),
  drillable in iter 28.
- 17 other FAILs unchanged: `{0024, 0031, 0032, 0037, 0038, 0040,
  0048, 0065, 0074-0077, 0084, 0090, 0092, 0097, 0100}`.

**Iter 27 sweep tally:** 86 PASS / 18 FAIL / 0 OTHER. FAIL set is
17 carry-overs from iter-23 plus snap 0089 (new regression),
minus snap 0025 (new WIN). Net effect of iter-26 is +2 PASS with
zero count regression; 102/104 snaps unchanged across the
support-iteration-rewrite. Lean binary
(`-define:ODIN_TEST_TRACK_MEMORY=false`, no `-debug`) is what
made the full sweep possible — per-snap log dropped from 3 GB
(debug+leak-tracker) to 4 KB.

**Iter 26 individual-snap re-checks (no full sweep this iter):**
- snap 0032: **0 PASS / 5 FAIL / 0 HANG (5-run solo loop, 240 s cap).
  DETERMINISTIC.** Same Alaska/Eastern Canada infantry swap every
  run. Fixes both the iter-23 intermittency and the iter-25
  hang/regression. Remaining FAIL is a real Java-fidelity bug to
  solve (iter 28+).
- snap 0024: FAIL in 1m 48 s, byte-identical to iter-24/25
  divergence. Confirms the support-iteration pipeline is now
  Java-faithful and the snap-0024 bug lives deeper.
- Full sweep deferred — completed in iter 27.

**Iter 25 individual-snap re-checks (NO full sweep this iter):**
- snap 0032: 0 PASS / 3 FAIL / 2 HANG (5-run solo loop, 180 s cap).
  REGRESSION vs iter-23 (was 2P/1F intermittent).
- snap 0024: FAIL in 1m 49 s, byte-identical divergence to iter-24.
  Iteration time grew but result is the same.
- Full 104-snap sweep deferred to iter 26 once the snap-0032
  regression is understood / fixed.

Iter-23 FAIL set (18): `{0024, 0025, 0031, 0032, 0037, 0038, 0040,
0048, 0065, 0074, 0075, 0076, 0077, 0084, 0090, 0092, 0097, 0100}`.

Iter-23 deltas vs iter-21:
- snap **0021 newly PASSES** (was iter-21 TIMEOUT at 120s; iter-23
  longer cap unmasks PASS).
- snap **0073 newly PASSES** (was iter-21 NO_EXIT; same cap unmask).
- snap **0089 changed NO_EXIT → FAIL** (deterministic now, easier
  to drill).
- snap **0037 changed TIMEOUT → FAIL** (deterministic now,
  easier to drill).
- snap **0032 changed PASS → FAIL** (REGRESSION — actually
  INTERMITTENT, see iter-24 finding above; passes solo run #1
  in 58.83 s, fails solo run #2 in 61.09 s).

| snap | status (iter 23) | top-level symptom |
|------|------------------|-------------------|
| 0017 | **PASSED** (iter 6) | russianPlace |
| 0013, 0022, 0029, 0073, 0089, 0021 | PASS (slow; longer cap) | various AI long-compute snaps |
| 0033, 0041, 0049, 0069, 0085, 0093, 0101 | PASS | iter-7 collateral wins |
| 0081 | PASS | iter-20 repair-frontier fix |
| **0032** | **INTERMITTENT** | britishNonCombatMove — passes solo #1 in 58.83 s, fails solo #2 in 61.09 s with British inf Alaska↔Eastern Canada swap. Hypothesis: iter-23 exposes `Available_Supports` pointer-hash iteration. Iter 25 fix planned. |
| 0024 | FAIL (iter 23, ~57 s) | germanNonCombatMove. Same unit tally divergence as iter 21. L9 yellow children classified: DummyPlayer.selectCasualties green, CasualtyUtil.getDependents green-for-snap, CombatValue suspects identified (see Trace table iter 24). |
| 0021 | **PASSED iter 23** (with longer cap) | germanPurchase, 3m+ AI purchase compute. |
| 0025, 0031, 0038, 0040, 0048, 0065 | FAIL | _see /tmp/snap_results_iter23/NNNN.txt_ |
| 0074–0077, 0084, 0090, 0092, 0097, 0100 | FAIL | _see /tmp/snap_results_iter23/NNNN.txt_ |
| 0037 | FAIL (iter 23, was iter-21 TIMEOUT) | AMPHIB_PROBE step (Pacific amphib). |
| 0089 | FAIL (iter 23, was iter-21 NO_EXIT) | japanesePurchase round 2. |
| 0053 | PASS | (fixed harness ≤ iter 5) |

To rebuild the binary after Odin changes:
```sh
cd triplea && odin test conversion/odin_tests/server_game_run_next_step \
  -collection:flat=/home/caleb/todin/odin_flat \
  -collection:test_common=conversion/odin_tests/test_common \
  -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_TRACK_MEMORY=false \
  -extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib"
  # Note: the in-process runner stalls; expect to kill it after a few
  # minutes once compile is done and the binary is on disk. Then use
  # the parallel FILTER_SNAP recipe above.
```

Quick recipe to re-run any single snap (no rebuild needed; binary
is at `triplea/server_game_run_next_step`):
```sh
cd triplea && TRIPLEA_BATTLE_PRECACHE_ENABLED=0 \
  FILTER_SNAP=0053 ./server_game_run_next_step 2>&1 | tail -10
```

Full parallel suite recipe (iter 7 version with 180s per-snap timeout):
```sh
cd triplea && rm -rf /tmp/snap_results && mkdir -p /tmp/snap_results
export TRIPLEA_BATTLE_PRECACHE_ENABLED=0
ls conversion/odin_tests/server_game_run_next_step/snapshots/ | \
  xargs -P 6 -I{} sh -c \
    'timeout 180 env FILTER_SNAP={} ./server_game_run_next_step \
     > /tmp/snap_results/{}.txt 2>&1; \
     echo "EXIT={}:$?" >> /tmp/snap_results/{}.txt'
for f in /tmp/snap_results/*.txt; do tail -1 "$f"; done | \
  awk -F: '{print $2}' | sort | uniq -c
```


## Notes / blockers

**Iter 68 (2026-06-03) — applied the cargo load-from order fix; build/run gotchas.**
- **Fix landed (4 files, all under `odin_flat/`):** `pro_transport.odin`
  (added `transport_map_order` + getter, `add_territories` now takes an ordered
  slice + LinkedHashSet dedup), `pro_territory_manager.odin`
  (`find_amphib_move_options` sorts each load set by Java bucket order before
  add), `pro_combat_move_ai.odin` (amphib commit reads the ordered list via the
  `_ordered_territories_4` variant), `pro_transport_utils.odin` (lines ~711 and
  ~1283 alphabetical → bucket-order fallback). Clean compile.
- **Result:** SFE cargo TYPE fixed (artillery+infantry, was armour) and the
  Manchuria/Kiangsu source diff resolved. Remaining: amphib cargo already_moved
  3 (Odin) vs 4 (Java) + 3 fighter rows — see Trace table NEW bottom row / Next
  action (iter-69).
- **The shell wrapper strips a leading `cd X &&`.** Build with ABSOLUTE package
  + collection paths (no cd); run inside a SUBSHELL `( cd …/triplea && … )` so
  the cwd (needed for the relative `snapshots/` path) sticks. Otherwise the
  build errors `Library collection 'test_common' path must be a directory` or
  the run reports a vacuous "No snapshots found ... test successful".
- **Digest field meaning:** in the unit-tally divergence, `Moves=` is the unit's
  `already_moved` (movement consumed, f64) — NOT movement remaining. See
  `conversion/odin_tests/test_common/game_state_compare.odin:88`.
- **Three odin_flat trees, one source:** `triplea/odin_flat` and
  `triplea/conversion/odin_flat` are symlinks to `/home/caleb/todin/odin_flat`
  (the canonical, build-referenced copy). Edit only the canonical one.

**Iter 67 (2026-06-03) — Java oracle runnable + snap 0038 ROOT CAUSE.**
- **Java oracle command (now proven runnable):** `export
  JAVA_HOME=/nix/store/c3pl7bqrx3d2rc3dh98z6yaj0mv1p52g-openjdk-21.0.10+7 &&
  export PATH=$JAVA_HOME/bin:$PATH && cd triplea && ./gradlew --no-daemon
  --quiet :game-app:smoke-testing:test --tests
  "*Ww2v5JacocoRun.runWithSnapshots"`. Compiles game-core + runs a
  deterministic 2-round WW2v5 game (seed 42). Gradle CAPTURES test stdout, so
  probes must write to a FILE, not System.out. snap 0038 = round-1
  japaneseCombatMove.
- **Probes used this iter (ALL REVERTED via git checkout; re-add to re-probe):**
  in `ProCombatMoveAi.java`: a `jprobe(String)` helper writing to
  `/tmp/jprobe_0038.txt`; `JPROBE_AMPHIB` at the amphib commit (`if
  (minWinTerritory != null)`, ~line 1808) printing transport home/target/
  cargo; `JPROBE_DUA_FINAL` at end of `determineTerritoriesToAttack` printing
  surviving list; `JPROBE_TXORDER` after `amphibAttackOptions` built printing
  transport order; `JPROBE_COMMIT` after the amphib loop printing
  `attackMap` units for Alaska+SFE with `round=data.getSequence().getRound()`.
  In `ProTransportUtils.java`: `JPROBE_CARGO` in the 5-arg
  `getUnitsToTransportFromTerritories` (gate `player==Japanese &&
  territoriesToLoadFrom.size()>1`) printing `terrs=` (iteration order),
  `gather=` (post-sort units), `cargo=` (return). All gated on Japanese.
- **DECISIVE DATA:** Java round-1 `JPROBE_COMMIT round=1
  Soviet Far East=[infantry,artillery] Alaska=[infantry,artillery]`. Java
  transport order = `60;61` (same as Odin). Java picks armour ONLY when
  artillery ignored AND armour leads the gather (round-2 `gather=armour,
  artillery → cargo=armour`) — so the cargo select is faithful.
- **ROOT CAUSE:** the armour/artillery tie (equal cost, equal decreasing-
  attack) is broken by the load-from TERRITORY iteration order. Java's
  `ProTransport.transportMap` value = `LinkedHashSet` (insertion order,
  `ProTransport.java:14-25`); for the SFE set it iterates `Kwangtung;Kiangsu;
  Japan;Manchuria`. Odin sorts ALPHABETICALLY via
  `pro_determinism_sorted_territory_keys` (`pro_transport_utils.odin:722`,
  `:1283`) → `Japan;Kiangsu;Kwangtung;Manchuria` → Japan's armour leads when
  its artillery is ignored → SFE=armour. The user's "sort-by-name is a red
  flag" anti-pattern, introduced as a (wrong) determinism workaround.
- **FIX (iter-68):** make Odin's `Pro_Transport.transport_map` load-from set
  insertion-ordered (matching `find_amphib_move_options`), and delete the
  alphabetical sort. NOT a blocker — actionable.

**Iter 66 (2026-06-03) — Java ground truth + trace back-up for snap 0038.**
- **Java after.json is the decisive oracle.** Parse
  `conversion/odin_tests/server_game_run_next_step/snapshots/0038/after.json`
  (territory `units` are ID refs → resolve via top-level `units` list).
  Result: **Alaska = AMERICAN** (60 SZ transport stays in 60 SZ with its
  battleship+destroyer, no cargo); **Soviet Far East = Japanese
  {artillery, infantry}**; 61 SZ transport → 63 SZ.
- **Odin spuriously plans 60 SZ → Alaska** (AMPHIB probe: `60 SZ → Alaska
  unloadFrom=64 SZ units=[infantry,artillery]`), processed before
  `61 SZ → Soviet Far East units=[infantry,armour]`. Alaska attackValue
  8.0 ≫ SFE 0.1, so Alaska commits first and grabs Japan's artillery →
  SFE gets armour. Alaska is later dropped (final state American, no
  Alaska divergence) but SFE's armour cargo is already locked.
- **Reachability is legitimate (NOT a connectivity bug).** before.json
  neighbour BFS: 60 SZ→64 SZ dist 2, 64 SZ→Alaska dist 1; the transport
  loads at Japan, moves 60→63→64, unloads Alaska. Java could attack
  Alaska too — it just doesn't.
- **Layer 27 (`tryToAttackTerritories`) is FAITHFUL.** Re-confirmed vs
  Java `ProCombatMoveAi` lines 1700-1800: the reset clears all attack_map
  entries each call; unit-assignment uses sorted keys
  (`sorted_unit_keys_by_move_options`/`sorted_territory_keys_by_priority`);
  amphib outer loop = `transport_map_list` LIST, inner = `prioritized_
  territories`; unload dest = `java_hashmap_bucket_for_string`. No leak.
- **Trace BACKED UP to layer 28 = `determineTerritoriesToAttack`.** Its
  while-loop grows `numToAttack`, re-runs tryToAttackTerritories on
  `subList(0,numToAttack)`, and keeps a territory only if `areSuccessful`.
  Odin's DUA_REMOVE_DECIDE keeps Alaska (win%=100, hasLandRem=true,
  removed=false). For Java's after-state, Java must evaluate Alaska's
  attack as UNSUCCESSFUL and remove it. ⇒ iter-67 must get Java's
  intermediate Alaska attacker-set + win% (via the Java oracle), then
  descend into the unit-assignment or battle-result estimation
  (`estimateBattleResult`/ProOddsCalculator, layers 15/14 — possibly a
  shared root with battle-resolution reds 0031/0074), or
  `prioritizeAttackOptions`/`findAmphibMoveOptions`.
- DB method layers: determineTerritoriesToAttack=28,
  tryToAttackTerritories=27, getUnitsToTransportFromTerritories=26,
  estimateStrengthDifference=15, checkForOverwhelmingWin=14. NOT a blocker.

**Iter 65 (2026-06-03) — cargo code exonerated; corrected facts + new
probe for snap 0038.**
- **CORRECTED transportCost (iter-64 said "both cost 1" — WRONG).** From
  `before.json` unitTypes: infantry transportCost=**2**, artillery=**3**,
  armour=**3**, transport transportCapacity=**5**. Cargo sort =
  transportCost asc then decreasing-attack; the four infantries (cost 2)
  sort first, then artillery+armour (cost 3, TIE at eff-attack 3).
  selectUnitsToTransportFromList loads {inf,inf}=cost4 then replaces the
  weakest selected (an infantry) with the strongest remaining cost-≤3
  unit → artillery (cost4-2+3=5=capacity) = Java's {infantry,artillery}.
- **`CARGO_PRE` probe EXONERATES the cargo code.** New `when PLAN_PROBE`
  probe in `get_units_to_transport_from_ordered_territories` (after the
  ignore-filter, before the sort) prints `loadFrom=[territory names]
  ignored=N gather=[unit type names]`. For `loadFrom=[Japan] ignored=0`
  the gather is STABLY `[inf,inf,inf,inf,artillery,armour]` (artillery
  before armour). armour only precedes artillery for `loadFrom=[Japan,
  Kiangsu,Kwangtung] ignored=2` — i.e. when Japan's artillery is ALREADY
  IN THE IGNORE SET, so Japan contributes only armour and the next
  artillery comes from Kwangtung (sorts after Japan). ⇒ the cargo
  comparator/sort/select are FAITHFUL; the divergence is in the INPUT
  ignore set.
- **Ordering inputs verified FAITHFUL (not the leak):** the snapshot
  serializer writes territories in `map.getTerritories()` List order and
  the JSON loader appends in array order ⇒ `game_map.territories` is
  Java-faithful; `my_unit_territories` is filtered from it in order;
  `transport_map_list` iterates `my_unit_territories` then within-terr
  `territory_get_matches`(=`unit_collection.units`, JSON order);
  `prioritized_territories` uses alphabetic pre-sort + stable value-desc.
- **Remaining suspect:** the amphib/attack COMMIT ORDER in
  `tryToAttackTerritories`/`determineUnitsToAttackWith` that puts Japan's
  artillery into `attack_map` before the SFE transport commits. iter-66
  must instrument the SFE commit (~`pro_combat_move_ai.odin` line 2255)
  to name the divergent prior commit (candidate: a 60 SZ→Alaska amphib
  Odin keeps but Java drops). Faithful port only.
- Probe binary: `/tmp/snaprun_0038plan5`; log `/tmp/snap0038_plan5.log`.
  (iter-64's `/tmp/snaprun_0038plan4` + CARGO_CMP probe still present.)
  NOT a blocker.

**Iter 64 (2026-06-03) — root cause + probe recipe for snap 0038.**
- **Key finding: pointer-order determinism bug in the Pro combat-move
  planner.** A given binary is deterministic run-to-run (`/tmp/div_A.txt`
  == `/tmp/div_B.txt`), but two logically-equivalent BUILDS give
  different divergence sets (plan3: SFE only; plan4: 8 territories). The
  planner reads pointer-hash map/set iteration order; any layout shift
  (a probe, a define) reorders tie-broken decisions. Fix path = port the
  uncovered iterations to Java's hash-bucket / stable-key order (use the
  existing `java_hashmap_bucket_for_string`). Faithful port only.
- **Cargo tie:** armour & artillery TIE at effective-attack 3 in
  `ProTransportUtils.getDecreasingAttackComparator` (artillery 2+1
  support, armour 3+0). Odin's comparator + stable insertion sort are
  FAITHFUL; the tie-break is the load-from territory's
  `unit_collection.units` order (`territory_get_matches`), which is the
  pointer-order-sensitive input. `before.json` lists Japan's artillery
  BEFORE armour, so a faithful stable order should pick artillery.
- **Ground-truth method:** parse `snapshots/0038/{before,after}.json`
  directly (territory `units` are ID refs → resolve via top-level
  `units` list). This is more reliable than planner probes for the
  expected end state. Alaska stays American in both ⇒ the iter-63 Alaska
  theory was a red herring (non-final planning iteration).
- **Probe build:** `-define:PLAN=true` gates `PLAN_PROBE` (now also the
  new `CARGO_CMP` probe in `pro_transport_utils.odin` printing each
  load candidate's `base+sup=effective` attack). Linker needs
  `LIBRARY_PATH`/`LD_LIBRARY_PATH` to include
  `/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib`. The
  run CWD MUST be `…/triplea` (relative `snapshots/`); running from repo
  root → vacuous "No snapshots found … test successful".
- Probe binary: `/tmp/snaprun_0038plan4`; logs `/tmp/snap0038_plan4.log`,
  `/tmp/snap0038_run{A,B}.log`, `/tmp/div_{A,B}.txt`. NOT a blocker.

**Iter 63 (2026-06-03) — build env + probe recipe for snap 0038.**
- The probe build links `-lsqlite3`; the Nix shell does NOT export the
  lib dir by default. Set `LIBRARY_PATH` and `LD_LIBRARY_PATH` to
  include `/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib`
  (a `libsqlite3.so` provider) for BOTH build and run, else the linker
  fails `cannot find -lsqlite3` and the binary fails to load at runtime.
- Probe defines: `-define:PLAN=true` (gates `PLAN_PROBE` in
  `pro_combat_move_ai.odin`, dumps `ASSIGN`/`AMPHIB`/`AMPHIB_CAND`/
  `AMPHIB_SD`) and `-define:AMPHIB_TRACE=true`
  (gates `pro_territory_manager.odin` / `pro_move_utils.odin` amphib
  probes). `PRIO*`/`DUA_PT` probes appear to be always-on.
- Probe binary: `/tmp/snaprun_0038plan`; log `/tmp/snap0038_plan.log`.
- NOT a blocker — capture infra is intact; this is the descent on 0038's
  cargo divergence (see Trace table / Next action). No user action
  required.

**Iter 52 (2026-05-29) — UUID→content sort-at-iteration refactor
landed; 87/104.** Key facts for whoever picks up iter-53:
- There were TWO Java determinism files. The TRACKED
  `ProDeterminism.java` is the CORRECT Odin mirror (content
  comparator, UUID removed, `*WithLocation` variants added). The
  untracked iter-49 `ProDeterministicOrder.java` (TreeMap/TreeSet
  UUID factories) was WRONG and is DELETED.
- A content-keyed TreeMap is fundamentally broken for MUTABLE Unit
  keys (mutating a key corrupts the tree invariant → NPE at
  `ProSimulateTurnUtils.transferUnit:275`). UUID worked only because
  `Unit.getId()` is immutable. The ONLY correct content-ordering
  approach is identity-keyed maps + SORT-AT-ITERATION — which is what
  Odin already does and what iter-52 implemented on the Java side.
- `Unit` has no live-location field; the location tiebreak comes from
  `ProData.unitTerritoryMap` via a `Function<Unit,Territory>` locator
  passed at the iteration site (helpers `orderedUnits` /
  `orderedEnemyAttackers` in `ProPurchaseAi.java`).
- Order-sensitive sites = those feeding the odds calculator
  (`calculateBattleResults` / `estimateDefendBattleResults`). Logging,
  `.stream().anyMatch()`, and `estimateStrengthDifference` are NOT
  order-sensitive. Odin has exactly 8 `_with_loc` sort sites, all in
  `pro_purchase_ai.odin` (2524 2769 3314 3332 3720 3764 3914 3921).
- 0024 regressed (was green under UUID order). Investigate the
  Java↔Odin tiebreak parity at the matching purchase site first.

---

- **(iter 51) DECISIVE: content-keyed TreeMap is BROKEN for mutable
  Unit keys.** Implemented `UNIT_BY_CONTENT` and pointed the unit-map
  factories at it; regen FAILED with NPE in
  `ProSimulateTurnUtils.transferUnit:275` (TreeMap lookup returned
  null). Cause: Units mutate mid-turn (alreadyMoved/hits/transportedBy/
  wasAmphibious/unloadedTo); a TreeMap needs a stable comparator over a
  key's lifetime, so a content-keyed mutable unit corrupts the tree.
  UUID worked only because `Unit.getId()` is immutable. ⇒ The ONLY
  correct content-ordering approach is identity-keyed maps +
  SORT-AT-ITERATION (snapshotting current content at the iteration
  site is fine; it need not be stable over time). This is exactly what
  the Odin side ALREADY does (`pro_determinism.odin`: sorts by content,
  "UUID deliberately NOT used"). So iter-49's real bug = Java sorted by
  UUID while Odin sorted by content.
  - State left: factories restored to immutable-safe `UNIT_BY_UUID`
    (working iter-49, 81/104, regen OK, snapshots untouched).
    `UNIT_BY_CONTENT` retained (with a javadoc'd "do not key a TreeMap"
    warning) ready for the sort-at-iteration refactor.
  - "territory" question resolved: Odin uses a `_with_loc` location
    tiebreak (from `pro_data.unit_territory_map`) at multi-territory
    sites. Java's TreeMap comparator can't see that — another reason
    keying fails — so Java must add the location tiebreak AT the
    iteration site, matching Odin.
  - `UNIT_BY_CONTENT` field order mirrors Odin's
    `pro_determinism_unit_property_less` EXACTLY: type name, owner name,
    hits, alreadyMoved, wasAmphibious, submerged, transported-presence,
    unloaded-count, unloadedTo-name (UUID only as final uniqueness
    tiebreak, never reached for content-distinct units).


  field types.** The Pro AI collections (ProTerritory, ProMyMoveOptions,
  ProData, ProTransport, ProOtherMoveOptions) are reachable from the
  GameData object graph that the battle calculator deep-copies via
  Java serialization (`BattleCalculator.translateCollectionIntoOtherGameData`
  → `GameDataUtils.translateIntoOtherGameData` → `IoUtils.writeToMemory`).
  `LinkedHashMap`/`HashMap` serialize transparently; a `TreeMap` whose
  comparator is a plain lambda throws `NotSerializableException:
  …$$Lambda` at regen time. FIX: intersection-cast the key extractor
  to `(Function<T,String> & Serializable)` so `Comparator.comparing`
  yields a serializable comparator (see `ProDeterministicOrder`). Any
  future field-type change in these classes MUST preserve
  serializability.
- **(iter 49) Unit.id is RANDOM per JVM run** (`UUID.randomUUID()` at
  `Unit.java:122`). The iter-48 premise "Java fully content-deterministic
  across runs" is FALSE. Determinism is only WITHIN a snapshot set
  (before.json freezes the UUIDs). This is why Approach A REQUIRED a
  regen: old snaps encoded LinkedHashMap-insertion-order AI decisions;
  new snaps encode UUID-sorted-TreeMap decisions that Odin can replay
  by sorting the same frozen UUIDs (iter-50). Corollary: any
  regen-vs-on-disk diff is expected to be 100% UUID + timestamp churn.
- **(iter 49) Driver `.odin` MUST NOT be overwritten by regen.** The
  `process_snapshots.py` output ships a `test_…run_next_step.odin` that
  calls `run_snapshot_tests` + `server_game_run_next_step`; the
  hand-customized on-disk driver calls
  `run_snapshot_tests_server_game` + `game.test_server_game_run_next_step`.
  When swapping regen output, copy ONLY the `snapshots/` dir, never the
  driver.


- **(iter 47) NCM-planner SEA-ZONE state divergence PROVEN.**
  `MOVE_ROUTES_DIGEST` probe at 4 checkpoints inside
  `pro_non_combat_move_ai_do_move` (after `calculate_move_routes`,
  after first `do_move`, after `calculate_amphib_routes`, after
  second `do_move`) shows BOTH calc procs receive different inputs
  across runs. Run 1 vs run 2: `calculate_move_routes` emits SZ 63
  transport routing to DIFFERENT destinations (60 vs 62). Run 3 vs
  run 4: `calculate_amphib_routes` emits an EXTRA SZ 63→60 transport
  repositioning in run 3 only, despite IDENTICAL `calc_move_routes`
  digest upstream. Run 3 vs run 5: amphib loads flip (60→61 with
  armour+infantry+transport vs 60→62 with just armour+transport).

  Translation: `Pro_Territory.units` and `Pro_Territory.amphib_attack_map`
  at the China-coast sea zones (SZ 60, 61, 62, 63) are populated
  with DIFFERENT contents across runs by the NCM planner BEFORE
  the route calculators ever execute. Iter-42 MOVE_PLAN proof was
  INCOMPLETE — it filtered destinations to Japan/Manchuria/Yunnan
  (land only) and missed all sea-zone Pro_Territory state.

  **Iter-48 PRIMARY suspect:** `ProNonCombatMoveAi#moveUnitsToBestTerritories`
  (Java l.1479; Odin
  `pro_non_combat_move_ai_move_units_to_best_territories`) populates
  attack/defence sea-zone `pt.units`/`pt.amphib_attack_map`.
  **Iter-48 secondary suspect:** `moveUnitsToDefendTerritories`
  (Java l.3628; Odin equivalent).

  Iter-48 must add `PLAN_INPUT_DIGEST` probe at NCM-planner exit
  (just before `calculate_move_routes` is called) covering ALL
  Pro_Territory entries in the move_map (not just land destinations).
  If digest varies across runs ⇒ leak is in the named planner
  sub-procs; if identical ⇒ leak is INSIDE the two calc procs
  themselves (carrier_must_move_with iteration, unit_territory_map
  pointer lookup, or get_route_for_unit tied-distance tiebreak).

- **(iter 46) NCM-exit divergence PROVEN.** `NCM_END_STATE` probe at
  end of `do_non_combat_move` + entry of `pro_purchase_ai_purchase`
  shows Japan unit-set varies in 4 distinct outcomes across 5 ASLR
  runs. The two digests are identical per-run ⇒ no mutation
  between NCM and purchase ⇒ NCM is the sole leak.

  Iter-47 must instrument the `pro_non_combat_move_ai_move_*`
  family with `MOVE_PLAN_DIGEST` probes at entry/exit and binary-
  search for the first proc whose exit differs while entry
  matches.

  **Allocator-perturbation antipattern observed.** Iter-44/45
  added 9 sort-fix call sites in `pro_purchase_ai`. Each sorted
  helper allocates a fresh `[dynamic]^Unit` or
  `[dynamic]^Territory`. Those allocations during the simwalk's
  purchase phase perturb heap addresses, which then shifts NCM's
  pointer-keyed map iteration when NCM runs later in the same
  process. This is why iter-46 sees MORE NCM-exit outcomes (4)
  than iter-43 saw (2). The iter-44/45 fixes are not wrong, but
  they amplify visibility of the upstream NCM nondeterminism.
  FIXING NCM IS STRICTLY REQUIRED.

  **Token-budget rule.** Last 2 sessions burned tool-budget
  polling the 5-run batch with foreground `tail --pid` or sleep
  loops. New protocol: launch via `setsid nohup ... & disown`,
  immediately end the turn after verifying the runner pid exists,
  and let the terminal-completion notification fire automatically
  on the next turn.

- **(iter 45) `purchase_land_units` + `purchase_defenders` +
  `purchase_factories` 5-site sort fix SHIPPED. Stock PASS rate
  3/5 → 2/5 — NO improvement. Pattern-matching on purchase-AI
  exhausted; residual leak is UPSTREAM in NCM.**

  After 9 total purchase-AI pointer-map iteration sites converted
  to deterministic-sorted iteration (iter 44: 4 sites in
  `purchase_sea_and_amphib_units`; iter 45: 5 sites across
  `purchase_land_units` l.3043, `purchase_defenders` l.2525/2768,
  `purchase_factories` l.3312/3327), the flake band has not
  moved. Identical failure pattern: `Japanese armour=1/exp 0,
  infantry=8/exp 10` (cost-equivalent 6-PU swap).

  Diagnosis: the purchase pool divergence is now PROVEN to be a
  downstream symptom of upstream NCM unit-set divergence — every
  purchase-AI internal iteration that could matter is already
  sorted. Layer 29a `do_move` is the only YELLOW upstream node;
  iter-46 must instrument it with `NCM_END_STATE` digest probe
  per status doc Next-action plan, not add a 10th purchase-AI sort.

  **HARD RULE recorded:** do NOT add another purchase-AI sort
  without first proving via `NCM_END_STATE` digest that PASS and
  FAIL runs see identical Japanese unit-collection state at NCM
  exit. If digests differ ⇒ fix the NCM divergence first.

- **(iter 44) sea-defender setup deterministic-sort fix SHIPPED.**
  Stock binary PASS rate 2/5 → 3/5 (matches iter-43 probe binary
  3/5). Same residual failure pattern: `Japanese armour=1/expected 0,
  infantry=8/expected 10` (cost-equivalent 6-PU swap).

  Stock baseline measurement (no probes, ran BEFORE iter-44 fixes
  to disambiguate probe-induced perturbation from actual leak)
  confirmed 2/5 PASS rate is real: failures BYTE-IDENTICAL to
  iter-43 probe binary. Therefore residual leak is NOT
  probe-induced and probes do not perturb the outcome in any
  problematic way (validates earlier allocator-perturbation
  concern at pro_move_utils.odin l.690).

  Iter-44 fix targets four pointer-keyed iterations in the
  SEA-DEFENDER setup of
  `pro_purchase_ai_purchase_sea_and_amphib_units` (BEFORE the
  AMPHIB section which iter-43 stabilised):
  1. `neighbors` map (l.3654) → `pro_determinism_sorted_territory_keys`.
     Feeds `owned_local_units` → support-factor float sum
     (order-sensitive).
  2. `attackers_set` (l.3690) → new UUID-tie-break helper.
     Feeds `calculate_battle_results` Monte Carlo.
  3. `mu_set` / `mb_set` (l.3880/3885) → UUID-tie-break helper.
     Feeds `estimate_defend_battle_results`.
  4. `bombard_set` (l.3748) → UUID-tie-break helper. Feeds
     `calculate_battle_results`.

  New helper `pro_determinism_sorted_unit_keys_with_uuid` added
  to `pro_determinism.odin`: sorts `map[^Unit]V` by
  `(owner_name, type_name, already_moved, UUID[0..16])`. UUID
  bytes give strictly-total tiebreak even for multiple same-type
  same-owner units, eliminating the
  `stable_sort_by`-with-ASLR-input fallback used by the older
  `pro_determinism_sorted_unit_keys` helper.

  Verification (`/tmp/snaprun_stock_iter44b`, 5× ASLR-on
  snap 0089): P/F/P/F/P = **3/5 PASS**. Net +1 PASS vs stock
  baseline. Residual leak still hits ~40% of runs with
  always-same divergence ⇒ one tied-float greedy decision
  remains ASLR-perturbed.

  Next: iter 45 audits `purchaseLandUnits` (l.2868) which has the
  same `for nb, _ in neighbors` pattern at l.3043 that iter-44
  just fixed at l.3654. Memory: `/memories/repo/iter44-purchase-sea-defender-fix.md`.

- **(iter 43) calculate_amphib_routes deterministic-sort fix
  SHIPPED. PASS 1/5 → 3/5; NCM 09_after_doMove byte-identical in
  4/5 runs.** Diagnosis: Java's `amphibUnitSortKey` 5-field
  composite key is NOT unique for same-type Japanese transports
  in the same sea zone with identical load state; Java relies on
  stable TimSort + HashMap-iteration order to break ties. Odin
  was using `slice.sort_by` (unstable pdqsort) + `for u in
  amphib_attack_map` (pointer-keyed ⇒ ASLR-random input). Result:
  fully nondeterministic transport processing order, → different
  Japanese units consumed/loaded per run, → different post-NCM
  unit_collection.
  Fix in
  `odin_flat/games__strategy__triplea__ai__pro__util__pro_move_utils.odin`:
  (1) extended `pro_move_utils_amphib_unit_sort_key` (l.15) with
  a loaded-unit-types signature AND a 32-char hex of
  `unit_get_id(u)` (the stable per-snap Unit UUID) as the final
  tie-break; (2) changed `slice.sort_by(pairs[:], ...)` to
  `slice.stable_sort_by(pairs[:], ...)` in both
  `calculate_amphib_routes` (l.430) and
  `calculate_bombard_move_routes` (l.706).
  Verification (5× ASLR-on snap 0089,
  `/tmp/snaprun_rpo_ncmu3.kept`): runs 1–4 all produce
  `09_after_doMove n=3 types=aaGun, armour, factory` (byte-
  identical); run 5 produces `n=4 types=aaGun, artillery,
  factory, infantry` (residual leak inside the proc). PASS rate
  3/5 (FAIL/PASS/FAIL/PASS/PASS). The FAIL/PASS split between
  identical-NCM runs (1 vs 2; 3 vs 4) correlates with `rem_prod`
  at SZ62 (3=FAIL, 1=PASS) ⇒ a separate downstream LEAK C in
  `purchase_sea_and_amphib_units`.
  Artifacts: `/tmp/iter43_run{1..5}.{stderr,stdout}.kept`,
  `/tmp/snaprun_rpo_ncmu3.kept`. Memory:
  `/memories/repo/iter43-amphib-routes-fix.md`. **Next iter (44)
  targets:** (a) AMPHIB_INNER probe to find run-5 deviation inside
  `calculate_amphib_routes`; (b) PURCH_GREEDY probe to find LEAK
  C in `purchase_sea_and_amphib_units`.

- **(iter 42) NCM LEAK LOCALISED TO `do_move` (the executor),
  NOT THE PLANNER.** Built `/tmp/snaprun_rpo_ncmu` with
  `RPO_DUMP=true` and 8 `NCM_UNITS` probes inside
  `pro_non_combat_move_ai_do_non_combat_move` (00..08). Ran
  5× snap 0089 ASLR-on: all 8 labels byte-identical at Japan
  (n=8, sorted types `aaGun, armour, artillery, factory,
  4× infantry`); AMPHIB own_n = 2/4/2/3/2 (1/5 PASS). Built
  `/tmp/snaprun_rpo_ncmu2` adding `08b_before_doMove`,
  `09_after_doMove`, and `MOVE_PLAN dst=… japan_units_n=… [i]type@ptr`
  (dumps every Japan-origin unit in each Pro_Territory's
  `.units` slice — the planner's output that feeds `do_move`).
  Ran 3× snap 0089 ASLR-on: MOVE_PLAN byte-identical (only ptr
  values change from ASLR), 08b_before_doMove identical n=8 —
  but 09_after_doMove = **n=5, n=3, n=2** across the 3 runs.
  The executor `pro_non_combat_move_ai_do_move` (`pro_non_combat_move_ai.odin`
  l.1226) consumes a deterministic `move_map` but removes
  DIFFERENT units from Japan each ASLR roll. Prime suspect:
  `pro_move_utils_calculate_amphib_routes` (`pro_move_utils.odin`
  l.392) — it iterates `pro_territory_get_amphib_attack_map(pt)`
  which is `map[^Unit][dynamic]^Unit` (pointer-keyed map ⇒
  nondeterministic across ASLR). Amphibious operations from
  Japan to Manchuria/Yunnan (sea zones 60, 62) DO mutate
  Japan's `unit_collection`, which matches the symptom.
  Artifacts: `/tmp/iter42_run{1..5}.{stderr,stdout}.kept`,
  `/tmp/iter42b_run{1..3}.{stderr,stdout}.kept`. Memory:
  `/memories/repo/iter42-do-move-leak.md`.

- **(iter 41) NCM LEAK CONFIRMED AT PER-UNIT GRANULARITY;
  NCM_TRACE AGGREGATE HASH IS INSUFFICIENT.** Built
  `/tmp/snaprun_rpo_ncm` with `RPO_DUMP=true NCM_TRACE=true`,
  ran 5× snap 0089 ASLR-on. Results: PASS / FAIL / FAIL / PASS
  / FAIL (2/5 PASS). **All 11 `NCM_TRACE` label hashes match
  byte-identical across all 5 runs** (`diff` of the two
  `.ncm` files is empty), yet AMPHIB outcomes diverge.
  `pro_ncm_trace_emit` only hashes per-territory aggregates
  (`U=len(units)|C=...|M=...|V=int(value*1000)|H=...`), never
  unit identities — so it is blind to NCM moving DIFFERENT
  individual units between territories while preserving counts.
  Built second binary `/tmp/snaprun_rpo_amphib` (RPO_DUMP +
  AMPHIB_PROBE) and ran 3× so far: `own_n@Japan` =
  **5, 3, 2** — Japan's `unit_collection.units` count itself
  varies across runs of the SAME binary. NCM physically moves
  different units off Japan each ASLR roll. Iter-42 must add
  per-unit identity probes inside NCM sub-phases.
- **(iter 41) WARNING: ITER 40'S TRACE-TABLE COLUMN "ttnu_n
  constant" WAS A COINCIDENCE.** With NCM_TRACE OFF the
  AMPHIB-OUTER `own_n` happened to be 3 in all iter-40B runs
  (allocator state pattern). With AMPHIB_PROBE alloc included,
  own_n varies 2/3/5. The real determinism layer is NCM, not
  the GATHER loop. GATHER is deterministic GIVEN inputs; its
  inputs are not deterministic.
- **(iter 40) LEAK B REFUTED; LEAK A CONFIRMED AS SOLE
  RESIDUAL.** Added `PHASE_PUS` probes at all 5 pre-amphib
  phase boundaries in `pro_purchase_ai_purchase`, and
  `AMPHIB_GATHER_DONE` probe inside
  `pro_purchase_ai_purchase_sea_and_amphib_units` reporting
  `transports_that_need_units` count and
  `potential_units_to_load` count just before the greedy
  purchase loop. 9 total ASLR-on snap-0089 runs across iter-40A
  (PHASE_PUS only) and iter-40B (+AMPHIB_GATHER_DONE).
  - **Iter 40A (5 runs)**: PUs at P00→P05 are 35→35→35→25→25→25
    in EVERY run regardless of PASS/FAIL. Pre-amphib pipeline is
    fully deterministic. **LEAK B does not exist.**
  - **Iter 40B (5 runs, 1/4 PASS)**: `ttnu_n@t=60=3` and
    `ttnu_n@t=62=4` constant across runs (GATHER loop is
    deterministic). But `own_n@Japan` fluctuates 2..5 across
    runs even at constant pre-NCM japan_n; and run 4 (FAIL,
    own_n=3, ptl_n@t=60=4) and run 5 (PASS, own_n=3,
    ptl_n@t=60=2) share own_n but DIFFER in adjacent-territory
    unit counts.
  - Conclusion: NCM moves DIFFERENT Japan units to DIFFERENT
    non-Japan destinations across ASLR runs. Iter-39's
    "purchase pipeline leak" interpretation was an artifact of
    differing `owned_local_amphib_units` and neighbor state
    fed in by upstream NCM. **`pro_non_combat_move_ai` is the
    sole residual flake source.**
- **(iter 39) FIX SHIPPED, STILL NECESSARY.** Java-fidelity fix
  in `pro_purchase_ai.odin`: `prioritize_sea_territories`
  replaced pointer-keyed `map[^Pro_Place_Territory]struct{}` with
  insertion-ordered list + dedup map (LinkedHashSet semantics
  per `/memories/java-hashmap-iteration-order.md`). Both
  `slice.sort_by` call sites upgraded to `slice.stable_sort_by`
  (Java `List.sort` is a stable mergesort). 3× ASLR-on snap-0089
  reruns: 2/3 PASS. Two residual leaks were suspected:
  - **LEAK A (sim-walk NCM):** runs 1 and 2 differ in jNCM
    outcome (8→4 vs 8→3) with the SAME pre-NCM state. Iter-38
    falsification of this hypothesis was a 2-sample coincidence.
    Likely a `map[^Territory]` or `map[^Unit]` iteration inside
    `pro_non_combat_move_ai_simulate_non_combat_move` (or a
    callee) that affects which Japan units get moved away.
    **CONFIRMED in iter 40.**
  - **LEAK B (pre-amphib purchase PU accounting):** runs 1 and
    3 have IDENTICAL post-NCM state (japan_n=4, same bp
    composition) but produce different purchases (run 1
    armour; run 3 infantry) and different `rem_prod`
    (3 vs 2) at the t=62 amphib iteration. Some pre-amphib
    phase (`purchase_aa_units`, `purchase_defenders_land`,
    `purchase_defenders_sea`, `purchase_land_units`, or
    `purchase_factory`) consumes production in ASLR-dependent
    order. **REFUTED in iter 40.** The "identical post-NCM
    state" was an illusion: NCM produces different units placed
    in different non-Japan territories that subsequently feed
    into `owned_local_amphib_units` and `potential_units_to_load`
    differently.
- **(iter 38) ~~BLOCKER MOVED — leak is INSIDE the purchase
  pipeline, NOT in the sim-walk loop as iter-37 hypothesised.~~**
  PARTIALLY FALSIFIED by iter 39. The sim-walk IS leaky in
  some samples (runs 1+2 of iter 39 show different NCM
  outcome with same input). The iter-38 conclusion was based
  on 2 samples that happened to land on identical NCM outcomes.
  The purchase-pipeline leak (LEAK B above) is REAL and remains.
- **(iter 37) ~~BLOCKER LOCALIZED FURTHER — leak is BEFORE
  `pro_purchase_ai_purchase`, inside the sim-walk loop in
  `abstract_pro_ai.odin` (line ~824).~~** FALSIFIED in iter 38.
  Sim-walk is deterministic; the iter-37 split (PASS n=3 vs
  FAIL n=5) was coincidence from sampling two ASLR variants
  whose pre-sim state happened to differ. The real flaky
  iteration is downstream, inside the purchase pipeline.
- **(iter 36) BLOCKER LOCALIZED — leak is BEFORE
  `purchase_sea_and_amphib_units`.** `TERR_DUMP_JAPAN_ENTRY`
  probe shows Japan's `unit_collection.units` differs (run-1
  PASS n=4 with infantry+artillery present; run-2 FAIL n=2 with
  only aaGun+factory) at the very first instruction of
  `purchase_sea_and_amphib_units`. The `prioritized_sea_territories`
  parameter is ALSO in different order across runs ([62,62,60] vs
  [60,62,62]). Both are inputs supplied by `pro_purchase_ai_purchase`
  or its preceding sim-clone NCM/CM pipeline. Iter 37 must add a
  probe at the entry of `pro_purchase_ai_purchase` and at the
  source of `prioritized_sea_territories` to bisect further.
- **(iter 35) BLOCKER PARTIAL — leak located upstream of
  `purchase_sea_and_amphib_units` entirely.** AMPHIB_OUTER probe
  added (gated, no overhead when off). 2× ASLR-on diff captures:
  Japan's `unit_collection` has different owned-by-Japanese
  counts (2 vs 4) at the very first `AMPHIB_OUTER` call —
  meaning the territory state was already different on entry to
  the amphib loop. `purchase_sea_and_amphib_units` and
  `calculate_support_factor` (iter 34 fix) are now BOTH
  deterministic given identical inputs; the inputs are not
  identical. The leak is in `ProPurchaseAi#purchase` itself OR in
  the AI sim-clone NCM/CM/factory-placement pipeline run before
  the purchase decision. **Iter 36 must add a `TERR_DUMP_JAPAN`
  probe at the entry of `purchase_sea_and_amphib_units` to
  determine whether the divergence is on entry (so leak is
  upstream of that function) or inside (so leak is downstream).**
- **(iter 35) Probe code shipped (gated).** In
  `pro_purchase_ai.odin`:
  - line ~3594 (start of sea-place-territory loop): `AMPHIB_SEA_PT t=...`
  - line ~4201 (after `territory_get_matches` for
    `owned_local_amphib_units`): `AMPHIB_OUTER t=... land=...
    spt_n=... own_n=... rem_prod=...` plus per-unit dump.
  - Both guarded by `when #config(RPO_DUMP, false)` and
    `_pname == "Japanese"`. Build with `-define:RPO_DUMP=true`.
- **(iter 34) BLOCKER PARTIAL — `calculate_support_factor` sort
  fix shipped in
  `games__strategy__triplea__ai__pro__data__pro_purchase_option.odin`.
  Two pointer-keyed iterations are now sorted by attachment
  `.name`: `rules_dyn` (built from
  `unit_type_list_get_support_rules(utl)`) and `usa_keys` (built
  from `self.unit_support_attachments`). Float-summation
  `total_support_factor += support_factor` is now deterministic
  given identical inputs. Verified via `RPO_DUMP=true` probe:
  artillery `sf=0.9095` stable across all CSF calls within a run;
  pass rate up to 60% (vs 20%). The remaining flakiness is an
  upstream leak that causes `owned_local_amphib_units` count to
  differ across ASLR runs (concrete evidence: run 5 `units_n=4`
  → sf=0; run 6 `units_n=6` → sf=0 at the SAME Amphib call with
  identical `rand=89.92`). Iter 35 must probe the outer Amphib
  loop (`AMPHIB_OUTER` probe) to pinpoint which iteration order
  changes.**
- **(iter 34) `pow(...,30)` amplification confirmed.** In
  `pro_purchase_option_get_amphib_efficiency`, the eff value
  uses `pow(attack_value, 30)` and `pow(defense_value, 30)`.
  A 5% difference in `support_attack_factor` becomes a ~4× swing
  in eff for artillery, which flips the cumulative
  `upper_bound > random_number` boundary in
  `randomize_purchase_option` → different unit picked →
  cascading state divergence. Lesson: pointer-keyed iteration
  in any function feeding `pow(..., N)` for large N is a leak
  candidate with disproportionate impact.
- **(iter 34) Java side may need patching too (deferred to
  iter 35+).** `ProPurchaseOption.unitSupportAttachments` is a
  `HashSet<UnitSupportAttachment>` (JVM-run-dependent iteration
  order). `UnitTypeList.getSupportRules()` is also `HashSet`. The
  Odin fix uses `.name` sort for determinism but does not
  necessarily match the JVM order at snapshot capture. If
  snap 0089 still fails consistently in ASLR-off mode after
  upstream fixes, add a `patch_pro_purchase_option_support` in
  `scripts/patch_triplea.py` to sort both sources by name in the
  Java code, then re-capture snapshots.
- **(iter 34) Chat-tool batch-run hazard.** `kill_terminal` on a
  polling shell sends SIGHUP → SIGINT propagates to the test
  framework, which catches it and prints
  `"Caught interrupt signal. Stopping all tests."`, corrupting
  any in-flight `for i in ... done` batch. Workaround: run
  batch via `nohup setsid ... &` or accept that interrupted
  runs (e.g. runs 7, 9, 10 in iter 34) must be excluded from
  the tally and rerun.
- **(iter 33) BLOCKER PARTIAL — `randomize_purchase_option`
  insertion-order fix is shipped at all 9 caller sites in
  `pro_purchase_ai.odin`. Java fidelity is now correct here
  (Java's `LinkedHashMap<ProPurchaseOption, Double>` →
  iterate in insertion order → sum). 3/3 ASLR-off PASS confirms
  the fix doesn't break anything; 3+/5 ASLR-on FAIL confirms it
  is necessary but not sufficient. Additional pointer-keyed map
  iteration leak(s) remain in the ProPurchaseAI pipeline. Iter 34
  must re-narrow under the iter-33 binary (PUR_TRACE or a
  lighter probe), then patch the next leak site.**
- **(iter 33) Validated ASLR is the source of snap-0089 flakiness.**
  Method:
  1. `setarch -R timeout 480 /tmp/snaprun_fast` (ASLR-off, lean
     iter-31 binary, 3 runs) → all PASS, proving the seed/RNG
     path is deterministic when pointer hashes are.
  2. PUR_TRACE binary with iter-31 code → 3/3 IDENTICAL FAIL
     hashes (PUR_TRACE perturbs allocator enough to hide ASLR
     effect, BUT consistently produces the FAIL path).
  3. iter-33 lean binary with fix, `setarch -R` → 3/3 PASS.
  4. iter-33 lean binary with fix, no `setarch` → 4/5 FAIL,
     1/5 PASS — same `armour 0/1, infantry 10/8` tally on failures
     as iter 32. PASS rate is roughly consistent with iter-31
     baseline (1/5 = 20%); the iter-33 fix does not visibly
     improve ASLR-on stability for snap 0089 (additional leaks
     are bigger contributors).
- **(iter 33) Verification recipe for additional ASLR leak
  hunting:**
  ```sh
  # Build lean binary (no PUR_TRACE; PUR_TRACE masks ASLR effects):
  cd /home/caleb/todin/triplea && /run/current-system/sw/bin/odin build \
    conversion/odin_tests/server_game_run_next_step \
    -collection:flat=../odin_flat \
    -collection:test_common=conversion/odin_tests/test_common \
    -build-mode:test -define:ODIN_TEST_TRACK_MEMORY=false \
    -extra-linker-flags:-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib \
    -out:/tmp/snaprun_fast

  # Test ASLR-on:
  TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP=0089 \
    timeout 480 /tmp/snaprun_fast 2>&1 | grep -E "FAILED|PASSED|divergence"

  # Test ASLR-off (proves the fix works):
  TRIPLEA_BATTLE_PRECACHE_ENABLED=0 FILTER_SNAP=0089 \
    setarch -R timeout 480 /tmp/snaprun_fast 2>&1 | grep -E "FAILED|PASSED|divergence"
  ```
  Run each set 5×. ASLR-off must be 5/5 PASS. ASLR-on is the
  metric: target 30/30 PASS once all leaks are plugged.
- **(iter 33) Sites already ruled out (do NOT re-investigate):**
  see "Iter 33 — candidate sites already ruled out" in Last action.

- **(iter 32) BLOCKER (now downgraded after iter-33 partial fix) —
  snap 0089 is non-deterministic across runs.** The iter-31 87/17
  sweep saw PASS on snap 0089, but re-running the SAME binary on
  snap 0089 in isolation produced PASS-TIMEOUT-PASS over 3
  sequential runs. The "PASS" outcomes are real (game state
  matches Java); the "TIMEOUT" is a 4-minute run hitting the
  240s budget — same FAIL semantics for sweep bookkeeping.
  Conclusion: snap 0089 outcome at iter-31 code state depends on
  per-process ASLR (pointer-hash-keyed map iteration order
  somewhere in the ProPurchaseAI pipeline). Iter 33 patched ONE
  such leak (`randomize_purchase_option` sum); more remain.
- **(iter 32) bisection of iter-31 scaffold was inconclusive.**
  Tested "variant A" (restore iter-27/Java early `transporting`
  check before sort allocation in `_from_territories`) across
  4 rebuilds; same code state gave opposite results on snap 0089.
  Reverted variant A — current code is iter-31 byte-for-byte.
- **(iter 32) lesson.** Snap-level PASS/FAIL is not a reliable
  signal when AI logic consumes pointer-hash-keyed map iteration.
  Single-run results across rebuilds will contradict each other
  by ASLR-noise. Need substrate-level determinism (probe + sort
  at the leak site) before scaffold-level bisection can be
  trusted.
- **(iter 31) UNEXPECTED WIN.** Full sweep is 87/17, the new best.
  Snap 0089 PASSES even though iter-31's *intended* code change
  was a full revert of iter-30. The PASS is incidental to the
  iter-30 refactor *scaffolding* (which iter 31 kept as dead
  code): either the new `_from_ordered_territories` overload's
  extra `[dynamic]^Territory` allocation OR removal of the
  duplicate `unit_get_transporting_no_args` call. Iter 32 must
  isolate which.  _[iter 32 update: neither — flaky ASLR roll.]_
- **(iter 31) bisection was misleading.** The 4-state bisection
  table at the top of `## Last action` showed snap 0089 failing
  in 3 of 4 states, including iter31d (bucket-sort OFF +
  insertion_order OFF). But iter31d only re-ran snap 0025, not
  snap 0089. The post-rollback FINAL build (22:39:30) is the
  first time snap 0089 was retested in the truly-clean state, and
  it PASSED. Lesson: when rolling back, retest BOTH canary snaps,
  not just the regressed one.
- **(iter 31) iter-30 algorithmic changes were noise.** Bucket-
  sort by `(bucket, name)` and `insertion_order` LinkedHashMap-
  faithful sum are both correct Java-fidelity instincts but
  neither was the actual divergence on snap 0089. They added a
  snap-0025 regression and traded it for a snap-0032 incidental
  gain. Iter 31 keeps the GOOD half (refactor scaffold).
- **(iter 30) BLOCKER RESOLVED — LinkedHashSet bucket-order in
  `purchaseSeaAndAmphibUnits`.** Iter-29 narrowed snap 0089 to
  P06; iter-30 used AMPHIB_PROBE to see that the inner
  `for transport in transports` loop was iterating
  `territoriesToLoadFrom` in alphabetical order while Java
  iterates it in `HashSet<Territory>` bucket order. **Pattern
  lesson:** when porting a Java `HashSet<X>` populated FROM
  another collection, the iteration order is the
  `String.hashCode()` bucket order over a capacity fixed at
  construction (NOT recomputed after `removeIf`). The fix
  template (now reusable):
  1. Capture `raw_size` BEFORE any `removeIf` filtering.
  2. `cap := java_hashmap_capacity_for_size(raw_size)`.
  3. `java_hashmap_sort_territories_by_bucket(slice, cap)` to
     impose Java's iteration order.
  4. Iterate the sorted slice instead of the bare map.
  Also fixed a parallel float-precision divergence in
  `randomize_purchase_option`: Java sums efficiencies in
  `LinkedHashMap` insertion order; Odin was summing in random map
  order. Added optional `insertion_order` parameter. Both amphib
  call sites now pass their option-list slice.
  Cross-ref: `/memories/java-hashmap-iteration-order.md`.
- **(iter 30) Residual on snap 0089: `PUs: 1 != 0`.** Unit tally
  is now exact; Japan ends round with 1 PU unspent that Java
  spent. Smaller, separate divergence — likely another
  map-iteration order effect downstream (suspected
  `removeInvalidPurchaseOptions` or one of the 6 remaining
  `randomize_purchase_option` non-amphib call sites). Drillable
  in iter 31 with AMPHIB_PROBE + Java oracle comparison.
- **(iter 29) BLOCKER RESOLVED.** Iter-28's tracer-perturbation
  blocker is fixed by routing all PUR_TRACE allocations through
  `context.temp_allocator` (1 file change in
  `pro_pur_trace.odin`). Snap 0089 now FAILS deterministically
  with trace on, matching the no-trace symptom byte-for-byte, AND
  prints 10 checkpoint hashes that immediately localised the bug
  to `purchaseSeaAndAmphibUnits` (P06). **Pattern lesson for future
  tracers:** any diagnostic instrumentation in mid-game code
  paths MUST use `context.temp_allocator` (or a single fixed
  scratch buffer); default-allocator allocations shift downstream
  pointer-keyed map iteration order and mask the exact bugs the
  tracer is meant to find. Codified in
  `/memories/repo/snap-0089-iter28-blocker.md`.
- **(iter 28) [resolved iter 29] BLOCKER: PUR_TRACE tracer perturbs
  the bug it tries to diagnose.** `pro_pur_trace_emit` allocated
  via default `context.allocator`; on snap 0089 those shifts
  flipped the AI's purchase decision back to Java-faithful state
  (test PASSED with trace on, FAILED without). Fixed iter 29 by
  temp_allocator-only allocations.
- **(iter 27)** **Memory / durability recipe for full sweeps.**
  The debug build (`/tmp/snaprun`, ~9.6 MB, includes per-step
  DIGEST + Odin's leak tracker) produces ≈ **3 GB per failing-snap
  log** when 18+ snaps fail, which fills disk and crashes the
  sweep terminal (this happened twice in iter-27 before pivoting).
  **Always use the lean binary for sweeps:**
  - Build: add `-define:ODIN_TEST_TRACK_MEMORY=false` and drop
    `-debug` → `/tmp/snaprun_fast` (5.2 MB).
  - Per-snap RSS ~3 MB; per-failing-snap log ~4 KB; 0001 smoke
    in 24 ms (vs 88 ms debug).
  - DO NOT use lean binary for leak / fault diagnosis — use the
    debug binary for that, one snap at a time.
  - Sample peak RSS via `awk '/VmRSS/{print $2}' /proc/$PID/status`
    in a polling loop (NixOS has NO `/usr/bin/time`; `ls` is
    aliased to `eza` so use `\ls`).
  - Launch sweep detached so terminal death doesn't kill it:
    `setsid nohup script.sh >log 2>&1 </dev/null & disown`,
    then poll a touch-file (`_DONE`) for completion.
  - Use `xargs -P 4` (not 8) to leave RAM/disk headroom.
  - Cap per-snap log with HEAD-5 + TAIL-60 only (or grep-filter
    inside the xargs cmd) to keep total disk footprint small.
- **(iter 26)** **iter-25 regression RESOLVED.** Root cause was
  `give_support_to_unit` iterating the OUTER `support_rules`
  `LinkedHashMap` via Odin bare-map (pointer-hash). Fix: added
  `support_rules_order` + `support_units_order` parallel slices
  to both `Support_Calculator` and `Available_Supports`, threaded
  through the builder, and rewrote 3 iteration sites
  (`give_support_to_unit` outer loop, `filter`,
  `get_unit_support_attachments`). Snap 0032 is now 5/5
  DETERMINISTIC (was 0P/3F/2HANG iter-25, 2P/1F iter-23).
  The remaining snap-0032 FAIL is a real 1-infantry swap to fix
  later (iter 27 Task C). Snap 0024 unchanged \u2014 confirms the
  divergence lives outside the support pipeline.
- **(iter 25)** **REGRESSION on snap 0032 from iter-25's Java-fidelity
  fix.** The 5 file changes (MainOffenseStrength accessor +
  Integer_Map_Unit.keys_order + Available_Supports.units_giving_support_order
  + producer/consumer wiring) are individually Java-faithful per
  `AvailableSupports.java:31-60` (all three suspect collections use
  `LinkedHashMap`), but the combined effect made snap 0032 worse:
  5-run loop = 0 PASS / 3 FAIL / 2 HANG (vs iter-23 2P/1F).
  Snap 0024 unchanged (same divergence, same regions). Most likely
  cause: the upstream caller that populates `Integer_Map_Unit`
  inside the builder loop is itself iterating a bare map
  (`support_rules` or `support_units`) in pointer-hash order, so
  the new `keys_order` slices capture a still-non-Java order. The
  two HANGs additionally suggest a UAF or busy loop in
  `get_next_available_supporter` after the `integer_map_unit_remove`
  call. **Iter 26 must triage this regression before further
  forward work.** See "Next action" Task A-E for the bisect /
  audit plan. DO NOT run a full 104-snap sweep until snap 0032 is
  back to deterministic PASS.
- **(iter 25)** Disk discipline: a 5-run solo loop for snap 0032
  with leak-tracker on can produce **~9 GB of per-step debug spam**
  (3 × 2.9 GB logs). For iter-26 reproductions, either build a
  `-define:ODIN_TEST_TRACK_MEMORY=false` variant or pipe through
  `grep -E 'PASS|FAIL|FATAL|leak' > log` to keep disk usage sane.
  Logs cleaned at iter-25 close.
- **(iter 24)** Snap 0032 is **intermittent** (PASS solo run #1
  in 58.83 s; FAIL solo run #2 in 61.09 s with British inf swap
  Alaska↔Eastern Canada). This is a NEW regression vs iter 21
  (which passed it deterministically because the iter-22-discovered
  value-copy bug masked the upstream pointer-hash iteration order
  of `Available_Supports.units_giving_support` and
  `Integer_Map_Unit.entries`). A 5-run repro launched at iter-24
  close confirms intermittency (see `/tmp/snap0032_iter24_repro/`).
  **Iter 25 must fix this** before the regression sweep is
  representative. _UPDATE iter 25:_ The three planned fixes were
  shipped but caused a regression — see iter-25 entry above. The 3 specific fixes are listed in "Next action"
  Task A/B/C above and as `Files of immediate interest`:
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__main_offense_combat_value__main_offense_strength.odin:52`
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__integer_map_unit.odin`
  - `odin_flat/games__strategy__triplea__delegate__power__calculator__available_supports.odin`
    and `…/available_supports__support_details.odin`
- **(iter 24)** L9 drill results for snap 0024 are documented in
  "Trace table (iter 24)" — DummyPlayer.selectCasualties cleared
  via Java fidelity verification (no AI call sites for setter +
  default false), CasualtyUtil.getDependents cleared as
  "green-for-snap" (no transports in this battle), CombatValue
  remains yellow with 3 specific suspect identified.
- **(iter 23)** Pointer-refactor `unit_support_power_map` /
  `unit_support_rolls_map` to `map[^Unit]^Integer_Map` SHIPPED.
  This is the right fix for the iter-22 root cause. The cost is a
  large slowdown in any snap whose AI evaluates combat — iter-21
  was silently truncating Java's support-power calculations, so
  the AI did less work. Snap 0073 went from "<60s pass" to "3m 40s
  pass"; snap 0032 from "fast pass" to "1m 6s pass". Snap 0024
  exceeded the 600s individual cap (was 37s FAIL iter-21) —
  whether it converges or still diverges is iter-24's task. A
  full 104-snap regression sweep is running in background at
  iter-23 session end (`/tmp/snap_results_iter23/`); analyze with
  `for f in /tmp/snap_results_iter23/*.txt; do tail -1 "$f"; done
  | awk -F: '{print $2}' | sort | uniq -c`.
- **(iter 22)** Iter-21's `Integer_Map.keys_order` fix is correct
  in isolation but FAILS the moment an `Integer_Map` is stored
  BY VALUE inside another `map[K]Integer_Map`. **FIXED by iter 23**
  for the PowerStrengthAndRolls sites. Audit for other
  `map[K]Integer_Map` storage sites BEFORE adding new ones.
  Current confirmed-safe sites store Integer_Map as a struct field
  (mutated via `&struct.field`, no descriptor copy): production_rule,
  repair_rule, strategic_bombing_raid_battle. The pattern to AVOID
  is `for k in map_of_integer_maps { v := map_of_integer_maps[k];
  integer_map_*(&v, …) }`.
- **(iter 22)** `DummyPlayer.selectCasualties` (Java
  `triplea/game-app/game-core/src/main/java/games/strategy/triplea/odds/calculator/DummyPlayer.java`
  lines 189-247) has NEVER been ported to Odin. Odin's
  `Dummy_Player` falls through to `Player#select_casualties` nil
  vtable → identity return of `defaultCasualties`. This matches
  Java behavior EXACTLY when both `keepAtLeastOneLand=false` and
  `orderOfLosses` is empty. Confirmed defender side hardcodes
  `keep_one_land_unit=false` at `dummy_delegate_bridge.odin:113`.
  Attacker side takes it as a parameter from `battle_calculator`;
  value at snap 0024 UkrSSR sims not yet verified — iter 24 task
  (only relevant if snap 0024 still diverges after iter-23).
- **(iter 21)** Java's `IntegerMap` was using bare `map[rawptr]i32`
  in Odin; Java backs it with `LinkedHashMap`. Fixed by adding
  `keys_order: [dynamic]rawptr` and walking it in every iteration
  proc. All Odin code that constructs an `Integer_Map` via the
  struct literal `Integer_Map{map_values = make(...)}` must ALSO
  set `keys_order = make([dynamic]rawptr)`. The `integer_map_new`
  ctor and the file-private `_iorder_put_`/`_iorder_remove_`
  helpers do this automatically. See
  `/memories/repo/integer-map-linked-hash.md` (new this iter) and
  `/memories/java-hashmap-iteration-order.md` for the broader
  pattern; both are part of the java-fidelity rule.
- **No infrastructure blockers.** Previous status file claim was
  wrong; all 6 scripts + Byte Buddy agent + schema are in place
  and have produced 18,734 passing fixtures across 153 green procs.
- **Snap suite is 104, not 52.** `/memories/repo/phase-c-state.md`
  "50/52 baseline" is stale. Trust the `Snap status` section above
  (74/104 PASS, 26 FAILED, 1 PANIC) from 2026-05-22.
- **In-process `odin test` runner stalls.** The piped output via
  `tail` blocks until completion and the runner never produces
  per-snap PASS/FAIL summaries until the very end. After 4m29s
  it had only completed snaps 0001-0015 sequentially. Workaround:
  use the parallel `FILTER_SNAP` recipe in `Snap status` above.
- **Linker needs `-lsqlite3` path.** The Odin runtime links to
  libsqlite3 but the default ld search path doesn't include the
  nix store. Append
  `-extra-linker-flags:"-L/nix/store/5087xk8l09k90gddzw8y9b4yypyn23a5-sqlite-3.51.2/lib"`
  to every `odin test`/`odin build` of this codebase. (This was
  not in the earlier status. Find the current store path with
  `find /nix/store -maxdepth 3 -name 'libsqlite3.so' -path '*/lib/*' 2>/dev/null`
  if it changes after a `nix-collect-garbage` or flake bump.)
- **Resolver limitations** (from prior session, still valid):
  - Receiver types not in `{Territory, Unit, GamePlayer, UnitType,
    UnitAttachment}` are skipped as `opaque` in
    `gen_replay_tests.py`. Singleton paths (`gd.map`,
    `gd.battle_tracker`) and per-instance battle objects are not
    yet wired in.
  - Lambda / functional-interface args and returns
    (`Predicate$$Lambda`) are skipped. ProMatches is 100%
    lambda-return.
- **Deep clone gated.** `game_data_utils_clone_game_data` returns
  nil by default; enable with `-define:DEEP_CLONE=true` only when
  drilling AI-purchase paths. See
  `serialization-shim-divergence-plan.md`.
- **Precache.** `export TRIPLEA_BATTLE_PRECACHE_ENABLED=0` before
  any DIGEST run; default-on hangs for 5+ min on Russian purchase.
  Per `next-steps.md`. The parallel snap recipe above sets this
  already.
- **Odds calculator perf.** Odin's odds_calculator path is
  ~100\u00d7-1000\u00d7 slower than Java per `next-steps.md` (germanPurchase
  snap 0021 alone takes 3m7s in Odin vs ~16s for the full Java r=1
  game). Orthogonal to correctness but blocks any drill-down that
  needs to iterate quickly on a late-game snap. Snap 0053 is
  19ms (no AI), so deferring this perf work is fine for now.

## Background fixtures inventory

From `golden_dashboard.py --once` on 2026-05-22:

| class | impl | captured | generated | green | red |
|-------|-----:|---------:|----------:|------:|----:|
| `Properties` | 120 | 0 | 95 | 95 | 0 |
| `UnitAttachment` | 188 | 74 | 53 | 54 | 0 |
| `ProBattleUtils` | 8 | 4 | 4 | 4 | 0 |
| `ProMatches` | 92 | 65 | 0 | 0 | 0 |
| `GameMap` | 45 | 25 | 0 | 0 | 0 |
| `AbstractBattle` | 27 | 23 | 0 | 0 | 0 |
| `BattleTracker` | 76 | 1 | 0 | 0 | 0 |

Totals: **31,722 fixtures** captured → **18,734 pass**, 12,988
unrun (almost all from the 4 zero-gen classes above).

Top methods by fixture count (all passing):
- `ProBattleUtils.estimatePower` n=1000, `estimateStrength` n=1000,
  `estimateStrengthDifference` n=996
- `ProMatches.territoryCanMove*` n=800 each (unrun — lambda return)
- 50+ `Properties.get*` accessors n=600-606 each

## Reference quicklinks

- Full pyramid + schema: [`golden_testing_plan.md`](./golden_testing_plan.md)
- Capture pipeline: [`how-to-take-snapshots-that-include-args-and-return-values.md`](./how-to-take-snapshots-that-include-args-and-return-values.md)
- Drill-down rules + green/red/yellow doctrine:
  [`llm-instructions.md`](./llm-instructions.md) §"Layered drill-down debugging"
- Java-fidelity rule: `/memories/java-fidelity-rule.md`
- Java HashMap iteration order: `/memories/java-hashmap-iteration-order.md`
- Phase-C historical state: `/memories/repo/phase-c-state.md`
- Divergence playbooks: `/memories/repo/divergence-iter7-russianBattle.md`,
  `step24-cruiser-divergence.md`, `step36-japanesePurchase-fix.md`,
  `step38-japaneseBattle-status.md`, etc.

## Setup template (one-time)

If the four mutable sections above are empty or the orchestrator
reports the file is malformed, restore from this skeleton:

```
## Last action
_(none)_

## Next action
_(none)_

## Trace table
_Empty — no drill-down in progress._

## Snap status
| snap | status | top-level symptom | trace seed |
|------|--------|-------------------|------------|
| 0013 | RED    | ... | _unseeded_ |
| 0014 | RED    | ... | _unseeded_ |
```
