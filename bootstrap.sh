#!/usr/bin/env bash
# bootstrap.sh — build the TripleA port-tracking database from scratch.
#
# Each step is idempotent (re-runnable). To run a single step manually, see
# README.md — every step below has a corresponding heading there.
#
# Usage:
#   ./bootstrap.sh                       # full pipeline
#   ./bootstrap.sh --skip-clone          # use existing $TRIPLEA_DIR
#   ./bootstrap.sh --skip-test           # reuse existing jacoco.xml
#
# Required environment (set in shell or this script will set defaults):
#   WORK_DIR        directory holding all generated artifacts (default: $PWD)
#   TRIPLEA_DIR     where TripleA is checked out (default: $WORK_DIR/triplea)
#   PORT_DB         output sqlite database (default: $WORK_DIR/port.sqlite)
#   ODIN_FLAT_DIR   where blank .odin stubs land (default: $WORK_DIR/odin_flat)
#   TRIPLEA_REMOTE  upstream git URL (default: https://github.com/triplea-game/triplea)
#   TRIPLEA_REF     git ref/tag/branch to check out (default: main)
#   ROUNDS          Ww2v5JacocoRun round cap (default: 8)
#   BOOTSTRAP_SNAPSHOTS  if =1, also run the seeded 1-round snapshot pass
#                        and process the JSON dumps into conversion/odin_tests/
#   SNAPSHOT_DIR    raw snapshot output (default: $TRIPLEA_DIR/build/snapshots)
#   SNAPSHOT_OUT    processed snapshot output (default: $TRIPLEA_DIR/conversion/odin_tests)

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$HERE/scripts"

WORK_DIR="${WORK_DIR:-$PWD}"
TRIPLEA_DIR="${TRIPLEA_DIR:-$WORK_DIR/triplea}"
PORT_DB="${PORT_DB:-$WORK_DIR/port.sqlite}"
ODIN_FLAT_DIR="${ODIN_FLAT_DIR:-$WORK_DIR/odin_flat}"
TRIPLEA_REMOTE="${TRIPLEA_REMOTE:-https://github.com/triplea-game/triplea}"
TRIPLEA_REF="${TRIPLEA_REF:-main}"
ROUNDS="${ROUNDS:-8}"
BOOTSTRAP_SNAPSHOTS="${BOOTSTRAP_SNAPSHOTS:-0}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$TRIPLEA_DIR/game-app/smoke-testing/build/snapshots}"
SNAPSHOT_OUT="${SNAPSHOT_OUT:-$TRIPLEA_DIR/conversion/odin_tests}"

export WORK_DIR TRIPLEA_DIR PORT_DB ODIN_FLAT_DIR

SKIP_CLONE=0
SKIP_TEST=0
for arg in "$@"; do
  case "$arg" in
    --skip-clone) SKIP_CLONE=1 ;;
    --skip-test)  SKIP_TEST=1 ;;
    -h|--help)
      sed -n '2,30p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) echo "unknown arg: $arg"; exit 2 ;;
  esac
done

step() { printf "\n\033[1;36m=== STEP %s — %s ===\033[0m\n" "$1" "$2"; }
log()  { printf "  %s\n" "$*"; }

# ---------------------------------------------------------------------------
# 1. Clone TripleA (skip if --skip-clone)
# ---------------------------------------------------------------------------
step 1 "clone TripleA"
if [ "$SKIP_CLONE" -eq 1 ]; then
  log "skipping (--skip-clone), expecting $TRIPLEA_DIR to exist"
elif [ -d "$TRIPLEA_DIR/.git" ]; then
  log "$TRIPLEA_DIR already exists; skipping clone"
else
  log "git clone $TRIPLEA_REMOTE $TRIPLEA_DIR (ref: $TRIPLEA_REF)"
  git clone "$TRIPLEA_REMOTE" "$TRIPLEA_DIR"
  ( cd "$TRIPLEA_DIR" && git checkout "$TRIPLEA_REF" )
fi
[ -d "$TRIPLEA_DIR" ] || { echo "TRIPLEA_DIR missing: $TRIPLEA_DIR"; exit 1; }

# ---------------------------------------------------------------------------
# 2. Patch TripleA (jacoco aggregation, round-limit bump)
# ---------------------------------------------------------------------------
step 2 "patch TripleA build files"
python3 "$SCRIPTS/patch_triplea.py" --triplea "$TRIPLEA_DIR" --rounds "$ROUNDS"

# ---------------------------------------------------------------------------
# 3. Compile Java (main + test) so we have .class files for entity
#    extraction. Test classes hold the JaCoCo entry-point harness
#    (Ww2v5JacocoRun, SnapshotHarness, GameTestUtils); they're the
#    runtime top-of-stack and must be in the dependency graph for
#    layering to bottom-out correctly.
# ---------------------------------------------------------------------------
step 3 "compile Java sources (main + test)"
( cd "$TRIPLEA_DIR" && ./gradlew --no-daemon \
    compileJava compileTestJava \
    -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest )

# ---------------------------------------------------------------------------
# 4. Run Ww2v5JacocoRun under JaCoCo (skip if --skip-test).
#    Note: entity extraction (formerly step 4) is now step 5 below — it
#    runs AFTER JaCoCo so the test classes are guaranteed compiled and
#    the harness procs are scanned in the same javap pass as main.
# ---------------------------------------------------------------------------
step 4 "run Ww2v5JacocoRun under JaCoCo"
if [ "$SKIP_TEST" -eq 1 ]; then
  log "skipping (--skip-test), expecting existing jacoco.xml"
else
  ( cd "$TRIPLEA_DIR" && ./gradlew --no-daemon \
      :game-app:smoke-testing:test \
      --tests "*Ww2v5JacocoRun.run" \
      :game-app:smoke-testing:jacocoTestReport \
      --rerun-tasks \
      -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest )
fi

JACOCO_XML="$TRIPLEA_DIR/game-app/smoke-testing/build/jacoco.xml"
[ -f "$JACOCO_XML" ] || { echo "missing $JACOCO_XML"; exit 1; }

# ---------------------------------------------------------------------------
# 5. Extract entities + dependencies via javap (main + test)
#    Runs after JaCoCo so test classes are guaranteed compiled and the
#    harness procs (Ww2v5JacocoRun, SnapshotHarness, GameTestUtils) are
#    scanned in the same pass. INCLUDE_TEST_CLASSES=1 also flips them
#    is_test_harness=1 in the entities table.
# ---------------------------------------------------------------------------
step 5 "extract entities + dependencies via javap (main + test)"
INCLUDE_TEST_CLASSES=1 python3 "$SCRIPTS/extract_entities.py" \
  --db "$PORT_DB" --triplea "$TRIPLEA_DIR" --include-tests

# ---------------------------------------------------------------------------
# 5b. (Optional) Run Ww2v5JacocoRun.runWithSnapshots — seeded 1-round dump
# ---------------------------------------------------------------------------
if [ "$BOOTSTRAP_SNAPSHOTS" = "1" ]; then
  step "5b" "run Ww2v5JacocoRun.runWithSnapshots (seeded, 1 round)"
  ( cd "$TRIPLEA_DIR" && ./gradlew --no-daemon \
      :game-app:smoke-testing:test \
      --tests "*Ww2v5JacocoRun.runWithSnapshots" \
      --rerun-tasks \
      -Dsnapshot.outDir="$SNAPSHOT_DIR" \
      -x checkstyleMain -x checkstyleTest -x pmdMain -x pmdTest \
      -x jacocoTestReport )
  log "raw snapshots in $SNAPSHOT_DIR"

  step "5c" "process snapshots into per-proc test directories"
  python3 "$SCRIPTS/process_snapshots.py" \
    --input "$SNAPSHOT_DIR" --output "$SNAPSHOT_OUT"
  log "processed snapshots in $SNAPSHOT_OUT"
fi

# ---------------------------------------------------------------------------
# 6. Apply JaCoCo coverage to entities table
# ---------------------------------------------------------------------------
step 6 "apply JaCoCo coverage"
python3 "$SCRIPTS/apply_jacoco.py" --db "$PORT_DB" --xml "$JACOCO_XML"

# ---------------------------------------------------------------------------
# 7. Build called-only methods + structs tables, layered via SCC.
#    Synthesizes virtual-dispatch override edges so abstract/interface
#    procs participate in layering instead of bottoming out at layer 0.
# ---------------------------------------------------------------------------
step 7 "build methods + structs tables (SCC-layered)"
python3 "$SCRIPTS/build_called_layered_tables.py" --db "$PORT_DB"

# ---------------------------------------------------------------------------
# 7b. Auto-mark trivially-implemented methods (abstract interface + UI/IO
#     lambdas) so the orchestrator doesn't re-dispatch them forever.
# ---------------------------------------------------------------------------
step "7b" "auto-mark abstract-interface + UI lambda methods is_implemented=1"
python3 "$SCRIPTS/auto_implement_trivial_methods.py" --db "$PORT_DB"

# ---------------------------------------------------------------------------
# 8. ID-based design what-if layering (resolves cycles)
# ---------------------------------------------------------------------------
step 8 "ID-based design layering (id_design_layer, scc_id)"
python3 "$SCRIPTS/id_design_layering.py" \
  --db "$PORT_DB" --triplea "$TRIPLEA_DIR"

# ---------------------------------------------------------------------------
# 9. Generate blank .odin files (one per Java owner class)
# ---------------------------------------------------------------------------
step 9 "generate blank .odin stubs"
python3 "$SCRIPTS/generate_odin_stubs.py" \
  --db "$PORT_DB" --out "$ODIN_FLAT_DIR"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "================================================================"
echo "Bootstrap complete."
echo
sqlite3 "$PORT_DB" <<SQL
.headers on
.mode column
SELECT 'entities'      AS tbl, COUNT(*) AS rows FROM entities
UNION ALL SELECT 'dependencies', COUNT(*) FROM dependencies
UNION ALL SELECT 'structs',      COUNT(*) FROM structs
UNION ALL SELECT 'methods',      COUNT(*) FROM methods;
SQL
echo
echo "Database:    $PORT_DB"
echo "Odin stubs:  $ODIN_FLAT_DIR"
echo "Next:        read llm-instructions.md and start porting layer 0."
