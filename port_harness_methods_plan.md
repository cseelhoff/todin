# Harness / test-driver port plan

Scope: every Java method that would need to be ported to Odin to
produce a self-contained Odin executable equivalent to
`Ww2v5JacocoRun.runWithSnapshots()` (load `WW2v5_1942_2nd.xml`, run
a 1-round AI-vs-AI game with `PlainRandomSource.fixedSeed = 42L`,
and emit byte-identical before/after JSON snapshots around every
delegate step).

These Java sources live under
`triplea/game-app/smoke-testing/src/test/java/...` and are
intentionally NOT tracked in `port.sqlite` today (the Odin test
harness sidesteps them by replaying captured Java JSON). Adding
them brings the Odin port to full self-containment.

Engine call graph below `ServerGame.runNextStep` is already 100%
ported (1068/1068 structs, 5550/5550 methods); nothing in the
table below depends on additional engine-side porting work.

Status legend:
- **needed** — required for `runWithSnapshots` end-to-end run.
- **optional** — sibling method in the same class, not on the
  `runWithSnapshots` path (only used by other smoke tests). Listed
  for completeness; safe to skip.

Effort legend (rough Odin LOC, including helpers):
- XS = ≤10, S = 10–30, M = 30–80, L = 80–200, XL = >200.

| # | Java class | Java method (signature) | Visibility | Status | Effort | Notes / dependencies |
|---|---|---|---|---|---|---|
| 1 | `org.triplea.portbootstrap.Ww2v5JacocoRun` | `setUp()` (`@BeforeAll`, `static`, `throws IOException`) | public | needed | XS | Calls `GameTestUtils.setUp()`. |
| 2 | `org.triplea.portbootstrap.Ww2v5JacocoRun` | `run()` | package | optional | S | JaCoCo coverage driver only; not used for snapshots. |
| 3 | `org.triplea.portbootstrap.Ww2v5JacocoRun` | `runWithSnapshots()` | package | needed | M | Sets `PlainRandomSource.fixedSeed = 42L`, builds `SnapshotHarness`, loops `harness.wrapStep(() -> game.runNextStep())` until `SNAPSHOT_ROUNDS` (1) elapsed. Top-level entry point. |
| 4 | `games.strategy.engine.data.GameTestUtils` | `setUp()` (`static`, `throws IOException`) | public | needed | S | `HeadlessLaunchAction.setSkipMapResourceLoading(true)`, install `MemoryPreferences`, zero AI pause durations, create temp `.triplea-root`, `assets/`, set `triplea.headless=true`. Most callees already ported. |
| 5 | `games.strategy.engine.data.GameTestUtils` | `setUpGameWithAis(String xmlName)` | public static | needed | M | Parse XML via `GameParser.parse` (ported), assign every player `PlayerTypes.PRO_AI` (ported), build `Messengers`/`LocalNoOpMessenger` (ported), construct `ServerGame` (ported), `setDelegateAutosavesEnabled(false)`, `gameLoader.startGame(...)`. Mocks `HeadlessGameServer` — replace with no-op struct. |
| 6 | `games.strategy.engine.data.GameTestUtils` | `runStepsUntil(ServerGame, String stopAfterStepName)` | public static | optional | XS | Used by other AI tests, not by `runWithSnapshots`. |
| 7 | `games.strategy.engine.data.GameTestUtils` | `addUnits(Territory, GamePlayer, String... unitTypes)` | public static | optional | XS | Used by `testAiGameWithConsumedUnits`-style tests only. |
| 8 | `games.strategy.engine.data.GameTestUtils` | `countUnitsOfType(GamePlayer, String unitType)` | public static | optional | XS | Test-assertion helper. |
| 9 | `games.strategy.engine.data.GameTestUtils` | `countUnitsOfType(Territory, GamePlayer, String unitType)` | public static | optional | XS | Test-assertion helper. |
| 10 | `games.strategy.engine.data.GameTestUtils` | `getUnitType(GameData, String name)` | public static | optional | XS | Trivial wrapper around `UnitTypeList.getUnitTypeOrThrow`. |
| 11 | `games.strategy.engine.data.GameTestUtils` | `getTerritory(GameData, String name)` | public static | optional | XS | Trivial wrapper. |
| 12 | `games.strategy.engine.data.SnapshotHarness` | `<init>(ServerGame, String outputDir, long rangeStart, long rangeEnd)` | public | needed | S | Stores game ref, creates output dir, instantiates `GameStateJsonSerializer`. |
| 13 | `games.strategy.engine.data.SnapshotHarness` | `wrapStep(Runnable stepRunner)` | public | needed | M | Increments counter, derives `step-NNNN-round-NNN-<stepName>` dir, calls `saveSnapshot("step-before", ...)`, runs the step, calls `saveSnapshot("step-after", ...)`. |
| 14 | `games.strategy.engine.data.SnapshotHarness` | `saveSnapshot(String label, Path dir, String stepName, String delegateName, String playerName, int round)` | private | needed | M | Writes `<label>-gamedata.json` (via serializer) and `<label>-meta.txt`. Filesystem + `System.currentTimeMillis()`. |
| 15 | `games.strategy.engine.data.GameStateJsonSerializer` | `serialize(GameData data)` | public | needed | S | Top-level dispatcher: assembles 14-key root JsonObject and `gson.toJson(root)`. |
| 16 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeSequence(GameSequence seq)` | private | needed | S | Round, step index, current step name/delegate/playerId. |
| 17 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializePlayers(PlayerList playerList, GameData data)` | private | needed | M | Per-player: name, isNull, isHidden, optional, canBeDisabled, defaultType, whoAmI, productionFrontier, repairFrontier, resources, techAttachment. |
| 18 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeResourceCollection(ResourceCollection rc)` | private | needed | XS | Map of resource-name → quantity. |
| 19 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeTechAttachment(TechAttachment ta)` | private | needed | M | Reflective dump of all `boolean` tech flags + tokens. Mirror Odin field set explicitly (no reflection on Odin side). |
| 20 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeTerritories(GameMap map, GameData data)` | private | needed | L | Territory name, owner-name, isWater, neighbors, attachments (TerritoryAttachment, CanalAttachment), production, units-by-id. Largest single serializer. |
| 21 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeAllUnits(GameData data)` | private | needed | S | Iterates `UnitsList`, dispatches `serializeUnit`. |
| 22 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeUnit(Unit u)` | private | needed | M | UUID, type, owner, hits, movementLeft, transportedBy, etc. |
| 23 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeUnitTypes(UnitTypeList utl, GameData data)` | private | needed | M | Per unit-type: name + per-player UnitAttachment view. |
| 24 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeUnitAttachment(UnitAttachment ua, GamePlayer player)` | private | needed | L | ~70 fields. The single biggest field-by-field translation. Mirror Java field-name list in Odin. |
| 25 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeAlliances(AllianceTracker tracker, GameData data)` | private | needed | S | alliance → players map. |
| 26 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeRelationships(RelationshipTracker tracker, GameData data)` | private | needed | M | Per ordered player-pair: relationshipType, roundCreated. |
| 27 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeRelationshipTypes(RelationshipTypeList rtl)` | private | needed | S | Name + RelationshipTypeAttachment fields. |
| 28 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeProperties(GameProperties props)` | private | needed | S | Every editable property + value. |
| 29 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializePropertyValue(Object value)` | private | needed | XS | Tagged union: bool / int / string / null. |
| 30 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeResourceList(ResourceList rl)` | private | needed | XS | Resource names. |
| 31 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeProductionRules(ProductionRuleList prl)` | private | needed | S | Per rule: name, costs, results. |
| 32 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeProductionFrontiers(ProductionFrontierList pfl)` | private | needed | S | Per frontier: name + rule names. |
| 33 | `games.strategy.engine.data.GameStateJsonSerializer` | `serializeTechFrontier(TechnologyFrontier tf)` | private | needed | S | Tech advances list + cached set. |
| 34 | `games.strategy.engine.data.GameStateJsonSerializer` | `getIntField(Object, String fieldName)` (`static`) | private | drop (Java-reflection only) | — | Reflection helper. Replace each call site with direct field access on the Odin side. |
| 35 | `games.strategy.engine.data.GameStateJsonSerializer` | `getBoolField(Object, String fieldName)` (`static`) | private | drop (Java-reflection only) | — | Same as above. |
| 36 | `games.strategy.engine.data.GameStateJsonSerializer` | `getStringField(Object, String fieldName)` (`static`, `throws Exception`) | private | drop (Java-reflection only) | — | Same as above. |
| 37 | `games.strategy.engine.data.GameStateJsonSerializer` | `findField(Class<?>, String name)` (`static`, `throws NoSuchFieldException`) | private | drop (Java-reflection only) | — | Walks parent classes to locate `Field`. Not portable; eliminated by direct field access. |

## Totals

- 37 Java methods identified.
- **23 needed** for end-to-end snapshot equivalence.
- **10 optional** sibling test helpers (other smoke tests only).
- **4 dropped** (Java reflection helpers; replaced by direct field access).

Estimated Odin work: ~1,200 LOC concentrated in
`game_state_json_serializer.odin` (rows 15–33), plus ~250 LOC of
glue across the harness/driver files (rows 1, 3, 4, 5, 12, 13, 14).

## Out of scope (deliberately not in the table)

- Any method below `ServerGame.runNextStep` — already ported.
- `Gson`/`GsonBuilder` — replaced by `core:encoding/json` or a
  small custom emitter on the Odin side.
- `Mockito.mock(HeadlessGameServer.class)` — replaced by a no-op
  struct.
- Filesystem helpers (`Files.createDirectories`, `Files.writeString`,
  `Files.newBufferedWriter`, `Path.of`) — JDK shims; either reuse
  existing shims under `odin_flat/java__nio__...` or add minimal
  ones on first reference.
