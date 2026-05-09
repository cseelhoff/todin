#!/usr/bin/env python3
"""patch_triplea.py
================================================================================
Prepare an upstream TripleA checkout for the triplea-port-bootstrap pipeline.

All edits are idempotent (re-running is a no-op once markers are present).

Edits applied:

 1. Inject `Ww2v5JacocoRun.java` into the smoke-testing test sources. It
    drives both the JaCoCo coverage run (8 rounds, default RNG) and the
    snapshot run (1 round, seeded RNG, wrapped in SnapshotHarness).
 2. Inject the three snapshot-harness sources next to it:
       - SnapshotHarness.java
       - GameStateJsonSerializer.java
       - SnapshotProcessor.java
 3. Append a JaCoCo aggregator block to
    `game-app/smoke-testing/build.gradle{.kts}` (auto-detected). Without
    this, the report is empty (smoke-testing has no production sources).
 4. Patch `PlainRandomSource.java` in game-core to add a static
    `fixedSeed` field, so the snapshot run can pin the RNG to a known
    seed for byte-for-byte port validation.
 5. Drop the Odin `test_common/` skeleton into `conversion/odin_tests/`
    of the upstream clone, ready for Phase 0.5 (Game_Data + JSON loader).

Usage:
    python3 patch_triplea.py [--triplea PATH] [--rounds N]
================================================================================
"""

import argparse
import os
import re
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATES = HERE.parent / "templates"

INJECT_TEST_REL = (
    "game-app/smoke-testing/src/test/java/"
    "org/triplea/portbootstrap/Ww2v5JacocoRun.java"
)
SNAPSHOT_PKG_REL = (
    "game-app/smoke-testing/src/test/java/"
    "games/strategy/engine/data"
)
SNAPSHOT_FILES = (
    "SnapshotHarness.java",
    "SnapshotProcessor.java",
    "GameStateJsonSerializer.java",
    "GenericValueSerializer.java",
)
ODIN_TEST_COMMON_REL = "conversion/odin_tests/test_common"
ODIN_TEST_COMMON_FILES = (
    "json_loader.odin",
    "game_state_compare.odin",
    "snapshot_runner.odin",
    "ww2v5_territory_attachments.json",
)
PRS_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/engine/random/PlainRandomSource.java"
)
PPU_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/triplea/ai/pro/util/ProPurchaseUtils.java"
)
BL_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/triplea/delegate/data/BattleListing.java"
)
PMMO_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/triplea/ai/pro/data/ProMyMoveOptions.java"
)
PRODATA_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/triplea/ai/pro/ProData.java"
)
PROTRANSPORT_REL = (
    "game-app/game-core/src/main/java/"
    "games/strategy/triplea/ai/pro/data/ProTransport.java"
)

GRADLE_MARKER = "Added by triplea-port-bootstrap"
AGENT_GRADLE_MARKER = "triplea-port-bootstrap: snapshot agent"
ADD_OPENS_GRADLE_MARKER = "triplea-port-bootstrap: add-opens for Math.random reseed"
JACKSON_DEP_MARKER = "triplea-port-bootstrap: needed by GenericValueSerializer"
JACKSON_LIB_MARKER = "jackson-databind ="
PRS_MARKER = "// triplea-port-bootstrap: fixedSeed"
PPU_MARKER = "// triplea-port-bootstrap: stable iteration"
BL_MARKER = "// triplea-port-bootstrap: sort battles"
LHM_MARKER = "// triplea-port-bootstrap: LinkedHashMap for stable iter"
LHMG_MARKER = "// triplea-port-bootstrap: global LHM rewrite"

SNAPSHOT_AGENT_REL = "conversion/snapshot-agent"

GRADLE_BLOCK_GROOVY = """
// Added by triplea-port-bootstrap to make jacocoTestReport aggregate
// production classes from all dependent modules. Without this, the smoke-
// testing report is empty (this module has no production sources of its own).
def coverageProjects = [
    ":game-app:domain-data",
    ":game-app:game-core",
    ":game-app:ai",
    ":game-app:game-headless",
    ":game-app:map-data",
    ":lib:java-extras",
    ":lib:xml-reader",
    ":lib:swing-lib",
    ":lib:websocket-client",
    ":lib:websocket-server",
    ":lib:feign-common",
    ":http-clients:lobby-client",
]
tasks.named("jacocoTestReport", JacocoReport).configure {
    coverageProjects.each { p ->
        def proj = project.findProject(p)
        if (proj != null) {
            sourceSets proj.sourceSets.main
        }
    }
}
"""

GRADLE_BLOCK_KTS = """
// Added by triplea-port-bootstrap to make jacocoTestReport aggregate
// production classes from all dependent modules. Without this, the smoke-
// testing report is empty (this module has no production sources of its own).
val coverageProjects = listOf(
    ":game-app:domain-data",
    ":game-app:game-core",
    ":game-app:ai",
    ":game-app:game-headless",
    ":game-app:map-data",
    ":lib:java-extras",
    ":lib:xml-reader",
    ":lib:swing-lib",
    ":lib:websocket-client",
    ":lib:websocket-server",
    ":lib:feign-common",
    ":http-clients:lobby-client",
)
tasks.named<org.gradle.testing.jacoco.tasks.JacocoReport>("jacocoTestReport") {
    coverageProjects.forEach { p ->
        val proj = project.findProject(p)
        if (proj != null) {
            sourceSets(proj.the<SourceSetContainer>()["main"])
        }
    }
    reports {
        xml.required.set(true)
        xml.outputLocation.set(layout.buildDirectory.file("jacoco.xml"))
    }
}
"""

AGENT_GRADLE_BLOCK_GROOVY = """
// triplea-port-bootstrap: snapshot agent
// When -PsnapshotAgent=<path-to-jar> is passed, attach the Byte Buddy
// snapshot agent to the test JVM. Per-call config + output dir are passed
// via -Dsnapshot.config and -Dsnapshot.outDir (set by
// scripts/capture_proc_snapshot.py).
tasks.withType(Test).configureEach {
    if (project.hasProperty('snapshotAgent')) {
        def agentJar = project.property('snapshotAgent')
        def methodsFile = project.findProperty('snapshotMethods') ?: "${rootProject.projectDir}/conversion/snapshot-agent/jfr-methods.txt"
        def configFile  = project.findProperty('snapshotConfig')  ?: "${rootProject.projectDir}/conversion/snapshot-agent/snapshot.config"
        def outDir      = System.getProperty('snapshot.outDir', "${project.layout.buildDirectory.get()}/snapshots")
        jvmArgs "-javaagent:${agentJar}=methods=${methodsFile},config=${configFile},outDir=${outDir}"
        jvmArgs "-XX:+EnableDynamicAgentLoading"
        systemProperty 'snapshot.outDir', outDir
        if (System.getProperty('snapshot.rounds') != null) {
            systemProperty 'snapshot.rounds', System.getProperty('snapshot.rounds')
        }
    }
}
"""

AGENT_GRADLE_BLOCK_KTS = """
// triplea-port-bootstrap: snapshot agent
// When -PsnapshotAgent=<path-to-jar> is passed, attach the Byte Buddy
// snapshot agent to the test JVM. Per-call config + output dir are passed
// via -Dsnapshot.config and -Dsnapshot.outDir (set by
// scripts/capture_proc_snapshot.py).
tasks.withType<Test>().configureEach {
    if (project.hasProperty("snapshotAgent")) {
        val agentJar = project.property("snapshotAgent") as String
        val methodsFile = (project.findProperty("snapshotMethods") as String?)
            ?: "${rootProject.projectDir}/conversion/snapshot-agent/jfr-methods.txt"
        val configFile = (project.findProperty("snapshotConfig") as String?)
            ?: "${rootProject.projectDir}/conversion/snapshot-agent/snapshot.config"
        val outDir = System.getProperty("snapshot.outDir")
            ?: "${project.layout.buildDirectory.get()}/snapshots"
        jvmArgs("-javaagent:${agentJar}=methods=${methodsFile},config=${configFile},outDir=${outDir}")
        jvmArgs("-XX:+EnableDynamicAgentLoading")
        systemProperty("snapshot.outDir", outDir)
        System.getProperty("snapshot.rounds")?.let { systemProperty("snapshot.rounds", it) }
    }
}
"""

# triplea-port-bootstrap: add-opens for Math.random reseed
# Ww2v5JacocoRun#runWithSnapshots reseeds
# java.lang.Math$RandomNumberGeneratorHolder#randomNumberGenerator via
# reflection so AI decisions (Math.random() in ProPurchaseUtils,
# AbstractAi politics/casualties, WeakAi purchase) are deterministic
# across snapshot runs. Without --add-opens, the reflection raises
# InaccessibleObjectException on JDK 17+.
ADD_OPENS_GRADLE_BLOCK_GROOVY = """
// triplea-port-bootstrap: add-opens for Math.random reseed
tasks.withType(Test).configureEach {
    jvmArgs '--add-opens', 'java.base/java.lang=ALL-UNNAMED'
    // Propagate snapshot-tuning system properties from gradle to the
    // forked test JVM (see equivalent block in the kotlin DSL variant).
    ['snapshot.outDir', 'snapshot.rounds', 'snapshot.rangeStart', 'snapshot.rangeEnd'].each { key ->
        if (System.getProperty(key) != null) {
            systemProperty key, System.getProperty(key)
        }
    }
}
"""

ADD_OPENS_GRADLE_BLOCK_KTS = """
// triplea-port-bootstrap: add-opens for Math.random reseed
tasks.withType<Test>().configureEach {
    jvmArgs("--add-opens", "java.base/java.lang=ALL-UNNAMED")
    // Propagate snapshot tuning system properties from the gradle invocation
    // into the test JVM, so e.g. `./gradlew :smoke-testing:test
    // -Dsnapshot.outDir=/tmp -Dsnapshot.rounds=1` actually reaches
    // Ww2v5JacocoRun#runWithSnapshots. Without this, gradle's daemon JVM
    // sees them but the forked test JVM does not.
    listOf("snapshot.outDir", "snapshot.rounds", "snapshot.rangeStart", "snapshot.rangeEnd")
        .forEach { key ->
            System.getProperty(key)?.let { systemProperty(key, it) }
        }
}
"""


def patch_gradle(triplea: Path) -> None:
    smoke = triplea / "game-app" / "smoke-testing"
    kts = smoke / "build.gradle.kts"
    grv = smoke / "build.gradle"
    if kts.is_file():
        target, block, flavor = kts, GRADLE_BLOCK_KTS, "kotlin DSL"
    elif grv.is_file():
        target, block, flavor = grv, GRADLE_BLOCK_GROOVY, "groovy DSL"
    else:
        sys.exit(f"  gradle: neither build.gradle nor build.gradle.kts under {smoke}")
    txt = target.read_text()
    if GRADLE_MARKER in txt:
        print(f"  gradle: already patched ({target.name}, {flavor})")
    else:
        target.write_text(txt.rstrip() + "\n" + block)
        print(f"  gradle: patched {target.name} ({flavor})")

    # Append the snapshot-agent JVM-args block (separate marker so the two
    # patches are independent and can be added/refreshed in either order).
    agent_block = AGENT_GRADLE_BLOCK_KTS if flavor == "kotlin DSL" else AGENT_GRADLE_BLOCK_GROOVY
    txt = target.read_text()
    if AGENT_GRADLE_MARKER in txt:
        print(f"  gradle: agent block already present")
    else:
        target.write_text(txt.rstrip() + "\n" + agent_block)
        print(f"  gradle: appended snapshot-agent JVM-args block")

    # Append the --add-opens block so Ww2v5JacocoRun can reflectively
    # reseed Math.random().
    add_opens_block = (
        ADD_OPENS_GRADLE_BLOCK_KTS if flavor == "kotlin DSL"
        else ADD_OPENS_GRADLE_BLOCK_GROOVY
    )
    txt = target.read_text()
    if ADD_OPENS_GRADLE_MARKER in txt:
        print(f"  gradle: add-opens block already present")
    else:
        target.write_text(txt.rstrip() + "\n" + add_opens_block)
        print(f"  gradle: appended --add-opens block (Math.random reseed)")

    # GenericValueSerializer.java needs jackson-databind on the test classpath.
    # The catalog already references jackson-datatype-jsr310 (transitively
    # pulls databind at runtime) but databind must be declared explicitly to
    # be visible at TEST compile time.
    txt = target.read_text()
    needle = (
        '    testImplementation(project(":lib:test-common"))'
        if flavor == "kotlin DSL"
        else "    testImplementation project(':lib:test-common')"
    )
    if JACKSON_DEP_MARKER in txt:
        print(f"  gradle: jackson testImpl already present")
    elif needle in txt:
        if flavor == "kotlin DSL":
            insert = (
                f"{needle}\n"
                f"    // {JACKSON_DEP_MARKER}\n"
                f"    testImplementation(libs.jackson.databind)"
            )
        else:
            insert = (
                f"{needle}\n"
                f"    // {JACKSON_DEP_MARKER}\n"
                f"    testImplementation libs.jackson.databind"
            )
        target.write_text(txt.replace(needle, insert, 1))
        print(f"  gradle: added jackson-databind testImplementation")
    else:
        print(f"  gradle: WARN: could not anchor jackson testImpl insertion in {target.name}")


def patch_libs_versions(triplea: Path) -> None:
    """Add `jackson-databind` to gradle/libs.versions.toml.

    The catalog already declares the `jackson-datatype` version and the
    jsr310 datatype library that uses it. We add the `jackson-databind`
    library entry sharing the same version so smoke-testing's
    GenericValueSerializer can compile against it.
    """
    cat = triplea / "gradle" / "libs.versions.toml"
    if not cat.is_file():
        sys.exit(f"  libs: missing {cat}")
    txt = cat.read_text()
    if JACKSON_LIB_MARKER in txt:
        print(f"  libs: jackson-databind already present")
        return
    needle = (
        'jackson-datatype-jsr310 = { module = '
        '"com.fasterxml.jackson.datatype:jackson-datatype-jsr310", '
        'version.ref = "jackson-datatype" }'
    )
    if needle not in txt:
        print(f"  libs: WARN: could not anchor jackson-databind entry in libs.versions.toml")
        return
    insert = (
        'jackson-databind = { module = "com.fasterxml.jackson.core:jackson-databind", '
        'version.ref = "jackson-datatype" }\n'
        + needle
    )
    cat.write_text(txt.replace(needle, insert, 1))
    print(f"  libs: added jackson-databind library entry")


def patch_plain_random_source(triplea: Path) -> None:
    target = triplea / PRS_REL
    if not target.is_file():
        sys.exit(f"  rng: missing {target}")
    txt = target.read_text()
    if PRS_MARKER in txt:
        print(f"  rng: already patched ({target.name})")
        return

    # Insert a static `fixedSeed` field after the class declaration, and
    # replace the no-arg constructor's MersenneTwister init to honor it.
    # The upstream class has:
    #   private final RandomGenerator random = new MersenneTwister();
    # We change it to a constructor that consults `fixedSeed`.
    needle_field = (
        "@GuardedBy(\"lock\")\n"
        "  private final RandomGenerator random = new MersenneTwister();"
    )
    if needle_field not in txt:
        sys.exit(
            "  rng: upstream PlainRandomSource has changed shape; "
            "patch needs an update")

    new_field = (
        PRS_MARKER + ": pin RNG for snapshot characterization runs.\n"
        "  /** When non-null, every new {@code PlainRandomSource} uses this seed. */\n"
        "  public static volatile Long fixedSeed = null;\n"
        "\n"
        "  @GuardedBy(\"lock\")\n"
        "  private final RandomGenerator random;\n"
        "\n"
        "  public PlainRandomSource() {\n"
        "    Long seed = fixedSeed;\n"
        "    this.random = (seed != null)\n"
        "        ? new MersenneTwister(seed)\n"
        "        : new MersenneTwister();\n"
        "  }"
    )
    txt = txt.replace(needle_field, new_field, 1)
    target.write_text(txt)
    print(f"  rng: patched {target.name}")


def patch_pro_purchase_utils(triplea: Path) -> None:
    """Make ProPurchaseUtils.randomizePurchaseOption iterate options in
    a deterministic order (sorted by production-rule name) so the
    snapshot characterization run is reproducible across JVM versions
    and matches the Odin port's sorted iteration. Without this, Java's
    HashMap iteration depends on identity hashCode (allocation address),
    which changes per-JVM-run."""
    target = triplea / PPU_REL
    if not target.is_file():
        sys.exit(f"  ppu: missing {target}")
    txt = target.read_text()
    if PPU_MARKER in txt:
        print(f"  ppu: already patched ({target.name})")
        return

    # Anchor on the upstream block we want to replace; if it has drifted
    # we'd rather fail loudly than silently miss the patch.
    old_block = (
        "    final Map<ProPurchaseOption, Double> purchasePercentages = new LinkedHashMap<>();\n"
        "    double upperBound = 0.0;\n"
        "    for (final ProPurchaseOption ppo : purchaseEfficiencies.keySet()) {\n"
    )
    if old_block not in txt:
        sys.exit(
            "  ppu: upstream ProPurchaseUtils.randomizePurchaseOption "
            "has drifted; patch needs an update"
        )
    new_block = (
        "    final Map<ProPurchaseOption, Double> purchasePercentages = new LinkedHashMap<>();\n"
        "    double upperBound = 0.0;\n"
        "    " + PPU_MARKER + ": sort options by production-rule name so the\n"
        "    // snapshot run is reproducible (HashMap iteration order otherwise\n"
        "    // depends on identity hashCode). Matches Odin port's\n"
        "    // pro_purchase_utils_randomize_purchase_option sort key.\n"
        "    final java.util.List<ProPurchaseOption> sortedOptions =\n"
        "        new java.util.ArrayList<>(purchaseEfficiencies.keySet());\n"
        "    sortedOptions.sort(java.util.Comparator.comparing(\n"
        "        ppo -> ppo.getProductionRule().getName()));\n"
        "    for (final ProPurchaseOption ppo : sortedOptions) {\n"
    )
    txt = txt.replace(old_block, new_block, 1)
    target.write_text(txt)
    print(f"  ppu: patched {target.name} (sorted randomizePurchaseOption iteration)")


def patch_battle_listing(triplea: Path) -> None:
    """Patch BattleListing constructor to sort each per-BattleType bucket
    of territories by name. Java uses HashSet<Territory> whose iteration
    depends on identity hashCode (allocation address) — non-portable
    across JVMs and across Odin's `map`. Sorting yields a stable order
    both sides agree on. Mirrors the Odin port's `battle_listing_new`
    sort (see odin_flat/games__strategy__triplea__delegate__data__battle_listing.odin)."""
    target = triplea / BL_REL
    if not target.is_file():
        sys.exit(f"  bl: missing {target}")
    txt = target.read_text()
    if BL_MARKER in txt:
        print(f"  bl: already patched ({target.name})")
        return

    # Anchor on the upstream BattleListing constructor body. The replacement
    # turns the Set<IBattle> into a list sorted by territory name, then
    # builds the EnumMap<BattleType, ArrayList<Territory>> from that list
    # so iteration order is reproducible.
    old_block = (
        "  public BattleListing(final Set<IBattle> battles) {\n"
        "    this.battlesMap = new EnumMap<>(BattleType.class);\n"
        "    battles.stream()\n"
        "        .filter(b -> !b.isEmpty())\n"
        "        .forEach(\n"
        "            b -> {\n"
        "              Collection<Territory> territories = battlesMap.get(b.getBattleType());\n"
        "              if (territories == null) {\n"
        "                territories = new HashSet<>();\n"
        "              }\n"
        "              territories.add(b.getTerritory());\n"
        "              battlesMap.put(b.getBattleType(), territories);\n"
        "            });\n"
        "  }\n"
    )
    if old_block not in txt:
        sys.exit(
            "  bl: upstream BattleListing constructor has drifted; "
            "patch needs an update"
        )
    new_block = (
        "  public BattleListing(final Set<IBattle> battles) {\n"
        "    this.battlesMap = new EnumMap<>(BattleType.class);\n"
        "    " + BL_MARKER + ": sort each per-BattleType territory bucket by\n"
        "    // territory name so iteration is stable. Mirrors the Odin port's\n"
        "    // battle_listing_new sort. Without this, ProAi.battle iteration\n"
        "    // order depends on HashSet<IBattle> hashCode order (allocation\n"
        "    // address) which is not reproducible across JVMs / Odin runs.\n"
        "    final java.util.List<IBattle> sortedBattles =\n"
        "        battles.stream()\n"
        "            .filter(b -> !b.isEmpty())\n"
        "            .sorted(java.util.Comparator.comparing(b -> b.getTerritory().getName()))\n"
        "            .collect(java.util.stream.Collectors.toList());\n"
        "    for (final IBattle b : sortedBattles) {\n"
        "      battlesMap\n"
        "          .computeIfAbsent(b.getBattleType(), k -> new java.util.ArrayList<>())\n"
        "          .add(b.getTerritory());\n"
        "    }\n"
        "  }\n"
    )
    txt = txt.replace(old_block, new_block, 1)
    target.write_text(txt)
    print(f"  bl: patched {target.name} (sorted BattleListing buckets)")


def patch_pro_ai_linkedhashmap(triplea: Path) -> None:
    """Convert HashMap/HashSet field declarations in Pro AI data classes
    to LinkedHashMap/LinkedHashSet so iteration preserves insertion
    order. Java's HashMap iteration depends on identity hashCode (object
    allocation address), which differs per JVM run — making the AI's
    decisions non-deterministic across runs even with PlainRandomSource
    and Math.random() both seeded. Empirical evidence: two consecutive
    Java game runs with seed 42 produced different game lengths
    (8 vs 13 rounds) and different unit counts at game-end.

    Mirrors the Odin-side fix where pro_combat_move_ai uses
    pro_sort_move_options_utils_sorted_unit_keys_by_move_options to
    iterate `map[^Unit]X` in deterministic order. The Java source needs
    the same treatment at the data-structure level so HashMap-backed
    iteration becomes insertion-ordered.

    This patch targets the highest-leverage fields:
      - ProMyMoveOptions.{territoryMap, unitMoveMap, transportMoveMap,
        bombardMap, bomberMoveMap}: all iterated by ProCombatMoveAi /
        ProNonCombatMoveAi to drive AI move decisions.
      - ProTransport.{transportMap, seaTransportMap}: iterated to
        choose amphibious targets.
      - ProData.{unitTerritoryMap, unitsToBeConsumed}: keyed by Unit;
        unitTerritoryMap is iterated when computing AI strategic value
        and unit reachability.

    Idempotent via LHM_MARKER. Fails loudly if upstream shape drifts.
    """
    targets_specs = [
        # (rel_path, [(old_decl, new_decl), ...])
        (PMMO_REL, [
            ("private final Map<Territory, ProTerritory> territoryMap = new HashMap<>();",
             "private final Map<Territory, ProTerritory> territoryMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Map<Unit, Set<Territory>> unitMoveMap = new HashMap<>();",
             "private final Map<Unit, Set<Territory>> unitMoveMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Map<Unit, Set<Territory>> transportMoveMap = new HashMap<>();",
             "private final Map<Unit, Set<Territory>> transportMoveMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Map<Unit, Set<Territory>> bombardMap = new HashMap<>();",
             "private final Map<Unit, Set<Territory>> bombardMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Map<Unit, Set<Territory>> bomberMoveMap = new HashMap<>();",
             "private final Map<Unit, Set<Territory>> bomberMoveMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
        ]),
        (PROTRANSPORT_REL, [
            ("private final Map<Territory, Set<Territory>> transportMap = new HashMap<>();",
             "private final Map<Territory, Set<Territory>> transportMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Map<Territory, Set<Territory>> seaTransportMap = new HashMap<>();",
             "private final Map<Territory, Set<Territory>> seaTransportMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
        ]),
        (PRODATA_REL, [
            ("private Map<Unit, Territory> unitTerritoryMap = new HashMap<>();",
             "private Map<Unit, Territory> unitTerritoryMap = new java.util.LinkedHashMap<>();  " + LHM_MARKER),
            ("private final Set<Unit> unitsToBeConsumed = new HashSet<>();",
             "private final Set<Unit> unitsToBeConsumed = new java.util.LinkedHashSet<>();  " + LHM_MARKER),
        ]),
    ]

    total_patched = 0
    for rel, replacements in targets_specs:
        target = triplea / rel
        if not target.is_file():
            sys.exit(f"  lhm: missing {target}")
        txt = target.read_text()
        if LHM_MARKER in txt:
            print(f"  lhm: already patched ({target.name})")
            continue
        n = 0
        for old, new in replacements:
            if old not in txt:
                sys.exit(
                    f"  lhm: upstream {target.name} has drifted; could not "
                    f"find: {old!r}"
                )
            txt = txt.replace(old, new, 1)
            n += 1
        target.write_text(txt)
        total_patched += n
        print(f"  lhm: patched {target.name} ({n} field decls)")
    if total_patched > 0:
        print(f"  lhm: total {total_patched} HashMap/HashSet fields converted")


# Directories swept by patch_global_hashmap_to_linkedhashmap. Each entry is
# a path relative to the upstream `triplea/` checkout. We deliberately
# scope to AI + delegate + attachments (the layers that drive snapshot
# state); the rest of game-core (UI, networking, parsers) is skipped to
# avoid behavioural surprises in non-snapshot code paths.
LHMG_SWEEP_DIRS = (
    "game-app/game-core/src/main/java/games/strategy/triplea/ai/pro",
    "game-app/game-core/src/main/java/games/strategy/triplea/delegate",
    "game-app/game-core/src/main/java/games/strategy/triplea/attachments",
)

# `new HashMap<>()` and `new HashSet<>()` (with optional whitespace and
# explicit type arguments) → LinkedHash equivalents. The diamond-arg case
# is the dominant idiom in upstream TripleA; explicit `<K,V>` is rare so
# we only match the diamond.
_HASH_MAP_RE = re.compile(r"\bnew HashMap<>\(\)")
_HASH_SET_RE = re.compile(r"\bnew HashSet<>\(\)")
# Constructor-with-arg variants: `new HashMap<>(otherMap)` etc. We
# preserve the constructor argument verbatim and just rewrite the type.
_HASH_MAP_ARG_RE = re.compile(r"\bnew HashMap<>\(([^()]*)\)")
_HASH_SET_ARG_RE = re.compile(r"\bnew HashSet<>\(([^()]*)\)")


def patch_global_hashmap_to_linkedhashmap(triplea: Path) -> None:
    """Mass-convert `new HashMap<>()` → `new LinkedHashMap<>()` (same for
    HashSet) across Pro AI / delegate / attachments source files. Adds
    LinkedHashMap / LinkedHashSet imports as needed.

    Rationale: even after patch_pro_ai_linkedhashmap converted 9 field
    declarations, full-game determinism probe still showed run-to-run
    divergence (Run A ended at round 29 vs Run B at round 16). The
    remaining non-determinism comes from local-variable HashMap/HashSet
    in BattleDelegate, MoveDelegate, MustFightBattle, TransportTracker,
    and similar places that get iterated and propagate AI decisions.

    LinkedHashMap is a strict superset of HashMap (preserves insertion
    order; ~5% memory overhead, negligible runtime). The conversion is
    safe-by-construction: any code that depended on HashMap's UNDEFINED
    iteration order was already broken (just non-deterministically).

    Marker line `LHMG_MARKER` is appended at the end of any file we
    rewrote; subsequent runs skip files with the marker present.
    """
    total_files = 0
    total_subs = 0
    for rel in LHMG_SWEEP_DIRS:
        root = triplea / rel
        if not root.is_dir():
            print(f"  lhmg: skip (missing dir) {rel}")
            continue
        for jf in sorted(root.rglob("*.java")):
            txt = jf.read_text()
            if LHMG_MARKER in txt:
                continue
            new_txt = txt
            n_subs = 0

            def _sub_diamond_map(m):
                nonlocal n_subs
                n_subs += 1
                return "new LinkedHashMap<>()"

            def _sub_diamond_set(m):
                nonlocal n_subs
                n_subs += 1
                return "new LinkedHashSet<>()"

            def _sub_arg_map(m):
                nonlocal n_subs
                n_subs += 1
                return f"new LinkedHashMap<>({m.group(1)})"

            def _sub_arg_set(m):
                nonlocal n_subs
                n_subs += 1
                return f"new LinkedHashSet<>({m.group(1)})"

            new_txt = _HASH_MAP_ARG_RE.sub(_sub_arg_map, new_txt)
            new_txt = _HASH_MAP_RE.sub(_sub_diamond_map, new_txt)
            new_txt = _HASH_SET_ARG_RE.sub(_sub_arg_set, new_txt)
            new_txt = _HASH_SET_RE.sub(_sub_diamond_set, new_txt)

            if n_subs == 0:
                continue

            # Add imports if missing. The upstream files already import
            # HashMap/HashSet so we just need to add the LinkedHash variants.
            if "import java.util.LinkedHashMap;" not in new_txt and "LinkedHashMap" in new_txt:
                new_txt = _add_import(new_txt, "java.util.LinkedHashMap")
            if "import java.util.LinkedHashSet;" not in new_txt and "LinkedHashSet" in new_txt:
                new_txt = _add_import(new_txt, "java.util.LinkedHashSet")

            # Add a trailing-line marker comment so re-runs skip this file.
            new_txt = new_txt.rstrip() + "\n" + LHMG_MARKER + "\n"

            jf.write_text(new_txt)
            total_files += 1
            total_subs += n_subs
    print(f"  lhmg: rewrote {total_subs} HashMap/HashSet allocations across "
          f"{total_files} files in {len(LHMG_SWEEP_DIRS)} dirs")


def _add_import(java_src: str, fq_class: str) -> str:
    """Insert `import <fq_class>;` after the last existing import line.
    Falls back to inserting after the package declaration if no imports
    exist yet (rare for upstream TripleA files)."""
    lines = java_src.split("\n")
    last_import_idx = -1
    package_idx = -1
    for i, ln in enumerate(lines):
        s = ln.strip()
        if s.startswith("package "):
            package_idx = i
        elif s.startswith("import "):
            last_import_idx = i
    if last_import_idx >= 0:
        # Insert in alphabetical order if possible; simplest: just append
        # to the import group then let formatter reorder. Many files have
        # blank lines between imports and code; we find the actual end of
        # the import block.
        insert_at = last_import_idx + 1
    elif package_idx >= 0:
        # No imports yet: insert blank-line + import after package.
        insert_at = package_idx + 1
        if insert_at < len(lines) and lines[insert_at].strip() != "":
            lines.insert(insert_at, "")
            insert_at += 1
    else:
        insert_at = 0
    lines.insert(insert_at, f"import {fq_class};")
    return "\n".join(lines)



def inject_test(triplea: Path, rounds: int) -> None:
    src = TEMPLATES / "Ww2v5JacocoRun.java"
    dst = triplea / INJECT_TEST_REL
    dst.parent.mkdir(parents=True, exist_ok=True)
    body = src.read_text().replace("__ROUND_CAP__", str(rounds))
    if dst.is_file() and dst.read_text() == body:
        print(f"  inject: already up-to-date ({dst.name})")
        return
    dst.write_text(body)
    print(f"  inject: wrote {dst.name} (rounds={rounds})")


def inject_snapshot_harness(triplea: Path) -> None:
    dst_dir = triplea / SNAPSHOT_PKG_REL
    dst_dir.mkdir(parents=True, exist_ok=True)
    for name in SNAPSHOT_FILES:
        src = TEMPLATES / "snapshot" / name
        if not src.is_file():
            sys.exit(f"  harness: template missing at {src}")
        dst = dst_dir / name
        if dst.is_file() and dst.read_text() == src.read_text():
            print(f"  harness: already up-to-date ({name})")
            continue
        shutil.copyfile(src, dst)
        print(f"  harness: wrote {name}")


def inject_odin_test_common(triplea: Path) -> None:
    dst_dir = triplea / ODIN_TEST_COMMON_REL
    dst_dir.mkdir(parents=True, exist_ok=True)
    for name in ODIN_TEST_COMMON_FILES:
        src = TEMPLATES / "odin_test_common" / name
        if not src.is_file():
            sys.exit(f"  odin: template missing at {src}")
        dst = dst_dir / name
        if dst.is_file() and dst.read_text() == src.read_text():
            print(f"  odin: already up-to-date ({name})")
            continue
        shutil.copyfile(src, dst)
        print(f"  odin: wrote {name}")


def inject_snapshot_agent(triplea: Path) -> None:
    """Install the Byte Buddy snapshot agent under triplea/conversion/snapshot-agent/.

    Mirror-copies the entire templates/snapshot-agent/ tree (gradle build,
    settings, agent + interceptor sources, master jfr-methods.txt, and the
    default snapshot.config.template). The first build of
    `cd <triplea>/conversion/snapshot-agent && ../../gradlew jar` produces a
    fat-jar with byte-buddy 1.17.7 bundled.
    """
    src_root = TEMPLATES / "snapshot-agent"
    dst_root = triplea / SNAPSHOT_AGENT_REL
    if not src_root.is_dir():
        sys.exit(f"  snapshot-agent: template missing at {src_root}")
    written = 0
    skipped = 0
    for src in src_root.rglob("*"):
        if src.is_dir():
            continue
        rel = src.relative_to(src_root)
        dst = dst_root / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.is_file() and dst.read_bytes() == src.read_bytes():
            skipped += 1
            continue
        shutil.copyfile(src, dst)
        written += 1
    # Materialise a default snapshot.config from the template if not present.
    cfg = dst_root / "snapshot.config"
    tpl = dst_root / "snapshot.config.template"
    if tpl.is_file() and not cfg.is_file():
        shutil.copyfile(tpl, cfg)
        print(f"  snapshot-agent: seeded snapshot.config from template")
    print(f"  snapshot-agent: {written} new/updated, {skipped} unchanged")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--triplea",
                    default=os.environ.get("TRIPLEA_DIR", "triplea"))
    ap.add_argument("--rounds", type=int, default=8,
                    help="round cap for the JaCoCo run (default: 8)")
    args = ap.parse_args()

    triplea = Path(args.triplea).resolve()
    if not triplea.is_dir():
        sys.exit(f"TRIPLEA_DIR not a directory: {triplea}")
    print(f"patching {triplea}...")
    inject_snapshot_harness(triplea)
    inject_test(triplea, args.rounds)
    patch_libs_versions(triplea)
    patch_gradle(triplea)
    patch_plain_random_source(triplea)
    patch_pro_purchase_utils(triplea)
    patch_battle_listing(triplea)
    patch_pro_ai_linkedhashmap(triplea)
    patch_global_hashmap_to_linkedhashmap(triplea)
    inject_odin_test_common(triplea)
    inject_snapshot_agent(triplea)
    print("done")


if __name__ == "__main__":
    main()
