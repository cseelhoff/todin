#!/usr/bin/env bash
# Single-snapshot runner with clear per-step status (no tail piping).
#
# Usage:
#   ./run_snap.sh            # snap 0013 (default)
#   ./run_snap.sh 0015       # any 4-digit snap id
#   ./run_snap.sh 0015 -debug
#
# Output is streamed live AND captured to /tmp/snap-NNNN.log.

set -u

SNAP="${1:-0013}"
shift || true
EXTRA_ARGS=("$@")

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ODIN_FLAT="${REPO_ROOT}/odin_flat"
ODIN_BIN="${ODIN:-$(command -v odin || true)}"

if [[ -z "${ODIN_BIN}" || ! -x "${ODIN_BIN}" ]]; then
    echo "ERROR: 'odin' compiler not found." >&2
    exit 1
fi

LOG="/tmp/snap-${SNAP}.log"
echo ">>> snap=${SNAP}  log=${LOG}"
echo ">>> extra args: ${EXTRA_ARGS[*]:-(none)}"
echo

cd "${REPO_ROOT}/triplea"

# stdbuf -oL forces line-buffered stdout so we see snap progress live.
SECONDS=0
stdbuf -oL "${ODIN_BIN}" test conversion/odin_tests/server_game_run_next_step \
    -collection:flat="${ODIN_FLAT}" \
    -collection:test_common=conversion/odin_tests/test_common \
    -define:ODIN_TEST_THREADS=1 \
    -define:ODIN_TEST_TRACK_MEMORY=false \
    "-define:FILTER_SNAP=\"${SNAP}\"" \
    "${EXTRA_ARGS[@]}" \
    2>&1 | stdbuf -oL tee "${LOG}"
status="${PIPESTATUS[0]}"

echo
echo ">>> snap ${SNAP}: exit=${status}  elapsed=${SECONDS}s  log=${LOG}"
exit "${status}"
