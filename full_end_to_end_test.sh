#!/usr/bin/env bash
# Full-fidelity 52-snapshot test run for the TripleA Odin port.
#
# - Uses Java-faithful AI (no FAST_AI override -> 16-100 sims per battle).
# - Continues past failures so a single run produces the complete pass/fail
#   profile (snapshot_runner now uses log.errorf instead of testing.expectf
#   on per-snapshot diffs).
# - Tees output to a timestamped log under /tmp.
#
# Usage:
#   ./full_end_to_end_test.sh                 # uses `odin` from $PATH
#   ODIN=/path/to/odin ./full_end_to_end_test.sh
#
# Run from the repo root (the directory containing odin_flat/ and triplea/).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ODIN_FLAT="${REPO_ROOT}/odin_flat"
TRIPLEA_DIR="${REPO_ROOT}/triplea"
TEST_PKG="conversion/odin_tests/server_game_run_next_step"
TEST_COMMON="conversion/odin_tests/test_common"

ODIN_BIN="${ODIN:-$(command -v odin || true)}"
if [[ -z "${ODIN_BIN}" || ! -x "${ODIN_BIN}" ]]; then
    echo "ERROR: 'odin' compiler not found. Set ODIN=/path/to/odin or add it to PATH." >&2
    exit 1
fi

if [[ ! -d "${ODIN_FLAT}" ]]; then
    echo "ERROR: odin_flat/ not found at ${ODIN_FLAT}" >&2
    exit 1
fi

if [[ ! -d "${TRIPLEA_DIR}/${TEST_PKG}" ]]; then
    echo "ERROR: test package not found at ${TRIPLEA_DIR}/${TEST_PKG}" >&2
    exit 1
fi

LOG="/tmp/snap-fullrun-$(date +%Y%m%d-%H%M%S).log"

echo "Odin compiler: ${ODIN_BIN}"
echo "odin_flat:     ${ODIN_FLAT}"
echo "triplea:       ${TRIPLEA_DIR}"
echo "log:           ${LOG}"
echo

cd "${TRIPLEA_DIR}"

# Run the full 52-snapshot suite with full Java fidelity.
# Tee everything; capture exit status from the test runner (not tee).
set +e
time "${ODIN_BIN}" test "${TEST_PKG}" \
    -collection:flat="${ODIN_FLAT}" \
    -collection:test_common="${TEST_COMMON}" \
    -define:ODIN_TEST_TRACK_MEMORY=false \
    2>&1 | tee "${LOG}"
status="${PIPESTATUS[0]}"
set -e

echo
echo "=================================================================="
echo "SUMMARY"
echo "=================================================================="
grep -E "Snapshot .* FAILED|Results:" "${LOG}" || echo "(no per-snapshot lines found)"
echo
echo "Log: ${LOG}"
echo "Test runner exit status: ${status}"
exit "${status}"
