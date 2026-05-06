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

GRADLE_MARKER = "Added by triplea-port-bootstrap"
AGENT_GRADLE_MARKER = "triplea-port-bootstrap: snapshot agent"
PRS_MARKER = "// triplea-port-bootstrap: fixedSeed"

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
    patch_gradle(triplea)
    patch_plain_random_source(triplea)
    inject_odin_test_common(triplea)
    inject_snapshot_agent(triplea)
    print("done")


if __name__ == "__main__":
    main()
